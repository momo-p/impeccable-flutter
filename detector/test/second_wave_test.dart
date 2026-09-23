import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

List<String> idsFor(String source,
        {Target target = Target.phone, String path = 'lib/screen.dart'}) =>
    Scanner(target: target).scanSource(path, source).map((f) => f.rule.id).toList();

void ruleTest(String id,
    {required String fires, required String quiet, Target target = Target.phone}) {
  group(id, () {
    test('fires',
        () => expect(idsFor(fires, target: target), contains(id)));
    test('stays quiet',
        () => expect(idsFor(quiet, target: target), isNot(contains(id))));
  });
}

void main() {
  ruleTest('radial-spotlight-glow',
      fires: '''
Container(decoration: BoxDecoration(
  gradient: RadialGradient(colors: [Color(0xFF8B5CF6), Colors.transparent]),
));''',
      quiet: '''
Container(decoration: BoxDecoration(
  gradient: RadialGradient(colors: [Color(0xFF303030), Color(0xFF101010)]),
));''');

  ruleTest('hero-eyebrow-chip',
      fires: '''
Column(children: [
  Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
    child: Text('NEW', style: TextStyle(fontSize: 12, letterSpacing: 2)),
  ),
  Text('Ship faster', style: TextStyle(fontSize: 40)),
]);''',
      quiet: '''
Column(children: [
  Text('Ship faster', style: TextStyle(fontSize: 40)),
  Text('Sync in the background.', style: TextStyle(fontSize: 16)),
]);''');

  ruleTest('undersized-ui-text',
      fires: "TextButton(onPressed: f, child: Text('Save', style: TextStyle(fontSize: 11)));",
      quiet: "TextButton(onPressed: f, child: Text('Save', style: TextStyle(fontSize: 16)));");

  ruleTest('gray-on-color',
      fires: '''
Container(
  color: Color(0xFF2E5AAC),
  child: Text('hi', style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A))),
);''',
      quiet: '''
Container(
  color: Color(0xFF2E5AAC),
  child: Text('hi', style: TextStyle(fontSize: 16, color: Color(0xFFF2F5FF))),
);''');

  ruleTest('aphoristic-cadence',
      fires: '''
const a = 'Not a database. Just your files.';
const b = 'No accounts. Just a link.';
const c = 'Not magic. It is plain sync.';''',
      quiet: '''
const a = 'Your files stay on disk.';
const b = 'Share with a link.';
const c = 'Sync runs in the background.';''');

  ruleTest('theater-slop-phrase',
      fires: "const a = 'Most security theater ends here.';",
      quiet: "const a = 'Keys never leave your device.';");

  ruleTest('numbered-section-labels',
      fires: "Column(children: [Text('01'), Text('Import'), Text('02'), Text('Review')]);",
      quiet: "Column(children: [Text('Import'), Text('Review')]);");

  ruleTest('pulsing-dot',
      fires: '''
final c = AnimationController(vsync: this)..repeat(reverse: true);
final dot = Container(
  width: 8, height: 8,
  decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E)),
);''',
      quiet: '''
final dot = Container(
  width: 8, height: 8,
  decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E)),
);''');

  ruleTest('marquee',
      fires: '''
final c = AnimationController(vsync: this)..repeat();
final row = SlideTransition(position: c.drive(t), child: logos);''',
      quiet: 'final row = SingleChildScrollView(scrollDirection: Axis.horizontal, child: logos);');

  ruleTest('cream-palette',
      fires: 'Container(decoration: BoxDecoration(color: Color(0xFFF5F0E6)), child: c);',
      quiet: 'Container(decoration: BoxDecoration(color: Color(0xFFF5F5F6)), child: c);');

  ruleTest('thin-border-wide-shadow',
      fires: '''
BoxDecoration(
  border: Border.all(width: 1, color: Color(0xFFE5E5E5)),
  boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
);''',
      quiet: '''
BoxDecoration(
  border: Border.all(width: 1, color: Color(0xFFE5E5E5)),
);''');

  ruleTest('repeating-stripes-gradient',
      fires: '''
BoxDecoration(gradient: LinearGradient(
  tileMode: TileMode.repeated,
  colors: [Color(0xFF101010), Color(0xFF181818)],
));''',
      quiet: '''
BoxDecoration(gradient: LinearGradient(
  colors: [Color(0xFF101010), Color(0xFF181818)],
));''');

  ruleTest('grid-line-background',
      fires: 'CustomPaint(painter: GridPainter(), child: content);',
      quiet: 'CustomPaint(painter: SparklinePainter(), child: content);');

  ruleTest('italic-serif-display',
      fires: '''
Text('Beautifully made',
  style: TextStyle(fontFamily: 'Playfair', fontSize: 48, fontStyle: FontStyle.italic));''',
      quiet: '''
Text('Beautifully made',
  style: TextStyle(fontFamily: 'Playfair', fontSize: 48));''');

  ruleTest('wide-tracking',
      fires: "Text('body copy here', style: TextStyle(fontSize: 16, letterSpacing: 1.6));",
      quiet: "Text('body copy here', style: TextStyle(fontSize: 16, letterSpacing: 0.2));");

  ruleTest('image-hover-transform',
      target: Target.web,
      fires: '''
MouseRegion(
  onEnter: (_) => setState(() => _hover = true),
  child: AnimatedScale(scale: _hover ? 1.05 : 1.0, child: Image.asset('a.png')),
);''',
      quiet: "Image.asset('a.png');");

  ruleTest('repeated-container-text',
      fires: "Column(children: [Text('Import your data'), Text('Import your data')]);",
      quiet: "Column(children: [Text('Import your data'), Text('Review them')]);");

  group('blinking-cursor', () {
    test('fires on a decorative caret driven by a repeating controller', () {
      const source = '''
final c = AnimationController(vsync: this)..repeat(reverse: true);
final cursorBar = FadeTransition(opacity: c, child: const Text('|'));''';
      expect(idsFor(source), contains('blinking-cursor'));
    });

    test('stays quiet where a real text field owns the caret', () {
      const source = '''
final c = AnimationController(vsync: this)..repeat(reverse: true);
final field = TextField(cursorColor: Colors.white);''';
      expect(idsFor(source), isNot(contains('blinking-cursor')));
    });
  });

  group('image-hover-transform is web-only', () {
    const source = '''
MouseRegion(
  onEnter: (_) => setState(() => _hover = true),
  child: AnimatedScale(scale: 1.05, child: Image.asset('a.png')),
);''';
    test('does not fire on a phone build',
        () => expect(idsFor(source), isNot(contains('image-hover-transform'))));
    test('does not fire on a TV build',
        () => expect(idsFor(source, target: Target.tv),
            isNot(contains('image-hover-transform'))));
  });
}
