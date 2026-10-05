import Foundation
import UIKit
import EventKit

// Live data for the widget extension: the same services the Scriptable
// template calls (Open-Meteo, Yahoo Finance, Google News RSS, Sleeper,
// EventKit, the battery) with the same caching windows, parsed by pure
// functions so the unit tests can feed canned payloads. Location comes from
// the App Group (the app stores it once the user allows it); without it,
// weather and sun/moon elements render their "--" placeholders.
enum WKLiveFetch {
    static let latKey = "widgetking.lat"
    static let lonKey = "widgetking.lon"

    static var location: (Double, Double)? {
        let d = WKStore.defaults
        guard let lat = d.object(forKey: latKey) as? Double, let lon = d.object(forKey: lonKey) as? Double else { return nil }
        return (lat, lon)
    }
    static func setLocation(lat: Double, lon: Double) {
        WKStore.defaults.set(lat, forKey: latKey)
        WKStore.defaults.set(lon, forKey: lonKey)
    }

    // MARK: cache (App Group container, JSON per key)

    static func cacheURL(_ key: String) -> URL? {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WKStore.groupID) else { return nil }
        let safe = key.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
        return dir.appendingPathComponent("widgetking-" + safe + ".json")
    }
    static func cached(_ key: String, maxAge: TimeInterval) -> Data? {
        guard let url = cacheURL(key), let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let mod = attrs[.modificationDate] as? Date, Date().timeIntervalSince(mod) < maxAge else { return nil }
        return try? Data(contentsOf: url)
    }
    static func staleCached(_ key: String) -> Data? {
        guard let url = cacheURL(key) else { return nil }
        return try? Data(contentsOf: url)
    }
    static func store(_ key: String, _ data: Data) {
        guard let url = cacheURL(key) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Fetch with a freshness window; on failure the stale cache still serves.
    static func fetch(_ key: String, url: URL, maxAge: TimeInterval) async -> Data? {
        if let d = cached(key, maxAge: maxAge) { return d }
        var req = URLRequest(url: url)
        req.timeoutInterval = 12
        if let result = try? await URLSession.shared.data(for: req),
           let http = result.1 as? HTTPURLResponse, (200..<300).contains(http.statusCode), !result.0.isEmpty {
            store(key, result.0)
            return result.0
        }
        return staleCached(key)
    }

    // MARK: parsers (pure)

    static func json(_ data: Data) -> Any? { return try? JSONSerialization.jsonObject(with: data) }
    static func num(_ v: Any?) -> Double? {
        if let n = v as? NSNumber { return n.doubleValue.isFinite ? n.doubleValue : nil }
        if let s = v as? String { return Double(s) }
        return nil
    }

    static func parseWeather(_ data: Data, hourNow: Int) -> WKWeather? {
        guard let root = json(data) as? [String: Any], let cur = root["current"] as? [String: Any],
              let temp = num(cur["temperature_2m"]), let code = num(cur["weather_code"]) else { return nil }
        var w = WKWeather(code: Int(code), tempF: temp.rounded(), hiF: temp, loF: temp, rainPct: nil, tmCode: Int(code), tmHiF: temp, tmLoF: temp, hours: [])
        if let d = root["daily"] as? [String: Any] {
            let hi = d["temperature_2m_max"] as? [Any] ?? [], lo = d["temperature_2m_min"] as? [Any] ?? []
            let rain = d["precipitation_probability_max"] as? [Any] ?? [], codes = d["weather_code"] as? [Any] ?? []
            if hi.count > 0, let v = num(hi[0]) { w.hiF = v.rounded() }
            if lo.count > 0, let v = num(lo[0]) { w.loF = v.rounded() }
            if rain.count > 0 { w.rainPct = Int((num(rain[0]) ?? 0).rounded()) }
            if hi.count > 1, let v = num(hi[1]) { w.tmHiF = v.rounded() }
            if lo.count > 1, let v = num(lo[1]) { w.tmLoF = v.rounded() }
            if codes.count > 1, let v = num(codes[1]) { w.tmCode = Int(v) }
        }
        if let h = root["hourly"] as? [String: Any] {
            let temps = h["temperature_2m"] as? [Any] ?? [], codes = h["weather_code"] as? [Any] ?? []
            for k in 1...3 {
                let idx = hourNow + k * 2
                if idx > 47 || idx >= temps.count || idx >= codes.count { break }
                if let t = num(temps[idx]), let c = num(codes[idx]) {
                    w.hours.append(WKWeatherHour(h: idx % 24, code: Int(c), tempF: t.rounded()))
                }
            }
        }
        return w
    }

    static func parseAstro(_ data: Data) -> WKAstro? {
        guard let root = json(data) as? [String: Any], let d = root["daily"] as? [String: Any],
              let rise = (d["sunrise"] as? [Any])?.first as? String, let set = (d["sunset"] as? [Any])?.first as? String else { return nil }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.timeZone = TimeZone.current
        guard let r = f.date(from: rise), let s = f.date(from: set) else { return nil }
        return WKAstro(sunrise: r, sunset: s)
    }

    static func parseStock(_ data: Data) -> WKStockQuote? {
        guard let root = json(data) as? [String: Any], let chart = root["chart"] as? [String: Any],
              let result = (chart["result"] as? [Any])?.first as? [String: Any], let meta = result["meta"] as? [String: Any],
              let price = num(meta["regularMarketPrice"]) else { return nil }
        let prev = num(meta["chartPreviousClose"]) ?? num(meta["previousClose"]) ?? price
        return WKStockQuote(price: price, pct: prev != 0 ? (price - prev) / prev * 100 : 0)
    }

    static func parseNews(_ xml: String) -> [String] {
        var titles: [String] = []
        guard let re = try? NSRegularExpression(pattern: "<title>(?:<!\\[CDATA\\[)?([^<]*?)(?:\\]\\]>)?</title>") else { return [] }
        let ns = xml as NSString
        for m in re.matches(in: xml, range: NSRange(location: 0, length: ns.length)) {
            if titles.count >= 7 { break }
            var t = ns.substring(with: m.range(at: 1))
            for (a, b) in [("&amp;", "&"), ("&#39;", "'"), ("&apos;", "'"), ("&quot;", "\""), ("&lt;", "<"), ("&gt;", ">")] { t = t.replacingOccurrences(of: a, with: b) }
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty && t.lowercased() != "google news" { titles.append(t) }
        }
        return titles
    }

    static func parseSleeper(rosters: Data, users: Data, matchups: Data?, userID: String) -> WKSleeper? {
        guard let rs = json(rosters) as? [[String: Any]], let us = json(users) as? [[String: Any]] else { return nil }
        guard let mine = rs.first(where: { ($0["owner_id"] as? String) == userID }) else { return nil }
        func settings(_ r: [String: Any]) -> [String: Any] { return r["settings"] as? [String: Any] ?? [:] }
        func teamName(_ ownerID: String?) -> String {
            let u = us.first { ($0["user_id"] as? String) == ownerID } ?? [:]
            let meta = u["metadata"] as? [String: Any] ?? [:]
            let name = (meta["team_name"] as? String) ?? (u["display_name"] as? String) ?? "Team"
            return String(name.prefix(18))
        }
        let sorted = rs.sorted { a, b in
            let aw = num(settings(a)["wins"]) ?? 0, bw = num(settings(b)["wins"]) ?? 0
            if aw != bw { return aw > bw }
            return (num(settings(a)["fpts"]) ?? 0) > (num(settings(b)["fpts"]) ?? 0)
        }
        let rank = (sorted.firstIndex { ($0["roster_id"] as? NSNumber) == (mine["roster_id"] as? NSNumber) } ?? 0) + 1
        var out = WKSleeper(me: 0, opp: 0, wins: Int(num(settings(mine)["wins"]) ?? 0), losses: Int(num(settings(mine)["losses"]) ?? 0),
                            rank: rank, myTeamName: teamName(userID), oppTeamName: "Opponent")
        if let md = matchups, let ms = json(md) as? [[String: Any]],
           let my = ms.first(where: { ($0["roster_id"] as? NSNumber) == (mine["roster_id"] as? NSNumber) }) {
            out.me = ((num(my["points"]) ?? 0) * 10).rounded() / 10
            if let opp = ms.first(where: { ($0["matchup_id"] as? NSNumber) == (my["matchup_id"] as? NSNumber) && ($0["roster_id"] as? NSNumber) != (my["roster_id"] as? NSNumber) }) {
                out.opp = ((num(opp["points"]) ?? 0) * 10).rounded() / 10
                if let r = rs.first(where: { ($0["roster_id"] as? NSNumber) == (opp["roster_id"] as? NSNumber) }) {
                    out.oppTeamName = teamName(r["owner_id"] as? String)
                }
            }
        }
        return out
    }

    // MARK: fetchers

    static func weather() async -> WKWeather? {
        guard let loc = location else { return nil }
        let lat = loc.0, lon = loc.1
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code&hourly=temperature_2m,weather_code&forecast_days=2&timezone=auto&temperature_unit=fahrenheit")!
        guard let data = await fetch("weather2", url: url, maxAge: 30 * 60) else { return nil }
        return parseWeather(data, hourNow: Calendar.current.component(.hour, from: Date()))
    }

    static func astro() async -> WKAstro? {
        guard let loc = location else { return nil }
        let lat = loc.0, lon = loc.1
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=sunrise,sunset&timezone=auto&forecast_days=1")!
        guard let data = await fetch("astro", url: url, maxAge: 3 * 60 * 60) else { return nil }
        return parseAstro(data)
    }

    static func stock(_ symbol: String) async -> WKStockQuote? {
        let clean = symbol.trimmingCharacters(in: .whitespaces).uppercased()
        guard !clean.isEmpty, let enc = clean.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(enc)?range=1d&interval=1d") else { return nil }
        guard let data = await fetch("stock-" + clean, url: url, maxAge: 15 * 60) else { return nil }
        return parseStock(data)
    }

    static func news() async -> [String]? {
        guard let url = URL(string: "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"),
              let data = await fetch("news", url: url, maxAge: 30 * 60), let xml = String(data: data, encoding: .utf8) else { return nil }
        return parseNews(xml)
    }

    static func sleeper(leagueID: String, userID: String) async -> WKSleeper? {
        guard !leagueID.isEmpty, !userID.isEmpty else { return nil }
        let base = "https://api.sleeper.app/v1"
        guard let stateData = await fetch("sleeper-state", url: URL(string: base + "/state/nfl")!, maxAge: 20 * 60),
              let state = json(stateData) as? [String: Any] else { return nil }
        let week = max(1, Int(num(state["display_week"]) ?? num(state["week"]) ?? 1))
        guard let rosters = await fetch("sleeper-rosters-" + leagueID, url: URL(string: base + "/league/\(leagueID)/rosters")!, maxAge: 20 * 60),
              let users = await fetch("sleeper-users-" + leagueID, url: URL(string: base + "/league/\(leagueID)/users")!, maxAge: 20 * 60) else { return nil }
        let matchups = await fetch("sleeper-matchups-" + leagueID, url: URL(string: base + "/league/\(leagueID)/matchups/\(week)")!, maxAge: 20 * 60)
        return parseSleeper(rosters: rosters, users: users, matchups: matchups, userID: userID)
    }

    static func events(count: Int) -> [WKEvent]? {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return nil }
        let store = EKEventStore()
        let now = Date()
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        guard let end = cal.date(byAdding: .day, value: 14, to: start) else { return nil }
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none
        let events = store.events(matching: pred).filter { $0.endDate > now }.sorted { $0.startDate < $1.startDate }
        return events.prefix(count).map { e in
            var title = e.title ?? "Event"
            if title.count > 20 { title = String(title.prefix(19)) + "…" }
            let dayDiff = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: e.startDate)).day ?? 0
            let when = dayDiff <= 0 ? (e.isAllDay ? "today" : f.string(from: e.startDate)) : dayDiff == 1 ? "tomorrow" : "in \(dayDiff)d"
            return WKEvent(title: title, when: when)
        }
    }

    static func reminders(count: Int) async -> [WKReminder]? {
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else { return nil }
        let store = EKEventStore()
        let pred = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        let items: [EKReminder] = await withCheckedContinuation { cont in
            store.fetchReminders(matching: pred) { cont.resume(returning: $0 ?? []) }
        }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let sorted = items.sorted { a, b in
            let ad = a.dueDateComponents.flatMap { cal.date(from: $0) }?.timeIntervalSince1970 ?? 9e15
            let bd = b.dueDateComponents.flatMap { cal.date(from: $0) }?.timeIntervalSince1970 ?? 9e15
            return ad < bd
        }
        return sorted.prefix(count).map { r in
            var title = r.title ?? "Reminder"
            if title.count > 22 { title = String(title.prefix(21)) + "…" }
            var when: String? = nil
            if let due = r.dueDateComponents.flatMap({ cal.date(from: $0) }) {
                let dayDiff = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: due)).day ?? 0
                when = dayDiff < 0 ? "overdue" : dayDiff == 0 ? "today" : dayDiff == 1 ? "tomorrow" : "in \(dayDiff)d"
            }
            return WKReminder(title: title, when: when)
        }
    }

    static func battery() -> (level: Double, charging: Bool) {
        let dev = UIDevice.current
        dev.isBatteryMonitoringEnabled = true
        let level = dev.batteryLevel
        let state = dev.batteryState
        return (level >= 0 ? Double(level) : 0.8, state == .charging || state == .full)
    }

    /// Only what the design actually shows — the twin of the template's liveDataFor().
    static func liveData(for design: WKDesign) async -> WKLiveData {
        var live = WKLiveData()
        let b = battery()
        live.batteryLevel = b.level
        live.isCharging = b.charging
        var els = design.elements
        if design.kind == "lock" { els = design.lockRows }
        let kinds = Set(els.map { $0.kind })
        if kinds.contains("weather") { live.weather = await weather() }
        if kinds.contains("astro"), els.contains(where: { $0.kind == "astro" && !["moon", "moonicon"].contains($0.str("mode", "sun")) }) {
            live.astro = await astro()
        }
        let calCount = els.filter { $0.kind == "calendar" }.map { WKText.count($0) }.max()
        if let n = calCount { live.events = events(count: n) }
        let remCount = els.filter { $0.kind == "reminders" || $0.kind == "reminder" }.map { WKText.count($0) }.max()
        if let n = remCount { live.reminders = await reminders(count: n) }
        if kinds.contains("news") { live.news = await news() }
        for el in els where el.kind == "stock" {
            let sym = el.str("symbol").trimmingCharacters(in: .whitespaces).uppercased()
            if !sym.isEmpty, live.stocks[sym] == nil, let q = await stock(sym) { live.stocks[sym] = q }
        }
        for el in els where (el.kind == "sleeper" || el.kind == "sleeperlogo") && !el.str("leagueID").isEmpty {
            let league = el.str("leagueID")
            if live.sleeper[league] == nil, let s = await sleeper(leagueID: league, userID: el.str("userID")) { live.sleeper[league] = s }
        }
        return live
    }
}

/// Stock artwork (stickers, moon packs, live weather/battery art) from the
/// bundled web/stock/art folder. The widget extension has no copy of its
/// own, so it reaches into the containing app's bundle.
enum WKAssets {
    static var cache: [String: UIImage] = [:]
    static func stockArt(_ slug: String) -> UIImage? {
        if slug.isEmpty { return nil }
        if let hit = cache[slug] { return hit }
        for bundle in candidateBundles() {
            if let url = bundle.url(forResource: slug, withExtension: "png", subdirectory: "web/stock/art"),
               let img = UIImage(contentsOfFile: url.path) {
                cache[slug] = img
                return img
            }
        }
        return nil
    }
    static func candidateBundles() -> [Bundle] {
        var out = [Bundle.main]
        // An app extension lives at App.app/PlugIns/Ext.appex — two levels up is the app.
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        if appURL.pathExtension == "app", let b = Bundle(url: appURL) { out.append(b) }
        return out
    }
}
