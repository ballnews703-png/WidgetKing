# WidgetKing — Surfaces Roadmap

Status: **planning record.** Every surface below is native-app work, blocked on
the Apple Developer membership + Mac CI (parked spend decision — see
PUBLISHING.md). This file preserves the costed sequence so the build starts
right when that unparks.

## Prerequisites — DONE

- `schemaVersion` on every design (web v82, Swift `WidgetDesign`)
- `surface` field on every design, default `"home"` (web v83, Swift)

## The sequence, by value-per-unit-of-work

1. **StandBy** (iOS 17+) — nearly free: reuses systemSmall; add a dim,
   red-shifted night variant. Proves the surface-variant plumbing.
2. **Widget tinting compliance** (iOS 18+) — correctness, not a feature:
   `widgetAccentedRenderingMode`, verify every element under flattened colors.
   Users report non-compliance as a bug.
3. **Interactive widgets** (iOS 17+) — `Button(intent:)` / `Toggle(isOn:intent:)`;
   cheap, turns launcher tiles into real buttons; deployment target already allows it.
4. **Reduced render path + Lock Screen widgets** (iOS 16+) — the hard, necessary
   one. Lock Screen renders vibrant/tinted/monochrome: not a size variant but a
   SECOND RENDER PATH that reduces a design to shapes, strokes, text, one tint,
   plus `AccessoryWidgetBackground`. Build it once — watch and tinted mode
   consume the same path. Line-style vector art survives the reduction; photos
   and gradients do not (the glyph/pattern systems are assets here).
5. **Watch complications** (watchOS 9+, WidgetKit) — real scope: a new watchOS
   app target, own assets and review surface. AFTER Lock Screen (reuses the
   reduced path; the other order builds it twice).
6. **Control Center controls** (iOS 18+, `ControlWidget`) — NOT a display
   surface; a symbol + label + state. Rethink as quick actions (open a design,
   cycle a widget, refresh all). Needs deployment target 17.0 → 18.0, or a
   gated target — decide before writing surface code.
7. **Live Activities / Dynamic Island** — last, and only the defensible
   version: bound to genuinely live events WidgetKing already knows (countdown
   reaching zero, sunset approaching, a timer). Time-boxed by the system
   (~8-12h); never an always-on display restarted by automation — that fights
   the guidelines and is a poor foundation for a headline feature.

## The differentiator: design once, adapt everywhere

Surface is a rendering target, not a design type. One design, stored once; the
renderer adapts per surface (drop color for Lock Screen, simplify for
accessoryCircular, expand for StandBy); the user can override per surface but
never starts over. "Put this everywhere" is one button. Extend the AI's closed
vocabulary with `surface` so "make this work on my Lock Screen" is a prompt it
can satisfy, and one prompt can produce a coordinated family — Home Screen,
Lock Screen, watch — visually related because the format is shared.

## UI rule

No visible surface switcher until a second surface actually ships — no
greyed-out "coming soon" entries. When one ships, the switcher is a row of
buttons and a data change, not a navigation rewrite (nav brief Rule 7).
