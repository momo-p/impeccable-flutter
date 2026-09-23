import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

/// The example is the claim the README makes, so it is checked like any
/// other claim. An "after" screen that quietly starts tripping a rule, or a
/// "before" screen someone helpfully cleaned up, both fail here.
void main() {
  const root = '../examples/watchlist';

  List<Finding> scan(String relative, {Target target = Target.phone}) {
    final file = File('$root/$relative');
    return Scanner(
      target: target,
      context: ProjectContext.discover(file.path),
    ).scanSource(file.path, file.readAsStringSync());
  }

  test('the example is present', () {
    expect(Directory(root).existsSync(), isTrue);
    expect(File('$root/DESIGN.md').existsSync(), isTrue);
    expect(File('$root/pubspec.yaml').existsSync(), isTrue);
  });

  test('the after screen reports nothing on any pointer target', () {
    for (final target in [Target.phone, Target.tablet]) {
      final findings = scan('lib/screens/library_after.dart', target: target);
      expect(findings.map((f) => '${f.line}: ${f.rule.id}'), isEmpty,
          reason: 'on $target');
    }
  });

  test('the TV screen reports nothing under --target tv', () {
    final findings = scan('lib/screens/library_tv.dart', target: Target.tv);
    expect(findings.map((f) => '${f.line}: ${f.rule.id}'), isEmpty);
  });

  test('the theme reports nothing, including its nested radii', () {
    expect(scan('lib/theme.dart').map((f) => '${f.line}: ${f.rule.id}'),
        isEmpty);
  });

  test('the before screen still demonstrates the problems it is kept for', () {
    final fired = scan('lib/screens/library_before.dart')
        .map((f) => f.rule.id)
        .toSet();
    expect(
        fired,
        containsAll([
          'radial-halo',
          'nested-cards',
          'border-accent-on-rounded',
          'icon-tile-stack',
          'tiny-text',
          'all-caps-body',
          'justified-text',
          'tap-target-undersized',
          'missing-semantics',
          'bounce-easing',
          'unbounded-list',
          'undeclared-font',
        ]));
  });

  test('every value in the theme is declared in DESIGN.md', () {
    // The theme is what the app reads; DESIGN.md is what the rules check
    // against. If they disagree, the example teaches the wrong thing.
    final findings = scan('lib/theme.dart')
        .where((f) => f.rule.id.startsWith('design-system-'));
    expect(findings, isEmpty);
  });
}
