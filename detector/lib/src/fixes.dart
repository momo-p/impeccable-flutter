import 'dart:io';

import 'finding.dart';

/// A mechanical rewrite for one finding.
///
/// Most rules cannot be fixed automatically and should not pretend otherwise.
/// "Use a theme role instead of this literal" needs someone to decide *which*
/// role; "give this button a tooltip" needs someone to write the words. A fix
/// belongs here only when the correct replacement follows from the source
/// alone, with no judgment involved — otherwise `--fix` quietly makes the
/// wrong decision at scale, which is worse than reporting the finding.
class Fix {
  const Fix({required this.ruleId, required this.pattern, required this.replace});

  final String ruleId;
  final RegExp pattern;
  final String Function(Match) replace;
}

/// Every rule `--fix` can act on. Deliberately short.
final List<Fix> kFixes = [
  Fix(
    ruleId: 'deprecated-with-opacity',
    // `withOpacity(x)` and `withValues(alpha: x)` mean the same thing, and the
    // argument carries over untouched, so there is nothing to decide.
    pattern: RegExp(r'\.withOpacity\(\s*([^()]*(?:\([^()]*\)[^()]*)*)\s*\)'),
    replace: (m) => '.withValues(alpha: ${m[1]!.trim()})',
  ),
];

final Map<String, Fix> kFixesByRule = {for (final f in kFixes) f.ruleId: f};

class FixResult {
  FixResult({required this.applied, required this.skipped, required this.files});

  /// Findings rewritten.
  final int applied;

  /// Findings left alone because no fix exists for that rule.
  final int skipped;

  /// Files actually changed.
  final Set<String> files;
}

/// Applies every available fix to the files the findings came from.
///
/// Rewrites are done per file in one pass, so two fixes on one line cannot
/// invalidate each other's offsets.
FixResult applyFixes(List<Finding> findings, {bool dryRun = false}) {
  final byFile = <String, Set<String>>{};
  var skipped = 0;

  for (final f in findings) {
    if (!kFixesByRule.containsKey(f.rule.id)) {
      skipped++;
      continue;
    }
    byFile.putIfAbsent(f.file, () => <String>{}).add(f.rule.id);
  }

  var applied = 0;
  final changed = <String>{};

  for (final entry in byFile.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) continue;
    final before = file.readAsStringSync();
    var after = before;

    for (final ruleId in entry.value) {
      final fix = kFixesByRule[ruleId]!;
      after = after.replaceAllMapped(fix.pattern, (m) {
        applied++;
        return fix.replace(m);
      });
    }

    if (after != before) {
      changed.add(entry.key);
      if (!dryRun) file.writeAsStringSync(after);
    }
  }

  return FixResult(applied: applied, skipped: skipped, files: changed);
}
