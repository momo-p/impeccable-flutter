import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('impeccable-fix'));
  tearDown(() => dir.deleteSync(recursive: true));

  String fixFile(String source) {
    final file = File('${dir.path}/screen.dart')..writeAsStringSync(source);
    final findings = Scanner().scanSource(file.path, source);
    applyFixes(findings);
    return file.readAsStringSync();
  }

  group('withOpacity', () {
    test('rewrites to withValues, carrying the argument over', () {
      expect(fixFile('final c = base.withOpacity(0.5);'),
          'final c = base.withValues(alpha: 0.5);');
    });

    test('handles a computed argument, including nested calls', () {
      expect(fixFile('final c = base.withOpacity(fade(t) * 0.5);'),
          'final c = base.withValues(alpha: fade(t) * 0.5);');
    });

    test('rewrites every occurrence in a file', () {
      final out = fixFile('''
final a = x.withOpacity(0.1);
final b = y.withOpacity(0.9);''');
      expect(out, isNot(contains('withOpacity')));
      expect('withValues'.allMatches(out).length, 2);
    });

    test('is idempotent', () {
      final once = fixFile('final c = base.withOpacity(0.5);');
      final twice = fixFile(once);
      expect(twice, once);
    });

    test('leaves already-correct code alone', () {
      const source = 'final c = base.withValues(alpha: 0.5);';
      expect(fixFile(source), source);
    });
  });

  group('scope', () {
    test('only rules with a mechanical fix are in the table', () {
      // A fix that needs a judgment call would make --fix quietly wrong at
      // scale, which is worse than reporting the finding.
      expect(kFixes.map((f) => f.ruleId), ['deprecated-with-opacity']);
      for (final f in kFixes) {
        expect(kRulesById.containsKey(f.ruleId), isTrue, reason: f.ruleId);
      }
    });

    test('findings without a fix are counted as skipped, not touched', () {
      const source = '''
final a = base.withOpacity(0.5);
final b = Container(color: Color(0xFF123456), child: c);''';
      final file = File('${dir.path}/screen.dart')..writeAsStringSync(source);
      final findings = Scanner().scanSource(file.path, source);
      final result = applyFixes(findings);

      expect(result.applied, 1);
      expect(result.skipped, greaterThan(0));
      expect(file.readAsStringSync(), contains('Color(0xFF123456)'));
    });

    test('a dry run reports without writing', () {
      const source = 'final c = base.withOpacity(0.5);';
      final file = File('${dir.path}/screen.dart')..writeAsStringSync(source);
      final findings = Scanner().scanSource(file.path, source);
      final result = applyFixes(findings, dryRun: true);

      expect(result.applied, 1);
      expect(result.files, isNotEmpty);
      expect(file.readAsStringSync(), source);
    });
  });

  test('the fixed file no longer trips the rule', () {
    final out = fixFile('final c = base.withOpacity(0.5);');
    final after = Scanner().scanSource('lib/a.dart', out);
    expect(after.map((f) => f.rule.id),
        isNot(contains('deprecated-with-opacity')));
  });
}
