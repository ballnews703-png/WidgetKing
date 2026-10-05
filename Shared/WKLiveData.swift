import Foundation

// Live values a design can show, and the text each element renders from
// them — ported line for line from the Scriptable template so the phone
// shows the same strings the web preview and the Scriptable widget show.
// Fetching (Open-Meteo, EventKit, Yahoo, Sleeper, Google News) lands with
// milestone 3; M1 renders from whatever is supplied here.

struct WKWeatherHour { var h: Int; var code: Int; var tempF: Double }
struct WKWeather {
    var code: Int; var tempF: Double; var hiF: Double; var loF: Double
    var rainPct: Int?; var tmCode: Int; var tmHiF: Double; var tmLoF: Double
    var hours: [WKWeatherHour]
}
struct WKEvent { var title: String; var when: String }
struct WKReminder { var title: String; var when: String? }
struct WKStockQuote { var price: Double; var pct: Double }
struct WKAstro { var sunrise: Date; var sunset: Date }
struct WKSleeper {
    var me: Double; var opp: Double; var wins: Int; var losses: Int; var rank: Int?
    var myTeamName: String?; var oppTeamName: String?
}

struct WKLiveData {
    var weather: WKWeather? = nil
    var events: [WKEvent]? = nil
    var reminders: [WKReminder]? = nil
    var news: [String]? = nil
    var stocks: [String: WKStockQuote] = [:]
    var astro: WKAstro? = nil
    var sleeper: [String: WKSleeper] = [:]
    var batteryLevel: Double = 0.8
    var isCharging: Bool = false

    /// Nothing fetched (first run, no permission, offline): every element
    /// still renders its placeholder text.
    static let offline = WKLiveData()

    /// Plausible values for previews and the render test battery.
    static var sample: WKLiveData {
        var l = WKLiveData()
        l.weather = WKWeather(code: 2, tempF: 72, hiF: 79, loF: 64, rainPct: 20, tmCode: 61, tmHiF: 70, tmLoF: 58,
                              hours: [WKWeatherHour(h: 14, code: 2, tempF: 72), WKWeatherHour(h: 17, code: 3, tempF: 70),
                                      WKWeatherHour(h: 20, code: 61, tempF: 64)])
        l.events = [WKEvent(title: "Team call", when: "2:30 PM"), WKEvent(title: "Dinner out", when: "tomorrow")]
        l.reminders = [WKReminder(title: "Buy groceries", when: "5 PM"), WKReminder(title: "Call mom", when: nil)]
        l.news = ["Markets rally as rates hold steady - Example News", "City opens new riverside park", "Local team clinches playoff spot"]
        l.stocks = ["AAPL": WKStockQuote(price: 229.1, pct: 1.2), "TSLA": WKStockQuote(price: 248.5, pct: -0.8),
                    "BTC-USD": WKStockQuote(price: 64210, pct: 2.4), "ETH-USD": WKStockQuote(price: 3120, pct: -1.1)]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        l.astro = WKAstro(sunrise: cal.date(byAdding: .minute, value: 6 * 60 + 52, to: today)!,
                          sunset: cal.date(byAdding: .minute, value: 19 * 60 + 4, to: today)!)
        l.sleeper = ["": WKSleeper(me: 112.4, opp: 98.7, wins: 5, losses: 2, rank: 2, myTeamName: "Crown Jewels", oppTeamName: "Gridiron Goats")]
        return l
    }

    func sleeper(for leagueID: String) -> WKSleeper? {
        return sleeper[leagueID] ?? sleeper[""]
    }
}

enum WKText {
    static func dayOfYear(_ d: Date) -> Int {
        return (Calendar.current.ordinality(of: .day, in: .year, for: d) ?? 1) - 1
    }
    static func daysUntil(_ iso: String, now: Date = Date()) -> Int {
        let parts = iso.split(separator: "-").map { Int($0) ?? 0 }
        guard parts.count >= 1, parts[0] > 0 else { return 0 }
        var c = DateComponents()
        c.year = parts[0]; c.month = parts.count > 1 ? max(1, parts[1]) : 1; c.day = parts.count > 2 ? max(1, parts[2]) : 1
        let cal = Calendar.current
        guard let target = cal.date(from: c) else { return 0 }
        let today = cal.startOfDay(for: now)
        let secs = target.timeIntervalSince(today)
        return Int((secs / 86400).rounded())
    }
    static func activeQuote(_ design: WKDesign, now: Date = Date()) -> String {
        let lines = design.primaryText.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if lines.count <= 1 { return design.primaryText }
        return lines[dayOfYear(now) % lines.count]
    }
    static func weatherEmoji(_ code: Int) -> String {
        if code == 0 { return "☀️" }
        if code <= 2 { return "🌤" }
        if code == 3 { return "☁️" }
        if code == 45 || code == 48 { return "🌫" }
        if code >= 51 && code <= 67 { return "🌧" }
        if code >= 71 && code <= 77 { return "❄️" }
        if code >= 80 && code <= 82 { return "🌧" }
        if code >= 85 && code <= 86 { return "❄️" }
        if code >= 95 { return "⛈" }
        return "🌡"
    }
    static func weatherWord(_ code: Int) -> String {
        if code == 0 { return "Clear" }
        if code <= 2 { return "Partly cloudy" }
        if code == 3 { return "Overcast" }
        if code == 45 || code == 48 { return "Foggy" }
        if code >= 51 && code <= 57 { return "Drizzle" }
        if code >= 61 && code <= 67 { return "Rain" }
        if code >= 71 && code <= 77 { return "Snow" }
        if code >= 80 && code <= 82 { return "Showers" }
        if code >= 85 && code <= 86 { return "Snow showers" }
        if code >= 95 { return "Thunderstorms" }
        return "Weather"
    }
    static func deg(_ el: WKElement, _ f: Double) -> String {
        guard f.isFinite else { return "--" }
        let c = el.str("unit") == "c"
        return String(Int((c ? (f - 32) * 5 / 9 : f).rounded()))
    }
    static func hourLabel(_ h: Int) -> String {
        let ap = h >= 12 ? "P" : "A"
        var x = h % 12; if x == 0 { x = 12 }
        return "\(x)\(ap)"
    }
    static func weather(_ el: WKElement, _ wx: WKWeather?) -> String {
        let mode = el.str("wmode", "now")
        guard let wx = wx else { return mode == "rain" ? "☔ --%" : "--°" }
        let now = weatherEmoji(wx.code) + " " + deg(el, wx.tempF) + "°"
        switch mode {
        case "hilo": return "H " + deg(el, wx.hiF) + "° · L " + deg(el, wx.loF) + "°"
        case "full": return now + "  H" + deg(el, wx.hiF) + " L" + deg(el, wx.loF)
        case "cond": return weatherWord(wx.code) + " " + deg(el, wx.tempF) + "°"
        case "rain": return "☔ " + (wx.rainPct.map(String.init) ?? "--") + "%"
        case "tomorrow": return "Tmrw " + weatherEmoji(wx.tmCode) + " " + deg(el, wx.tmHiF) + "°/" + deg(el, wx.tmLoF) + "°"
        case "hourly":
            if wx.hours.isEmpty { return now }
            return wx.hours.map { hourLabel($0.h) + " " + weatherEmoji($0.code) + deg(el, $0.tempF) + "°" }.joined(separator: "  ")
        default: return now
        }
    }
    static func greeting(_ el: WKElement, now: Date = Date()) -> String {
        let hr = Calendar.current.component(.hour, from: now)
        let base = hr < 5 ? "Good night" : hr < 12 ? "Good morning" : hr < 17 ? "Good afternoon" : "Good evening"
        let emo = el.bool("emoji", true) ? (hr < 5 ? " 🌙" : hr < 12 ? " ☀️" : hr < 17 ? " 👋" : " 🌆") : ""
        let name = el.str("name").trimmingCharacters(in: .whitespaces)
        return base + (name.isEmpty ? "" : ", " + name) + emo
    }
    static func weekNumber(_ d: Date) -> Int {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone.current
        return cal.component(.weekOfYear, from: d)
    }
    struct Moon { var emoji: String; var name: String; var slug: String }
    static func moonInfo(_ d: Date) -> Moon {
        let synodic = 29.530588853
        let ref = 946750440.0 // 2000-01-06 18:14 UTC
        var age = (d.timeIntervalSince1970 - ref) / 86400
        age = age.truncatingRemainder(dividingBy: synodic)
        if age < 0 { age += synodic }
        let idx = Int(floor(age / synodic * 8 + 0.5)) % 8
        let emojis = ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"]
        let names = ["New moon", "Waxing crescent", "First quarter", "Waxing gibbous", "Full moon", "Waning gibbous", "Last quarter", "Waning crescent"]
        let slugs = ["new", "waxing-crescent", "first-quarter", "waxing-gibbous", "full", "waning-gibbous", "last-quarter", "waning-crescent"]
        return Moon(emoji: emojis[idx], name: names[idx], slug: slugs[idx])
    }
    static func weatherArtSlug(_ c: Int, isDay: Bool) -> String {
        if c == 0 || c == 1 { return isDay ? "clear-day" : "clear-night" }
        if c == 2 { return isDay ? "partly-cloudy-day" : "partly-cloudy-night" }
        if c == 3 { return "overcast" }
        if c == 45 || c == 48 { return "fog" }
        if c >= 51 && c <= 57 { return "drizzle" }
        if c == 61 || c == 63 || c == 80 || c == 81 { return "rain" }
        if c == 65 || c == 82 { return "heavy-rain" }
        if c == 66 || c == 67 { return "sleet" }
        if (c >= 71 && c <= 77) || c == 85 || c == 86 { return "snow" }
        if c == 95 { return "thunderstorm" }
        if c == 96 || c == 99 { return "hail" }
        return "cloudy"
    }
    static func batteryArtSlug(_ level: Double, charging: Bool) -> String {
        if charging { return "battery-charging" }
        if level >= 0.75 { return "battery-full" }
        if level >= 0.35 { return "battery-half" }
        return "battery-low"
    }
    static func shortClock(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
    static func astro(_ el: WKElement, _ astro: WKAstro?, now: Date = Date()) -> String {
        let mode = el.str("mode", "sun")
        if mode == "moon" { let m = moonInfo(now); return m.emoji + " " + m.name }
        if mode == "moonicon" { return moonInfo(now).emoji }
        guard let a = astro else { return "🌅 --  🌇 --" }
        let rise = shortClock(a.sunrise), set = shortClock(a.sunset)
        if mode == "sunrise" { return "🌅 " + rise }
        if mode == "sunset" { return "🌇 " + set }
        if mode == "next" {
            let day = now >= a.sunrise && now < a.sunset
            return day ? "🌇 " + set : "🌅 " + rise
        }
        return "🌅 " + rise + "  🌇 " + set
    }
    static func stock(_ el: WKElement, _ q: WKStockQuote?) -> String {
        var sym = el.str("symbol").trimmingCharacters(in: .whitespaces).uppercased()
        if sym.isEmpty { sym = "STOCK" }
        guard let q = q, q.price.isFinite else { return sym + " --" }
        let arrow = q.pct >= 0 ? "▲" : "▼"
        let price = q.price >= 1000 ? String(Int(q.price.rounded())) : String((q.price * 100).rounded() / 100)
        let pct = abs((q.pct * 10).rounded() / 10)
        let mode = el.str("mode", "both")
        if mode == "price" { return sym + " " + price }
        if mode == "change" { return sym + " " + arrow + " " + trimNum(pct) + "%" }
        return sym + " " + price + " " + arrow + trimNum(pct) + "%"
    }
    static func trimNum(_ v: Double) -> String {
        return v == v.rounded() ? String(Int(v)) : String(v)
    }
    static func worldClock(_ el: WKElement, now: Date = Date()) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "h:mm a"
        if let tz = TimeZone(identifier: el.str("tz")) { f.timeZone = tz }
        else { f.timeZone = TimeZone(secondsFromGMT: Int(el.num("offsetMin", 0)) * 60) ?? .current }
        let t = f.string(from: now)
        let city = el.str("city")
        return (el.bool("showCity", true) && !city.isEmpty ? city + " " : "") + t
    }
    static func count(_ el: WKElement) -> Int { return Int(clamp(el.num("count", 1).rounded(), 1, 4)) }
    static func reminders(_ el: WKElement, _ items: [WKReminder]?) -> String {
        guard let items = items else { return "Reminders off" }
        if items.isEmpty { return "All done ✓" }
        return items.prefix(count(el)).map { "○ " + $0.title + ($0.when.map { " · " + $0 } ?? "") }.joined(separator: "\n")
    }
    static func calendar(_ el: WKElement, _ events: [WKEvent]?) -> String {
        guard let events = events else { return "Calendar off" }
        if events.isEmpty { return "No events ✓" }
        return events.prefix(count(el)).map { $0.title + " · " + $0.when }.joined(separator: "\n")
    }
    static func news(_ el: WKElement, _ titles: [String]?) -> String {
        guard let titles = titles else { return "News unavailable" }
        if titles.isEmpty { return "No headlines right now" }
        return titles.prefix(count(el)).map { t -> String in
            var s = t
            if let r = t.range(of: " - ", options: .backwards), t.distance(from: t.startIndex, to: r.lowerBound) > 20 {
                s = String(t[..<r.lowerBound])
            }
            return "▪ " + (s.count > 92 ? String(s.prefix(90)) + "…" : s)
        }.joined(separator: "\n")
    }
    static func sleeper(_ el: WKElement, _ s: WKSleeper?) -> String {
        let mode = el.str("mode", "score")
        guard let s = s else {
            if mode == "record" { return "– · –" }
            if mode == "myteam" { return "My Team" }
            if mode == "opponent" { return "Opponent" }
            return "Connect Sleeper"
        }
        if mode == "record" { return "\(s.wins)-\(s.losses)" + (s.rank.map { " · #\($0)" } ?? "") }
        if mode == "myteam" { return s.myTeamName ?? "My Team" }
        if mode == "opponent" { return s.oppTeamName ?? "Opponent" }
        return String(format: "%.1f – %.1f", s.me, s.opp)
    }
    static func progressPct(_ el: WKElement, live: WKLiveData, now: Date = Date()) -> Double {
        let src = el.str("source", "day")
        let cal = Calendar.current
        if src == "battery" { return live.batteryLevel }
        if src == "year" {
            let y = cal.component(.year, from: now)
            let start = cal.date(from: DateComponents(year: y, month: 1, day: 1))!
            let end = cal.date(from: DateComponents(year: y + 1, month: 1, day: 1))!
            return now.timeIntervalSince(start) / end.timeIntervalSince(start)
        }
        if src == "countdown" {
            let startISO = el.str("startISO")
            let done = max(0, -daysUntil(startISO.isEmpty ? el.str("dateISO") : startISO, now: now))
            let left = max(0, daysUntil(el.str("dateISO"), now: now))
            let span = done + left
            return span > 0 ? Double(done) / Double(span) : 1
        }
        let c = cal.dateComponents([.hour, .minute, .second], from: now)
        return Double((c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)) / 86400
    }
    static func timeString(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: d)
    }
    static func dateString(_ d: Date, _ format: String) -> String {
        let f = DateFormatter(); f.dateFormat = format
        return f.string(from: d)
    }
}
