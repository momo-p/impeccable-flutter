import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

DesignSystem get _system => DesignSystem.parse(
    File('test/fixtures/project/DESIGN.md').readAsStringSync(),
    path: 'test/fixtures/project/DESIGN.md');

List<String> idsFor(String source, {DesignSystem? design}) =>
    Scanner(design: design)
        .scanSource('lib/screen.dart', source)
        .map((f) => f.rule.id)
        .toList();

void main() {
  group('parsing DESIGN.md', () {
    test('reads the declared colors', () {
      final d = _system;
      expect(d.declaresColor(const Rgb(0x1B, 0x7F, 0x5C)), isTrue);
      expect(d.declaresColor(const Rgb(0x63, 0x66, 0xF1)), isFalse);
    });

    test('ignores alpha, so a token at partial opacity still counts', () {
      expect(_system.declaresColor(const Rgb(0x1B, 0x7F, 0x5C, 0.4)), isTrue);
    });

    test('reads fonts regardless of spacing and case', () {
      final d = _system;
      expect(d.declaresFont('Söhne'), isTrue);
      expect(d.declaresFont('fraunces'), isTrue);
      expect(d.declaresFont('Inter'), isFalse);
    });

    test('reads the type ramp and the radius scale separately', () {
      final d = _system;
      expect(d.declaresFontSize(16), isTrue);
      expect(d.declaresFontSize(17), isFalse);
      expect(d.declaresRadius(12), isTrue);
      expect(d.declaresRadius(20), isFalse);
    });

    test('an empty document declares nothing', () {
      expect(DesignSystem.parse('# DESIGN.md\n\nNothing yet.\n').isEmpty, isTrue);
    });

    test('discovery walks up to find the document', () {
      final found = DesignSystem.discover('test/fixtures/project');
      expect(found, isNotNull);
      expect(found!.declaresColor(const Rgb(0x1B, 0x7F, 0x5C)), isTrue);
    });
  });

  group('the rules stay silent without a design system', () {
    const source = '''
Container(
  color: Color(0xFF6366F1),
  child: Text('hi', style: TextStyle(fontFamily: 'Doto', fontSize: 17)),
);''';

    test('no DESIGN.md means no design-system findings', () {
      final ids = idsFor(source);
      expect(ids.where((id) => id.startsWith('design-system-')), isEmpty);
    });

    test('an empty DESIGN.md is the same as none', () {
      final ids = idsFor(source, design: DesignSystem.parse('# DESIGN.md\n'));
      expect(ids.where((id) => id.startsWith('design-system-')), isEmpty);
    });
  });

  group('with a design system', () {
    test('an undeclared color is flagged', () {
      final ids = idsFor('Container(color: Color(0xFF6366F1), child: c);',
          design: _system);
      expect(ids, contains('design-system-color'));
    });

    test('a declared color is not', () {
      final ids = idsFor('Container(color: Color(0xFF1B7F5C), child: c);',
          design: _system);
      expect(ids, isNot(contains('design-system-color')));
    });

    test('an undeclared font is flagged, a declared one is not', () {
      expect(
          idsFor("Text('x', style: TextStyle(fontFamily: 'Inter'));",
              design: _system),
          contains('design-system-font'));
      expect(
          idsFor("Text('x', style: TextStyle(fontFamily: 'Fraunces'));",
              design: _system),
          isNot(contains('design-system-font')));
    });

    test('a size off the ramp is flagged, one on it is not', () {
      expect(
          idsFor("Text('x', style: TextStyle(fontSize: 17));", design: _system),
          contains('design-system-font-size'));
      expect(
          idsFor("Text('x', style: TextStyle(fontSize: 18));", design: _system),
          isNot(contains('design-system-font-size')));
    });

    test('a radius off the scale is flagged, one on it is not', () {
      expect(
          idsFor('BorderRadius.circular(20);', design: _system),
          contains('design-system-radius'));
      expect(
          idsFor('BorderRadius.circular(12);', design: _system),
          isNot(contains('design-system-radius')));
    });

    test('a nested Radius.circular does not crash the parse', () {
      // `[\d.]+` matched the dot in `Radius.circular` before it reached the
      // number, and double.parse(".") threw. This shape is ordinary Flutter.
      const source = '''
const shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);''';
      expect(() => idsFor(source, design: _system), returnsNormally);
      expect(idsFor(source, design: _system),
          isNot(contains('design-system-radius')));
    });

    test('a nested radius off the scale is still flagged', () {
      const source = 'const s = BorderRadius.all(Radius.circular(20));';
      expect(idsFor(source, design: _system), contains('design-system-radius'));
    });

    test('the finding names the value and the document', () {
      final f = Scanner(design: _system)
          .scanSource('lib/a.dart', 'Container(color: Color(0xFF6366F1), child: c);')
          .firstWhere((f) => f.rule.id == 'design-system-color');
      expect(f.detail, '#6366f1 is not in DESIGN.md');
    });
  });
}
