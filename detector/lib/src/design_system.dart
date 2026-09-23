import 'dart:io';

import 'colors.dart';

/// The tokens a project's DESIGN.md declares.
///
/// Upstream keeps this in a generated sidecar beside DESIGN.md. Here it is
/// read from the document itself, because DESIGN.md is written by a person or
/// an agent and a format that only a generator can produce would go stale the
/// first time someone edits it by hand.
///
/// The parse is deliberately forgiving: it scans for value-shaped tokens
/// anywhere in the document rather than demanding a schema. A design system
/// nobody can edit is a design system nobody updates.
class DesignSystem {
  DesignSystem({
    required this.colors,
    required this.fonts,
    required this.fontSizes,
    required this.radii,
    this.path,
  });

  /// Declared colors, as 24-bit RGB. Alpha is ignored: a token used at 60%
  /// opacity is still that token.
  final Set<int> colors;

  /// Declared font families, lowercased with spaces and dashes removed.
  final Set<String> fonts;

  final Set<double> fontSizes;
  final Set<double> radii;

  /// Where the document was read from, for the finding message.
  final String? path;

  bool get isEmpty =>
      colors.isEmpty && fonts.isEmpty && fontSizes.isEmpty && radii.isEmpty;

  static String normalizeFont(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  /// Walks up from [start] looking for DESIGN.md. Returns null when the
  /// project has no design system, which is what keeps these rules silent
  /// rather than noisy on a project that never declared one.
  static DesignSystem? discover(String start) {
    var dir = Directory(start).absolute;
    if (FileSystemEntity.isFileSync(start)) {
      dir = File(start).absolute.parent;
    }
    for (var i = 0; i < 8; i++) {
      for (final name in const ['DESIGN.md', 'design.md', 'docs/DESIGN.md']) {
        final file = File('${dir.path}/$name');
        if (file.existsSync()) {
          return parse(file.readAsStringSync(), path: file.path);
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  static DesignSystem parse(String markdown, {String? path}) {
    // Fenced code blocks hold examples, which are the most reliable place a
    // token appears; prose around them is scanned too.
    final text = markdown;

    final colors = <int>{};
    for (final m in RegExp(r'#([0-9a-fA-F]{6})\b').allMatches(text)) {
      colors.add(int.parse(m[1]!, radix: 16));
    }
    for (final m in RegExp(r'0x[fF]{2}([0-9a-fA-F]{6})\b').allMatches(text)) {
      colors.add(int.parse(m[1]!, radix: 16));
    }
    for (final m in RegExp(r'#([0-9a-fA-F]{3})\b').allMatches(text)) {
      final s = m[1]!;
      final expanded = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
      colors.add(int.parse(expanded, radix: 16));
    }

    final fonts = <String>{};
    // The negative lookahead keeps "font size: 36" out of the font list, and
    // the capture runs to the end of the value rather than an ASCII class, so
    // a face like Söhne survives.
    for (final re in [
      RegExp(r'(?:font|family|typeface)(?!\s*sizes?)\s*[:=]\s*([^\n,;|#*]{2,40})',
          caseSensitive: false),
      RegExp(r'''fontFamily\s*:\s*['"]([^'"]{2,40})['"]'''),
    ]) {
      for (final m in re.allMatches(text)) {
        final raw = m[1]!.trim().replaceAll(RegExp(r'^[`"\x27]|[`"\x27]$'), '');
        if (raw.isEmpty) continue;
        // A value that is really a number list is a ramp, not a face.
        if (RegExp(r'^[\d\s.]+$').hasMatch(raw)) continue;
        fonts.add(normalizeFont(raw));
      }
    }

    // Sizes and radii are only trustworthy when the document says which is
    // which, so each is read from its own labelled context.
    final fontSizes = _numbersNear(
        text, RegExp(r'(?:font\s*size|fontSize|size|type\s*scale)', caseSensitive: false));
    final radii = _numbersNear(
        text, RegExp(r'(?:radius|radii|corner|rounding)', caseSensitive: false));

    return DesignSystem(
      colors: colors,
      fonts: fonts,
      fontSizes: fontSizes,
      radii: radii,
      path: path,
    );
  }

  /// Every number on a line whose text matches [label].
  static Set<double> _numbersNear(String text, RegExp label) {
    final out = <double>{};
    for (final line in text.split('\n')) {
      if (!label.hasMatch(line)) continue;
      for (final m in RegExp(r'\b(\d{1,3}(?:\.\d+)?)\b').allMatches(line)) {
        final v = double.parse(m[1]!);
        if (v > 0 && v <= 200) out.add(v);
      }
    }
    return out;
  }

  bool declaresColor(Rgb c) =>
      colors.contains((c.r << 16) | (c.g << 8) | c.b);

  bool declaresFont(String family) => fonts.contains(normalizeFont(family));

  bool declaresFontSize(double size) => fontSizes.contains(size);

  bool declaresRadius(double radius) => radii.contains(radius);
}
