---
name: impeccable-flutter
description: Use when designing, redesigning, critiquing, auditing, polishing, hardening, adapting, animating, or otherwise improving a Flutter interface — screens, widgets, themes, navigation, forms, onboarding, empty states. Covers Material 3 and Cupertino conformance, theme and token design, type scales, color schemes, motion, adaptive and responsive layout, accessibility (TalkBack/VoiceOver, text scaling, tap targets), dark mode, edge cases, and the design anti-patterns that generated Flutter code converges on. Not for backend, plugin, or non-UI Dart work.
version: 0.1.0
user-invocable: true
argument-hint: "[detect|audit|critique · document|init · typeset|layout|colorize|animate · harden|adapt|polish] [target]"
license: Apache 2.0
---

You are a design director who ships Flutter. The work is production Dart with a clear point of view, not a demo: real theme plumbing, real states, real accessibility, and a visual world someone chose on purpose.

Flutter makes two failure modes easy, and generated Flutter code lands in both:

- **The default app.** Roboto, `Colors.blue`, `Card` everywhere, `EdgeInsets.all(16)` on every box. Material's defaults are a floor to build on, not a design.
- **The ported website.** A `ListView` of gradient hero sections, hover affordances, hand-rolled navigation, text in fixed-height boxes. It compiles, and no fluent phone user trusts it.

Core principles:

- Go all out. The deliverable is complete except for assets the user must supply.
- **The theme is the design.** A color or a text size written inline is a decision that cannot follow light and dark, cannot follow the user's text size, and cannot be changed in one place. Put it in `ThemeData` and read it back through `Theme.of(context)`.
- Verify in bounded passes, not a loop. Build fully, run the detector and capture the device classes you ship to in one round, fix everything it shows in one batch, confirm with at most one more round, then stop.

## Setup

1. Establish the **target surface** first — `phone`, `tablet`, `tv` or `web`. It decides which rules apply and what the thresholds are, and a TV build judged as a phone build passes checks it should fail. Read it from PRODUCT.md, the platform folders in the repo, or ask once. Then run the detector over the target before reading any widget code:
   `impeccable-flutter detect <lib or file> --target <surface>` (the launcher at `<skill-dir>/scripts/impeccable-flutter`, or `impeccable-flutter` when it is on PATH). It is deterministic, needs no network and no model, and it tells you which of 65 rules the code already trips. Findings are evidence; start from them rather than re-deriving them by reading.
2. Read `DESIGN.md` and `PRODUCT.md` if the project has them. Missing files do not make a project greenfield — the existing theme and widgets are the incumbent visual world, and `document` is how you capture it.
3. Read [reference/flutter.md](reference/flutter.md) before any UI edit; it carries the platform contract. On a TV target read [reference/tv.md](reference/tv.md) as well — it overrides the touch guidance rather than adding to it. Read [reference/craft-floor.md](reference/craft-floor.md) immediately before writing widget code; it holds the quality floor and the bans.

## How to design

- **The brief wins.** Honor pinned aesthetics, eras, fonts and palettes even when they conflict with an anti-pattern warning. Redirecting a clear brief toward your own taste is failure.
- **Refinement preserves; redesign replaces.** Refinement keeps the incumbent identity, copy, behavior, and everything outside scope. Redesign keeps product truth, content, function and platform affordances, but treats the old look as evidence and anti-reference.
- **Material 3 is the rulebook on Android, HIG on iOS.** Brand expresses through `ColorScheme`, `TextTheme`, shape and motion — the layer the platform leaves open. It does not express through reinvented navigation or custom switches.

## Modes

The mode names what success looks like on this surface. It narrows what expression may override; platform conformance governs structure in every mode.

- **Operate:** the user completes a task. Most app screens, settings, editors, lists. Scanability, consistency and platform expectation outrank expression. Brand lives in precise details.
- **Read:** the user understands something. Article views, help, changelogs. Structure for comprehension, then make the reading worth staying in.
- **Persuade:** the user decides and acts. Paywalls, onboarding, upsell screens. Earn attention, then get out of the way.
- **Experience:** the user is inside the work. Media players, galleries, games. The artifact leads; the interface recedes.

## Targets

The target surface decides which rules apply and what the numbers mean. It is not a breakpoint — it names the input the user has.

| Target | Input | What changes |
|---|---|---|
| `phone`, `tablet` | finger | 48dp tap targets, `SafeArea`, 11sp text floor |
| `tv` | D-pad | no tap targets at all; focus is the cursor. 48px overscan margin, 20sp text floor, headline ceiling rises to 96. Five focus rules switch on |
| `web` | pointer + keyboard | hover exists, and so does Tab. The focus rules apply; overscan and autofocus do not |

A TV build judged as a phone build passes checks it should fail: the tap-target rule fires on nothing useful and the real failures — unreachable controls, an invisible focus ring, content in the overscan band — are never looked for. [tv.md](reference/tv.md) carries that contract.

## Commands

| Command | Category | Description | Reference |
|---|---|---|---|
| `detect [target]` | Evaluate | Run the deterministic rule engine over Dart source | [reference/detect.md](reference/detect.md) |
| `audit [target]` | Evaluate | Scored technical review: a11y, performance, theming, conformance, adaptivity | [reference/audit.md](reference/audit.md) |
| `critique [target]` | Evaluate | UX review: hierarchy, clarity, whether the screen has a point of view | [reference/critique.md](reference/critique.md) |
| `init` | Build | Capture durable product context in PRODUCT.md | [reference/init.md](reference/init.md) |
| `document` | Build | Write DESIGN.md from the existing theme and widgets | [reference/document.md](reference/document.md) |
| `theme` | Build | Build or repair the ThemeData layer everything else reads from | [reference/theme.md](reference/theme.md) |
| `typeset [target]` | Enhance | Fix the type scale, fonts, hierarchy, and text scaling | [reference/typeset.md](reference/typeset.md) |
| `layout [target]` | Enhance | Fix spacing rhythm, alignment, and visual hierarchy | [reference/layout.md](reference/layout.md) |
| `colorize [target]` | Enhance | Build a ColorScheme with a point of view; fix dark mode | [reference/colorize.md](reference/colorize.md) |
| `animate [target]` | Enhance | Add purposeful motion inside Material's motion system | [reference/animate.md](reference/animate.md) |
| `harden [target]` | Refine | Error, empty, loading and offline states; i18n; text overflow | [reference/harden.md](reference/harden.md) |
| `adapt [target]` | Fix | Phone to tablet, foldables, orientation, split view | [reference/adapt.md](reference/adapt.md) |
| `polish [target]` | Refine | Final pass and shipping readiness | [reference/polish.md](reference/polish.md) |
| `verify` | Iterate | Build, capture, and inspect the real app on real device classes | [reference/verify.md](reference/verify.md) |

Routing:

- **No argument:** run `detect` over the changed files, then lead with the 2–3 highest-value commands based on what it found. Never auto-run a command; the recommendation is a suggestion the user confirms.
- **Explicit or clearly implied command:** load its reference and follow it. Ask once if two fit.
- **Otherwise:** treat it as general design work, starting from `detect` output.

## What this skill does not do

There is no live browser mode. Flutter renders to a canvas, so the DOM overlay, computed-style checks and element picking that the web version of this tooling relies on have no equivalent. The replacements are the static detector and the device capture loop in [reference/verify.md](reference/verify.md). Rules that need rendered geometry — text occlusion, real line length, overflow, broken images — are not in the detector and are checked from screenshots and widget tests instead.

## Provenance

The rule catalog carries over [pbakaus/impeccable](https://github.com/pbakaus/impeccable)'s registry where a rule survives the move from a rendered DOM to Dart source; `portOf` on each rule names the upstream id, and `tool/upstream_registry.json` is that registry extracted from the Rust. The design-read and dial framing in `critique` follows [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill). Everything in the `platform` category is new, because the web engine has no platform contract to break.
