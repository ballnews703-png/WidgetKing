import XCTest
@testable import WidgetKing

// The App Group store and the web→native bridge: the designer's library
// round-trips byte for byte, malformed messages can't wipe it, and the
// bundled designer is really inside the app.
final class WKStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        WKStore.defaults.removeObject(forKey: WKStore.designsKey)
    }

    func testBridgeSavesTheLibrary() {
        let json = #"[{"id":"a1","name":"Stencil Clock","kind":"freestyle","canvasElements":[{"kind":"clock","x":0.5,"y":0.5,"size":30}]},{"id":"b2","name":"Lock","kind":"lock"}]"#
        XCTAssertEqual(WKBridge.handle(["type": "designs", "json": json]), .saved(2))
        XCTAssertEqual(WKStore.designsJSON(), json)
        XCTAssertEqual(WKStore.designs().count, 2)
        XCTAssertEqual(WKStore.design(named: "stencil clock ")?.id, "a1")
        XCTAssertEqual(WKStore.design(id: "b2")?.kind, "lock")
        XCTAssertNil(WKStore.design(named: "nope"))
    }

    func testBadMessagesNeverWipeTheLibrary() {
        _ = WKBridge.handle(["type": "designs", "json": #"[{"id":"keep","name":"Keep","kind":"clock"}]"#])
        XCTAssertEqual(WKBridge.handle(["type": "designs", "json": "not json"]), .rejected)
        XCTAssertEqual(WKBridge.handle(["type": "designs", "json": #"{"id":"obj"}"#]), .rejected)
        XCTAssertEqual(WKBridge.handle(["type": "designs"]), .rejected)
        XCTAssertEqual(WKBridge.handle(["type": "mystery", "json": "[]"]), .ignored)
        XCTAssertEqual(WKBridge.handle("garbage"), .ignored)
        XCTAssertEqual(WKStore.designs().first?.id, "keep")
        XCTAssertEqual(WKBridge.handle(["type": "designs", "json": "[]"]), .saved(0))
        XCTAssertEqual(WKStore.designs().count, 0)
    }

    func testDesignerShipsInTheBundle() {
        let index = WebShellView.indexURL()
        XCTAssertNotNil(index, "web/index.html must be bundled as a folder reference")
        if let url = index, let html = try? String(contentsOf: url, encoding: .utf8) {
            XCTAssertTrue(html.contains("function wkNativeSend"), "bundled designer predates the native bridge")
            XCTAssertTrue(html.contains("const WK_VERSION = "))
        }
        XCTAssertNotNil(Bundle.main.url(forResource: "privacy", withExtension: "html", subdirectory: "web"))
        XCTAssertNotNil(Bundle.main.url(forResource: "clear-day", withExtension: "png", subdirectory: "web/stock/art"))
    }
}
