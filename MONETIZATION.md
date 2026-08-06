# WidgetKing — Monetization Plan

Status: **agreed, not yet built.** Nothing in the app enforces any of this today —
it requires the accounts backend (sign-in, usage metering, payments), which is a
future phase with its own go decision. This document is the source of truth for
that build.

## Philosophy

- **Design free forever.** The designer, Studio, templates, icons, and manual
  widget building never go behind a paywall. They cost nothing per use and they
  are what makes the app spread.
- **Meter the thing that costs money.** AI generation is the only feature with a
  real per-use cost, so it is the metered feature.
- **Enough to love it, not enough to finish.** The free tier should let someone
  build one beautiful home page — and hit the wall exactly when they want a
  second one.

## Tiers

### Free
- Full designer, Studio, templates, icon maker — unlimited, forever
- **3 AI builds per month** (resets monthly; drives re-engagement)
- **4 active widgets per device**, counting Home Screen and Lock Screen widgets
  together
  - Why 4: an iPhone page is a 4×6 grid; large + medium + two smalls is a
    complete, gorgeous page. 4 covers every realistic one-page setup while
    making a second page impossible without Pro. (6 was considered and
    rejected: six mediums/larges dress 2–3 pages.)

### Pro (subscription)
- Unlimited AI builds — marketed as unlimited, backed by a generous fair-use
  daily cap (e.g. 100/day) to prevent scripted abuse
- Unlimited active widgets
- Full Explore access (published designs and icon packs)
- No promo cards, ever
- Pricing: monthly in the $2–4 range + discounted yearly framed as "2 months
  free." Web payments via Stripe (~3% fees). If a native App Store build ships
  later, in-app subscriptions must use Apple IAP (15% small-business rate).
- Optional add-on for non-subscribers: one-time AI build top-up pack

## Sign-in & abuse prevention

- **Email + 6-digit code** sign-in (email OTP — magic-link security delivered as
  digits; iPhone auto-suggests the code above the keyboard). No passwords to
  create, forget, reset, or leak. Users stay signed in; login is roughly a
  once-per-phone event.
- **Free-tier counters live on the device, not the account.** Logging out and
  back in with a different account changes nothing — the phone remembers its own
  allowance. This kills multi-account cycling without punishing anyone.
- **Accounts carry the valuables:** designs, settings, and Pro status sync to
  any phone the user signs into. New phone = sign in, everything appears, fresh
  device allowance (acceptable: nobody buys phones to farm 3 AI builds).
- **No widget lockouts.** Nothing a signed-out or free user made ever goes
  blank. The "sign back in to view this widget" concept was considered and
  scrapped — widgets going blank is the #1 complaint in this category, and the
  device cap already does the enforcement.
- Accept the residue: perfect prevention isn't the bar. Someone determined to
  farm pennies of AI credit was never a customer.

## Promo cards (house ads only)

- **No third-party ad networks.** Banner and interstitial ads were considered
  and rejected: they fight the premium-design brand, review-bomb this app
  category, and pay almost nothing at early-stage volumes.
- **House promo cards instead:** tasteful in-app cards for Pro, featured Explore
  packs, new style drops.
- Cadence: **once per day baseline** (shown at the first save/publish of the
  day — the post-creation high point — falling back to on-open only if the user
  browses without saving), **plus one** on saving/pushing a new widget
  (placement on the Home Screen itself is not detectable by iOS design, so
  save/push is the trigger), **hard cap: two per day total.**
- Never in a user's first session. Never for Pro users.
- Frequency is a tunable dial; launch at the above and adjust with real data.

## Build order (when greenlit)

1. Accounts backend (email OTP, design sync) — also unlocks Explore publishing;
   starts on free-tier infrastructure (Supabase-class) at ~$0 until real traffic
2. Usage metering (AI builds, active-widget count) built in from day one
3. Stripe + Pro entitlement — monetization becomes a switch to flip, not a
   rebuild
