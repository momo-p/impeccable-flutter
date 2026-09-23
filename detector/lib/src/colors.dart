import 'dart:math' as math;

/// Color helpers, following upstream impeccable's `foundation::color`
/// (relative luminance and contrast are the WCAG 2.x formulas it uses).
class Rgb {
  const Rgb(this.r, this.g, this.b, [this.a = 1.0]);
  final int r, g, b;
  final double a;

  /// WCAG relative luminance.
  double get luminance {
    double channel(int c) {
      final s = c / 255.0;
      return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
  }

  /// 0 for a neutral gray, up to 1 for a fully saturated hue.
  double get chroma {
    final mx = math.max(r, math.max(g, b));
    final mn = math.min(r, math.min(g, b));
    if (mx == 0) return 0;
    return (mx - mn) / mx;
  }

  /// Hue in degrees, or null for a neutral.
  double? get hue {
    final mx = math.max(r, math.max(g, b));
    final mn = math.min(r, math.min(g, b));
    if (mx == mn) return null;
    final d = (mx - mn).toDouble();
    double h;
    if (mx == r) {
      h = ((g - b) / d) % 6;
    } else if (mx == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h *= 60;
    return h < 0 ? h + 360 : h;
  }

  bool get isNeutral => chroma < 0.12;

  String get hex => '#'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

double contrastRatio(Rgb fg, Rgb bg) {
  final l1 = fg.luminance;
  final l2 = bg.luminance;
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

final RegExp _colorLiteral =
    RegExp(r'Color\(\s*0x([0-9a-fA-F]{8})\s*\)');
final RegExp _colorFromARGB =
    RegExp(r'Color\.fromARGB\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)');

/// Parses the color notations that appear in Flutter source. Returns null for
/// anything computed at runtime, which the detector deliberately never guesses at.
Rgb? parseColor(String expr) {
  final m = _colorLiteral.firstMatch(expr);
  if (m != null) {
    final v = int.parse(m[1]!, radix: 16);
    return Rgb((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF, ((v >> 24) & 0xFF) / 255);
  }
  final a = _colorFromARGB.firstMatch(expr);
  if (a != null) {
    return Rgb(int.parse(a[2]!), int.parse(a[3]!), int.parse(a[4]!),
        int.parse(a[1]!) / 255);
  }
  final named = RegExp(r'\bColors\.([a-zA-Z]+)(?:\[(\d+)\]|\.shade(\d+))?')
      .firstMatch(expr);
  if (named != null) {
    final base = kMaterialColors[named[1]!];
    if (base != null) return base;
  }
  return null;
}

/// Every `Color(0x…)` / `Color.fromARGB` / `Colors.x` in a span, with offsets.
Iterable<({int offset, String text, Rgb rgb})> findColors(String s) sync* {
  for (final re in [
    _colorLiteral,
    _colorFromARGB,
    RegExp(r'\bColors\.([a-zA-Z]+)(?:\[(\d+)\]|\.shade(\d+))?')
  ]) {
    for (final m in re.allMatches(s)) {
      final rgb = parseColor(m[0]!);
      if (rgb != null) yield (offset: m.start, text: m[0]!, rgb: rgb);
    }
  }
}

/// The 500 weight of each Material palette, plus the constants that carry no
/// shade. Enough to reason about a hard-coded color without resolving a theme.
const Map<String, Rgb> kMaterialColors = {
  'red': Rgb(0xF4, 0x43, 0x36),
  'pink': Rgb(0xE9, 0x1E, 0x63),
  'purple': Rgb(0x9C, 0x27, 0xB0),
  'deepPurple': Rgb(0x67, 0x3A, 0xB7),
  'indigo': Rgb(0x3F, 0x51, 0xB5),
  'blue': Rgb(0x21, 0x96, 0xF3),
  'lightBlue': Rgb(0x03, 0xA9, 0xF4),
  'cyan': Rgb(0x00, 0xBC, 0xD4),
  'teal': Rgb(0x00, 0x96, 0x88),
  'green': Rgb(0x4C, 0xAF, 0x50),
  'lightGreen': Rgb(0x8B, 0xC3, 0x4A),
  'lime': Rgb(0xCD, 0xDC, 0x39),
  'yellow': Rgb(0xFF, 0xEB, 0x3B),
  'amber': Rgb(0xFF, 0xC1, 0x07),
  'orange': Rgb(0xFF, 0x98, 0x00),
  'deepOrange': Rgb(0xFF, 0x57, 0x22),
  'brown': Rgb(0x79, 0x55, 0x48),
  'grey': Rgb(0x9E, 0x9E, 0x9E),
  'gray': Rgb(0x9E, 0x9E, 0x9E),
  'blueGrey': Rgb(0x60, 0x7D, 0x8B),
  'black': Rgb(0x00, 0x00, 0x00),
  'black87': Rgb(0x00, 0x00, 0x00),
  'black54': Rgb(0x00, 0x00, 0x00),
  'white': Rgb(0xFF, 0xFF, 0xFF),
  'white70': Rgb(0xFF, 0xFF, 0xFF),
  'transparent': Rgb(0x00, 0x00, 0x00, 0.0),
};

/// The hue band every generated UI lands on: indigo through violet.
bool isAiPaletteHue(Rgb c) {
  final h = c.hue;
  if (h == null) return false;
  return h >= 225 && h <= 285 && c.chroma > 0.35;
}
