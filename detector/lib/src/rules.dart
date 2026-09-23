import 'colors.dart';
import 'context.dart';
import 'target.dart';
import 'source.dart';

typedef RuleCheck = void Function(DartSource src, Profile profile, ProjectContext ctx, Emit emit);
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
  _unreachableByDpad,
  _missingFocusHighlight,
  _noAutofocusOnRoute,
  _hoverOnlyAffordance,
  _overscanUnsafe,
  _copyCadenceRules,
  _typeSecondWave,
  _heroEyebrowChip,
  _grayOnColor,
  _surfaceDecorationRules,
  _motionSecondWave,
  _radialSpotlightGlow,
  _imageHoverTransform,
  _repeatedContainerText,
  _designSystemRules,
  _webRules,
  _pubspecRules,
  _mouseDragScroll,
  _imageNoCacheSize,
];

// --------------------------------------------------------------------------
// Ported slop
// --------------------------------------------------------------------------

void _overusedFont(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _gradientText(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final mask in src.calls.where((c) => c.name == 'ShaderMask')) {
    final inner = src.calls.where(mask.contains);
    if (inner.any((c) => c.name == 'Text') &&
        mask.args.contains('Gradient')) {
      emit('gradient-text', mask.line);
    }
  }
}

void _aiColorPalette(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _nestedCards(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  final cards = src.calls.where((c) => c.name == 'Card').toList();
  for (final outer in cards) {
    for (final inner in cards) {
      if (outer.contains(inner)) {
        emit('nested-cards', inner.line);
      }
    }
  }
}

void _bounceEasing(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  final re = RegExp(r'\bCurves\.(bounce\w+|elastic\w+|easeOutBack|easeInBack|easeInOutBack)\b');
  for (final m in re.allMatches(src.masked)) {
    emit('bounce-easing', src.lineAt(m.start), detail: 'Curves.${m[1]}');
  }
}

void _sideTab(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _darkGlow(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _radialHalo(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final g in src.calls.where((c) => c.name == 'RadialGradient')) {
    final inDecoration = src.calls.any((c) =>
        c.name == 'BoxDecoration' && c.contains(g));
    if (inDecoration) emit('radial-halo', g.line);
  }
}

void _iconTileStack(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _kickerAboveHeading(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _typeScaleRules(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  final sizes = <double>[];
  for (final style in src.calls.where((c) => c.name == 'TextStyle')) {
    final size = style.numArg('fontSize');
    if (size == null) continue;
    sizes.add(size);

    if (size < profile.minBodyTextSize) {
      emit('tiny-text', style.line, detail: 'fontSize: $size');
    }
    if (size > profile.maxHeadlineSize) {
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

void _monotonousSpacing(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _copyRules(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _crampedPadding(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _layoutTransition(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final c in src.calls.where((c) =>
      c.name == 'AnimatedContainer' || c.name == 'AnimatedPositioned')) {
    if (c.arg('width') != null || c.arg('height') != null) {
      emit('layout-transition', c.line,
          detail: '${c.name} animating ${c.arg('width') != null ? 'width' : 'height'}');
    }
  }
}

void _lowContrast(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _hardcodedColor(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _hardcodedTextStyle(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _missingSafeArea(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  final scaffolds = src.calls.where((c) => c.name == 'Scaffold').toList();
  if (scaffolds.isEmpty) return;
  if (profile.target == Target.tv) return; // overscan-unsafe covers TV
  if (src.calls.any((c) => c.name == 'SafeArea')) return;
  for (final s in scaffolds) {
    // An AppBar covers the top inset; the bottom one still needs handling.
    emit('missing-safe-area', s.line);
  }
}

void _tapTargetUndersized(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (!profile.isTouch) return;
  for (final box in src.calls.where((c) => c.name == 'SizedBox' || c.name == 'Container')) {
    final w = box.numArg('width');
    final h = box.numArg('height');
    if (w == null && h == null) continue;
    final min = profile.minTapTarget;
    final small = (w != null && w < min) || (h != null && h < min);
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

void _mediaQuerySizeBranch(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _missingSemantics(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _deprecatedApis(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final m in RegExp(r'\.withOpacity\(').allMatches(src.masked)) {
    emit('deprecated-with-opacity', src.lineAt(m.start));
  }
  for (final m in RegExp(r'\bWillPopScope\b').allMatches(src.masked)) {
    emit('deprecated-will-pop-scope', src.lineAt(m.start));
  }
}

void _unboundedList(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

void _fixedHeightTextBox(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final box in src.calls.where((c) => c.name == 'SizedBox')) {
    final h = box.numArg('height');
    if (h == null || h > 200) continue;
    final holdsText = src.calls.any((c) => box.contains(c) && c.name == 'Text');
    if (holdsText) {
      emit('fixed-height-text-box', box.line, detail: 'height: $h around Text');
    }
  }
}

void _platformControlMix(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (profile.target == Target.tv) return;
  final cupertino = RegExp(r'\bCupertino[A-Z]\w*\s*\(').firstMatch(src.masked);
  if (cupertino == null) return;
  final material = RegExp(
          r'\b(Scaffold|AppBar|ElevatedButton|FilledButton|MaterialApp|Drawer|SnackBar)\s*\(')
      .firstMatch(src.masked);
  if (material == null) return;
  emit('platform-control-mix', src.lineAt(cupertino.start),
      detail: '${cupertino[0]!.trim()} beside ${material[1]}');
}

void _networkImageUnguarded(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
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

// --------------------------------------------------------------------------
// Focus-driven targets (TV, and the web's keyboard path)
//
// These have no counterpart in upstream impeccable: a web page has no D-pad,
// and a phone has no focus ring. On a TV the focus ring is the cursor, so a
// control that cannot take focus or does not visibly change when it has focus
// is not styled badly — it is unusable.
// --------------------------------------------------------------------------

/// Widgets that bring their own focus handling and focus visuals.
const _focusableWidgets = {
  'ElevatedButton', 'FilledButton', 'OutlinedButton', 'TextButton',
  'IconButton', 'FloatingActionButton', 'InkWell', 'InkResponse',
  'FocusableActionDetector', 'Focus', 'TextField', 'TextFormField',
  'ListTile', 'Radio', 'Checkbox', 'Switch', 'MenuItemButton',
};

void _unreachableByDpad(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (!profile.isFocusDriven) return;
  for (final g in src.calls.where((c) => c.name == 'GestureDetector')) {
    if (g.arg('onTap') == null) continue;
    final wrapped = src.calls.any((c) =>
        c.contains(g) && _focusableWidgets.contains(c.name));
    if (!wrapped) {
      emit('unreachable-by-dpad', g.line,
          detail: 'GestureDetector.onTap with nothing focusable around it');
    }
  }
}

void _missingFocusHighlight(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (!profile.isFocusDriven) return;
  for (final f in src.calls
      .where((c) => c.name == 'Focus' || c.name == 'FocusableActionDetector')) {
    // Something in the subtree has to react to focus, or the ring is invisible.
    final reacts = RegExp(
            r'\b(hasFocus|onShowFocusHighlight|onFocusChange|focusColor|focusNode\s*:\s*\w+\s*,?\s*\)?\s*builder)')
        .hasMatch(f.rawArgs);
    if (!reacts) {
      emit('missing-focus-highlight', f.line,
          detail: '${f.name} whose subtree never reads focus state');
    }
  }
}

void _noAutofocusOnRoute(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (!profile.isFocusDriven) return;
  final scaffolds = src.calls.where((c) => c.name == 'Scaffold').toList();
  if (scaffolds.isEmpty) return;
  final focusable = src.calls.any((c) => _focusableWidgets.contains(c.name));
  if (!focusable) return;
  if (RegExp(r'autofocus\s*:\s*true').hasMatch(src.masked)) return;
  if (src.calls.any((c) => c.name == 'FocusScope' || c.name == 'FocusTraversalGroup')) {
    return;
  }
  emit('no-autofocus-on-route', scaffolds.first.line,
      detail: 'screen has focusable controls but nothing takes focus on entry');
}

void _hoverOnlyAffordance(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (profile.isTouch) return;
  for (final c in src.calls) {
    final hover = c.arg('onHover') ?? (c.name == 'MouseRegion' ? c.arg('onEnter') : null);
    if (hover == null) continue;
    final hasFocusPath = c.arg('onFocusChange') != null ||
        c.arg('focusColor') != null ||
        src.calls.any((p) => p.contains(c) && p.name == 'FocusableActionDetector');
    if (!hasFocusPath) {
      emit('hover-only-affordance', c.line,
          detail: '${c.name} reacts to hover with no focus equivalent');
    }
  }
}

void _overscanUnsafe(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (profile.target != Target.tv) return;
  final scaffolds = src.calls.where((c) => c.name == 'Scaffold').toList();
  if (scaffolds.isEmpty) return;
  final inset = profile.overscanInset;
  final padded = src.calls
      .where((c) => c.name == 'EdgeInsets' || c.name == 'EdgeInsetsDirectional')
      .any((c) {
    final nums = RegExp(r'([\d.]+)')
        .allMatches(c.args)
        .map((m) => double.parse(m[1]!))
        .toList();
    return nums.isNotEmpty && nums.every((v) => v >= inset);
  });
  if (!padded) {
    emit('overscan-unsafe', scaffolds.first.line,
        detail: 'no margin of ${inset.toInt()} or more; TV panels crop the edges');
  }
}

// --------------------------------------------------------------------------
// Second port wave
// --------------------------------------------------------------------------

const _theaterPhrases = [
  'security theater', 'is just theater', 'cut through the noise', 'just works',
  'it just works', 'like magic', 'is magic', 'no magic',
];

/// "Not X. Y." / "No X. Just Y." — the rebuttal cadence generated copy falls
/// into. One is a sentence; several across a screen is a tic.
final _aphorismRe = RegExp(
    r'^\s*(?:not|no)\b[^.!?]{2,60}[.!?]\s+(?:just|only|simply|it\s)',
    caseSensitive: false);

void _copyCadenceRules(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  var aphorisms = 0;
  int? aphorismLine;
  final numbered = <int>[];

  for (final lit in src.strings) {
    final value = lit.value.trim();
    final line = src.lineAt(lit.offset);

    // A bare "01" / "02" used as a label. Checked before the length guard
    // below, because the whole point of this one is that the string is tiny.
    if (RegExp(r'^0\d$').hasMatch(value)) {
      numbered.add(line);
      continue;
    }
    if (value.length < 8) continue;

    if (_aphorismRe.hasMatch(value)) {
      aphorisms++;
      aphorismLine ??= line;
    }
    final lower = value.toLowerCase();
    for (final phrase in _theaterPhrases) {
      if (lower.contains(phrase)) {
        emit('theater-slop-phrase', line, detail: phrase);
        break;
      }
    }
  }

  // One numbered label is a label; a run of them is a screen numbering its
  // own chapters, which is what upstream flags.
  if (numbered.length >= 2) {
    emit('numbered-section-labels', numbered.first,
        detail: '${numbered.length} numeric section labels');
  }
  if (aphorisms >= 3) {
    emit('aphoristic-cadence', aphorismLine!,
        detail: '$aphorisms strings share the rebuttal cadence');
  }
}

void _typeSecondWave(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final style in src.calls.where((c) => c.name == 'TextStyle')) {
    final size = style.numArg('fontSize');
    final tracking = style.numArg('letterSpacing');
    final family = style.arg('fontFamily') ?? '';
    final italic = style.args.contains('FontStyle.italic');

    if (size != null &&
        size >= profile.minBodyTextSize &&
        size < profile.minUiTextSize) {
      // Only functional text: something the user reads to operate the screen.
      final functional = src.calls.any((c) =>
          c.contains(style) &&
          const {
            'TextButton', 'ElevatedButton', 'FilledButton', 'OutlinedButton',
            'ListTile', 'Chip', 'Tab', 'AppBar', 'NavigationDestination',
          }.contains(c.name));
      if (functional) {
        emit('undersized-ui-text', style.line, detail: 'fontSize: $size');
      }
    }

    // Wide tracking is for short caps labels; on running text it slows reading.
    if (tracking != null && size != null && tracking > 0.05 * size && size >= 14) {
      final shouty = style.args.contains('FontWeight.w') &&
          RegExp(r'toUpperCase').hasMatch(src.text);
      if (!shouty) {
        emit('wide-tracking', style.line,
            detail: 'letterSpacing: $tracking at fontSize: $size');
      }
    }

    if (italic && size != null && size >= 32) {
      final serif = RegExp(
              r'(fraunces|recoleta|playfair|newsreader|lora|merriweather|georgia|garamond|serif)',
              caseSensitive: false)
          .hasMatch(family.isEmpty ? src.text : family);
      if (serif) {
        emit('italic-serif-display', style.line,
            detail: 'italic serif at fontSize: $size');
      }
    }
  }
}

void _heroEyebrowChip(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  // The eyebrow rendered as a pill: a rounded, padded container holding a
  // small letterspaced label, sitting above a display-size heading.
  for (final chip in src.calls.where((c) =>
      c.name == 'Container' || c.name == 'Chip' || c.name == 'DecoratedBox')) {
    final rounded = chip.args.contains('BorderRadius') || chip.name == 'Chip';
    if (!rounded) continue;
    final label = src.calls.firstWhere(
        (c) => chip.contains(c) && c.name == 'TextStyle',
        orElse: () => chip);
    if (identical(label, chip)) continue;
    final size = label.numArg('fontSize');
    final tracked = (label.numArg('letterSpacing') ?? 0) > 0;
    if (size == null || size > 14 || !tracked) continue;
    final heading = src.calls.any((c) =>
        c.name == 'TextStyle' &&
        c.start > chip.end &&
        (c.numArg('fontSize') ?? 0) >= 32);
    if (heading) emit('hero-eyebrow-chip', chip.line);
  }
}

void _grayOnColor(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final box in src.calls
      .where((c) => c.name == 'BoxDecoration' || c.name == 'Container')) {
    final bg = parseColor(box.arg('color') ?? '');
    if (bg == null || bg.isNeutral || bg.a < 0.9) continue;
    for (final style
        in src.calls.where((c) => c.name == 'TextStyle' && box.contains(c))) {
      final fg = parseColor(style.arg('color') ?? '');
      if (fg == null || !fg.isNeutral) continue;
      // Near-white and near-black are the honest answers, not the failure.
      final l = fg.luminance;
      if (l > 0.75 || l < 0.05) continue;
      emit('gray-on-color', style.line,
          detail: '${fg.hex} on ${bg.hex}');
    }
  }
}

void _surfaceDecorationRules(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final d in src.calls.where((c) => c.name == 'BoxDecoration')) {
    final bg = parseColor(d.arg('color') ?? '');
    if (bg != null && _isCream(bg)) {
      emit('cream-palette', d.line, detail: bg.hex);
    }

    // A hairline edge and a wide soft shadow are two answers to one question.
    final border = d.arg('border') ?? '';
    final hairline = RegExp(r'width\s*:\s*(0?\.\d+|1(?:\.0)?)\b').hasMatch(border);
    if (hairline) {
      final wide = src.calls.any((s) =>
          s.name == 'BoxShadow' && d.contains(s) && (s.numArg('blurRadius') ?? 0) >= 16);
      if (wide) {
        emit('thin-border-wide-shadow', d.line,
            detail: 'hairline border with a blur of 16 or more');
      }
    }

    // Stripes: a gradient whose stops repeat the same pair, or TileMode.repeated.
    final gradient = d.arg('gradient') ?? '';
    if (gradient.contains('TileMode.repeated') ||
        RegExp(r'stops\s*:\s*\[[^\]]{20,}\]').hasMatch(gradient)) {
      emit('repeating-stripes-gradient', d.line);
    }
  }

  // A grid painted behind content, rather than a canvas or map surface.
  for (final p in src.calls.where((c) => c.name == 'CustomPaint')) {
    final painter = p.arg('painter') ?? '';
    if (RegExp(r'grid|graphpaper|dotgrid', caseSensitive: false).hasMatch(painter)) {
      emit('grid-line-background', p.line, detail: painter.trim());
    }
  }
  for (final m in RegExp(r'\b\w*Grid(?:Painter|Background|Pattern)\b')
      .allMatches(src.masked)) {
    emit('grid-line-background', src.lineAt(m.start), detail: m[0]);
  }
}

/// Warm off-white: high lightness, low chroma, hue in the yellow-orange band.
bool _isCream(Rgb c) {
  final h = c.hue;
  if (h == null) return false;
  final light = c.luminance > 0.7;
  return light && h >= 20 && h <= 70 && c.chroma > 0.03 && c.chroma < 0.25;
}

void _motionSecondWave(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  // A repeating controller is what turns a dot into a pulse and a caret into
  // a blink; without one these are static and fine.
  final repeats = RegExp(r'\.repeat\s*\(').hasMatch(src.masked);

  if (repeats) {
    for (final c in src.calls.where((c) => c.name == 'Container' || c.name == 'DecoratedBox')) {
      final w = c.numArg('width');
      final h = c.numArg('height');
      final small = (w ?? 99) <= 16 && (h ?? 99) <= 16;
      final round = c.args.contains('BoxShape.circle') ||
          (c.args.contains('BorderRadius') && small);
      if (small && round) {
        emit('pulsing-dot', c.line, detail: 'small round container on a repeating animation');
      }
    }
    // A decorative caret is either named like one, or is a Text holding
    // nothing but a bar or underscore driven by the repeating controller.
    // A real text field draws its own caret, so the rule stands down there.
    final realField =
        RegExp(r'TextField|TextFormField|EditableText').hasMatch(src.masked);
    if (!realField) {
      for (final m in RegExp(r'\b(cursor|caret)\w*\b', caseSensitive: false)
          .allMatches(src.masked)) {
        emit('blinking-cursor', src.lineAt(m.start), detail: m[0]);
      }
      for (final lit in src.strings) {
        if (RegExp(r'^[|_▌▊]$').hasMatch(lit.value.trim())) {
          emit('blinking-cursor', src.lineAt(lit.offset),
              detail: 'animated "${lit.value.trim()}" standing in for a caret');
        }
      }
    }
  }

  // Marquee: an endlessly repeating horizontal scroll or slide.
  if (repeats) {
    final scrolls = RegExp(
            r'(animateTo|jumpTo|SlideTransition|Transform\.translate|ScrollController)')
        .hasMatch(src.masked);
    if (scrolls) {
      final m = RegExp(r'\.repeat\s*\(').firstMatch(src.masked)!;
      emit('marquee', src.lineAt(m.start),
          detail: 'content scrolls on a repeating animation');
    }
  }
  for (final m in RegExp(r'\bMarquee\s*\(').allMatches(src.masked)) {
    emit('marquee', src.lineAt(m.start));
  }
}

void _radialSpotlightGlow(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final g in src.calls.where((c) => c.name == 'RadialGradient')) {
    // The spotlight variant fades a chromatic accent out to transparent; the
    // plain halo is already covered by radial-halo.
    final colors = g.arg('colors') ?? '';
    if (!colors.contains('transparent') && !colors.contains('withValues')) {
      continue;
    }
    final chromatic = findColors(colors).any((c) => !c.rgb.isNeutral);
    if (chromatic) emit('radial-spotlight-glow', g.line);
  }
}

void _imageHoverTransform(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (profile.target != Target.web) return;
  for (final r in src.calls.where((c) => c.name == 'MouseRegion')) {
    if (r.arg('onEnter') == null) continue;
    final transformsImage = src.calls.any((c) =>
        r.contains(c) &&
        const {'AnimatedScale', 'AnimatedRotation', 'Transform', 'ScaleTransition'}
            .contains(c.name)) &&
        src.calls.any((c) => r.contains(c) && c.name == 'Image');
    if (transformsImage) {
      emit('image-hover-transform', r.line);
    }
  }
}

void _repeatedContainerText(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final parent
      in src.calls.where((c) => c.name == 'Column' || c.name == 'Row')) {
    final seen = <String, int>{};
    for (final text in src.calls.where((c) => parent.contains(c) && c.name == 'Text')) {
      // The literal this Text renders, when it renders a literal at all.
      final lit = src.strings.firstWhere(
        (s) => s.offset > text.start && s.offset < text.end,
        orElse: () => const StringLiteral(-1, ''),
      );
      final value = lit.value.trim();
      if (lit.offset == -1 || value.length < 3) continue;
      if (seen.containsKey(value)) {
        emit('repeated-container-text', text.line, detail: '"$value" twice in one ${parent.name}');
      } else {
        seen[value] = text.line;
      }
    }
  }
}

// --------------------------------------------------------------------------
// Design-system conformance
//
// These stay silent unless the project has a DESIGN.md. The point is not that
// a literal is bad — the other rules cover that — but that the value is not
// one the project ever declared. A project with no declared system has nothing
// to be outside of.
// --------------------------------------------------------------------------

void _designSystemRules(
    DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  final design = ctx.design;
  if (design == null || design.isEmpty) return;
  const where = 'DESIGN.md';

  if (design.colors.isNotEmpty) {
    for (final c in src.calls) {
      for (final name in const ['color', 'backgroundColor', 'foregroundColor']) {
        final expr = c.arg(name);
        if (expr == null) continue;
        final rgb = parseColor(expr);
        if (rgb == null || rgb.a == 0) continue;
        if (design.declaresColor(rgb)) continue;
        emit('design-system-color', c.line,
            detail: '${rgb.hex} is not in $where');
      }
    }
  }

  if (design.fonts.isNotEmpty) {
    for (final m
        in RegExp(r"""fontFamily\s*:\s*['"]([^'"]+)['"]""").allMatches(src.text)) {
      if (design.declaresFont(m[1]!)) continue;
      emit('design-system-font', src.lineAt(m.start),
          detail: '${m[1]} is not in $where');
    }
  }

  if (design.fontSizes.isNotEmpty) {
    for (final style in src.calls.where((c) => c.name == 'TextStyle')) {
      final size = style.numArg('fontSize');
      if (size == null || design.declaresFontSize(size)) continue;
      emit('design-system-font-size', style.line,
          detail: 'fontSize $size is not on the ramp in $where');
    }
  }

  if (design.radii.isNotEmpty) {
    for (final r in src.calls.where((c) =>
        (c.name == 'BorderRadius' || c.name == 'Radius') &&
        (c.constructor == 'circular' || c.constructor == 'all'))) {
      final m = RegExp(r'([\d.]+)').firstMatch(r.args);
      if (m == null) continue;
      final value = double.parse(m[1]!);
      if (design.declaresRadius(value)) continue;
      emit('design-system-radius', r.line,
          detail: 'radius $value is not in $where');
    }
  }
}

// --------------------------------------------------------------------------
// Web
//
// Flutter on the web inherits expectations the framework does not meet by
// default. These are the two that users notice within seconds.
// --------------------------------------------------------------------------

void _webRules(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (profile.target != Target.web) return;

  // Selection: a screen with real running copy and no SelectionArea anywhere.
  if (!src.calls.any((c) =>
      c.name == 'SelectionArea' || c.name == 'SelectableText' ||
      c.name == 'SelectableRegion')) {
    final prose = src.calls.where((c) {
      if (c.name != 'Text') return false;
      final lit = src.strings.firstWhere(
        (s) => s.offset > c.start && s.offset < c.end,
        orElse: () => const StringLiteral(-1, ''),
      );
      // Running copy, not a button label: several words.
      return lit.offset != -1 && lit.value.trim().split(RegExp(r'\s+')).length >= 6;
    }).toList();
    if (prose.isNotEmpty) {
      emit('text-not-selectable', prose.first.line,
          detail: '${prose.length} paragraph-length Text widgets, no SelectionArea');
    }
  }

  // URL strategy: only meaningful in the file that boots the app.
  final bootstraps = RegExp(r'\brunApp\s*\(').firstMatch(src.masked);
  if (bootstraps != null &&
      !RegExp(r'usePathUrlStrategy\s*\(|setUrlStrategy\s*\(')
          .hasMatch(src.masked)) {
    emit('hash-url-strategy', src.lineAt(bootstraps.start),
        detail: 'runApp with no usePathUrlStrategy()');
  }
}

// --------------------------------------------------------------------------
// pubspec.yaml conformance
//
// Both of these are invisible everywhere else: the analyzer does not read
// pubspec against Dart source, and Flutter resolves a missing font silently.
// --------------------------------------------------------------------------

void _pubspecRules(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  final pubspec = ctx.pubspec;
  if (pubspec == null) return;

  for (final m
      in RegExp("""fontFamily\\s*:\\s*['"]([^'"]+)['"]""").allMatches(src.text)) {
    final family = m[1]!;
    if (pubspec.declaresFont(family)) continue;
    emit('undeclared-font', src.lineAt(m.start),
        detail: '$family is not under flutter: fonts:');
  }

  // A package with no flutter: section declares no assets by design.
  if (!pubspec.declaresFlutter) return;

  for (final call in src.calls) {
    final isAsset = (call.name == 'Image' && call.constructor == 'asset') ||
        (call.name == 'AssetImage' && call.constructor == null);
    if (!isAsset) continue;
    final lit = src.strings.firstWhere(
      (s) => s.offset > call.start && s.offset < call.end,
      orElse: () => const StringLiteral(-1, ''),
    );
    // Only a literal path can be checked; one built at runtime is not ours.
    if (lit.offset == -1) continue;
    final path = lit.value.trim();
    if (path.isEmpty || path.contains(r'$')) continue;
    if (pubspec.declaresAsset(path)) continue;
    emit('undeclared-asset', call.line,
        detail: '$path is not under flutter: assets:');
  }
}

void _mouseDragScroll(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  if (profile.target != Target.web) return;
  final apps = src.calls
      .where((c) => c.name == 'MaterialApp' || c.name == 'CupertinoApp')
      .toList();
  if (apps.isEmpty) return;
  // Either a ScrollBehavior that names the mouse, or nothing.
  if (RegExp(r'PointerDeviceKind\.mouse').hasMatch(src.masked)) return;
  emit('mouse-drag-scroll', apps.first.line,
      detail:
          '${apps.first.name} with no ScrollBehavior naming PointerDeviceKind.mouse');
}

void _imageNoCacheSize(DartSource src, Profile profile, ProjectContext ctx, Emit emit) {
  for (final img in src.calls.where((c) =>
      c.name == 'Image' &&
      (c.constructor == 'network' || c.constructor == 'asset' ||
          c.constructor == 'file' || c.constructor == 'memory'))) {
    final sized = img.numArg('width') != null || img.numArg('height') != null;
    if (!sized) continue;
    if (img.arg('cacheWidth') != null || img.arg('cacheHeight') != null) continue;
    emit('image-no-cache-size', img.line,
        detail: 'Image.${img.constructor} sized but decoded in full');
  }
}
