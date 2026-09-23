import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

List<String> idsFor(String source, {String path = 'lib/screen.dart'}) =>
    Scanner().scanSource(path, source).map((f) => f.rule.id).toList();

/// Asserts a rule fires on [fires] and stays quiet on [quiet]. The negative
/// half is the point: a detector that flags everything is noise, and upstream's
/// own rules are written with the same exemptions.
void ruleTest(String id, {required String fires, required String quiet}) {
  group(id, () {
    test('fires', () => expect(idsFor(fires), contains(id)));
    test('stays quiet', () => expect(idsFor(quiet), isNot(contains(id))));
  });
}

void main() {
  ruleTest('overused-font',
      fires: "Text('hi', style: TextStyle(fontFamily: 'Inter'));",
      quiet: "Text('hi', style: TextStyle(fontFamily: 'Fraunces'));");

  ruleTest('gradient-text',
      fires: '''
ShaderMask(
  shaderCallback: (r) => LinearGradient(colors: c).createShader(r),
  child: Text('Welcome'),
);''',
      quiet: "ShaderMask(shaderCallback: cb, child: Image.asset('a.png'));");

  ruleTest('ai-color-palette',
      fires: 'const a = Color(0xFF6366F1); const b = Color(0xFF8B5CF6);',
      quiet: 'const a = Color(0xFF1B7F5C); const b = Color(0xFFD4A15A);');

  ruleTest('nested-cards',
      fires: 'Card(child: Column(children: [Card(child: Text("x"))]));',
      quiet: 'Card(child: Column(children: [ListTile(title: Text("x"))]));');

  ruleTest('bounce-easing',
      fires: 'AnimationController(vsync: this).drive(CurveTween(curve: Curves.elasticOut));',
      quiet: 'AnimationController(vsync: this).drive(CurveTween(curve: Curves.easeOutCubic));');

  ruleTest('side-tab',
      fires: '''
Container(decoration: BoxDecoration(
  border: Border(left: BorderSide(width: 4, color: Color(0xFF6366F1))),
));''',
      quiet: '''
Container(decoration: BoxDecoration(
  border: Border(left: BorderSide(width: 1, color: Color(0xFFE5E5E5))),
));''');

  ruleTest('border-accent-on-rounded',
      fires: '''
Container(decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  border: Border(left: BorderSide(width: 4, color: Color(0xFFEF4444))),
));''',
      quiet: '''
Container(decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  border: Border.all(width: 1, color: Color(0xFFE5E5E5)),
));''');

  ruleTest('dark-glow',
      fires: 'BoxShadow(color: Color(0xFF6366F1), blurRadius: 40, offset: Offset(0, 0));',
      quiet: 'BoxShadow(color: Color(0x14000000), blurRadius: 40, offset: Offset(0, 8));');

  ruleTest('radial-halo',
      fires: 'Container(decoration: BoxDecoration(gradient: RadialGradient(colors: c)));',
      quiet: 'Container(decoration: BoxDecoration(color: Color(0xFF101010)));');

  ruleTest('icon-tile-stack',
      fires: '''
Column(children: [
  Container(decoration: BoxDecoration(borderRadius: r), child: Icon(Icons.bolt)),
  Text('Fast sync'),
]);''',
      quiet: "Column(children: [Icon(Icons.bolt), Text('Fast sync')]);");

  ruleTest('kicker-above-heading',
      fires: '''
Column(children: [
  Text('WHY US', style: TextStyle(fontSize: 12, letterSpacing: 2)),
  Text('Ship faster', style: TextStyle(fontSize: 34)),
]);''',
      quiet: '''
Column(children: [
  Text('Ship faster', style: TextStyle(fontSize: 34)),
  Text('Sync in the background.', style: TextStyle(fontSize: 16)),
]);''');

  ruleTest('oversized-headline',
      fires: "Text('Hi', style: TextStyle(fontSize: 72));",
      quiet: "Text('Hi', style: TextStyle(fontSize: 34));");

  ruleTest('extreme-negative-tracking',
      fires: "Text('Hi', style: TextStyle(fontSize: 40, letterSpacing: -2.4));",
      quiet: "Text('Hi', style: TextStyle(fontSize: 40, letterSpacing: -0.5));");

  ruleTest('tiny-text',
      fires: "Text('legal', style: TextStyle(fontSize: 9));",
      quiet: "Text('legal', style: TextStyle(fontSize: 13));");

  ruleTest('tight-leading',
      fires: "Text('body copy', style: TextStyle(fontSize: 16, height: 1.0));",
      quiet: "Text('body copy', style: TextStyle(fontSize: 16, height: 1.45));");

  ruleTest('flat-type-hierarchy',
      fires: '''
const a = TextStyle(fontSize: 14);
const b = TextStyle(fontSize: 16);
const c = TextStyle(fontSize: 18);''',
      quiet: '''
const a = TextStyle(fontSize: 14);
const b = TextStyle(fontSize: 22);
const c = TextStyle(fontSize: 34);''');

  ruleTest('justified-text',
      fires: "Text('body', textAlign: TextAlign.justify);",
      quiet: "Text('body', textAlign: TextAlign.start);");

  ruleTest('all-caps-body',
      fires: "Text(label.toUpperCase());", quiet: "Text(label);");

  ruleTest('marketing-buzzword',
      fires: "Text('Seamless sync across every device');",
      quiet: "Text('Syncs across your devices');");

  ruleTest('em-dash-overuse',
      fires: '''
const a = 'Fast — and quiet';
const b = 'Simple — by design';
const c = 'Yours — always';''',
      quiet: "const a = 'Fast and quiet'; const b = 'Simple by design';");

  ruleTest('cramped-padding',
      fires: '''
Container(
  decoration: BoxDecoration(color: Color(0xFF222222)),
  padding: EdgeInsets.all(3),
  child: Text('x'),
);''',
      quiet: '''
Container(
  decoration: BoxDecoration(color: Color(0xFF222222)),
  padding: EdgeInsets.all(16),
  child: Text('x'),
);''');

  ruleTest('layout-transition',
      fires: 'AnimatedContainer(duration: d, width: w, child: c);',
      quiet: 'AnimatedContainer(duration: d, transform: t, child: c);');

  ruleTest('low-contrast',
      fires: '''
Container(
  color: Color(0xFFFFFFFF),
  child: Text('hi', style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB))),
);''',
      quiet: '''
Container(
  color: Color(0xFFFFFFFF),
  child: Text('hi', style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
);''');

  ruleTest('hardcoded-color',
      fires: 'Container(color: Color(0xFF123456), child: c);',
      quiet: 'Container(color: Theme.of(context).colorScheme.surface, child: c);');

  ruleTest('hardcoded-text-style',
      fires: "Text('hi', style: TextStyle(fontSize: 18));",
      quiet: "Text('hi', style: Theme.of(context).textTheme.titleMedium);");

  ruleTest('missing-safe-area',
      fires: "Scaffold(body: Column(children: [Text('hi')]));",
      quiet: "Scaffold(body: SafeArea(child: Column(children: [Text('hi')])));");

  ruleTest('tap-target-undersized',
      fires: 'SizedBox(width: 32, height: 32, child: InkWell(onTap: f, child: c));',
      quiet: 'SizedBox(width: 48, height: 48, child: InkWell(onTap: f, child: c));');

  ruleTest('mediaquery-size-branch',
      fires: 'if (MediaQuery.of(context).size.width > 600) { return Wide(); }',
      quiet: 'LayoutBuilder(builder: (c, box) => box.maxWidth > 600 ? Wide() : Narrow());');

  ruleTest('missing-semantics',
      fires: 'IconButton(icon: Icon(Icons.close), onPressed: f);',
      quiet: "IconButton(icon: Icon(Icons.close), tooltip: 'Close', onPressed: f);");

  ruleTest('deprecated-with-opacity',
      fires: 'final c = base.withOpacity(0.5);',
      quiet: 'final c = base.withValues(alpha: 0.5);');

  ruleTest('deprecated-will-pop-scope',
      fires: 'WillPopScope(onWillPop: f, child: c);',
      quiet: 'PopScope(canPop: false, onPopInvokedWithResult: f, child: c);');

  ruleTest('unbounded-list',
      fires: 'Column(children: [ListView(children: items)]);',
      quiet: 'Column(children: [Expanded(child: ListView(children: items))]);');

  ruleTest('fixed-height-text-box',
      fires: "SizedBox(height: 24, child: Text('Label'));",
      quiet: "Text('Label');");

  ruleTest('platform-control-mix',
      fires: "Scaffold(body: CupertinoButton(child: Text('ok'), onPressed: f));",
      quiet: "Scaffold(body: FilledButton(child: Text('ok'), onPressed: f));");

  ruleTest('network-image-unguarded',
      fires: 'Image.network(url);',
      quiet: 'Image.network(url, errorBuilder: (c, e, s) => Placeholder());');

  ruleTest('monotonous-spacing',
      fires: '''
Column(children: [
  SizedBox(height: 16), SizedBox(height: 16), SizedBox(height: 16),
  SizedBox(height: 16), SizedBox(height: 16), SizedBox(height: 24),
]);''',
      quiet: '''
Column(children: [
  SizedBox(height: 4), SizedBox(height: 8), SizedBox(height: 12),
  SizedBox(height: 24), SizedBox(height: 40), SizedBox(height: 64),
]);''');

  group('exemptions', () {
    test('theme files may hold literal colors and sizes', () {
      final source = '''
ThemeData buildTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1B7F5C)),
  textTheme: TextTheme(bodyMedium: TextStyle(fontSize: 16)),
);''';
      final ids = idsFor(source, path: 'lib/theme/app_theme.dart');
      expect(ids, isNot(contains('hardcoded-color')));
      expect(ids, isNot(contains('hardcoded-text-style')));
    });

    test('a style derived from the theme is not a hand-picked one', () {
      const source =
          "Text('hi', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 18));";
      expect(idsFor(source), isNot(contains('hardcoded-text-style')));
    });

    test('generated files are skipped by path', () {
      final findings = Scanner().scanPaths(const []);
      expect(findings, isEmpty);
    });
  });

  group('waivers', () {
    test('an inline waiver suppresses the finding', () {
      const source = '''
// impeccable-disable: hardcoded-color
Container(color: Color(0xFF123456), child: c);''';
      expect(idsFor(source), isNot(contains('hardcoded-color')));
    });

    test('a waiver for another rule does not suppress this one', () {
      const source = '''
// impeccable-disable: nested-cards
Container(color: Color(0xFF123456), child: c);''';
      expect(idsFor(source), contains('hardcoded-color'));
    });
  });

  group('findings', () {
    test('carry file, line, snippet and the upstream link', () {
      final f = Scanner()
          .scanSource('lib/a.dart', "\n\nText('x', style: TextStyle(fontSize: 9));")
          .firstWhere((f) => f.rule.id == 'tiny-text');
      expect(f.file, 'lib/a.dart');
      expect(f.line, 3);
      expect(f.snippet, contains('fontSize: 9'));
      expect(f.detail, 'fontSize: 9.0');
      expect(f.toJson()['portOf'], 'tiny-text');
    });

    test('one finding per rule per line', () {
      const source = 'Row(children: [Curves.bounceOut, Curves.elasticIn]);';
      final hits = Scanner()
          .scanSource('lib/a.dart', source)
          .where((f) => f.rule.id == 'bounce-easing');
      expect(hits.length, 1);
    });
  });
}
