# WidgetKing — Native plan (approved Oct 2026, $0 until signing)

Decision: **wrap the web designer in a native shell and build a native
WidgetKit renderer** for the WidgetKing design format. Scriptable stays the
delivery path for the web product until the native widgets are ready; it
has not been updated since September 2024 and cannot reach iOS 27's
full-page widget family (`systemExtraLargePortrait`), which is the headline
reason to go native.

Cost rule: everything below runs on GitHub's free macOS runners (public
repo) and Apple's iOS Simulator. The only paid step — installing on a real
iPhone — needs the Apple Developer membership and is explicitly deferred.

## Milestones

0. **Pipeline (M0)** — `.github/workflows/ios.yml` compiles the app + widget
   extension for the Simulator on every push, boots a simulator, installs
   and launches the app, uploads logs and a screenshot. Shared Xcode scheme
   committed. *Done when the workflow is green.*
1. **Native renderer parity (M1)** — `Shared/` gains a renderer for the real
   design format: every design kind (clock, date, countdown, quote, note,
   launcher, battery, freestyle, lock, playlist) and every freestyle element
   kind the web supports, all 22 themes, fonts, backgrounds (gradient,
   mesh, patterns), per-size layouts. Decodes the web JSON as-is (lowercase
   kinds, ISO date strings, string ids). A test target renders every
   template from `tests/fixtures/designs.json` in the Simulator and fails
   on any crash or empty render — the native twin of `tests/renderer.mjs`.
   *Status (Oct 5):* `Shared/WKDesign.swift` (lenient model of the web
   JSON), `Shared/WKLiveData.swift` (live values + the template's text
   formatters), `Shared/WKRenderer.swift` (CoreGraphics renderer: every
   kind, every element, themes, fonts, backgrounds, patterns, per-size
   layouts, launcher tiles incl. vector glyphs, Lock Screen rows) and
   `Shared/WKData.swift` (generated from the template by
   `tools/gen_wkdata.mjs` — run it after editing THEMES / FONT_NAMES /
   ICON_THEMES / VGLYPHS in `web/index.html`). `WidgetKingTests` renders
   every fixture design at six families with and without live data, plus
   hostile inputs, in the Simulator on every push. Still M1-open: nothing —
   real icons, stickers from the bundle, wallpaper slices and live clocks
   are M3 hooks (closures on `WKRenderer`) that return nil today.
2. **Shell (M2)** — the app becomes a `WKWebView` hosting `web/index.html`
   from the bundle (offline-capable, same file the site serves), with a
   small bridge: the designer hands the design library to native storage
   (App Group) whenever it saves; native hands back the device's widget
   sizes. The existing SwiftUI screens retire.
   *Status (Oct 5):* `WidgetKing/WebShellView.swift` hosts the bundled `web/`
   folder (index, privacy, stock art) in a `WKWebView`; `persist()` in the
   designer posts the library over `webkit.messageHandlers.widgetking` and
   `Shared/WKStore.swift` writes it to the App Group and reloads widgets.
   The page gets `document.documentElement.classList` "wk-native" and
   `window.wkNative` at document start. Old SwiftUI screens deleted.
   `WidgetKingTests/WKStoreTests.swift` covers the bridge and the bundle.
   Device widget sizes → page: M3.
3. **Widgets (M3)** — the extension renders from the App Group store at
   small, medium, large, the Lock Screen accessory families, and
   `systemExtraLargePortrait` (iOS 27). The design picker intent stays.
   Live data (weather, calendar, reminders, battery, stocks, astro,
   sleeper, news) ported from the Scriptable template.
4. **Full-page (M4)** — the web designer gains an XL canvas (4×6 page) and
   Page Studio can export a page as ONE full-page widget.
5. **Signing (M5, paid)** — Apple Developer enrollment, TestFlight,
   App Store. Not before Andrew says go.

## Working rules

- The web app stays the product throughout; nothing here regresses it.
- Native code is tested the same way the web is: an automated battery on
  every push, failing the build on any crash.
- Model/AI vocabulary and pricing decisions already made for the web apply
  to native unchanged (Sonnet default, "access key", no competitor names).
