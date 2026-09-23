import 'package:flutter/material.dart';

/// The one file where literal colours and sizes belong. Every value here is
/// declared in DESIGN.md, so `design-system-color` and its siblings check the
/// rest of the app against this.
ThemeData buildWatchlistTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B7F5C),
    brightness: brightness,
  ).copyWith(
    // Hand-picked where the generated tone was wrong for this product; the
    // artifact that chose these showed these exact values. See vibe.md.
    onSurfaceVariant:
        brightness == Brightness.light ? const Color(0xFF5C6360) : null,
  );

  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'Karla',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 36,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontFamily: 'Fraunces', fontSize: 24, height: 1.2),
      titleMedium: TextStyle(fontSize: 20, height: 1.3),
      bodyMedium: TextStyle(fontSize: 16, height: 1.5),
      labelSmall: TextStyle(fontSize: 13, height: 1.4),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    // The surfaces nobody themes. Cheapest signal the app was built.
    splashColor: scheme.primary.withValues(alpha: 0.08),
    highlightColor: scheme.primary.withValues(alpha: 0.04),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.24),
    ),
  );
}
