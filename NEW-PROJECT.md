# Starting a Flutter app from scratch

A walkthrough from an empty directory to a first screen that passes the detector. [GETTING-STARTED.md](GETTING-STARTED.md) covers installing the skill and the detector; this assumes both are done.

The order matters. Building a screen before the theme exists means every colour and size gets decided twice, once inline and again when someone moves it into `ThemeData`.

## 1. Create the project

```bash
flutter create --empty --org com.example --platforms=android,ios my_app
cd my_app
```

`--empty` skips the counter demo. Deleting generated sample code is a worse start than never having it, because the sample's habits (inline colours, hand-picked sizes) tend to survive into the real screens.

Pick `--platforms` deliberately. It decides what the detector infers later, and adding a platform afterwards is one command while removing one is manual cleanup.

For Android TV, create it as an Android project and add the leanback intent to `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
  <action android:name="android.intent.action.MAIN" />
  <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
</intent-filter>
```

That one line is what makes the skill and the editor plugin treat this as a TV project without being told.

## 2. Install the skill into this project

For a project the team clones, copy it in and commit it:

```bash
mkdir -p .claude/skills
cp -r "$IMPECCABLE/skills/impeccable-flutter" .claude/skills/
```

Skip this if you symlinked the skill personally. Either way `make install` in the checkout has to have run once, or a copied skill cannot find the detector.

## 3. Establish the direction

```
/impeccable-flutter init
```

On an empty project it will find no `PRODUCT.md`, no theme, and one Dart file, so it treats the work as greenfield and asks whether to build plain or shape a direction first.

Answer Discuss if you want the look decided before code. It runs `vibe` and comes back with two or three directions as an artifact. Pick one, or take one and pull a detail from another.

Answer Plain if you already know what you are building. It writes a short `PRODUCT.md` recording what it could not infer, marks the rest unknown, and stops.

Either way you end up with `PRODUCT.md` in the repo. Commit it. It holds the facts that survive a redesign: who uses this, where, on what hardware, under what constraints.

## 4. Build the theme before the first screen

```
/impeccable-flutter theme
```

This is the highest-leverage step and the easiest to skip. It writes the `ColorScheme` from a seed you chose, the `TextTheme` roles with real steps between them, and the component themes. It also writes `DESIGN.md`, which the four `design-system-*` rules check your code against from then on.

Wire both schemes into `MaterialApp`:

```dart
MaterialApp(
  theme: buildAppTheme(Brightness.light),
  darkTheme: buildAppTheme(Brightness.dark),
  home: const HomeScreen(),
)
```

A dark scheme built on day one costs nothing. Retrofitting one onto thirty screens of literal colours is the most common reason an app never ships dark mode.

## 5. Build the first screen

Write it reading `Theme.of(context)` as you go. The cleanup pass where someone replaces literals with theme roles does not happen, so there is no point planning for it.

Then:

```bash
impeccable-flutter detect lib
```

On a screen built against a real theme this should be close to empty. A long list here usually means step 4 was skipped or the screen ignores the theme it has.

## 6. Add the states before you add the second screen

```
/impeccable-flutter harden
```

Every screen that loads anything needs loading, empty, error and offline. Generated code ships one of the four, and the empty state is the screen a new user sees first.

## 7. Check it on a device

```bash
flutter run
"$IMPECCABLE/skills/impeccable-flutter/scripts/capture-conditions" --out shots
```

Static analysis cannot see rendering. The capture walks light, dark and large text, then puts the device's settings back. Look for clipped labels at large text and hard-coded colours in dark, which are the two that static rules miss most often.

## 8. Lock it in

Add the detector to CI before the codebase grows:

```bash
impeccable-flutter detect lib --fail-on error --format github
```

On a project this young there is nothing to baseline, which is the advantage of starting now. `--fail-on error` from the first commit means the list never grows.

## What changes for TV

Read [reference/tv.md](skills/impeccable-flutter/reference/tv.md) before the first screen, not after. TV removes the pointer, and several decisions that are cosmetic on a phone become structural:

- Every interactive element has to be focusable and visibly so. The focus ring is the cursor.
- Something takes focus on route entry, or the first press of the remote does nothing.
- Content sits inside a 5% overscan margin. `SafeArea` does not cover this.
- Body text starts at 20sp, not 14.

Run the detector with the target set, or none of that is checked:

```bash
impeccable-flutter detect lib --target tv
```

## Order, in short

```
flutter create --empty          # no sample code to unlearn
/impeccable-flutter init        # PRODUCT.md, and the direction
/impeccable-flutter theme       # ColorScheme, TextTheme, DESIGN.md
                                # ... first screen ...
impeccable-flutter detect lib   # should be near-empty
/impeccable-flutter harden      # loading, empty, error, offline
capture-conditions              # light, dark, large text
```
