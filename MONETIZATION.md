# WidgetKing — Monetization Plan

Status: **decided Nov 9, 2026 — pricing, AI-in-Pro, limits, no trial. Backend
not built yet.** The client side of accounts — email-code sign-in and design
sync — is live (Supabase + Resend; see ACCOUNTS_SETUP.md). The AI still runs on
a pasted access key. The Pro/AI server piece and payments are the next build
phases; this document is the source of truth for them.

Note on the existing dollar budget: today the AI runs on the user's own access
key, so the app shows a **spend budget in dollars** (Settings → AI designer).
That is a bring-your-own-key safety rail, not the free-tier counter below.
When Pro ships, everyone uses WidgetKing's key through the proxy below and the
paste-your-key screen leaves the normal flow (it stays as a developer option).
The "AI builds per month" counter (already recorded per device) becomes the
visible limit.

## Decision record (Nov 9, 2026)

Agreed with Andrew in discussion. Everything below in this document is kept in
step with these points; where older text disagrees, this record wins.

- **AI is a Pro feature, with limits.** Andrew: "the AI should be part of the
  Pro tool, but we also need limits so someone doesn't blow through money."
- **Free tier keeps 3 AI builds per month** on the best quality setting, with
  review passes included — a real taste of the product, not a crippled one.
- **Pro is marketed as unlimited AI**, enforced by fair-use caps nobody
  legitimate hits: **150 builds per month, 30 per day soft cap** (a friendly
  "come back tomorrow" message, never an error). A review pass counts as half a
  build. Fast mode may keep going at a lower cap after the daily soft cap.
- **Global daily spend breaker** on WidgetKing's own key: if the whole app's
  AI spend in a day crosses the breaker, AI pauses for everyone until midnight
  and Andrew gets an email. Amount to confirm with Andrew (proposal: ~$20/day).
- **The key never ships in the app.** AI calls go through a Supabase Edge
  Function proxy that holds the Anthropic key, checks the caller's Pro status,
  counts the build, and forwards the request. The "paste your access key"
  screen is removed for normal users (developer option remains).
- **No free trial.** Andrew: "you can churn a lot of your widgets in a week …
  the 3 free kind of cover that." The 3 free builds are the trial.
- **Price: $2.99/month, $24.99/year.** Yearly is the default-selected option
  ("2 months free"). No struck-through fake "regular" prices — the price is the
  price.
- **Possible launch price:** $19.99 yearly for the first stretch, shown
  honestly as a launch price with an end date. To confirm with Andrew.
- **Lifetime unlock: not at launch.** Revisit once real usage shows what AI
  actually costs per user.
- **Pro keeps paying for itself after the AI novelty fades:** design sync
  across phones, unlimited active widgets, full Explore access, future style
  packs, and no promo cards.

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
  - **Untouched starter designs are exempt.** The app seeds a few badged
    "Starter" examples on first run so the first phone sync isn't blank; they
    count toward the cap only once the user edits and saves one (which removes
    the badge and makes it theirs).
  - Why 4: an iPhone page is a 4×6 grid; large + medium + two smalls is a
    complete, gorgeous page. 4 covers every realistic one-page setup while
    making a second page impossible without Pro. (6 was considered and
    rejected: six mediums/larges dress 2–3 pages.)

### Pro (subscription)
- **AI designer** — marketed as unlimited, enforced at 150 builds/month and a
  30/day soft cap (review passes count half; Fast mode may continue at a lower
  cap after the daily soft cap). These numbers are far above real use and exist
  only to stop scripted abuse.
- Unlimited active widgets
- Design sync across every phone signed into the account
- Full Explore access (published designs and icon packs)
- No promo cards, ever
- **Pricing: $2.99/month or $24.99/year**, yearly selected by default and
  framed as "2 months free." No fake struck-through prices. Possible honest
  launch price of $19.99/year with a stated end date (to confirm).
- **No free trial** — the 3 free builds are the trial.
- Payments: the native app uses Apple In-App Purchase (15% small-business
  rate); the web designer can sell the same subscription via Stripe (~3%).
- Lifetime unlock and AI top-up packs: not at launch; revisit with real cost
  data.

### Cost protection (all tiers)
- **Per-user counters** on the server (builds this month, builds today), keyed
  by account for Pro and by device for free.
- **Global daily spend breaker** on WidgetKing's key — pauses AI for everyone
  until midnight ET and emails Andrew when tripped. Amount: ~$20/day proposed,
  to confirm.
- **Supabase Edge Function proxy** holds the Anthropic key, verifies the
  caller (Supabase session → Pro status), enforces the counters, and forwards
  the request. The client never sees the key.

## Sign-in & abuse prevention

- **Email + one-time code** sign-in (email OTP — magic-link security delivered as
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

## Market reference points (observed Aug 2026)

A competing AI widget maker's live pricing, recorded here as a sanity check for
our numbers — reference only, not a template:

- Free tier: **2 widgets and 5 AI edits/month** (tighter than our free tier on
  widgets, looser on AI). Their upsell screen leads with the free-tier limits in
  plain language before listing Pro benefits — worth keeping.
- Pro: **$2.99/month or $24.99/year**, both displayed against struck-through
  "regular" prices ($9.99 / $119.99) as a permanent "70% off." Our decided
  price matches theirs exactly — at market, not under it. The fake-discount
  anchoring is a dark pattern — App Store review increasingly flags it, and it
  reads as distrust; we show the real price and frame yearly as "2 months
  free" (decision record above).
- Their paywall sells feature *outcomes* ("iterate without hitting the wall")
  rather than feature names; their footer covers auto-renew terms + restore
  purchases + a real "Not now" escape. All three are the standard to meet.
- **Referral program**: "Give a month, get a month" — both sides get a free
  month of Pro on code redemption, and referral months stack per friend. Cheap
  to run (marginal cost of Pro is near zero pre-AI-usage), turns happy users
  into distribution, and fits our word-of-mouth thesis. Needs the accounts
  backend; add to the build order when that phase is greenlit.
- Their account screen frames the FREE plan as a benefits card ("Current plan"
  with a bullet list of what you get) rather than a wall of limits — the free
  tier is presented with the same dignity as Pro. Keep that.

## Build order

1. ✅ Accounts backend (email OTP, design sync) — live on Supabase + Resend
2. **AI proxy + metering** (next): Supabase Edge Function holding the key,
   per-user build counters, global daily spend breaker, Pro-status check;
   remove the paste-your-key screen from the normal flow
3. **Pro entitlement + payments**: Apple In-App Purchase in the native app
   (needs the Apple Developer membership), Stripe on the web; Pro status synced
   to the account so either purchase unlocks both
4. Paywall screen per the standards above (outcomes, honest prices, auto-renew
   terms, restore purchases, a real "Not now")
