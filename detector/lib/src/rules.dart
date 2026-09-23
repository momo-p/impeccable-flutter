import 'colors.dart';
import 'source.dart';

typedef RuleCheck = void Function(DartSource src, Emit emit);
typedef Emit = void Function(String ruleId, int line, {String? detail, String? snippet});

/// Widget names that make their subtree tappable.
const _tapWidgets = {
  'GestureDetector', 'InkWell', 'InkResponse', 'IconButton', 'TextButton',
  'ElevatedButton', 'FilledButton', 'OutlinedButton', 'FloatingActionButton',
};

const _overusedFonts = {
  'inter', 'roboto', 'poppins', 'montserrat', 'plusjakartasans',
  'plus jakarta sans', 'spacegrotesk', 'space grotesk', 'geist', 'opensans',
  'open sans', 'lato', 'nunito',
};

const _buzzwords = [
  'seamless', 'seamlessly', 'effortless', 'effortlessly', 'supercharge',
  'game-changing', 'game changing', 'unlock the power', 'elevate your',
  'take it to the next level', 'revolutionize', 'cutting-edge',
];

/// A file that defines the theme is where literal colors and sizes belong.
bool _isThemeFile(DartSource src) {
  final p = src.path.toLowerCase();
  if (p.contains('theme') || p.contains('tokens') || p.contains('palette') ||
      p.contains('design_system')) {
    return true;
  }
  return RegExp(r'\b(ThemeData|ColorScheme|TextTheme)\s*\(').hasMatch(src.masked);
}

final List<RuleCheck> kChecks = [
  _overusedFont,
  _gradientText,
  _aiColorPalette,
  _nestedCards,
  _bounceEasing,
  _sideTab,
  _darkGlow,
  _radialHalo,
  _iconTileStack,
  _kickerAboveHeading,
  _typeScaleRules,
  _monotonousSpacing,
  _copyRules,
  _crampedPadding,
  _layoutTransition,
  _lowContrast,
  _hardcodedColor,
  _hardcodedTextStyle,
  _missingSafeArea,
  _tapTargetUndersized,
  _mediaQuerySizeBranch,
  _missingSemantics,
  _deprecatedApis,
  _unboundedList,
  _fixedHeightTextBox,
  _platformControlMix,
  _networkImageUnguarded,
];

// --------------------------------------------------------------------------
// Ported slop
// --------------------------------------------------------------------------

void _overusedFont(DartSource src, Emit emit) {
  final re = RegExp(
      r"""(?:fontFamily\s*:\s*['"]([^'"]+)['"])|(?:GoogleFonts\.([a-zA-Z]+)\s*\()""");
  // fontFamily values live in string literals, which `masked` blanks, so this
  // one rule reads the raw text.
  for (final m in re.allMatches(src.text)) {
    final name = (m[1] ?? m[2] ?? '').replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
    if (!_overusedFonts.contains(name)) continue;
    emit('overused-font', src.lineAt(m.start), detail: m[1] ?? m[2]);
  }
}

void _gradientText(DartSource src, Emit emit) {
  for (final mask in src.calls.where((c) => c.name == 'ShaderMask')) {
    final inner = src.calls.where(mask.contains);
    if (inner.any((c) => c.name == 'Text') &&
        mask.args.contains('Gradient')) {
      emit('gradient-text', mask.line);
    }
  }
}

void _aiColorPalette(DartSource src, Emit emit) {
  final hits = <int>[];
  for (final c in findColors(src.masked)) {
    if (isAiPaletteHue(c.rgb)) hits.add(c.offset);
  }
  // One violet is a choice; a palette built from the band is the tell.
  if (hits.length < 2) return;
  hits.sort();
  emit('ai-color-palette', src.lineAt(hits.first),
      detail: '${hits.length} colors in the indigo-violet band');
}

void _nestedCards(DartSource src, Emit emit) {
  final cards = src.calls.where((c) => c.name == 'Card').toList();
  for (final outer in cards) {
    for (final inner in cards) {
      if (outer.contains(inner)) {
        emit('nested-cards', inner.line);
      }
    }
  }
}

void _bounceEasing(DartSource src, Emit emit) {
  final re = RegExp(r'\bCurves\.(bounce\w+|elastic\w+|easeOutBack|easeInBack|easeInOutBack)\b');
  for (final m in re.allMatches(src.masked)) {
    emit('bounce-easing', src.lineAt(m.start), detail: 'Curves.${m[1]}');
  }
}

void _sideTab(DartSource src, Emit emit) {
  // Border(left: BorderSide(...)) / Border(right: ...) with a visible width.
  for (final border in src.calls.where((c) => c.name == 'Border' && c.constructor == null)) {
    for (final side in ['left', 'right', 'top', 'bottom']) {
      final expr = border.arg(side);
      if (expr == null || !expr.contains('BorderSide')) continue;
      final width = RegExp(r'width\s*:\s*([\d.]+)').firstMatch(expr);
      final w = double.tryParse(width?[1] ?? '') ?? 1.0;
      if (w < 2) continue;
      final colorExpr = RegExp(r'color\s*:\s*([^,)]+)').firstMatch(expr)?[1] ?? '';
      final rgb = parseColor(colorExpr);
      if (rgb != null && rgb.isNeutral) continue;

      // Rounded or not decides which of the two rules fires, as upstream does.
      final owner = src.calls
          .where((c) => c.contains(border) && c.name == 'BoxDecoration')
          .toList();
      final rounded = owner.any((c) => c.args.contains('borderRadius'));
      final isSide = side == 'left' || side == 'right';
      if (rounded && w >= 2) {
        emit('border-accent-on-rounded', border.line,
            detail: 'border-$side: ${w}px on a rounded surface');
      } else if (isSide) {
        emit('side-tab', border.line, detail: 'border-$side: ${w}px');
      }
    }
  }
}

void _darkGlow(DartSource src, Emit emit) {
  for (final s in src.calls.where((c) => c.name == 'BoxShadow')) {
    final blur = s.numArg('blurRadius') ?? 0;
    final offset = s.arg('offset') ?? '';
    final zeroOffset = offset.isEmpty ||
        RegExp(r'Offset\(\s*0(?:\.0)?\s*,\s*0(?:\.0)?\s*\)').hasMatch(offset);
    if (blur < 12 || !zeroOffset) continue;
    final rgb = parseColor(s.arg('color') ?? '');
    if (rgb == null || rgb.isNeutral) continue;
    emit('dark-glow', s.line, detail: 'blurRadius: $blur, no offset, ${rgb.hex}');
  }
}

void _radialHalo(DartSource src, Emit emit) {
  for (final g in src.calls.where((c) => c.name == 'RadialGradient')) {
    final inDecoration = src.calls.any((c) =>
        c.name == 'BoxDecoration' && c.contains(g));
    if (inDecoration) emit('radial-halo', g.line);
  }
}

void _iconTileStack(DartSource src, Emit emit) {
  for (final col in src.calls.where((c) => c.name == 'Column')) {
    final children = src.calls.where(col.contains).toList();
    final tile = children.firstWhere(
      (c) => (c.name == 'Container' || c.name == 'DecoratedBox') &&
          c.args.contains('decoration') &&
          src.calls.any((i) => c.contains(i) && i.name == 'Icon'),
      orElse: () => col,
    );
    if (identical(tile, col)) continue;
    final hasHeading = children.any((c) =>
        c.name == 'Text' && c.start > tile.end);
    if (hasHeading) emit('icon-tile-stack', tile.line);
  }
}

void _kickerAboveHeading(DartSource src, Emit emit) {
  for (final col in src.calls.where((c) => c.name == 'Column')) {
    final texts = src.calls
        .where((c) => col.contains(c) && c.name == 'Text')
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 0; i + 1 < texts.length; i++) {
      final kicker = texts[i];
      final heading = texts[i + 1];
      if (heading.start < kicker.end) continue; // nested, not siblings
      final kickerSize = _fontSizeOf(src, kicker) ?? 14;
      final headingSize = _fontSizeOf(src, heading);
      if (headingSize == null || headingSize < 24) continue;
      final shouty = kicker.rawArgs.contains('toUpperCase') ||
          RegExp(r'letterSpacing\s*:\s*[1-9]').hasMatch(kicker.args);
      if (kickerSize <= 14 && (shouty || headingSize >= kickerSize * 2)) {
        emit('kicker-above-heading', kicker.line);
      }
    }
  }
}

double? _fontSizeOf(DartSource src, WidgetCall text) {
  final style = src.calls.firstWhere(
    (c) => c.name == 'TextStyle' && text.contains(c),
    orElse: () => text,
  );
  if (identical(style, text)) return null;
  return style.numArg('fontSize');
}

void _typeScaleRules(DartSource src, Emit emit) {
  final sizes = <double>[];
  for (final style in src.calls.where((c) => c.name == 'TextStyle')) {
    final size = style.numArg('fontSize');
    if (size == null) continue;
    sizes.add(size);

    if (size < 11) {
      emit('tiny-text', style.line, detail: 'fontSize: $size');
    }
    if (size > 56) {
      emit('oversized-headline', style.line, detail: 'fontSize: $size');
    }
    final tracking = style.numArg('letterSpacing');
    if (tracking != null && tracking < -0.04 * size) {
      emit('extreme-negative-tracking', style.line,
          detail: 'letterSpacing: $tracking at fontSize: $size');
    }
    final height = style.numArg('height');
    if (height != null && height < 1.15 && size >= 14) {
      emit('tight-leading', style.line, detail: 'height: $height');
    }
  }

  // Flat hierarchy: several sizes, none of them a real step apart.
  final distinct = sizes.toSet().toList()..sort();
  if (distinct.length >= 3) {
    final span = distinct.last - distinct.first;
    if (span < 8) {
      emit('flat-type-hierarchy', src.calls
              .firstWhere((c) => c.name == 'TextStyle')
              .line,
          detail: 'sizes ${distinct.join(", ")} span only ${span}px');
    }
  }

  for (final m in RegExp(r'TextAlign\.justify').allMatches(src.masked)) {
    emit('justified-text', src.lineAt(m.start));
  }
  for (final m in RegExp(r'\.toUpperCase\(\)').allMatches(src.masked)) {
    emit('all-caps-body', src.lineAt(m.start));
  }
}

void _monotonousSpacing(DartSource src, Emit emit) {
  final values = <double, int>{};
  int? firstLine;
  void note(double v, int line) {
    if (v <= 0) return;
    values[v] = (values[v] ?? 0) + 1;
    firstLine ??= line;
  }

  for (final c in src.calls) {
    if (c.name == 'SizedBox') {
      final h = c.numArg('height');
      final w = c.numArg('width');
      if (h != null) note(h, c.line);
      if (w != null && h == null) note(w, c.line);
    }
    if (c.name == 'EdgeInsets') {
      for (final m in RegExp(r'([\d.]+)').allMatches(c.args)) {
        note(double.parse(m[1]!), c.line);
      }
    }
  }
  final total = values.values.fold(0, (a, b) => a + b);
  if (total < 6) return;
  final top = values.entries.reduce((a, b) => a.value >= b.value ? a : b);
  if (top.value / total >= 0.7) {
    emit('monotonous-spacing', firstLine!,
        detail: '${top.value} of $total gaps are ${top.key}');
  }
}

void _copyRules(DartSource src, Emit emit) {
  var emDashes = 0;
  int? emDashLine;
  for (final lit in src.strings) {
    final value = lit.value;
    if (value.trim().length < 4) continue;
    final lower = value.toLowerCase();
    for (final word in _buzzwords) {
      if (lower.contains(word)) {
        emit('marketing-buzzword', src.lineAt(lit.offset), detail: word);
        break;
      }
    }
    final dashes = '—'.allMatches(value).length;
    if (dashes > 0) {
      emDashes += dashes;
      emDashLine ??= src.lineAt(lit.offset);
    }
  }
  if (emDashes >= 3) {
    emit('em-dash-overuse', emDashLine!, detail: '$emDashes em dashes in UI copy');
  }
}

void _crampedPadding(DartSource src, Emit emit) {
  for (final c in src.calls.where((c) => c.name == 'EdgeInsets')) {
    final nums = RegExp(r'([\d.]+)')
        .allMatches(c.args)
        .map((m) => double.parse(m[1]!))
        .where((v) => v > 0)
        .toList();
    if (nums.isEmpty || nums.any((v) => v >= 8)) continue;
    final decorated = src.calls.any((p) =>
        p.contains(c) &&
        (p.name == 'Container' || p.name == 'Card' || p.name == 'DecoratedBox') &&
        (p.args.contains('decoration') || p.name == 'Card'));
    if (decorated) {
      emit('cramped-padding', c.line, detail: 'EdgeInsets ${nums.join(", ")}');
    }
  }
}

void _layoutTransition(DartSource src, Emit emit) {
  for (final c in src.calls.where((c) =>
      c.name == 'AnimatedContainer' || c.name == 'AnimatedPositioned')) {
    if (c.arg('width') != null || c.arg('height') != null) {
      emit('layout-transition', c.line,
          detail: '${c.name} animating ${c.arg('width') != null ? 'width' : 'height'}');
    }
  }
}

void _lowContrast(DartSource src, Emit emit) {
  // A literal text color inside a container with a literal background is the
  // one contrast pair a static pass can actually resolve.
  for (final box in src.calls.where((c) => c.name == 'BoxDecoration' || c.name == 'Container')) {
    final bg = parseColor(box.arg('color') ?? '');
    if (bg == null || bg.a < 0.9) continue;
    for (final style in src.calls.where((c) => c.name == 'TextStyle' && box.contains(c))) {
      final fg = parseColor(style.arg('color') ?? '');
      if (fg == null) continue;
      final size = style.numArg('fontSize') ?? 14;
      final bold = style.args.contains('FontWeight.bold') ||
          RegExp(r'FontWeight\.w[789]').hasMatch(style.args);
      final large = size >= 24 || (size >= 18.66 && bold);
      final ratio = contrastRatio(fg, bg);
      final floor = large ? 3.0 : 4.5;
      if (ratio < floor) {
        emit('low-contrast', style.line,
            detail:
                '${fg.hex} on ${bg.hex} is ${ratio.toStringAsFixed(2)}:1, needs $floor:1');
      }
    }
  }
}

// --------------------------------------------------------------------------
// Flutter platform rules
// --------------------------------------------------------------------------

void _hardcodedColor(DartSource src, Emit emit) {
  if (_isThemeFile(src)) return;
  const colorArgs = [
    'color', 'backgroundColor', 'foregroundColor', 'fillColor',
    'surfaceTintColor', 'shadowColor', 'barrierColor', 'cursorColor',
  ];
  final seen = <int>{};
  for (final c in src.calls) {
    for (final name in colorArgs) {
      final expr = c.arg(name);
      if (expr == null) continue;
      final rgb = parseColor(expr);
      if (rgb == null) continue;
      if (expr.contains('Colors.transparent')) continue;
      if (seen.add(c.line)) {
        emit('hardcoded-color', c.line, detail: '$name: ${expr.trim()}');
      }
    }
  }
}

void _hardcodedTextStyle(DartSource src, Emit emit) {
  if (_isThemeFile(src)) return;
  for (final c in src.calls.where((c) => c.name == 'TextStyle')) {
    if (c.numArg('fontSize') == null) continue;
    // A style copied off the theme and then nudged is fine.
    final derived = src.text
        .substring(0, c.start)
        .trimRight()
        .endsWith('.copyWith');
    if (derived) continue;
    emit('hardcoded-text-style', c.line, detail: 'fontSize: ${c.numArg('fontSize')}');
  }
}

void _missingSafeArea(DartSource src, Emit emit) {
  final scaffolds = src.calls.where((c) => c.name == 'Scaffold').toList();
  if (scaffolds.isEmpty) return;
  if (src.calls.any((c) => c.name == 'SafeArea')) return;
  for (final s in scaffolds) {
    // An AppBar covers the top inset; the bottom one still needs handling.
    emit('missing-safe-area', s.line);
  }
}

void _tapTargetUndersized(DartSource src, Emit emit) {
  for (final box in src.calls.where((c) => c.name == 'SizedBox' || c.name == 'Container')) {
    final w = box.numArg('width');
    final h = box.numArg('height');
    if (w == null && h == null) continue;
    final small = (w != null && w < 48) || (h != null && h < 48);
    if (!small) continue;
    final tappable = src.calls.any((c) => box.contains(c) && _tapWidgets.contains(c.name));
    if (tappable) {
      emit('tap-target-undersized', box.line,
          detail: '${w ?? '-'}x${h ?? '-'} around a tap handler');
    }
  }
  for (final b in src.calls.where((c) => c.name == 'IconButton')) {
    final constraints = b.arg('constraints');
    final size = b.numArg('iconSize');
    if (constraints != null && RegExp(r'(maxWidth|maxHeight)\s*:\s*([\d.]+)')
        .allMatches(constraints)
        .any((m) => double.parse(m[2]!) < 48)) {
      emit('tap-target-undersized', b.line, detail: 'IconButton constraints under 48');
    } else if (size != null && size < 24 && b.arg('padding') == 'EdgeInsets.zero') {
      emit('tap-target-undersized', b.line, detail: 'iconSize: $size with zero padding');
    }
  }
}

void _mediaQuerySizeBranch(DartSource src, Emit emit) {
  final re = RegExp(r'MediaQuery\.(?:of\(\s*context\s*\)\.size|sizeOf\(\s*context\s*\))\.(width|height)');
  for (final m in re.allMatches(src.masked)) {
    // Only flag when the value drives a decision or a dimension, not when it
    // is merely read (a full-bleed background is a legitimate use).
    final tail = src.masked.substring(m.end, (m.end + 40).clamp(0, src.masked.length));
    final head = src.masked.substring((m.start - 30).clamp(0, src.masked.length), m.start);
    final branches = RegExp(r'^\s*[<>]').hasMatch(tail) ||
        RegExp(r'[<>]\s*$').hasMatch(head) ||
        RegExp(r'\b(if|\?)\s*\($').hasMatch(head.trimRight());
    if (branches) {
      emit('mediaquery-size-branch', src.lineAt(m.start), detail: 'branches on .${m[1]}');
    }
  }
}

void _missingSemantics(DartSource src, Emit emit) {
  for (final b in src.calls.where((c) => c.name == 'IconButton')) {
    if (b.arg('tooltip') == null) {
      emit('missing-semantics', b.line, detail: 'IconButton without tooltip');
    }
  }
  for (final g in src.calls.where((c) => c.name == 'GestureDetector' || c.name == 'InkWell')) {
    if (g.arg('onTap') == null) continue;
    final labelled = src.calls.any((c) => c.name == 'Semantics' && c.contains(g)) ||
        src.calls.any((c) => g.contains(c) && (c.name == 'Text' || c.name == 'Semantics'));
    if (!labelled) {
      emit('missing-semantics', g.line, detail: '${g.name} with no label in its subtree');
    }
  }
}

void _deprecatedApis(DartSource src, Emit emit) {
  for (final m in RegExp(r'\.withOpacity\(').allMatches(src.masked)) {
    emit('deprecated-with-opacity', src.lineAt(m.start));
  }
  for (final m in RegExp(r'\bWillPopScope\b').allMatches(src.masked)) {
    emit('deprecated-will-pop-scope', src.lineAt(m.start));
  }
}

void _unboundedList(DartSource src, Emit emit) {
  const scrollers = {'ListView', 'GridView', 'CustomScrollView', 'SingleChildScrollView'};
  for (final col in src.calls.where((c) => c.name == 'Column' || c.name == 'Row')) {
    for (final list in src.calls.where((c) => col.contains(c) && scrollers.contains(c.name))) {
      final bounded = src.calls.any((c) =>
          (c.name == 'Expanded' || c.name == 'Flexible' || c.name == 'SizedBox') &&
          col.contains(c) &&
          c.contains(list));
      final shrink = RegExp(r'shrinkWrap\s*:\s*true').hasMatch(list.args);
      if (!bounded && !shrink) {
        emit('unbounded-list', list.line,
            detail: '${list.name} directly inside a ${col.name}');
      }
    }
  }
}

void _fixedHeightTextBox(DartSource src, Emit emit) {
  for (final box in src.calls.where((c) => c.name == 'SizedBox')) {
    final h = box.numArg('height');
    if (h == null || h > 200) continue;
    final holdsText = src.calls.any((c) => box.contains(c) && c.name == 'Text');
    if (holdsText) {
      emit('fixed-height-text-box', box.line, detail: 'height: $h around Text');
    }
  }
}

void _platformControlMix(DartSource src, Emit emit) {
  final cupertino = RegExp(r'\bCupertino[A-Z]\w*\s*\(').firstMatch(src.masked);
  if (cupertino == null) return;
  final material = RegExp(
          r'\b(Scaffold|AppBar|ElevatedButton|FilledButton|MaterialApp|Drawer|SnackBar)\s*\(')
      .firstMatch(src.masked);
  if (material == null) return;
  emit('platform-control-mix', src.lineAt(cupertino.start),
      detail: '${cupertino[0]!.trim()} beside ${material[1]}');
}

void _networkImageUnguarded(DartSource src, Emit emit) {
  for (final img in src.calls
      .where((c) => c.name == 'Image' && c.constructor == 'network')) {
    if (img.arg('errorBuilder') == null) {
      emit('network-image-unguarded', img.line, detail: 'no errorBuilder');
    }
  }
  for (final m in RegExp(r'NetworkImage\(').allMatches(src.masked)) {
    emit('network-image-unguarded', src.lineAt(m.start),
        detail: 'NetworkImage has no error path at all');
  }
}
