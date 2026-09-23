import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

List<String> idsFor(String source, Target target,
        {String path = 'lib/screen.dart'}) =>
    Scanner(target: target)
        .scanSource(path, source)
        .map((f) => f.rule.id)
        .toList();

void main() {
  group('rules that assume a finger', () {
    const tappable =
        'SizedBox(width: 32, height: 32, child: InkWell(onTap: f, child: c));';

    test('a small tap target is an error on a phone', () {
      expect(idsFor(tappable, Target.phone), contains('tap-target-undersized'));
    });

    test('and means nothing on a TV, which has no touch', () {
      expect(idsFor(tappable, Target.tv), isNot(contains('tap-target-undersized')));
    });
  });

  group('thresholds move with the target', () {
    test('16sp is fine on a phone and too small on a TV', () {
      const source = "Text('body', style: TextStyle(fontSize: 16));";
      expect(idsFor(source, Target.phone), isNot(contains('tiny-text')));
      expect(idsFor(source, Target.tv), contains('tiny-text'));
    });

    test('a 72px headline overflows a phone and fits a TV', () {
      const source = "Text('Hi', style: TextStyle(fontSize: 72));";
      expect(idsFor(source, Target.phone), contains('oversized-headline'));
      expect(idsFor(source, Target.tv), isNot(contains('oversized-headline')));
    });
  });

  group('TV rules do not fire on touch targets', () {
    const source = '''
Scaffold(
  body: Column(children: [
    GestureDetector(onTap: f, child: const Text('Play')),
    Focus(child: Container(child: const Text('Settings'))),
  ]),
);''';

    test('a phone build sees none of them', () {
      final ids = idsFor(source, Target.phone);
      expect(ids, isNot(contains('unreachable-by-dpad')));
      expect(ids, isNot(contains('missing-focus-highlight')));
      expect(ids, isNot(contains('no-autofocus-on-route')));
      expect(ids, isNot(contains('overscan-unsafe')));
    });

    test('a TV build sees all of them', () {
      final ids = idsFor(source, Target.tv);
      expect(ids, contains('unreachable-by-dpad'));
      expect(ids, contains('missing-focus-highlight'));
      expect(ids, contains('no-autofocus-on-route'));
      expect(ids, contains('overscan-unsafe'));
    });
  });

  group('focus-driven rules', () {
    test('a focusable that reads focus state is fine', () {
      const source = '''
FocusableActionDetector(
  onShowFocusHighlight: (v) => setState(() => _focused = v),
  child: Container(child: const Text('Play')),
);''';
      expect(idsFor(source, Target.tv), isNot(contains('missing-focus-highlight')));
    });

    test('a tap wrapped in a button is reachable', () {
      const source = "FilledButton(onPressed: f, child: const Text('Play'));";
      expect(idsFor(source, Target.tv), isNot(contains('unreachable-by-dpad')));
    });

    test('autofocus satisfies the entry rule', () {
      const source = '''
Scaffold(
  body: Padding(
    padding: const EdgeInsets.all(48),
    child: FilledButton(autofocus: true, onPressed: f, child: const Text('Play')),
  ),
);''';
      final ids = idsFor(source, Target.tv);
      expect(ids, isNot(contains('no-autofocus-on-route')));
      expect(ids, isNot(contains('overscan-unsafe')));
    });

    test('hover with no focus path is flagged on web and TV only', () {
      const source = 'MouseRegion(onEnter: (_) => _show(), child: c);';
      expect(idsFor(source, Target.web), contains('hover-only-affordance'));
      expect(idsFor(source, Target.tv), contains('hover-only-affordance'));
      expect(idsFor(source, Target.phone), isNot(contains('hover-only-affordance')));
    });
  });

  group('target parsing', () {
    test('accepts every name', () {
      for (final t in Target.values) {
        expect(Target.parse(t.name), t);
      }
    });

    test('rejects anything else', () => expect(Target.parse('watch'), isNull));
  });

  group('registry scoping', () {
    test('focus rules declare the targets they apply to', () {
      for (final id in [
        'unreachable-by-dpad',
        'missing-focus-highlight',
        'no-autofocus-on-route',
        'overscan-unsafe',
        'hover-only-affordance',
      ]) {
        expect(kRulesById[id]!.targets, isNotNull, reason: id);
        expect(kRulesById[id]!.appliesTo(Target.phone), isFalse, reason: id);
      }
    });

    test('an unscoped rule applies everywhere', () {
      final rule = kRulesById['nested-cards']!;
      expect(rule.targets, isNull);
      for (final t in Target.values) {
        expect(rule.appliesTo(t), isTrue);
      }
    });
  });
}
