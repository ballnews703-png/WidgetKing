// WidgetKing AI proxy — the budget rules, as one pure function.
// Source of truth for MONETIZATION.md's numbers. Imported by the Edge
// Function (Deno) and by tests/check137.mjs (Node) — no runtime APIs here.

export const LIMITS = {
  freeBuilds: 3,            // free: distinct builds per month (device or account, whichever is higher)
  freeMonthCost: 0.60,      // free: cost ceiling per month, catches build-id replay
  callsPerBuild: 4,         // any tier: one build = first pass + review + polish, never a loop
  proHighCost: 1.50,        // pro: High-quality budget per month, then Fast mode
  proMonthCost: 3.00,       // pro: fair-use ceiling per month (≈ 20 High + 60 Fast builds)
  proDailyBuilds: 30,       // pro: soft cap per day
  globalDailyCost: 25.00,   // everyone: bug backstop; pauses AI until midnight
  maxTokens: 16000
};

export const MODELS = { high: "claude-sonnet-5", fast: "claude-haiku-4-5" };
// $ per million tokens: [input, output]
export const PRICES = { "claude-opus-5": [5, 25], "claude-sonnet-5": [3, 15], "claude-haiku-4-5": [1, 5] };
// What a typical build costs (two passes) — only for the "about N left" copy.
export const TYPICAL_BUILD_COST = { high: 0.075, fast: 0.025 };

export function costOf(model, usage) {
  const price = PRICES[model] || PRICES[MODELS.high];
  usage = usage || {};
  return (
    (usage.input_tokens || 0) * price[0] +
    (usage.output_tokens || 0) * price[1] +
    (usage.cache_read_input_tokens || 0) * price[0] * 0.1 +
    (usage.cache_creation_input_tokens || 0) * price[0] * 1.25
  ) / 1e6;
}

// usage: { userMonthCost, userMonthHighCost, userMonthBuilds, userTodayBuilds,
//          deviceMonthBuilds, buildCalls, globalTodayCost }  (all numbers)
// Returns { allow, model, reason, quota }.
//   reason: "ok" | "fast" (downshifted) | "paused" | "free" | "monthly" | "daily" | "build"
export function decide(input) {
  const L = Object.assign({}, LIMITS, input.limits || {});
  const u = input.usage || {};
  const requested = input.requestedModel === MODELS.fast ? MODELS.fast : MODELS.high;
  const pro = !!input.pro;
  const quota = quotaFor(pro, u, L);
  const deny = function (reason) { return { allow: false, model: requested, reason: reason, quota: quota }; };

  if ((u.globalTodayCost || 0) >= L.globalDailyCost) return deny("paused");
  if ((u.buildCalls || 0) >= L.callsPerBuild) return deny("build");
  if (!pro) {
    const builds = Math.max(u.userMonthBuilds || 0, u.deviceMonthBuilds || 0);
    // A build already started this month may finish its passes.
    const continuing = (u.buildCalls || 0) > 0;
    if (!continuing && builds >= L.freeBuilds) return deny("free");
    if ((u.userMonthCost || 0) >= L.freeMonthCost) return deny("free");
    return { allow: true, model: requested, reason: "ok", quota: quota };
  }
  if ((u.userMonthCost || 0) >= L.proMonthCost) return deny("monthly");
  if ((u.buildCalls || 0) === 0 && (u.userTodayBuilds || 0) >= L.proDailyBuilds) return deny("daily");
  if (requested === MODELS.high && (u.userMonthHighCost || 0) >= L.proHighCost) {
    return { allow: true, model: MODELS.fast, reason: "fast", quota: quota };
  }
  return { allow: true, model: requested, reason: "ok", quota: quota };
}

export function quotaFor(pro, u, L) {
  L = L || LIMITS; u = u || {};
  if (!pro) {
    const builds = Math.max(u.userMonthBuilds || 0, u.deviceMonthBuilds || 0);
    return { tier: "free", freeLeft: Math.max(0, L.freeBuilds - builds), freeTotal: L.freeBuilds };
  }
  const highLeftCost = Math.max(0, L.proHighCost - (u.userMonthHighCost || 0));
  return {
    tier: "pro",
    highLeft: Math.round(highLeftCost / TYPICAL_BUILD_COST.high),
    highTotal: Math.round(L.proHighCost / TYPICAL_BUILD_COST.high),
    fastMode: highLeftCost <= 0
  };
}

// Only the fields the proxy forwards; everything else a client sends is dropped.
export function sanitizeBody(body, model, L) {
  L = L || LIMITS;
  if (!body || typeof body !== "object") return null;
  if (!Array.isArray(body.messages) || !body.messages.length) return null;
  const out = { model: model, max_tokens: Math.min(Number(body.max_tokens) || L.maxTokens, L.maxTokens), messages: body.messages };
  if (body.system) out.system = body.system;
  if (body.output_config) out.output_config = body.output_config;
  return out;
}
