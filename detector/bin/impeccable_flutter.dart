import 'dart:convert';
import 'dart:io';

import 'package:impeccable_flutter/impeccable_flutter.dart';

const _usage = '''
impeccable-flutter — deterministic design detector for Flutter source

  impeccable-flutter detect [options] <paths…>
  impeccable-flutter rules [--json]

Options
  --json              Machine-readable findings
  --format <kind>     text (default) or github (inline PR annotations)
  --only <ids>        Comma-separated rule ids to run
  --ignore <ids>      Comma-separated rule ids to skip
  --baseline <path>   Suppress findings recorded in this file; report only new ones
  --write-baseline    Record every current finding to --baseline and exit 0
  --design <path>     DESIGN.md to check against (default: discovered by
                      walking up from the scanned path)
  --target <surface>  phone (default) | tablet | tv | web — changes which
                      rules apply and the thresholds they use
  --fail-on <level>   Exit 1 at or above this severity: error|warning|advisory

Waivers
  // impeccable-disable[: rule-id,…]        waives the next line, or its own
  // impeccable-disable-file                waives the whole file
''';

void main(List<String> argv) {
  if (argv.isEmpty) {
    stdout.write(_usage);
    exit(64);
  }

  final command = argv.first;
  final rest = argv.skip(1).toList();
  final json = rest.remove('--json');

  Set<String> listOpt(String name) {
    final i = rest.indexOf(name);
    if (i == -1 || i + 1 >= rest.length) return {};
    final value = rest.removeAt(i + 1);
    rest.removeAt(i);
    return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  }

  String? stringOpt(String name) {
    final i = rest.indexOf(name);
    if (i == -1 || i + 1 >= rest.length) return null;
    final value = rest.removeAt(i + 1);
    rest.removeAt(i);
    return value;
  }

  switch (command) {
    case 'rules':
      _printRules(json);
    case 'detect':
      final only = listOpt('--only');
      final ignore = listOpt('--ignore');
      final failOn = stringOpt('--fail-on');
      final format = stringOpt('--format') ?? 'text';
      if (format != 'text' && format != 'github') {
        stderr.writeln('--format: expected text or github, got "$format"');
        exit(64);
      }
      final baselinePath = stringOpt('--baseline');
      final writeBaseline = rest.remove('--write-baseline');
      final designPath = stringOpt('--design');
      final targetName = stringOpt('--target') ?? 'phone';
      final target = Target.parse(targetName);
      if (target == null) {
        stderr.writeln('--target: expected phone|tablet|tv|web, got "$targetName"');
        exit(64);
      }
      final paths = rest.where((a) => !a.startsWith('-')).toList();
      if (paths.isEmpty) {
        stderr.writeln('detect: no paths given');
        exit(64);
      }
      _detect(paths,
          only: only,
          ignore: ignore,
          json: json,
          failOn: failOn,
          target: target,
          designPath: designPath,
          baselinePath: baselinePath,
          writeBaseline: writeBaseline,
          format: format);
    default:
      stdout.write(_usage);
      exit(64);
  }
}

void _printRules(bool asJson) {
  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({
      'count': kRules.length,
      'rules': [
        for (final r in kRules)
          {
            'id': r.id,
            'category': r.category.name,
            'severity': r.severity.name,
            'name': r.name,
            'description': r.description,
            if (r.portOf != null) 'portOf': r.portOf,
            if (r.targets != null)
              'targets': [for (final t in r.targets!) t.name],
            if (r.section != null) 'section': r.section,
          }
      ],
    }));
    return;
  }
  for (final category in Category.values) {
    final rows = kRules.where((r) => r.category == category);
    if (rows.isEmpty) continue;
    stdout.writeln('\n${category.name} (${rows.length})');
    for (final r in rows) {
      final port = r.portOf == null ? 'flutter-only' : 'ports ${r.portOf}';
      final scope = r.targets == null
          ? ''
          : '  [${r.targets!.map((t) => t.name).join(", ")}]';
      stdout.writeln(
          '  ${r.id.padRight(28)} ${r.severity.name.padRight(9)} $port$scope');
    }
  }
  stdout.writeln('\n${kRules.length} rules total.');
}

void _detect(
  List<String> paths, {
  required Set<String> only,
  required Set<String> ignore,
  required bool json,
  required Target target,
  String? failOn,
  String? designPath,
  String? baselinePath,
  bool writeBaseline = false,
  String format = 'text',
}) {
  final design = designPath != null
      ? DesignSystem.parse(File(designPath).readAsStringSync(), path: designPath)
      : DesignSystem.discover(paths.first);
  final all =
      Scanner(only: only, ignore: ignore, target: target, design: design)
          .scanPaths(paths);

  if (writeBaseline) {
    final path = baselinePath ?? '.impeccable-baseline.json';
    Baseline.fromFindings(all).save(path);
    stdout.writeln('Recorded ${all.length} findings to $path.');
    stdout.writeln('Delete an entry once it is fixed; nothing re-adds it.');
    return;
  }

  var findings = all;
  if (baselinePath != null) {
    if (!File(baselinePath).existsSync()) {
      stderr.writeln('--baseline: $baselinePath does not exist. '
          'Create it with --write-baseline.');
      exit(66);
    }
    final baseline = Baseline.load(baselinePath);
    findings = baseline.filter(all);
    final stale = baseline.staleAgainst(all);
    if (stale.isNotEmpty && !json) {
      stdout.writeln('${stale.length} baseline '
          '${stale.length == 1 ? "entry no longer occurs" : "entries no longer occur"}; '
          're-run with --write-baseline to prune.');
    }
  }

  if (json) {
    stdout.writeln(const JsonEncoder.withIndent('  ')
        .convert({'findings': [for (final f in findings) f.toJson()]}));
  } else if (format == 'github') {
    // GitHub reads these off stdout and pins them to the diff.
    for (final f in findings) {
      final level = f.rule.severity == Severity.error ? 'error' : 'warning';
      final detail = f.detail == null ? '' : ' (${f.detail})';
      final message = '${f.rule.name}$detail — ${f.rule.description}'
          .replaceAll('\n', ' ')
          .replaceAll('%', '%25')
          .replaceAll('\r', '');
      stdout.writeln('::$level file=${f.file},line=${f.line},'
          'title=impeccable-flutter ${f.rule.id}::$message');
    }
    stdout.writeln('${findings.length} findings.');
  } else if (findings.isEmpty) {
    stdout.writeln('No findings.');
  } else {
    String? currentFile;
    for (final f in findings) {
      if (f.file != currentFile) {
        currentFile = f.file;
        stdout.writeln('\n$currentFile');
      }
      final detail = f.detail == null ? '' : '  (${f.detail})';
      stdout.writeln('  ${f.line.toString().padLeft(4)}  '
          '${f.rule.severity.name.padRight(9)}${f.rule.id.padRight(28)}'
          '${f.rule.name}$detail');
    }
    final counts = severityCounts(findings);
    stdout.writeln('\n${findings.length} findings  ·  '
        '${counts['error']} error, ${counts['warning']} warning, '
        '${counts['advisory']} advisory');
  }

  if (failOn != null) {
    const order = ['advisory', 'warning', 'error'];
    final floor = order.indexOf(failOn);
    if (floor == -1) {
      stderr.writeln('--fail-on: expected error|warning|advisory, got "$failOn"');
      exit(64);
    }
    final tripped =
        findings.any((f) => order.indexOf(f.rule.severity.name) >= floor);
    if (tripped) exit(1);
  }
}
