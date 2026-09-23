import 'dart:convert';
import 'dart:io';

import 'finding.dart';

/// A record of findings a project has decided to carry for now.
///
/// Adopting a detector on an existing app is the part that usually fails: a
/// first run reports hundreds of findings, `--fail-on` can never be switched
/// on, and the tool gets ignored. A baseline freezes what is already there so
/// CI can block *new* findings from day one.
///
/// Entries are matched on rule id, file and the source line's text — not the
/// line number, so inserting a line above a finding does not resurrect it.
class Baseline {
  Baseline(this._entries);

  final Set<String> _entries;

  int get length => _entries.length;

  static String keyFor(Finding f) =>
      '${f.rule.id}|${f.file}|${f.snippet.trim()}';

  static Baseline fromFindings(Iterable<Finding> findings) =>
      Baseline({for (final f in findings) keyFor(f)});

  static Baseline load(String path) {
    final raw = jsonDecode(File(path).readAsStringSync());
    if (raw is! Map || raw['entries'] is! List) {
      throw FormatException('$path is not an impeccable-flutter baseline');
    }
    return Baseline({for (final e in raw['entries'] as List) e as String});
  }

  void save(String path) {
    final sorted = _entries.toList()..sort();
    File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
            'version': 1,
            'note': 'Findings this project carries for now. Delete an entry '
                'once it is fixed; the detector never re-adds one on its own.',
            'entries': sorted,
          })}\n',
    );
  }

  bool covers(Finding f) => _entries.contains(keyFor(f));

  /// Findings not already recorded. This is what CI should act on.
  List<Finding> filter(Iterable<Finding> findings) =>
      findings.where((f) => !covers(f)).toList();

  /// Entries whose finding no longer occurs, so the file can be pruned.
  Set<String> staleAgainst(Iterable<Finding> findings) =>
      _entries.difference({for (final f in findings) keyFor(f)});
}
