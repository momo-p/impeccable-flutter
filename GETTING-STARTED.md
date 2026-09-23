# Getting started

Two pieces install separately. The skill is what the agent reads; the detector is what it runs. Neither needs the other to be useful: the skill falls back to the Dart source when no binary is built, and the detector works on its own from a terminal or in CI.

Paths below write the checkout as `$IMPECCABLE`. Set it once:

```bash
IMPECCABLE=/path/to/impeccable-flutter
```

## 1. Install the skill

A skill is a directory containing `SKILL.md`. Claude Code reads two locations.

For every project you work on, symlink it into your personal skills directory. Pulling this repo then updates the skill with no second step:

```bash
ln -s "$IMPECCABLE/skills/impeccable-flutter" ~/.claude/skills/impeccable-flutter
```

For one project only, committed alongside it, copy it into the project. Use this when a team should get the skill by cloning:

```bash
mkdir -p .claude/skills
cp -r "$IMPECCABLE/skills/impeccable-flutter" .claude/skills/
git add .claude/skills/impeccable-flutter
```

Copy rather than symlink here. A symlink into your home directory is broken for everyone else on the team.

Either way the result must be `<skills-dir>/impeccable-flutter/SKILL.md`, with `reference/` and `scripts/` beside it. The skill calls its own launcher at `scripts/impeccable-flutter`, which travels with the copy.

To check it took, start Claude Code in the project and type `/impeccable-flutter`. If nothing is offered, the path is wrong.

## 2. Install the detector

The skill runs without this, falling back to the Dart source. Building the binary makes it fast and removes the need for a Dart SDK at runtime:

```bash
cd "$IMPECCABLE"
make build      # compiles detector/build/impeccable-flutter
make install    # symlinks the launcher into ~/.local/bin
```

Pass `make install PREFIX=/somewhere/else` if `~/.local/bin` is not on your PATH.

A copied skill has no detector above it in the tree, so it looks for `impeccable-flutter` on your PATH. Running `make install` once is what makes project-scoped copies work.

Confirm:

```bash
impeccable-flutter rules | tail -1     # "69 rules total."
```

## 3. Start a project

In a Flutter project, with the skill installed:

```
/impeccable-flutter init
```

It reads the project first: name, platform folders, whether `PRODUCT.md`, `DESIGN.md`, a theme and a baseline exist, and the target it can infer. An Android TV app declares a `LEANBACK_LAUNCHER` intent, so a TV project never has to be asked what it is.

Then it asks one question, and the answer picks the path.

Plain means you want to build. It records whatever it could not infer, writes a short `PRODUCT.md`, names the next command, and gets out of the way. No design interview. Say this when you already know what you are making.

Discuss means you want a direction first. It runs `vibe`, which renders two or three visual directions as an artifact for you to point at.

If your request already contains a brief, say Plain and attach it. Being interviewed about something you have already described is the failure this is built to avoid.

From there the usual order is:

```
/impeccable-flutter vibe        # pick a direction (Discuss runs this for you)
/impeccable-flutter theme       # build the ThemeData everything reads from
                                # ... build the first screen ...
/impeccable-flutter detect lib  # what the code already trips
/impeccable-flutter critique    # does the screen have a point of view
```

Run `theme` first on a greenfield project and `document` first on an existing one. `init` will say which.

## 4. Adopt on an existing app

A first run on a codebase that was not built against this reports a lot. Freeze what is there so CI can block new findings from day one:

```bash
impeccable-flutter detect lib --baseline .impeccable-baseline.json --write-baseline
git add .impeccable-baseline.json

# from now on
impeccable-flutter detect lib --baseline .impeccable-baseline.json --fail-on error
```

Entries key on the source line's text rather than its number, so editing above a finding does not bring it back. Delete an entry by hand to opt that finding back in. Nothing re-adds one on its own.

## 5. Set the target

The target decides which rules run and what the numbers mean. A TV build judged as a phone build passes checks it should fail.

```bash
impeccable-flutter detect lib --target tv
```

`phone` is the default. `signals` infers the target where it can, and the editor plugin infers it per project with no configuration.

## 6. Editor diagnostics (optional)

In the Flutter project:

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.7.0
  impeccable_flutter_lint:
    path: ../impeccable-flutter/lint
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

Pub does not expand `~` in a path dependency, and fails with "could not find package" if you use one. Write the path relative to the pubspec, or absolute.

Then `dart pub get` and reopen the project. Rule names match the CLI, so a finding reads the same in both places.

## 7. Verify on a device

Static analysis cannot see rendering. With the app running on a device or emulator:

```bash
"$IMPECCABLE/skills/impeccable-flutter/scripts/capture-conditions" --out shots
```

It captures light, dark and large text, then restores the device's own settings, including when you interrupt it. `reference/verify.md` covers what to look for. One default-phone screenshot proves almost nothing.

## Everyday

```bash
impeccable-flutter detect lib                      # what is wrong
impeccable-flutter detect lib --target tv          # judged as a TV build
impeccable-flutter detect lib --fix --dry-run      # what could be rewritten
impeccable-flutter detect lib --json               # for a script
impeccable-flutter signals                         # what this project already is
impeccable-flutter rules                           # the catalog
```

Waive a finding in place, with the reason in the same comment:

```dart
// impeccable-disable: hardcoded-color
const brandStamp = Color(0xFF1B7F5C);
```

A comment on its own line waives the line below. A trailing one waives its own line. `// impeccable-disable-file` covers the file.
