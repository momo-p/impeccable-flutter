# detect

Run the deterministic rule engine over Dart source. No model, no network, no running app.

```bash
impeccable-flutter detect lib
impeccable-flutter detect lib --target tv
impeccable-flutter detect lib/screens/home.dart --json
impeccable-flutter detect lib --only hardcoded-color,missing-semantics
impeccable-flutter detect lib --ignore em-dash-overuse --fail-on error
impeccable-flutter rules
```

From the repo, `make detect P=path/to/lib` does the same.

## What it reads

Every `.dart` file under the paths given, skipping `.dart_tool/`, `build/`, `.g.dart` and `.freezed.dart` — generated code is not the author's design work.

Comments and string bodies are blanked before matching, so a widget name in a doc comment is not a finding. String literals are kept separately for the copy rules.

## Project state

```bash
impeccable-flutter signals            # human-readable
impeccable-flutter signals . --json   # for a flow to branch on
```

Reports what the project already is: name, platform folders, whether `PRODUCT.md`, `DESIGN.md`, a theme file and a baseline exist, how many Dart files and how many hold a `Scaffold`, and the target it can infer.

The target inference is the useful part. An Android TV app declares a `LEANBACK_LAUNCHER` intent in its manifest and nothing else does, so a TV project never has to be asked what it is. Android or iOS folders mean `phone`; web alone means `web`; anything else reports `unclear — ask`.

[init.md](init.md) branches on this. Nothing here mutates the project.

## Targets

`--target phone|tablet|tv|web` (default `phone`) decides which rules run and what their thresholds are. Five rules only exist on focus-driven surfaces:

```
unreachable-by-dpad       [tv, web]   error
missing-focus-highlight   [tv, web]   error
no-autofocus-on-route     [tv]        error
hover-only-affordance     [tv, web]   warning
overscan-unsafe           [tv]        error
```

And these move with the target:

| Rule | phone | tv |
|---|---|---|
| `tiny-text` floor | 11 | 20 |
| `oversized-headline` ceiling | 56 | 96 |
| `tap-target-undersized` | 48dp | does not apply |
| `missing-safe-area` | `SafeArea` | replaced by `overscan-unsafe` |

Running a TV codebase on the default target is the most likely way to get a clean report that means nothing. `impeccable-flutter rules` prints each rule's target scope in brackets.

## Design system

`--design <path>` points at a `DESIGN.md`; without it the detector walks up from the scanned path to find one. The four `design-system-*` rules stay silent when there is none.

```bash
impeccable-flutter detect lib --design DESIGN.md
impeccable-flutter detect lib --only design-system-color
```

These rules are the only ones that ask about the project rather than about Flutter. A value they flag is not wrong — it is undeclared. Either add it to the document on purpose, or use the token that already covers the case.

## pubspec.yaml

Two rules read `pubspec.yaml` alongside the Dart source, because what they check is invisible everywhere else:

- **`undeclared-font`** — a `fontFamily` the pubspec never declares. Flutter falls back to the platform face with no warning, so the app ships in Roboto and nothing reports it: not the analyzer, not a crash, not a log line.
- **`undeclared-asset`** — an `Image.asset` or `AssetImage` path no entry under `flutter: assets:` covers. It throws when that widget builds, which is often a screen nobody opened before release.

The detector walks up from the scanned path to find the pubspec. A directory entry such as `assets/images/` covers files directly inside it and not deeper ones, which is what Flutter itself does. A path built at runtime is skipped rather than guessed at, and a package with no `flutter:` section declares no assets by design, so the asset rule stands down.

## Fixing

`--fix` rewrites the findings that have a mechanical fix and leaves the rest alone. `--dry-run` reports without writing.

```bash
impeccable-flutter detect lib --fix --dry-run
impeccable-flutter detect lib --fix
```

The table is deliberately short — today it is `deprecated-with-opacity` alone, because `.withOpacity(x)` and `.withValues(alpha: x)` mean the same thing and the argument carries over untouched.

Nothing else on the list qualifies. "Use a theme role instead of this literal" needs someone to decide *which* role. "Give this button a tooltip" needs someone to write the words. `WillPopScope` → `PopScope` changes the callback's signature and its semantics. A fix that needs a judgment call would make `--fix` quietly wrong at scale, which is worse than reporting the finding, so those stay manual.

Output says how many were rewritten and how many were left:

```
rewrote 2 findings in 1 file.
3 findings need a decision and were left alone; run without --fix to see them.
```

## Baseline

`--baseline <path>` suppresses findings recorded in that file and reports only new ones; `--write-baseline` records the current set. This is how the detector gets adopted on a codebase that was not built against it.

```bash
impeccable-flutter detect lib --baseline .impeccable-baseline.json --write-baseline
impeccable-flutter detect lib --baseline .impeccable-baseline.json --fail-on error
```

Entries key on the source line's text rather than its number, so an edit above a finding does not bring it back. A run against a baseline reports how many entries are stale; `--write-baseline` prunes them. Deleting an entry by hand is how a finding is opted back in — the detector never re-adds one.

## Output

`--json` gives machine-readable findings. `--format github` prints annotations that GitHub pins to the diff, which is the useful form in CI.

## Reading the output

Each finding carries a rule id, a severity, the file and line, the source line, and the measured value that tripped it.

- **error** — a user hits this: an unlabeled control, a tap target under 48, a layout that throws, text under the contrast floor.
- **warning** — a design defect: taste failures and theming that will break dark mode.
- **advisory** — a judgment call, mostly copy. Read it, then decide.

`--fail-on error` in CI is the useful setting. `--fail-on warning` will fail on a project that has not been through `theme` yet.

## Waiving a finding

```dart
// impeccable-disable: hardcoded-color
const brandStamp = Color(0xFF1B7F5C);

final splash = Color(0xFF1B7F5C); // impeccable-disable
```

A comment on its own line waives the line below; a trailing comment waives its own line. Naming ids scopes the waiver to them. `// impeccable-disable-file` covers the whole file. Waive with a reason in the same comment where the reason is not obvious.

## What it cannot see

The detector reads source, not pixels. It does not know whether text is occluded, whether a line runs too long at the width it actually got, whether an image is broken, or whether a layout overflows. Those come from [verify.md](verify.md) and from golden tests.

It also cannot resolve a color computed at runtime. `low-contrast` fires only on literal pairs, so a clean run is not proof of contrast — it is proof that the pairs it could resolve were fine.

## When a rule is wrong

A false positive is a bug in the rule, not a reason to blanket-disable it. The rule set is in `detector/lib/src/rules.dart`, each rule has a fires/stays-quiet test pair in `detector/test/rules_test.dart`, and the clean fixture in `detector/test/fixtures/clean_screen.dart` must stay at zero findings. Add the case that broke, then fix the rule.
