# impeccable-flutter

Design guidance and a deterministic detector for Flutter, ported from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (web) with the taste framing from [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill).

Two pieces:

- `skills/impeccable-flutter/` is the agent skill: `SKILL.md` plus 18 reference playbooks covering the Flutter platform contract, theming, type, layout, color, motion, hardening, adaptivity, TV, and a device-based verification loop.
- `detector/` is a zero-dependency Dart CLI that runs 69 rules over Dart source across four target surfaces (phone, tablet, TV, web). It needs no model, no network and no running app.

## Why a port rather than a config

Upstream impeccable is a 125k-line Rust engine whose static path reads HTML and CSS and whose deep checks drive a real browser: computed styles, element picking, rendered geometry. Flutter paints to a canvas. None of that transfers.

What does transfer is the rule catalog. `tool/extract_registry.pl` pulls all 61 rules straight out of upstream's `crates/foundation/src/registry.rs` into `tool/upstream_registry.json`, and every ported rule names the upstream id it carries in its `portOf` field. A test checks that, so the provenance cannot silently rot.

## The rules

| Category | Count | What it is |
|---|---|---|
| `slop` | 31 | Taste failures, all ported from upstream |
| `quality` | 15 | Defects a user feels, all ported |
| `platform` | 23 | Flutter, Material, HIG, TV focus, web and pubspec contracts, with no upstream equivalent |

## What is not ported, and why

46 of upstream's 61 rules are carried over. The remaining 15 fall into two groups.

**12 need rendered geometry** and are not portable to static source at any effort. `reference/verify.md` covers them with screenshots and golden tests instead:

`body-text-viewport-edge` · `broken-image` · `buried-raster` · `clipped-overflow-container` · `content-hidden-at-rest` · `edge-flush-cards` · `first-viewport-column-overflow` · `heading-rhythm` · `line-length` · `script-error` · `text-occlusion` · `text-overflow`

**3 are portable but deliberately skipped**, because a Flutter port of them would report more noise than signal:

- `organic-clip-path` and `shape-assembled-illustration`: a `ClipPath` with a custom clipper is ordinary in Flutter, and nothing in the source separates a cheap geometric stand-in from a legitimate one.
- `skipped-heading`: Flutter has no heading levels. `Semantics(header: true)` is a boolean, so there is no level to skip.

The 23 platform rules have no upstream counterpart at all, because a web page has no notch, no text scaler, no predictive back, no D-pad and no 48dp floor. Fifteen of them run on every target: `hardcoded-color`, `hardcoded-text-style`, `missing-safe-area`, `tap-target-undersized`, `mediaquery-size-branch`, `missing-semantics`, `deprecated-with-opacity`, `unbounded-list`, `fixed-height-text-box`, `platform-control-mix`, `deprecated-will-pop-scope`, `network-image-unguarded`, `image-no-cache-size`, `undeclared-font`, `undeclared-asset`.

Eight more are scoped to a surface. Five run where focus is the cursor: `unreachable-by-dpad`, `missing-focus-highlight`, `no-autofocus-on-route`, `hover-only-affordance`, `overscan-unsafe`. Three run on web only: `mouse-drag-scroll`, `text-not-selectable`, `hash-url-strategy`.

## Design-system conformance

Four rules (`design-system-color`, `design-system-font`, `design-system-font-size`, `design-system-radius`) check code against the project's own `DESIGN.md` rather than against a universal standard. They ask whether a value is one the project ever declared.

They stay silent unless a `DESIGN.md` is found, because a project with no declared system has nothing for a value to be outside of. The detector walks up from the scanned path to find it, or takes `--design <path>`.

The parse is deliberately forgiving. It scans for value-shaped tokens instead of demanding a schema, so the document stays something a person can edit:

```markdown
## Color
| primary | #1B7F5C |

## Type
Font: Söhne
Type ramp, font size: 36, 24, 18, 16, 13

## Spacing and shape
Corner radius: 4, 8, 12
```

Alpha is ignored when matching colors, so a declared token used at 40% opacity still counts. `reference/document.md` covers writing the document; `make detect P=... ` picks it up automatically.

## Use

```bash
nix develop            # or direnv allow; any Dart 3.6+ SDK works without nix
make test              # 247 tests across both packages
make rules             # the catalog
make signals P=path/to/your/app   # what the project already is
make detect P=path/to/your/app/lib
make detect P=path/to/your/app/lib TARGET=tv
```

From any Flutter project, once installed:

```bash
impeccable-flutter detect lib --fail-on error
impeccable-flutter detect lib --target tv
impeccable-flutter detect lib --only hardcoded-color --json
```

An `// impeccable-disable` comment waives a finding in place; [GETTING-STARTED.md](GETTING-STARTED.md#everyday) has the syntax.

## Adopting on an existing app

A first run on a real codebase reports a lot, `--fail-on` can never be switched on, and the tool gets ignored. A baseline freezes what is already there so CI can block *new* findings from day one. Entries key on rule id, file, and the source line's text instead of the line number, so editing above a finding does not resurrect it. When a finding is fixed, the next run says how many entries are stale and `--write-baseline` prunes them. Nothing re-adds an entry on its own; deleting one by hand is how you opt a finding back in.

In CI, `--format github` prints annotations that land on the diff instead of in the log. [GETTING-STARTED.md](GETTING-STARTED.md#4-adopt-on-an-existing-app) has the commands.

## In the editor

`lint/` is a [custom_lint](https://pub.dev/packages/custom_lint) plugin that surfaces the same findings as squiggles in VS Code and IntelliJ. The detector stays dependency-free; this package is the only thing that touches the analyzer.

It goes in the Flutter project's `dev_dependencies` alongside `custom_lint`, with `custom_lint` listed under `analyzer.plugins`; [GETTING-STARTED.md](GETTING-STARTED.md#6-editor-diagnostics-optional) has both snippets. Then `dart run custom_lint` on the command line, or just open the project.

**The target is inferred.** An Android TV app declares a `LEANBACK_LAUNCHER` intent and nothing else does, so a TV project gets its focus rules in the editor without anyone remembering to set a flag. Override it where the inference is wrong:

```yaml
custom_lint:
  rules:
    - impeccable_target:
        target: tv
```

Rule names match the CLI's, so `// ignore: tiny-text` and the detector's own `// impeccable-disable` read the same way.

## Install

[GETTING-STARTED.md](GETTING-STARTED.md) covers the skill in personal or project scope, the detector build, adoption and editor diagnostics. [NEW-PROJECT.md](NEW-PROJECT.md) walks a new app from `flutter create` to a first screen that passes. The short version:

```bash
make build      # compile detector/build/impeccable-flutter
make install    # put the launcher on PATH (override with PREFIX=)

ln -s "$PWD/skills/impeccable-flutter" ~/.claude/skills/impeccable-flutter
```

Then `/impeccable-flutter init` inside a Flutter project.

## Example

`examples/watchlist/` is the same screen built twice, plus the TV version.

```bash
make example
```

`library_before.dart` reports 47 findings, `library_after.dart` and `library_tv.dart` report none, and `examples/watchlist/README.md` explains each decision and which playbook it comes from. A test pins all of it, so an "after" screen that starts tripping a rule fails the suite.

It is source rather than a built app, since this repo has no Flutter toolchain. Run `flutter create --platforms=android,ios .` inside it to generate the platform folders.

## Fixtures

`detector/test/fixtures/` is the corpus, and two tests over it matter more than the rest: the slop fixtures must trip **every** rule in the catalog, and the clean ones must produce **zero** findings. A rule that only fires in its own unit test does not survive contact with real widget code.

## Re-extracting upstream

```bash
git clone --depth 1 https://github.com/pbakaus/impeccable /tmp/impeccable
make registry SRC=/tmp/impeccable
make test
```

If upstream renames or drops a rule, the provenance test fails and names it.

## Layout

```
GETTING-STARTED.md           installing the skill and the detector
NEW-PROJECT.md               a new app from flutter create to a passing screen
examples/watchlist/          the same screen before and after, plus TV
skills/impeccable-flutter/   SKILL.md + reference/*.md + scripts/
detector/lib/src/            source model, colors, registry, rules, scanner
lint/                        custom_lint plugin for IDE diagnostics
detector/test/               unit, rule, registry and fixture tests
tool/extract_registry.pl     upstream Rust registry -> JSON
tool/upstream_registry.json  the 61 upstream rules
```

## License

Apache-2.0, matching [Impeccable](https://github.com/pbakaus/impeccable), which this derives from. The rule catalog in `tool/upstream_registry.json` is extracted from its Apache-2.0 source, so this project cannot be released under more permissive terms. `NOTICE` records what was derived and how it changed, as Apache-2.0 §4 requires.

