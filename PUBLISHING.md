# WidgetKing — Publishing / Native App Plan

Status: **planning notes, not yet built.** The native SwiftUI/WidgetKit app is
scaffolded in this repo (`WidgetKing.xcodeproj`, `WidgetKingWidgets/`). Building
and shipping it requires an Apple Developer membership ($99/yr) and CI builds on
macOS runners — a spend decision that is parked until explicitly approved.

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

- Alternate icons: ship the 8 v69 colorways (royal, noir, glass, cream, ocean,
  sunset, neon, pastel) as bundled alternate icons; picker UI already designed.
- Migration: import designs from the web app (share-link payload already
  round-trips full libraries).
- Keep the web designer alive as the desktop/companion editor — same design
  format everywhere.

## Path (when greenlit)

1. Apple Developer enrollment ($99/yr) — the only unavoidable cost
2. GitHub Actions macOS runners + fastlane: build, sign, TestFlight — no Mac
   owned required
3. TestFlight beta (family + trusted testers) → App Store review → launch
4. Accounts backend + metering (MONETIZATION.md) can land before or alongside
