import XCTest
import UIKit
@testable import WidgetKing

// Wallpaper slices: the measured frame table, scaled screenshots, the
// proportional fallback, the bridge round-trip, and the renderer using it.
final class WKWallpaperTests: XCTestCase {
    override func tearDown() { WKWallpaper.clear(); super.tearDown() }

    func testMeasuredFramesForAnIPhone17Pro() {
        let r = WKWallpaper.widgetRect(imgW: 1206, imgH: 2622, family: .small, position: "top-left", frameKey: "2622")
        XCTAssertEqual(r, CGRect(x: 87, y: 261, width: 486, height: 486))
        let right = WKWallpaper.widgetRect(imgW: 1206, imgH: 2622, family: .small, position: "middle-right", frameKey: "2622")
        XCTAssertEqual(right.minX, 633); XCTAssertEqual(right.minY, 872)
        let med = WKWallpaper.widgetRect(imgW: 1206, imgH: 2622, family: .medium, position: "bottom", frameKey: "2622")
        XCTAssertEqual(med.width, 1032); XCTAssertEqual(med.height, 486); XCTAssertEqual(med.minY, 1485)
        let large = WKWallpaper.widgetRect(imgW: 1206, imgH: 2622, family: .large, position: "bottom", frameKey: "2622")
        XCTAssertEqual(large.height, 1098)
        XCTAssertEqual(large.minY, 872, "a large widget can't start at the bottom row; it uses the middle")
        // the Large-icons look shifts the grid
        let nolabels = WKWallpaper.widgetRect(imgW: 1206, imgH: 2622, family: .small, position: "top-left", frameKey: "2622", iconLabels: false)
        XCTAssertEqual(nolabels.minY, 270)
    }

    func testScaledScreenshotScalesTheFrame() {
        let r = WKWallpaper.widgetRect(imgW: 603, imgH: 1311, family: .small, position: "top-left", frameKey: "2622")
        XCTAssertEqual(r.width, 243); XCTAssertEqual(r.minY, 130.5)
    }

    func testUnknownScreenshotFallsBackProportionally() {
        let r = WKWallpaper.widgetRect(imgW: 1000, imgH: 2000, family: .small, position: "top-right", frameKey: nil)
        XCTAssertEqual(r.width, 402)
        XCTAssertGreaterThan(r.minX, 500)
        let big = WKWallpaper.widgetRect(imgW: 1000, imgH: 2000, family: .extraLargePortrait, position: "top", frameKey: nil)
        XCTAssertLessThanOrEqual(big.maxY, 2000)
    }

    func testFrameKeyMatchesKnownScreens() {
        XCTAssertEqual(WKWallpaper.frameKey(screenHeightPx: 2622), "2622")
        XCTAssertEqual(WKWallpaper.frameKey(screenHeightPx: 2868), "2868")
        XCTAssertNil(WKWallpaper.frameKey(screenHeightPx: 1234))
    }

    func samplePNG(_ w: Int, _ h: Int) -> String {
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { rc in
            UIColor.systemTeal.setFill(); rc.fill(CGRect(x: 0, y: 0, width: w, height: h))
            UIColor.white.setFill(); rc.fill(CGRect(x: 0, y: 0, width: w / 2, height: h / 2))
        }
        return "data:image/png;base64," + img.pngData()!.base64EncodedString()
    }

    func testBridgeStoresTheWallpaperAndTheRendererSlicesIt() {
        XCTAssertEqual(WKBridge.handle(["type": "wallpaper", "dataUrl": "data:image/png;base64,notanimage"]), .wallpaper(false))
        XCTAssertNil(WKWallpaper.load())
        XCTAssertEqual(WKBridge.handle(["type": "wallpaper", "dataUrl": samplePNG(1206, 2622)]), .wallpaper(true))
        let wall = WKWallpaper.load()
        XCTAssertEqual(wall?.cgImage?.height, 2622)
        let clear = WKDesign(["kind": "clock", "background": "clear", "position": "top-left"])
        let slice = WKWallpaper.slice(for: clear, family: .small, screenHeightPx: 2622)
        XCTAssertEqual(slice?.cgImage?.width, 486)
        let glass = WKDesign(["kind": "clock", "background": "glass"])
        let blurred = WKWallpaper.slice(for: glass, family: .medium, screenHeightPx: 2622)
        XCTAssertNotNil(blurred)
        XCTAssertNil(WKWallpaper.slice(for: clear, family: .accessoryCircular, screenHeightPx: 2622))
        var r = WKRenderer(live: .offline)
        r.scale = 1
        r.wallpaper = { d, fam in WKWallpaper.slice(for: d, family: fam, screenHeightPx: 2622) }
        XCTAssertFalse(r.wallpaperMissing(clear, family: .small))
        let img = r.render(clear, family: .small)
        XCTAssertEqual(img.size.width, 155)
        XCTAssertEqual(WKBridge.handle(["type": "clearWallpaper"]), .wallpaper(true))
        XCTAssertNil(WKWallpaper.load())
        XCTAssertTrue(r.wallpaperMissing(clear, family: .small))
    }

    func testClocksCanBeLeftOutForLiveOverlays() {
        var r = WKRenderer(live: .offline); r.scale = 1
        let d = WKDesign(["kind": "freestyle", "canvasElements": [["kind": "clock", "x": 0.5, "y": 0.5, "size": 30]]])
        r.bakeClocks = true
        let baked = r.render(d, family: .small)
        r.bakeClocks = false
        let bare = r.render(d, family: .small)
        XCTAssertNotEqual(baked.pngData(), bare.pngData())
    }
}
