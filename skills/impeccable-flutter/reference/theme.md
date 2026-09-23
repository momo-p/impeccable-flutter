# theme

Build or repair the `ThemeData` layer everything else reads from. This is the highest-leverage command in the set: most `hardcoded-color` and `hardcoded-text-style` findings are one theme away from gone, and dark mode does not work until this is done.

## 1. Find what exists

```bash
dart run impeccable_flutter detect lib --only hardcoded-color,hardcoded-text-style
```

Group the literals. A color used in 14 places is one role; a color used once may be a genuine one-off. Count before naming.

## 2. Pick the seed

`ColorScheme.fromSeed` generates a tonally correct, contrast-checked scheme from one color. Pick the seed from the product, not from the palette the code drifted into.

```dart
ColorScheme.fromSeed(seedColor: const Color(0xFF1B7F5C), brightness: brightness)
```

Then override only the roles you have an opinion about. Overriding most of them means the seed was wrong.

Roles worth knowing: `primary` and `onPrimary` for the main action; `surface`, `surfaceContainer`, `surfaceContainerHighest` for the elevation ladder; `onSurface` and `onSurfaceVariant` for primary and secondary text; `outline` and `outlineVariant` for borders; `error` and `onError`.

Secondary text is `onSurfaceVariant`, not gray. Gray on a tinted surface is a rule upstream flags and Flutter makes easy to get wrong.

## 3. Build both schemes

```dart
ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: kSeed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    textTheme: _textTheme,
    cardTheme: CardThemeData(elevation: 0, color: scheme.surfaceContainerLow),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(...)),
    inputDecorationTheme: InputDecorationTheme(...),
  );
}
```

Wire both into `MaterialApp` as `theme` and `darkTheme`. Dark is a scheme you designed, not `Brightness.dark` bolted on.

## 4. The type scale

Define the roles you use, with real steps between them. Three sizes within four pixels is not a scale.

```dart
const _textTheme = TextTheme(
  displaySmall: TextStyle(fontSize: 36, height: 1.15, letterSpacing: -0.5),
  titleMedium: TextStyle(fontSize: 18, height: 1.3),
  bodyMedium: TextStyle(fontSize: 16, height: 1.5),
  labelSmall: TextStyle(fontSize: 12, height: 1.4),
);
```

Set `fontFamily` on `ThemeData` once; bundle the face through `pubspec.yaml` rather than shipping the system default as the brand.

## 5. Theme the surfaces nobody themes

These carry framework defaults that belong to no design system, and theming them is the cheapest signal the app was built rather than assembled:

`splashColor` and `highlightColor` · `scrollbarTheme` · `textSelectionTheme` (cursor, selection, handles) · `dividerTheme` · `snackBarTheme` · `appBarTheme` system bar contrast via `systemOverlayStyle`.

## 6. Migrate the call sites

Replace literals with roles in one pass per file, then re-run detect. `make detect` going from dozens of findings to zero on a screen is the check that the migration landed.

**Never**: keep a second source of truth (a `AppColors` class beside the scheme); override `ThemeData.copyWith` deep in a widget tree to patch one screen; ship a dark scheme you have not looked at.
