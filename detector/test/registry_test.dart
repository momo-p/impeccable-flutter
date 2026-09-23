import 'dart:convert';
import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

/// The upstream catalog this port was derived from, extracted by
/// `tool/extract_registry.pl` straight out of pbakaus/impeccable's Rust.
Map<String, dynamic> _upstream() {
  final file = File('../tool/upstream_registry.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test('rule ids are unique', () {
    final ids = kRules.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every rule carries a name and a description', () {
    for (final r in kRules) {
      expect(r.name, isNotEmpty, reason: r.id);
      expect(r.description.length, greaterThan(40), reason: r.id);
    }
  });

  test('every portOf names a rule that exists upstream', () {
    final upstreamIds = {
      for (final r in _upstream()['rules'] as List) (r as Map)['id'] as String
    };
    // The extraction itself must have worked, or this test proves nothing.
    expect(upstreamIds.length, 61);
    for (final r in kRules.where((r) => r.portOf != null)) {
      expect(upstreamIds, contains(r.portOf),
          reason: '${r.id} claims to port "${r.portOf}", which is not in the '
              'upstream registry');
    }
  });

  test('platform rules are Flutter-only by construction', () {
    for (final r in kRules.where((r) => r.category == Category.platform)) {
      expect(r.portOf, isNull,
          reason: '${r.id} is a platform rule, so it cannot port a web rule');
    }
  });

  test('every registered rule is reachable from some check', () {
    // A rule in the catalog that no check can ever emit is dead copy in a
    // report the user is told is exhaustive.
    final fired = <String>{};
    for (final file in Directory('lib/src/rules.dart')
        .parent
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('rules.dart'))) {
      final text = file.readAsStringSync();
      for (final m in RegExp(r"""emit\(\s*'([a-z0-9-]+)'""").allMatches(text)) {
        fired.add(m[1]!);
      }
    }
    final orphans = kRules.map((r) => r.id).toSet().difference(fired);
    expect(orphans, isEmpty, reason: 'no check emits these rules');
  });

  test('the README port count matches the registry', () {
    // The counts in the README are a claim about this file. Pinning them here
    // means adding a rule fails the suite until the prose is updated too.
    final upstreamIds = {
      for (final r in _upstream()['rules'] as List) (r as Map)['id'] as String
    };
    final ported = kRules.map((r) => r.portOf).whereType<String>().toSet();
    expect(upstreamIds.length, 61);
    expect(ported.length, 46);
    expect(upstreamIds.difference(ported).length, 15);
    expect(kRules.length, 67);
  });

  test('no check emits a rule the registry does not define', () {
    final text = File('lib/src/rules.dart').readAsStringSync();
    final emitted = RegExp(r"""emit\(\s*'([a-z0-9-]+)'""")
        .allMatches(text)
        .map((m) => m[1]!)
        .toSet();
    expect(emitted.difference(kRulesById.keys.toSet()), isEmpty);
  });
}
