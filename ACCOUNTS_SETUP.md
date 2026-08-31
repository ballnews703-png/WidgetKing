# WidgetKing accounts backend — setup (phase 1)

The client side shipped in v124 (email-code sign-in + design sync in
Settings → Account & sync) but stays **invisible** until the two constants in
`web/index.html` are filled in. This file is the complete recipe. Total time:
about 10 minutes, cost: $0 (Supabase free tier, no card required).

## 1. Create the Supabase project (Andrew — 5 minutes)

1. Go to <https://supabase.com> → Start your project → sign up (GitHub login
   is easiest).
2. New project → name it `widgetking`, pick the region closest to you
   (US East), let it generate the database password (we never use it
   directly — store it in your password manager anyway).
3. When the project finishes provisioning, open **Project Settings → API**
   and copy two values:
   - **Project URL** (like `https://abcdefgh.supabase.co`)
   - **anon / public key** (a long `eyJ…` string — this one is SAFE to put
     in the app; it's designed to be public)
   - Do NOT copy the `service_role` key anywhere. That one is secret.
4. Paste both into the chat. That's your whole job.

## 2. Database table (run once in the SQL editor)

Supabase dashboard → SQL Editor → New query → paste and run:

```sql
create table public.designs (
  id text not null,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  updated_at bigint not null default 0,
  data jsonb not null,
  primary key (user_id, id)
);

alter table public.designs enable row level security;

create policy "users own their designs" on public.designs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

Row-level security means every signed-in user can only ever see and write
their own rows — enforced by the database itself, not by app code.

## 3. Auth settings (dashboard → Authentication)

- **Sign In / Up → Email**: ON (it is by default). Turn **Confirm email**
  OFF if present — the 6-digit code IS the confirmation.
- **Email OTP length**: 6 (default). OTP expiry: default 1 hour is fine
  (the app copy says 10 minutes to nudge urgency; tighten to 600s here if
  you want the copy to be literal).
- Rate limits: defaults are fine to start (Supabase's built-in email sender
  allows ~2 emails/hour per address on free tier — enough for testing; before
  launch we plug in a real sender via SMTP, e.g. Resend's free tier, so codes
  arrive instantly and reliably).

## 4. Light it up (Claude)

- Put the two values into `web/index.html`:
  `WK_SYNC_URL = "https://<project>.supabase.co"` and
  `WK_SYNC_KEY = "<anon key>"`.
- Ship. The Account & sync section appears in Settings for everyone.

To test on one device before baking the constants: in Safari's console on
that device run
`localStorage.setItem("widgetking.sync.url", "https://<project>.supabase.co")`
and `localStorage.setItem("widgetking.sync.key", "<anon key>")`, reload.

## What the client does (already built)

- **Sign-in**: email → `POST /auth/v1/otp` → 6-digit code →
  `POST /auth/v1/verify` → session stored locally, auto-refreshed via
  refresh token. No passwords anywhere.
- **Sync**: on every save (debounced 4s) all designs upsert to `designs`
  (photos stripped, same as share links — they never leave the device);
  on launch and on "Sync now" the client pulls and merges — newest
  `updatedAt` wins per design, local photo data grafted back.
- **Metering** (recording only, nothing enforced): AI builds counted per
  month in `widgetking.meter.ai`, device-local per MONETIZATION.md.

## What comes later (build order per MONETIZATION.md)

2. Enforcement UI: free-tier caps (3 AI builds/mo, 4 active widgets) with
   the upsell card — ships together with payments, never before.
3. Stripe checkout + `pro` entitlement column; Explore publishing rides on
   the same accounts.
