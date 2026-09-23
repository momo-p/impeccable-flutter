# polish

The final pass before shipping. Everything is built; this closes the gap between working and finished.

## 1. Close the backlog

```bash
dart run impeccable_flutter detect lib --fail-on error
flutter analyze
flutter test
```

If a previous `audit` or `critique` produced findings, this is where they get closed. Work P0 to P2; leave P3 unless it is free.

## 2. Consistency sweep

Across the whole app, not one screen:

- The same action has the same label everywhere. "Done", "Save" and "Confirm" doing the same thing is three decisions the user has to make.
- The same concept has the same icon, from one icon set.
- Spacing steps come from the scale; type comes from `TextTheme`; color comes from `ColorScheme`.
- Loading, empty and error states look like the same app wrote them.
- Route transitions are the same pattern for the same kind of move.

## 3. The surfaces nobody themes

Framework defaults belonging to no design system, and the cheapest signal an app was built rather than assembled: splash and highlight, scrollbar, text selection and handles, overscroll indicator, divider color, snackbar, system bar contrast. See [theme.md](theme.md).

## 4. Verify on real conditions

The four that break layouts, from [verify.md](verify.md): dark scheme, 200% text, the smallest device class you ship to, tablet or split view. One default-phone screenshot proves almost nothing.

Then look for what a static rule cannot see: occluded text, overflow stripes, broken images, body text running the full width of a tablet.

## 5. Lock it in

Golden tests for the screens that matter, including one in the dark scheme and one at `TextScaler.linear(2.0)`. A screenshot proves today; a golden proves every day after.

## 6. Say what is left

Report honestly: what was fixed, what was found and deliberately left, which conditions the evidence came from, and what still needs real hardware. An unflagged assumption is a bug you buried.

**Never**: declare ready without running the checks; polish a screen while ignoring that the theme does not exist; report a fix you have not seen work.
