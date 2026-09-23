import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('masking', () {
    test('blanks line comments but keeps offsets and lines', () {
      final src = DartSource.parse('a.dart', 'var a = 1; // Card(\nvar b = 2;\n');
      expect(src.masked.length, src.text.length);
      expect(src.masked, isNot(contains('Card')));
      expect(src.lineAt(src.text.indexOf('var b')), 2);
    });

    test('blanks block comments without eating their newlines', () {
      final src = DartSource.parse('a.dart', '/* Card(\n   Card( */\nvar x = 1;\n');
      expect(src.calls, isEmpty);
      expect(src.lineAt(src.text.indexOf('var x')), 3);
    });

    test('blanks string bodies but records them', () {
      final src = DartSource.parse('a.dart', "const s = 'Card(unclosed';\n");
      expect(src.calls, isEmpty);
      expect(src.strings.single.value, 'Card(unclosed');
    });

    test('handles triple-quoted and raw strings', () {
      final src = DartSource.parse('a.dart', "const a = '''one\ntwo''';\nconst b = r'\\d+';\n");
      expect(src.strings.map((s) => s.value), ['one\ntwo', r'\d+']);
      expect(src.lineAt(src.text.indexOf('const b')), 3);
    });
  });

  group('widget calls', () {
    final src = DartSource.parse('a.dart', '''
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('hi'),
    ),
  );
}
''');

    test('finds constructors and nests them', () {
      final card = src.calls.firstWhere((c) => c.name == 'Card');
      final text = src.calls.firstWhere((c) => c.name == 'Text');
      expect(card.contains(text), isTrue);
      expect(text.contains(card), isFalse);
    });

    test('reads named arguments at the right depth', () {
      final padding = src.calls.firstWhere((c) => c.name == 'Padding');
      expect(padding.arg('padding'), 'EdgeInsets.all(16)');
      expect(padding.arg('missing'), isNull);
    });

    test('a named argument belongs to the call that declares it', () {
      final src = DartSource.parse('a.dart',
          'Border(left: BorderSide(width: 4, color: Color(0xFFEF4444)));');
      final border = src.calls.firstWhere((c) => c.name == 'Border');
      final side = src.calls.firstWhere((c) => c.name == 'BorderSide');
      // The color belongs to BorderSide. If Border claimed it, every ancestor
      // widget would report its descendants' arguments as its own.
      expect(border.arg('color'), isNull);
      expect(side.arg('color'), 'Color(0xFFEF4444)');
      expect(side.numArg('width'), 4);
    });

    test('records named constructors', () {
      final img = DartSource.parse('a.dart', 'Image.network(url);')
          .calls
          .firstWhere((c) => c.name == 'Image');
      expect(img.constructor, 'network');
    });
  });

  group('waivers', () {
    test('a comment on its own line waives the line below', () {
      final src = DartSource.parse('a.dart', '// impeccable-disable\nCard();\n');
      expect(src.isWaived(2, 'nested-cards'), isTrue);
    });

    test('a trailing comment waives its own line', () {
      final src = DartSource.parse('a.dart', 'Card(); // impeccable-disable\n');
      expect(src.isWaived(1, 'nested-cards'), isTrue);
    });

    test('a scoped waiver only covers the ids it names', () {
      final src =
          DartSource.parse('a.dart', '// impeccable-disable: nested-cards\nCard();\n');
      expect(src.isWaived(2, 'nested-cards'), isTrue);
      expect(src.isWaived(2, 'hardcoded-color'), isFalse);
    });

    test('a file waiver covers everything', () {
      final src = DartSource.parse('a.dart', '// impeccable-disable-file\nCard();\n');
      expect(src.isWaived(99, 'anything'), isTrue);
    });
  });
}
