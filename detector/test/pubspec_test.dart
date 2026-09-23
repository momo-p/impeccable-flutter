import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

const _pubspec = '''
name: my_app
environment:
  sdk: ^3.6.0

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/logo.png
    - assets/images/
  fonts:
    - family: Söhne
      fonts:
        - asset: fonts/Soehne-Buch.otf
        - asset: fonts/Soehne-Halbfett.otf
          weight: 600
    - family: Fraunces
      fonts:
        - asset: fonts/Fraunces.ttf
''';

List<String> idsFor(String source, {Pubspec? pubspec}) =>
    Scanner(pubspec: pubspec)
        .scanSource('lib/screen.dart', source)
        .map((f) => f.rule.id)
        .toList();

void main() {
  final parsed = Pubspec.parse(_pubspec);

  group('parsing', () {
    test('reads families from the top-level fonts list only', () {
      // The nested `fonts:` under each family lists weight files, not
      // families; folding them in would declare fonts that do not exist.
      expect(parsed.fontFamilies, {'Söhne', 'Fraunces'});
    });

    test('reads asset entries', () {
      expect(parsed.assetEntries, ['assets/logo.png', 'assets/images/']);
    });

    test('notices the flutter section', () {
      expect(parsed.declaresFlutter, isTrue);
      expect(Pubspec.parse('name: a\n').declaresFlutter, isFalse);
    });

    test('font matching ignores case and separators', () {
      expect(parsed.declaresFont('söhne'), isTrue);
      expect(parsed.declaresFont('Plus Jakarta'), isFalse);
    });

    test('a directory entry covers files directly inside it, not deeper', () {
      expect(parsed.declaresAsset('assets/images/hero.png'), isTrue);
      expect(parsed.declaresAsset('assets/images/icons/star.png'), isFalse);
      expect(parsed.declaresAsset('assets/logo.png'), isTrue);
      expect(parsed.declaresAsset('assets/missing.png'), isFalse);
    });
  });

  group('undeclared-font', () {
    test('fires on a family the pubspec never declares', () {
      final ids = idsFor("Text('x', style: TextStyle(fontFamily: 'Satoshi'));",
          pubspec: parsed);
      expect(ids, contains('undeclared-font'));
    });

    test('stays quiet on a declared family', () {
      final ids = idsFor("Text('x', style: TextStyle(fontFamily: 'Fraunces'));",
          pubspec: parsed);
      expect(ids, isNot(contains('undeclared-font')));
    });

    test('stays quiet with no pubspec in scope', () {
      final ids = idsFor("Text('x', style: TextStyle(fontFamily: 'Satoshi'));");
      expect(ids, isNot(contains('undeclared-font')));
    });
  });

  group('undeclared-asset', () {
    test('fires on an undeclared path', () {
      expect(idsFor("Image.asset('assets/missing.png');", pubspec: parsed),
          contains('undeclared-asset'));
    });

    test('stays quiet on a declared file and a covered directory', () {
      expect(idsFor("Image.asset('assets/logo.png');", pubspec: parsed),
          isNot(contains('undeclared-asset')));
      expect(idsFor("Image.asset('assets/images/hero.png');", pubspec: parsed),
          isNot(contains('undeclared-asset')));
    });

    test('covers AssetImage too', () {
      expect(idsFor("AssetImage('assets/missing.png');", pubspec: parsed),
          contains('undeclared-asset'));
    });

    test('skips a path built at runtime', () {
      expect(idsFor(r"Image.asset('assets/$name.png');", pubspec: parsed),
          isNot(contains('undeclared-asset')));
    });

    test('stands down for a package with no flutter section', () {
      final plain = Pubspec.parse('name: a\n');
      expect(idsFor("Image.asset('assets/missing.png');", pubspec: plain),
          isNot(contains('undeclared-asset')));
    });
  });

  test('discovery walks up to the pubspec', () {
    final found = Pubspec.discover('lib/src');
    expect(found, isNotNull);
    expect(found!.path, endsWith('pubspec.yaml'));
  });
}
