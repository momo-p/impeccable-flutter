import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

/// Fixture-driven coverage, in the spirit of upstream's golden tests: the
/// positive corpus must trip every rule in the catalog at least once, and the
/// negative fixture must trip none. A rule that only ever fires in its own
/// unit test is a rule that does not survive contact with real widget code.
void main() {
  List<Finding> scanFixture(String name, {Target target = Target.phone}) {
    final file = File('test/fixtures/$name');
    return Scanner(target: target)
        .scanSource(file.path, file.readAsStringSync());
  }

  test('the clean phone fixture produces no findings on pointer targets', () {
    // Not TV: a screen built for a finger is not a valid remote screen, and
    // the focus rules are right to say so. tv_clean_screen.dart is the TV one.
    for (final target in [Target.phone, Target.tablet, Target.web]) {
      final findings = scanFixture('clean_screen.dart', target: target);
      expect(
        findings.map((f) => '${f.line}: ${f.rule.id}').toList(),
        isEmpty,
        reason: 'false positives on $target for a screen that follows the skill',
      );
    }
  });

  test('the clean TV fixture produces no findings under --target tv', () {
    final findings = scanFixture('tv_clean_screen.dart', target: Target.tv);
    expect(
      findings.map((f) => '${f.line}: ${f.rule.id}').toList(),
      isEmpty,
      reason: 'false positives on a TV screen that follows the skill',
    );
  });

  test('the slop corpus trips every rule in the catalog', () {
    // Scoped rules only fire on the targets they apply to, so coverage is the
    // union across targets rather than one phone-shaped pass.
    final fired = <String>{};
    for (final target in Target.values) {
      for (final name in ['slop_home.dart', 'slop_settings.dart', 'tv_screen.dart', 'slop_marketing.dart']) {
        fired.addAll(scanFixture(name, target: target).map((f) => f.rule.id));
      }
    }
    final never = kRules.map((r) => r.id).toSet().difference(fired);
    expect(never, isEmpty,
        reason: 'these rules never fire on the fixture corpus, so nothing '
            'proves they work on real widget code');
  });

  test('the TV fixture trips every focus rule under --target tv', () {
    final fired = scanFixture('tv_screen.dart', target: Target.tv)
        .map((f) => f.rule.id)
        .toSet();
    expect(
        fired,
        containsAll([
          'unreachable-by-dpad',
          'missing-focus-highlight',
          'no-autofocus-on-route',
          'hover-only-affordance',
          'overscan-unsafe',
        ]));
  });

  test('the same TV fixture trips none of them as a phone build', () {
    final fired = scanFixture('tv_screen.dart')
        .map((f) => f.rule.id)
        .toSet();
    expect(
        fired.intersection({
          'unreachable-by-dpad',
          'missing-focus-highlight',
          'no-autofocus-on-route',
          'hover-only-affordance',
          'overscan-unsafe',
        }),
        isEmpty);
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
