# WidgetKing — Publishing / Native App Plan

Status: **native shell + native renderer, built on free CI, never signed.**
The Xcode project (`WidgetKing.xcodeproj`, `WidgetKing/`, `WidgetKingWidgets/`,
`Shared/`) now follows NATIVE_PLAN.md: the app is a `WKWebView` shell around
the bundled `web/index.html` (the same file the site serves, offline), and
`Shared/WKRenderer.swift` paints the real web design format natively — every
kind, every element, all 22 themes, per-size layouts — with a Simulator test
battery that renders every template on every push (`.github/workflows/ios.yml`,
GitHub's free macOS runners). The widget extension still runs on the old
from-scratch model until milestone 3 swaps it onto the App Group library the
shell writes. Installing on a real iPhone, TestFlight and the App Store need
the Apple Developer membership ($99/yr) — a spend decision parked until
explicitly approved.

## Why native (what the web app can't do)

- **One-tap app-icon switching** — native apps get Apple's alternate-icon API:
  pick an icon in-app, iOS swaps it instantly, no re-add. The v69 web picker
  (choose icon → re-add to Home Screen once) is the ceiling of what web apps
  are allowed; day one of native, it becomes the instant switch users know
  from other widget apps.
- **Real widgets without Scriptable** — WidgetKit renders our designs directly;
  no companion app, no script paste, no update button.
- **App Store presence** — discoverability, reviews, trust, and the
  subscription rails (Apple IAP at the 15% small-business rate; the web
  version can keep Stripe at ~3%).
- **Push notifications, iCloud sync, camera/photo integrations** at full
  fidelity.

## Decisions already made (see MONETIZATION.md for detail)

- Free: full designer forever, 3 AI builds/month, 4 active widgets per device
  (home + lock combined)
- Pro: unlimited fair-use AI, unlimited widgets, full Explore, no promos
- Sign-in: email + 6-digit code; device-tied free counters; account-synced
  designs; no widget lockouts
- Promos: house cards only, 1/day + 1 on new-widget save, max 2/day
- Explore publishing (user-submitted widgets + icon packs, tagged by vibe and
  size) unlocks with the accounts backend

## Native-day-one feature notes

- Alternate icons: the 8 v69 colorways (royal, noir, glass, cream, ocean,
  sunset, neon, pastel) are bundled as app icon sets; the shell's SwiftUI
  picker retired with the old screens, so the designer's icon picker needs a
  bridge message (`setIcon`) to drive `UIApplication.setAlternateIconName` —
  a milestone-3 item.
- Migration: solved by construction — the shell runs the web designer, so
  share links, backups and sync work exactly as on the web, and the native
  renderer decodes the web format as-is (`Shared/WKDesign.swift`).
- Sign-in + design sync: the web implementation (v124/v128) runs unchanged
  inside the shell.
- Keep the web designer alive as the desktop/companion editor — same design
  format everywhere.

## Path (when greenlit)

1. Apple Developer enrollment ($99/yr) — the only unavoidable cost
2. GitHub Actions macOS runners + fastlane: build, sign, TestFlight — no Mac
   owned required
3. TestFlight beta (family + trusted testers) → App Store review → launch
4. Accounts backend + metering (MONETIZATION.md) can land before or alongside
