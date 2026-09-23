import 'dart:io';

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:impeccable_flutter_lint/src/plugin.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('impeccable-lint'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String contents) {
    final file = File('${root.path}/$path');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  Target targetFor(String relative) =>
      ImpeccableFlutterPlugin.targetFor('${root.path}/$relative');

  group('target resolution', () {
    test('falls back to phone when nothing says otherwise', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/a.dart', 'const x = 1;');
      expect(targetFor('lib/a.dart'), Target.phone);
    });

    test('infers tv from a leanback launcher, with no configuration', () {
      // This is what makes the plugin usable on a TV project: a build judged
      // as a phone build passes checks it should fail, and nobody remembers
      // to configure a linter.
      write('pubspec.yaml', 'name: a\n');
      write('lib/a.dart', 'const x = 1;');
      write('android/app/src/main/AndroidManifest.xml',
          '<manifest>android.intent.category.LEANBACK_LAUNCHER</manifest>');
      expect(targetFor('lib/a.dart'), Target.tv);
    });

    test('finds the project root from a nested file', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/feature/deep/screen.dart', 'const x = 1;');
      write('android/app/src/main/AndroidManifest.xml',
          '<manifest>LEANBACK_LAUNCHER</manifest>');
      expect(targetFor('lib/feature/deep/screen.dart'), Target.tv);
    });

    test('an android app with no leanback intent is a phone', () {
      write('pubspec.yaml', 'name: a\n');
      write('lib/a.dart', 'const x = 1;');
      write('android/app/src/main/AndroidManifest.xml', '<manifest />');
      expect(targetFor('lib/a.dart'), Target.phone);
    });
  });

  group('rule registration', () {
    // getLintRules is an override, so the internal empty config is the only
    // way to call it from a test.
    // ignore: invalid_use_of_internal_member
    final rules = ImpeccableFlutterPlugin().getLintRules(CustomLintConfigs.empty);

    test('registers every rule in the catalog', () {
      // Each rule decides per file whether it applies, because one analysis
      // session can span projects with different targets.
      expect(rules.length, kRules.length);
    });

    test('rule names match the detector ids, so waivers read the same', () {
      expect(rules.map((r) => r.code.name).toSet(),
          kRules.map((r) => r.id).toSet());
    });

    test('every rule carries its description as the correction message', () {
      for (final r in rules) {
        expect(r.code.problemMessage, isNotEmpty, reason: r.code.name);
        expect(r.code.correctionMessage, isNotNull, reason: r.code.name);
      }
    });
  });
}
