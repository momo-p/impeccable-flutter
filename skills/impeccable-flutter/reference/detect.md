# detect

Run the deterministic rule engine over Dart source. No model, no network, no running app.

```bash
dart run impeccable_flutter detect lib
dart run impeccable_flutter detect lib/screens/home.dart --json
dart run impeccable_flutter detect lib --only hardcoded-color,missing-semantics
dart run impeccable_flutter detect lib --ignore em-dash-overuse --fail-on error
dart run impeccable_flutter rules
```

From the repo, `make detect P=path/to/lib` does the same.

## What it reads

Every `.dart` file under the paths given, skipping `.dart_tool/`, `build/`, `.g.dart` and `.freezed.dart` — generated code is not the author's design work.

Comments and string bodies are blanked before matching, so a widget name in a doc comment is not a finding. String literals are kept separately for the copy rules.

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
