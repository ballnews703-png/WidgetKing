import XCTest
@testable import WidgetKing

// The live-data parsers against canned payloads shaped like the real
// services, so a format change shows up here before it blanks a widget.
final class WKLiveFetchTests: XCTestCase {
    func testWeatherParsesOpenMeteo() {
        let json = """
        {"current":{"temperature_2m":71.6,"weather_code":2},
         "daily":{"temperature_2m_max":[79.2,70.1],"temperature_2m_min":[63.8,58.4],"precipitation_probability_max":[20,60],"weather_code":[2,61]},
         "hourly":{"temperature_2m":[60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83],
                   "weather_code":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,3,3,61,61,61,61,61,61,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
        """.data(using: .utf8)!
        let w = WKLiveFetch.parseWeather(json, hourNow: 12)!
        XCTAssertEqual(w.code, 2); XCTAssertEqual(w.tempF, 72); XCTAssertEqual(w.hiF, 79); XCTAssertEqual(w.loF, 64)
        XCTAssertEqual(w.rainPct, 20); XCTAssertEqual(w.tmCode, 61); XCTAssertEqual(w.tmHiF, 70); XCTAssertEqual(w.tmLoF, 58)
        XCTAssertEqual(w.hours.map { $0.h }, [14, 16, 18])
        XCTAssertEqual(w.hours.map { $0.code }, [2, 3, 61])
        XCTAssertEqual(WKText.weather(WKElement(["wmode": "hourly"]), w), "2P 🌤74°  4P ☁️76°  6P 🌧78°")
        XCTAssertNil(WKLiveFetch.parseWeather("{}".data(using: .utf8)!, hourNow: 1))
    }

    func testAstroParsesSunTimes() {
        let json = #"{"daily":{"sunrise":["2026-10-05T06:52"],"sunset":["2026-10-05T19:04"]}}"#.data(using: .utf8)!
        let a = WKLiveFetch.parseAstro(json)!
        XCTAssertEqual(WKText.shortClock(a.sunrise), "6:52 AM")
        XCTAssertEqual(WKText.shortClock(a.sunset), "7:04 PM")
        XCTAssertEqual(WKText.astro(WKElement(["mode": "sunset"]), a), "🌇 7:04 PM")
    }

    func testStockParsesYahooChart() {
        let json = #"{"chart":{"result":[{"meta":{"regularMarketPrice":229.1,"chartPreviousClose":226.38}}]}}"#.data(using: .utf8)!
        let q = WKLiveFetch.parseStock(json)!
        XCTAssertEqual(q.price, 229.1)
        XCTAssertEqual(q.pct, 1.2, accuracy: 0.05)
        XCTAssertEqual(WKText.stock(WKElement(["symbol": "aapl"]), q), "AAPL 229.1 ▲1.2%")
        XCTAssertNil(WKLiveFetch.parseStock(#"{"chart":{"result":[]}}"#.data(using: .utf8)!))
    }

    func testNewsParsesRssAndDropsTheFeedName() {
        let xml = """
        <rss><channel><title>Google News</title><image><title>Google News</title></image>
        <item><title><![CDATA[Markets rally as rates hold steady - Example News]]></title></item>
        <item><title>City opens new park &amp; garden</title></item>
        <item><title>  </title></item></channel></rss>
        """
        let titles = WKLiveFetch.parseNews(xml)
        XCTAssertEqual(titles, ["Markets rally as rates hold steady - Example News", "City opens new park & garden"])
        XCTAssertEqual(WKText.news(WKElement(["count": 2]), titles), "▪ Markets rally as rates hold steady\n▪ City opens new park & garden")
    }

    func testSleeperParsesMatchup() {
        let rosters = #"[{"roster_id":1,"owner_id":"u1","settings":{"wins":5,"losses":2,"fpts":900}},{"roster_id":2,"owner_id":"u2","settings":{"wins":6,"losses":1,"fpts":950}}]"#.data(using: .utf8)!
        let users = #"[{"user_id":"u1","display_name":"Andrew","metadata":{"team_name":"Crown Jewels"}},{"user_id":"u2","display_name":"Rival"}]"#.data(using: .utf8)!
        let matchups = #"[{"roster_id":1,"matchup_id":7,"points":112.44},{"roster_id":2,"matchup_id":7,"points":98.71}]"#.data(using: .utf8)!
        let s = WKLiveFetch.parseSleeper(rosters: rosters, users: users, matchups: matchups, userID: "u1")!
        XCTAssertEqual(s.wins, 5); XCTAssertEqual(s.losses, 2); XCTAssertEqual(s.rank, 2)
        XCTAssertEqual(s.me, 112.4); XCTAssertEqual(s.opp, 98.7)
        XCTAssertEqual(s.myTeamName, "Crown Jewels"); XCTAssertEqual(s.oppTeamName, "Rival")
        XCTAssertEqual(WKText.sleeper(WKElement(["mode": "record"]), s), "5-2 · #2")
        XCTAssertNil(WKLiveFetch.parseSleeper(rosters: rosters, users: users, matchups: nil, userID: "nobody"))
    }

    func testLocationRoundTripsThroughTheAppGroup() {
        WKLiveFetch.setLocation(lat: 36.85, lon: -75.98)
        XCTAssertEqual(WKLiveFetch.location?.0, 36.85)
        XCTAssertEqual(WKLiveFetch.location?.1, -75.98)
    }

    func testStockArtComesFromTheBundle() {
        XCTAssertNotNil(WKAssets.stockArt("clear-day"))
        XCTAssertNil(WKAssets.stockArt("../../etc/passwd"))
        XCTAssertNil(WKAssets.stockArt(""))
    }

    func testLockRendersWithoutBackdropForWidgetKit() {
        var r = WKRenderer(live: .sample)
        r.scale = 2
        r.lockBackdrop = false
        let design = WKDesign(["kind": "lock", "lockStyle": "rect", "lockRows": [["kind": "text", "text": "UP NEXT"], ["kind": "weather"]]])
        let img = r.render(design, family: .accessoryRectangular, pointSize: CGSize(width: 160, height: 72))
        XCTAssertEqual(img.size.width, 320)
        XCTAssertEqual(img.size.height, 144)
    }
}
