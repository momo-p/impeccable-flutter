import 'dart:io';

import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:impeccable_flutter/impeccable_flutter.dart' as impeccable;

/// Surfaces the detector's findings as IDE diagnostics.
///
/// The detector itself stays dependency-free and knows nothing about the
/// analyzer; this package is the only thing that bridges the two. That
/// separation is deliberate — the compiled binary has to keep working with no
/// pub fetch, and the analyzer's dependency tree is the opposite of that.
class ImpeccableFlutterPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // Every rule is registered; each decides per file whether it applies,
    // because one analysis session can span projects with different targets.
    return [for (final rule in impeccable.kRules) _ImpeccableRule(rule, configs)];
  }

  /// The target a file should be judged against.
  ///
  /// Inferred from the project itself, exactly as `impeccable-flutter signals`
  /// does: an Android TV app declares a LEANBACK_LAUNCHER intent and nothing
  /// else does. That means a TV project gets its focus rules in the IDE with
  /// no configuration, which matters because a TV build judged as a phone
  /// build passes checks it should fail.
  ///
  /// Override in `analysis_options.yaml` when the inference is wrong:
  ///
  /// ```yaml
  /// custom_lint:
  ///   rules:
  ///     - impeccable_target:
  ///         target: tv
  /// ```
  static impeccable.Target targetFor(String path, [CustomLintConfigs? configs]) {
    final configured = configs?.rules['impeccable_target']?.json['target'];
    if (configured is String) {
      final parsed = impeccable.Target.parse(configured);
      if (parsed != null) return parsed;
    }
    return impeccable.Signals.gather(_projectRoot(path)).inferredTarget ??
        impeccable.Target.phone;
  }

  /// Walks up to the directory holding pubspec.yaml.
  static String _projectRoot(String path) {
    var dir = Directory(path);
    if (FileSystemEntity.isFileSync(path)) dir = File(path).parent;
    for (var i = 0; i < 8; i++) {
      if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return dir.path;
  }
}

class _ImpeccableRule extends DartLintRule {
  _ImpeccableRule(this.rule, this.configs)
      : super(
          code: LintCode(
            name: rule.id,
            problemMessage: rule.name,
            correctionMessage: rule.description,
            errorSeverity: _severityOf(rule.severity),
          ),
        );

  final impeccable.Rule rule;
  final CustomLintConfigs? configs;

  static analyzer.ErrorSeverity _severityOf(impeccable.Severity s) =>
      switch (s) {
        impeccable.Severity.error => analyzer.ErrorSeverity.WARNING,
        impeccable.Severity.warning => analyzer.ErrorSeverity.INFO,
        impeccable.Severity.advisory => analyzer.ErrorSeverity.INFO,
      };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.path;
    final content = resolver.source.contents.data;
    final target = ImpeccableFlutterPlugin.targetFor(path, configs);
    if (!rule.appliesTo(target)) return;

    // The project context is resolved per file so a monorepo with more than
    // one app still checks each against its own DESIGN.md and pubspec.
    final scanner = impeccable.Scanner(
      only: {rule.id},
      target: target,
      context: impeccable.ProjectContext.discover(path),
    );

    for (final finding in scanner.scanSource(path, content)) {
      final line = finding.line;
      if (line < 1 || line > resolver.lineInfo.lineCount) continue;

      // Findings carry a line, not an offset. Underlining the whole line is
      // the honest rendering: a design finding is about the line, not about
      // one token in it.
      final start = resolver.lineInfo.getOffsetOfLine(line - 1);
      final end = line < resolver.lineInfo.lineCount
          ? resolver.lineInfo.getOffsetOfLine(line) - 1
          : content.length;

      final trimmedStart = _firstNonSpace(content, start, end);
      reporter.atOffset(
        offset: trimmedStart,
        length: (end - trimmedStart).clamp(1, content.length - trimmedStart),
        errorCode: code,
        arguments: const [],
      );
    }
  }

  static int _firstNonSpace(String content, int start, int end) {
    var i = start;
    while (i < end && (content[i] == ' ' || content[i] == '\t')) {
      i++;
    }
    return i;
  }
}
