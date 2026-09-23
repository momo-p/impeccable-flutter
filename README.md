# impeccable-flutter

Design guidance and a deterministic detector for Flutter, ported from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (web) with the taste framing from [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill).

Two pieces:

- **`skills/impeccable-flutter/`** — an agent skill: `SKILL.md` plus 16 reference playbooks covering the Flutter platform contract, theming, type, layout, color, motion, hardening, adaptivity, and a device-based verification loop.
- **`detector/`** — a zero-dependency Dart CLI that runs 65 rules over Dart source across four target surfaces (phone, tablet, TV, web). No model, no network, no running app.

## Why a port rather than a config

Upstream impeccable is a 125k-line Rust engine whose static path reads HTML and CSS and whose deep checks drive a real browser: computed styles, element picking, rendered geometry. Flutter paints to a canvas. None of that transfers.

What does transfer is the rule catalog. `tool/extract_registry.pl` pulls all 61 rules straight out of upstream's `crates/foundation/src/registry.rs` into `tool/upstream_registry.json`, and every ported rule names the upstream id it carries in its `portOf` field — checked by a test, so the provenance cannot silently rot.

## The rules

| Category | Count | What it is |
|---|---|---|
| `slop` | 31 | Taste failures, all ported from upstream |
| `quality` | 15 | Defects a user feels, all ported |
| `platform` | 19 | Flutter, Material, HIG, TV focus and web contracts — no upstream equivalent |

## What is not ported, and why

46 of upstream's 61 rules are carried over. The remaining 15 fall into two groups.

**12 need rendered geometry** and are not portable to static source at any effort. `reference/verify.md` covers them with screenshots and golden tests instead:

`body-text-viewport-edge` · `broken-image` · `buried-raster` · `clipped-overflow-container` · `content-hidden-at-rest` · `edge-flush-cards` · `first-viewport-column-overflow` · `heading-rhythm` · `line-length` · `script-error` · `text-occlusion` · `text-overflow`

**3 are portable but deliberately skipped**, because a Flutter port of them would report more noise than signal:

- `organic-clip-path` and `shape-assembled-illustration` — a `ClipPath` with a custom clipper is ordinary in Flutter, and nothing in the source separates a cheap geometric stand-in from a legitimate one.
- `skipped-heading` — Flutter has no heading levels. `Semantics(header: true)` is a boolean, so there is no level to skip.

The 17 platform rules are the part that has no upstream counterpart, because a web page has no notch, no text scaler, no predictive back, no D-pad and no 48dp floor: `hardcoded-color`, `hardcoded-text-style`, `missing-safe-area`, `tap-target-undersized`, `mediaquery-size-branch`, `missing-semantics`, `deprecated-with-opacity`, `unbounded-list`, `fixed-height-text-box`, `platform-control-mix`, `deprecated-will-pop-scope`, `network-image-unguarded`, plus five that only apply to focus-driven surfaces: `unreachable-by-dpad`, `missing-focus-highlight`, `no-autofocus-on-route`, `hover-only-affordance`, `overscan-unsafe`.

## Design-system conformance

Four rules — `design-system-color`, `design-system-font`, `design-system-font-size`, `design-system-radius` — check code against the project's own `DESIGN.md` rather than against a universal standard. They ask whether a value is one the project ever declared.

They stay silent unless a `DESIGN.md` is found, because a project with no declared system has nothing for a value to be outside of. The detector walks up from the scanned path to find it, or takes `--design <path>`.

The parse is deliberately forgiving — it scans for value-shaped tokens rather than demanding a schema, so the document stays something a person can edit:

```markdown
## Color
| primary | #1B7F5C |

## Type
Font: Söhne
Type ramp — font size: 36, 24, 18, 16, 13

## Spacing and shape
Corner radius: 4, 8, 12
```

Alpha is ignored when matching colors, so a declared token used at 40% opacity still counts. `reference/document.md` covers writing the document; `make detect P=... ` picks it up automatically.

## Use

```bash
nix develop            # or direnv allow
make test              # 189 tests
make rules             # the catalog
make detect P=path/to/your/app/lib
make detect P=path/to/your/app/lib TARGET=tv
```

From any Flutter project, once installed:

```bash
impeccable-flutter detect lib --fail-on error
impeccable-flutter detect lib --target tv
impeccable-flutter detect lib --only hardcoded-color --json
```

Waive a finding inline:

```dart
// impeccable-disable: hardcoded-color
const brandStamp = Color(0xFF1B7F5C);
```

A comment on its own line waives the line below; a trailing one waives its own line. `// impeccable-disable-file` covers the file.

## Adopting on an existing app

A first run on a real codebase reports a lot, `--fail-on` can never be switched on, and the tool gets ignored. A baseline freezes what is already there so CI can block *new* findings from day one.

```bash
impeccable-flutter detect lib --baseline .impeccable-baseline.json --write-baseline
impeccable-flutter detect lib --baseline .impeccable-baseline.json --fail-on error
```

Entries key on rule id, file, and the source line's text — not the line number — so editing above a finding does not resurrect it. When a finding is fixed, the next run says how many entries are stale and `--write-baseline` prunes them. Nothing re-adds an entry on its own; deleting one by hand is how you opt a finding back in.

In CI, `--format github` prints annotations that land on the diff instead of in the log.

## Install

```bash
make build      # compile detector/build/impeccable-flutter (standalone, no Dart at runtime)
make install    # symlink the launcher into ~/.local/bin (override with PREFIX=)
```

`make install` links `skills/impeccable-flutter/scripts/impeccable-flutter`, a launcher that runs the compiled binary when one exists and falls back to the Dart source otherwise. Either way the calling project needs nothing: no pubspec entry, no Dart SDK once the binary is built.

`dart run impeccable_flutter …` only works from inside `detector/`, because `dart run <package>` resolves against the *calling* project's dependencies. Use the launcher from a real Flutter project.

## Install the skill

```bash
cp -r skills/impeccable-flutter ~/.claude/skills/
```

The skill calls the launcher at `<skill-dir>/scripts/impeccable-flutter`, which is copied along with it, so the skill works whether or not the binary is on PATH.


## Test bed

`../flutter-tests` is a runnable Flutter app holding four screens: two phone (`slop_home.dart`, 32 findings across 25 rules, and `clean_home.dart`, none) and two TV (`tv_home.dart`, 6 findings including two focus errors under `--target tv`, and `tv_clean_home.dart`, none). `make -C ../flutter-tests detect`, `clean-detect`, `tv-detect` and `tv-clean-detect` show each pair; `make run` switches between all four in the app.

The detector's own corpus is in `detector/test/fixtures/`, with two tests that matter more than the rest: the slop corpus must trip **every** rule in the catalog, and the clean fixture must produce **zero** findings. A rule that only fires in its own unit test does not survive contact with real widget code.

## Re-extracting upstream

```bash
git clone --depth 1 https://github.com/pbakaus/impeccable /tmp/impeccable
make registry SRC=/tmp/impeccable
make test
```

If upstream renames or drops a rule, the provenance test fails and names it.

## Layout

```
skills/impeccable-flutter/   SKILL.md + reference/*.md
detector/lib/src/            source model, colors, registry, rules, scanner
detector/test/               unit, rule, registry and fixture tests
tool/extract_registry.pl     upstream Rust registry -> JSON
tool/upstream_registry.json  the 61 upstream rules
```

## License

Apache-2.0, matching [Impeccable](https://github.com/pbakaus/impeccable), which this derives from. The rule catalog in `tool/upstream_registry.json` is extracted from its Apache-2.0 source, so this project cannot be released under more permissive terms. `NOTICE` records what was derived and how it changed, as Apache-2.0 §4 requires.

The `../flutter-tests` test bed shares no upstream material and is MIT.
