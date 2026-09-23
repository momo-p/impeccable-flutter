import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('impeccable-signals'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String contents) {
    final file = File('${root.path}/$path');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  Signals gather() => Signals.gather(root.path);

  test('an empty directory is not a Flutter project', () {
    final s = gather();
    expect(s.hasPubspec, isFalse);
    expect(s.projectName, isNull);
    expect(s.inferredTarget, isNull);
    expect(s.isGreenfield, isTrue);
  });

  test('reads the project name from pubspec', () {
    write('pubspec.yaml', 'name: my_app\ndescription: x\n');
    expect(gather().projectName, 'my_app');
  });

  group('target inference', () {
    test('an Android TV launcher intent means TV, without asking', () {
      // This is the whole point: the answer is already on disk.
      write('pubspec.yaml', 'name: tv_app\n');
      Directory('${root.path}/android').createSync();
      write('android/app/src/main/AndroidManifest.xml', '''
<manifest>
  <application>
    <activity>
      <intent-filter>
        <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
      </intent-filter>
    </activity>
  </application>
</manifest>''');
      expect(gather().inferredTarget, Target.tv);
    });

    test('a plain Android app is a phone', () {
      write('pubspec.yaml', 'name: a\n');
      Directory('${root.path}/android').createSync();
      write('android/app/src/main/AndroidManifest.xml',
          '<manifest><application /></manifest>');
      expect(gather().inferredTarget, Target.phone);
    });

    test('iOS alone is also a phone', () {
      write('pubspec.yaml', 'name: a\n');
      Directory('${root.path}/ios').createSync();
      expect(gather().inferredTarget, Target.phone);
    });

    test('web only is web', () {
      write('pubspec.yaml', 'name: a\n');
      Directory('${root.path}/web').createSync();
      expect(gather().inferredTarget, Target.web);
    });

    test('a desktop-only project is unclear, so init must ask', () {
      write('pubspec.yaml', 'name: a\n');
      Directory('${root.path}/linux').createSync();
      expect(gather().inferredTarget, isNull);
    });
  });

  group('setup state', () {
    test('finds the theme file by what it defines, not its name', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/looks.dart',
          'ThemeData build() => ThemeData(colorScheme: scheme);');
      final s = gather();
      expect(s.hasTheme, isTrue);
      expect(s.themeFiles, ['lib/looks.dart']);
    });

    test('counts screens by Scaffold', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/a.dart', 'Widget b() => Scaffold(body: x);');
      write('lib/b.dart', 'Widget b() => Scaffold(body: y);');
      write('lib/util.dart', 'int add(int a, int b) => a + b;');
      final s = gather();
      expect(s.dartFiles, 3);
      expect(s.screenFiles, 2);
    });

    test('skips generated files', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/a.dart', 'const x = 1;');
      write('lib/a.g.dart', 'const y = 2;');
      write('lib/a.freezed.dart', 'const z = 3;');
      expect(gather().dartFiles, 1);
    });

    test('notices the documents and the baseline', () {
      write('pubspec.yaml', 'name: a\n');
      write('PRODUCT.md', '# PRODUCT');
      write('DESIGN.md', '# DESIGN');
      write('.impeccable-baseline.json', '{"entries":[]}');
      final s = gather();
      expect(s.hasProduct, isTrue);
      expect(s.hasDesign, isTrue);
      expect(s.designPath, 'DESIGN.md');
      expect(s.hasBaseline, isTrue);
    });

    test('greenfield means nothing to preserve', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/main.dart', 'void main() {}');
      expect(gather().isGreenfield, isTrue);

      write('lib/theme.dart', 'final t = ThemeData();');
      expect(gather().isGreenfield, isFalse);
    });
  });

  test('json carries what an init flow needs to branch on', () {
    write('pubspec.yaml', 'name: a\n');
    final json = gather().toJson();
    expect(json['inferredTarget'], isNull);
    expect((json['setup']! as Map)['hasProductMd'], isFalse);
    expect((json['code']! as Map)['greenfield'], isTrue);
  });
}
