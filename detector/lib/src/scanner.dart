import 'dart:io';

import 'design_system.dart';
import 'finding.dart';
import 'registry.dart';
import 'rules.dart';
import 'source.dart';
import 'target.dart';

/// Runs the rule set over Dart source and applies inline waivers, the way
/// upstream's `detect_text` does for HTML/CSS.
class Scanner {
  Scanner({
    Set<String>? only,
    Set<String>? ignore,
    Target target = Target.phone,
    this.design,
  })  : only = only ?? const {},
        ignore = ignore ?? const {},
        profile = Profile(target);

  final Set<String> only;
  final Set<String> ignore;
  final Profile profile;

  /// The project's declared tokens. Null leaves the design-system rules
  /// silent, which is the right default: a project with no DESIGN.md has
  /// nothing for a value to be outside of.
  final DesignSystem? design;

  List<Finding> scanSource(String path, String text) {
    final src = DartSource.parse(path, text);
    final out = <Finding>[];
    final seen = <String>{};

    void emit(String ruleId, int line, {String? detail, String? snippet}) {
      final rule = kRulesById[ruleId];
      if (rule == null) {
        throw StateError('rule "$ruleId" fired but is not in the registry');
      }
      if (!rule.appliesTo(profile.target)) return;
      if (only.isNotEmpty && !only.contains(ruleId)) return;
      if (ignore.contains(ruleId)) return;
      if (src.isWaived(line, ruleId)) return;
      // One finding per rule per line; a rule that matches twice on a line is
      // one problem to the reader.
      if (!seen.add('$ruleId:$line')) return;
      out.add(Finding(
        rule: rule,
        file: path,
        line: line,
        snippet: snippet ?? src.lineText(line),
        detail: detail,
      ));
    }

    for (final check in kChecks) {
      check(src, profile, design, emit);
    }
    out.sort((a, b) {
      final byLine = a.line.compareTo(b.line);
      return byLine != 0 ? byLine : a.rule.id.compareTo(b.rule.id);
    });
    return out;
  }

  List<Finding> scanPaths(List<String> paths) {
    final out = <Finding>[];
    for (final path in paths) {
      for (final file in _dartFilesUnder(path)) {
        out.addAll(scanSource(file.path, file.readAsStringSync()));
      }
    }
    return out;
  }

  Iterable<File> _dartFilesUnder(String path) sync* {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      if (path.endsWith('.dart')) yield File(path);
      return;
    }
    if (type != FileSystemEntityType.directory) return;
    final entries = Directory(path).listSync(recursive: true, followLinks: false);
    for (final e in entries) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final p = e.path;
      // Generated and vendored code is not the author's design work.
      if (p.contains('/.dart_tool/') ||
          p.contains('/build/') ||
          p.contains('/.pub-cache/') ||
          p.endsWith('.g.dart') ||
          p.endsWith('.freezed.dart')) {
        continue;
      }
      yield e;
    }
  }
}

/// Counts by severity, for the report header.
Map<String, int> severityCounts(List<Finding> findings) {
  final out = <String, int>{'error': 0, 'warning': 0, 'advisory': 0};
  for (final f in findings) {
    out[f.rule.severity.name] = (out[f.rule.severity.name] ?? 0) + 1;
  }
  return out;
}
