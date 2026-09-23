import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

/// Fixture-driven coverage, in the spirit of upstream's golden tests: the
/// positive corpus must trip every rule in the catalog at least once, and the
/// negative fixture must trip none. A rule that only ever fires in its own
/// unit test is a rule that does not survive contact with real widget code.
void main() {
  final scanner = Scanner();

  List<Finding> scanFixture(String name) {
    final file = File('test/fixtures/$name');
    return scanner.scanSource(file.path, file.readAsStringSync());
  }

  test('the clean fixture produces no findings', () {
    final findings = scanFixture('clean_screen.dart');
    expect(
      findings.map((f) => '${f.line}: ${f.rule.id}').toList(),
      isEmpty,
      reason: 'false positives on a screen that follows the skill',
    );
  });

  test('the slop corpus trips every rule in the catalog', () {
    final fired = {
      for (final name in ['slop_home.dart', 'slop_settings.dart'])
        ...scanFixture(name).map((f) => f.rule.id),
    };
    final never = kRules.map((r) => r.id).toSet().difference(fired);
    expect(never, isEmpty,
        reason: 'these rules never fire on the fixture corpus, so nothing '
            'proves they work on real widget code');
  });

  test('findings are ordered by line', () {
    final findings = scanFixture('slop_home.dart');
    final lines = findings.map((f) => f.line).toList();
    expect(lines, orderedEquals(List.of(lines)..sort()));
  });

  test('--only narrows to one rule', () {
    final file = File('test/fixtures/slop_home.dart');
    final findings = Scanner(only: {'tiny-text'})
        .scanSource(file.path, file.readAsStringSync());
    expect(findings, isNotEmpty);
    expect(findings.every((f) => f.rule.id == 'tiny-text'), isTrue);
  });

  test('--ignore drops one rule and keeps the rest', () {
    final file = File('test/fixtures/slop_home.dart');
    final all = scanFixture('slop_home.dart');
    final without = Scanner(ignore: {'hardcoded-color'})
        .scanSource(file.path, file.readAsStringSync());
    expect(without.length, lessThan(all.length));
    expect(without.any((f) => f.rule.id == 'hardcoded-color'), isFalse);
  });
}
