-- WidgetKing AI proxy — usage metering + Pro status (phase 2).
-- Run once in the Supabase SQL editor. Safe to re-run.

create table if not exists public.ai_usage (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null default 'unknown',
  build_id text not null,
  model text not null,
  cost_usd numeric(10, 6) not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists ai_usage_user_month on public.ai_usage (user_id, created_at);
create index if not exists ai_usage_device_month on public.ai_usage (device_id, created_at);
create index if not exists ai_usage_created on public.ai_usage (created_at);

create table if not exists public.pro_status (
  user_id uuid primary key references auth.users (id) on delete cascade,
  active boolean not null default false,
  source text not null default 'manual',      -- manual | apple | stripe
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_alerts (
  day date primary key,
  created_at timestamptz not null default now()
);

alter table public.ai_usage enable row level security;
alter table public.pro_status enable row level security;
alter table public.ai_alerts enable row level security;
-- Users may read their own usage and status; only the proxy (service role) writes.
drop policy if exists "read own usage" on public.ai_usage;
create policy "read own usage" on public.ai_usage for select using (auth.uid() = user_id);
drop policy if exists "read own pro status" on public.pro_status;
create policy "read own pro status" on public.pro_status for select using (auth.uid() = user_id);

-- Everything the proxy needs to decide one call, in one round trip.
create or replace function public.ai_usage_summary(p_user uuid, p_device text, p_build text)
returns jsonb language sql security definer set search_path = public as $$
  with month as (select date_trunc('month', now()) as start),
       today as (select date_trunc('day', now()) as start)
  select jsonb_build_object(
    'pro', coalesce((select active and (expires_at is null or expires_at > now()) from pro_status where user_id = p_user), false),
    'user_month_cost', coalesce((select sum(cost_usd) from ai_usage, month where user_id = p_user and created_at >= month.start), 0),
    'user_month_high_cost', coalesce((select sum(cost_usd) from ai_usage, month where user_id = p_user and created_at >= month.start and model = 'claude-sonnet-5'), 0),
    'user_month_builds', coalesce((select count(distinct build_id) from ai_usage, month where user_id = p_user and created_at >= month.start), 0),
    'user_today_builds', coalesce((select count(distinct build_id) from ai_usage, today where user_id = p_user and created_at >= today.start), 0),
    'device_month_builds', coalesce((select count(distinct build_id) from ai_usage, month where device_id = p_device and created_at >= month.start), 0),
    'build_calls', coalesce((select count(*) from ai_usage where build_id = p_build), 0),
    'global_today_cost', coalesce((select sum(cost_usd) from ai_usage, today where created_at >= today.start), 0)
  );
$$;
revoke all on function public.ai_usage_summary(uuid, text, text) from public;
grant execute on function public.ai_usage_summary(uuid, text, text) to service_role;

-- To give an account Pro by hand (testing, friends): find the user's id under
-- Authentication → Users, then:
--   insert into public.pro_status (user_id, active, source) values ('<user id>', true, 'manual')
--   on conflict (user_id) do update set active = true, updated_at = now();
