import 'dart:io';

import 'package:test/test.dart';

/// The skill tells an agent which command to run. If that command does not
/// work from a real Flutter project, every instruction downstream of it fails.
/// That is what shipped once: `dart run impeccable_flutter` resolves against
/// the *calling* project's dependencies, not this package's.
void main() {
  final skillDir = Directory('../skills/impeccable-flutter');
  final launcher = File('${skillDir.path}/scripts/impeccable-flutter');

  List<File> skillDocs() => skillDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  test('the skill ships its launcher', () {
    expect(launcher.existsSync(), isTrue,
        reason: 'the skill references scripts/impeccable-flutter');
    final mode = launcher.statSync().mode;
    expect(mode & 0x40, isNot(0), reason: 'launcher must be executable by owner');
  });

  test('the launcher resolves the repo root from its own location', () {
    final body = launcher.readAsStringSync();
    // It is copied into ~/.claude/skills and symlinked onto PATH, so neither
    // the working directory nor $0 being a symlink may break it.
    expect(body, contains('readlink'));
    expect(body, contains(r'dirname'));
  });

  test('no skill doc prescribes a command that needs this package as a dep', () {
    final offenders = <String>[];
    for (final doc in skillDocs()) {
      final text = doc.readAsStringSync();
      for (final line in text.split('\n')) {
        if (line.contains('dart run impeccable_flutter') ||
            line.contains('dart run bin/impeccable_flutter.dart')) {
          offenders.add('${doc.path}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'these only work from inside detector/; use the launcher');
  });

  test('every documented subcommand and flag exists in the CLI', () {
    final cli = File('bin/impeccable_flutter.dart').readAsStringSync();
    final documented = <String>{};
    for (final doc in skillDocs()) {
      for (final m in RegExp(r'impeccable-flutter\s+(\w+)([^\n`]*)')
          .allMatches(doc.readAsStringSync())) {
        documented.add(m[1]!);
        for (final f in RegExp(r'--[a-z-]+').allMatches(m[2]!)) {
          documented.add(f[0]!);
        }
      }
    }
    expect(documented, isNotEmpty, reason: 'the docs should show real commands');
    for (final token in documented) {
      expect(cli, contains("'$token'"),
          reason: '$token is documented but the CLI does not handle it');
    }
  });
  test('the launcher can find a detector from a copied skill', () {
    // The skill installs two ways: symlinked at ~/.claude/skills, or copied
    // into <project>/.claude/skills. A copy has no detector above it, so the
    // launcher has to fall back to PATH. An earlier version did not, so the
    // documented project-scope install simply did not work.
    final body = launcher.readAsStringSync();
    expect(body, contains('command -v impeccable-flutter'),
        reason: 'no PATH fallback, so a copied skill cannot find the detector');
    expect(body, contains(r'$onpath" != "$self'),
        reason: 'the PATH fallback must not re-exec this same script');
  });
}
