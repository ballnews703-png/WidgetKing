import XCTest
import UIKit
@testable import WidgetKing

// Native twin of tests/renderer.mjs: every template the web designer ships
// (tests/fixtures/designs.json, bundled into this test target) renders at
// every widget family with live data present AND absent, never crashes, and
// never produces a blank image. Hostile inputs degrade instead of failing.
final class WKRendererTests: XCTestCase {

    static var fixtures: [WKDesign] = {
        let bundle = Bundle(for: WKRendererTests.self)
        guard let url = bundle.url(forResource: "designs", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return WKDesign.decodeArray(data)
    }()

    func testFixturesDecode() {
        let designs = Self.fixtures
        XCTAssertGreaterThan(designs.count, 50, "fixture designs.json should bundle every template")
        let kinds = Set(designs.map { $0.kind })
        for k in ["freestyle", "lock", "clock", "launcher", "quote", "countdown"] {
            XCTAssertTrue(kinds.contains(k), "missing kind \(k)")
        }
        let elementKinds = Set(designs.flatMap { $0.elements.map { $0.kind } })
        for k in ["shape", "text", "weather", "clock", "date", "ring", "progress", "astro", "calendar", "app"] {
            XCTAssertTrue(elementKinds.contains(k), "missing element kind \(k)")
        }
        XCTAssertEqual(WKData.themes.count, 22)
        XCTAssertEqual(WKData.iconThemes.count, 18)
        XCTAssertGreaterThan(WKData.vglyphs.count, 40)
    }

    /// Fraction of pixels with any opacity, sampled on a shrunken copy.
    func coverage(_ img: UIImage) -> Double {
        let w = 24, h = 24
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cg = img.cgImage else { return 0 }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var opaque = 0
        for i in 0..<(w * h) where pixels[i * 4 + 3] > 8 { opaque += 1 }
        return Double(opaque) / Double(w * h)
    }

    func testEveryTemplateRendersAtEveryFamily() {
        let designs = Self.fixtures
        XCTAssertFalse(designs.isEmpty)
        let families: [WKFamily] = [.small, .medium, .large, .extraLargePortrait, .accessoryRectangular, .accessoryCircular]
        for live in [WKLiveData.sample, WKLiveData.offline] {
            var r = WKRenderer(live: live)
            r.scale = 2
            for d in designs {
                for fam in families {
                    let img = r.render(d, family: fam)
                    let expected = fam.points
                    XCTAssertEqual(img.size.width, (expected.width * 2).rounded(), "\(d.name) \(fam)")
                    XCTAssertEqual(img.size.height, (expected.height * 2).rounded(), "\(d.name) \(fam)")
                    let cov = coverage(img)
                    // Clear backgrounds are transparent by design; everything else paints most of the canvas.
                    let minimum = d.background == "clear" ? 0.0 : (fam.isAccessory ? 0.3 : 0.9)
                    XCTAssertGreaterThanOrEqual(cov, minimum, "\(d.name) at \(fam) rendered mostly blank (\(cov))")
                }
            }
        }
    }

    func testHostileDesignsDegradeInsteadOfCrashing() {
        let hostile: [[String: Any]] = [
            [:],
            ["kind": "freestyle", "canvasElements": [["kind": "text", "text": 42, "x": "0.5", "y": Double.nan, "size": -3],
                                                      ["kind": "shape", "w": 0, "h": 0, "colorHex": "red", "border": 999],
                                                      ["kind": "ring", "source": "bogus", "w": 50],
                                                      ["kind": "month", "size": 400, "w": 3],
                                                      ["kind": "photo", "dataUrl": "data:image/png;base64,!!!notbase64!!!"],
                                                      ["kind": "art", "artType": "arc", "text": "", "w": 0],
                                                      ["kind": "app", "label": NSNull(), "iconTheme": "nope"],
                                                      ["kind": "unknownkind"]]],
            ["kind": "launcher", "apps": [["label": "Spotify", "url": "spotify://"], ["label": 7]], "launcherStyle": ["iconSize": "huge", "columns": -4, "iconTheme": "neonsign"]],
            ["kind": "lock", "lockRows": [["kind": "mystery"], ["kind": "countdown", "dateISO": "not-a-date"]], "lockStyle": "triangle"],
            ["kind": "quote", "primaryText": "", "themeID": "custom", "customColors": ["#12", "blue"]],
            ["kind": "playlist", "playlist": ["morning": "missing"]],
            ["kind": "freestyle", "themeID": "nonexistent", "gradientDir": "mesh", "bgPattern": "waves", "background": "glass", "glassTint": "light", "bgOpacity": 0.3],
            ["kind": "clock", "fontStyle": "comic-sans", "textColorHex": "#GGGGGG", "background": "clear"]
        ]
        var r = WKRenderer(live: .sample)
        r.scale = 2
        for (i, raw) in hostile.enumerated() {
            let d = WKDesign(raw)
            for fam in WKFamily.allCases {
                let img = r.render(d, family: fam)
                XCTAssertGreaterThan(img.size.width, 0, "hostile \(i) at \(fam)")
            }
        }
    }

    func testTextFormattersMatchTheTemplate() {
        let el = WKElement(["kind": "weather", "wmode": "hilo", "unit": "f"])
        XCTAssertEqual(WKText.weather(el, WKLiveData.sample.weather), "H 79° · L 64°")
        XCTAssertEqual(WKText.weather(WKElement(["wmode": "rain"]), nil), "☔ --%")
        XCTAssertEqual(WKText.stock(WKElement(["symbol": "aapl"]), WKStockQuote(price: 229.1, pct: 1.2)), "AAPL 229.1 ▲1.2%")
        XCTAssertEqual(WKText.stock(WKElement(["symbol": "BTC-USD", "mode": "price"]), WKStockQuote(price: 64210, pct: 2.4)), "BTC-USD 64210")
        XCTAssertEqual(WKText.reminders(WKElement(["count": 1]), []), "All done ✓")
        XCTAssertEqual(WKText.calendar(WKElement(["count": 2]), nil), "Calendar off")
        XCTAssertEqual(WKText.news(WKElement(["count": 1]), ["Markets rally as rates hold steady - Example News"]), "▪ Markets rally as rates hold steady")
        XCTAssertEqual(WKText.sleeper(WKElement(["mode": "record"]), nil), "– · –")
        XCTAssertEqual(WKText.moonInfo(Date(timeIntervalSince1970: 946750440)).slug, "new")
        let oct1 = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 12))!
        XCTAssertEqual(WKText.daysUntil("2026-10-05", now: oct1), 4)
        XCTAssertEqual(WKText.daysUntil("2026-09-28", now: oct1), -3)
        XCTAssertEqual(WKText.daysUntil("", now: oct1), 0)
        XCTAssertTrue(WKText.greeting(WKElement(["name": "Andrew"])).contains(", Andrew"))
        let layout = WKDesign(["kind": "freestyle", "fitSize": "small",
                               "canvasElements": [["id": "a", "kind": "text", "x": 0.1, "y": 0.1, "size": 10]],
                               "sizes": ["medium": [["id": "a", "x": 0.9, "y": 0.8, "size": 20]]]])
        let applied = layout.applyingSizeLayout("medium")
        XCTAssertEqual(applied.elements[0].x, 0.9)
        XCTAssertEqual(applied.elements[0].size, 20)
        XCTAssertEqual(layout.applyingSizeLayout("small").elements[0].x, 0.1)
    }
}
