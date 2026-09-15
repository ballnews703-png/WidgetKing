# WidgetKing — Publishing / Native App Plan

Status: **native app scaffolded, never signed or shipped.** The SwiftUI/WidgetKit
project in this repo (`WidgetKing.xcodeproj`, `WidgetKing/`, `WidgetKingWidgets/`,
`Shared/`) is a **from-scratch native rewrite, not a wrapper around the web
app** — it loads no web content. Today it renders 6 of the web's 10 design kinds
and 5 of its 25 element kinds, has 12 of 22 themes, hardcodes the expensive
`claude-opus-5` model (the web moved to Sonnet/Haiku in v121), and cannot decode
a web design (lowercase `kind`, string dates). Closing that gap — or replacing
the native UI with a web view around `web/index.html` — is the first decision of
this phase. Building and shipping either way requires an Apple Developer
membership ($99/yr) and CI builds on macOS runners — a spend decision that is
parked until explicitly approved. The project also has no shared Xcode scheme
committed yet, which any CI build needs.

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

- Alternate icons: DONE in the native project — the 8 v69 colorways (royal,
  noir, glass, cream, ocean, sunset, neon, pastel) are bundled and the picker
  in native Settings switches them.
- Migration: NOT BUILT. The web share-link payload round-trips full libraries
  between web devices, but the native app has no link importer and its decoder
  rejects web designs. Needs a web-format decoding shim before it can be
  claimed.
- Sign-in + design sync: shipped on web in v124 (dark until keys); not built
  natively.
- Keep the web designer alive as the desktop/companion editor — same design
  format everywhere.

## Path (when greenlit)

1. Apple Developer enrollment ($99/yr) — the only unavoidable cost
2. GitHub Actions macOS runners + fastlane: build, sign, TestFlight — no Mac
   owned required
3. TestFlight beta (family + trusted testers) → App Store review → launch
4. Accounts backend + metering (MONETIZATION.md) can land before or alongside
