import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';
import 'package:test/test.dart';

void main() {
  const slop = '''
Container(
  color: Color(0xFF6366F1),
  child: Text('hi', style: TextStyle(fontSize: 9)),
);''';

  List<Finding> scan(String source) =>
      Scanner().scanSource('lib/screen.dart', source);

  test('a baseline suppresses exactly what it recorded', () {
    final first = scan(slop);
    expect(first, isNotEmpty);
    final baseline = Baseline.fromFindings(first);
    expect(baseline.filter(scan(slop)), isEmpty);
  });

  test('a new finding is still reported', () {
    final baseline = Baseline.fromFindings(scan(slop));
    final changed = '$slop\nconst bad = TextStyle(fontSize: 7);';
    final fresh = baseline.filter(scan(changed));
    expect(fresh.map((f) => f.rule.id), contains('tiny-text'));
  });

  test('inserting a line above a finding does not resurrect it', () {
    // Entries key on the source line's text, not its number. Keying on the
    // number would mean every edit above a finding re-reports it, which is
    // what makes a line-numbered baseline useless in practice.
    final baseline = Baseline.fromFindings(scan(slop));
    final shifted = '// a new comment\n// and another\n$slop';
    expect(baseline.filter(scan(shifted)), isEmpty);
  });

  test('a fixed finding shows up as a stale entry', () {
    final baseline = Baseline.fromFindings(scan(slop));
    const fixed = '''
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text('hi', style: Theme.of(context).textTheme.bodyMedium),
);''';
    final stale = baseline.staleAgainst(scan(fixed));
    expect(stale, isNotEmpty);
    expect(baseline.filter(scan(fixed)), isEmpty);
  });

  test('round-trips through a file', () {
    final dir = Directory.systemTemp.createTempSync('impeccable-baseline');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/base.json';

    final original = Baseline.fromFindings(scan(slop));
    original.save(path);
    final loaded = Baseline.load(path);

    expect(loaded.length, original.length);
    expect(loaded.filter(scan(slop)), isEmpty);
    // The file is readable and editable by hand, which is the point.
    final text = File(path).readAsStringSync();
    expect(text, contains('"entries"'));
    expect(text, contains('tiny-text|lib/screen.dart'));
  });

  test('a file that is not a baseline is rejected', () {
    final dir = Directory.systemTemp.createTempSync('impeccable-baseline');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/nope.json';
    File(path).writeAsStringSync('{"something": "else"}');
    expect(() => Baseline.load(path), throwsFormatException);
  });

  test('entries are sorted, so the file diffs cleanly', () {
    final dir = Directory.systemTemp.createTempSync('impeccable-baseline');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/base.json';
    Baseline.fromFindings(scan(slop)).save(path);
    // Entries are the only lines carrying the "rule|file|snippet" shape; the
    // version and note keys are not entries.
    final text = File(path).readAsStringSync();
    final entries = RegExp('^\\s+"([^"]*\\|[^"]*)",?\$', multiLine: true)
        .allMatches(text)
        .map((m) => m[1]!)
        .toList();
    expect(entries, orderedEquals(List.of(entries)..sort()));
  });
}
