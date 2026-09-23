import 'dart:io';

/// The declarations in `pubspec.yaml` that widget code depends on at runtime.
///
/// Flutter resolves both silently. A `fontFamily` that was never declared
/// falls back to the platform face with no warning, and an `Image.asset` path
/// that was never declared throws only when that widget builds. Neither shows
/// up in `flutter analyze`, and neither is visible in the Dart source alone —
/// which is exactly why the detector has to read this file.
///
/// Parsed by hand rather than with a YAML package: the two blocks needed here
/// are a flat list each, and the detector stays dependency-free so the
/// compiled binary keeps working with no pub fetch.
class Pubspec {
  Pubspec({
    required this.path,
    required this.fontFamilies,
    required this.assetEntries,
    required this.declaresFlutter,
  });

  final String path;

  /// Families from `flutter: fonts: - family: X`.
  final Set<String> fontFamilies;

  /// Entries from `flutter: assets:`. A trailing slash means a directory,
  /// which covers every file directly inside it.
  final List<String> assetEntries;

  /// Whether the file has a `flutter:` section at all. A package without one
  /// declares no assets by design, so the asset rule stands down.
  final bool declaresFlutter;

  bool declaresFont(String family) => fontFamilies
      .map(_normalize)
      .contains(_normalize(family));

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  /// Whether [assetPath] is covered by a declared entry, directly or through
  /// a declared directory.
  bool declaresAsset(String assetPath) {
    for (final entry in assetEntries) {
      if (entry == assetPath) return true;
      if (entry.endsWith('/') && assetPath.startsWith(entry)) {
        // A directory entry covers files directly inside it, not deeper ones.
        final rest = assetPath.substring(entry.length);
        if (!rest.contains('/')) return true;
      }
    }
    return false;
  }

  static Pubspec? discover(String start) {
    var dir = Directory(start).absolute;
    if (FileSystemEntity.isFileSync(start)) {
      dir = File(start).absolute.parent;
    }
    for (var i = 0; i < 8; i++) {
      final file = File('${dir.path}/pubspec.yaml');
      if (file.existsSync()) {
        return parse(file.readAsStringSync(), path: file.path);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  static Pubspec parse(String yaml, {String path = 'pubspec.yaml'}) {
    final families = <String>{};
    final assets = <String>[];
    var declaresFlutter = false;

    // `assets:` and `fonts:` both appear under `flutter:`, and `fonts:` also
    // appears nested under each family. Tracking the active block by its own
    // indent is enough to keep the two apart without a real YAML parse.
    String? block;
    var blockIndent = 0;

    for (final raw in yaml.split('\n')) {
      final line = raw.replaceAll('\t', '  ');
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final indent = line.length - line.trimLeft().length;
      final trimmed = line.trim();

      if (indent == 0) {
        block = null;
        if (trimmed == 'flutter:') declaresFlutter = true;
        continue;
      }

      if (block != null && indent <= blockIndent && !trimmed.startsWith('-')) {
        block = null;
      }

      if (trimmed == 'assets:') {
        block = 'assets';
        blockIndent = indent;
        continue;
      }
      if (trimmed == 'fonts:') {
        // Two different `fonts:` keys exist: the top-level list of families,
        // and a nested one under each family listing its weight files. The
        // nested one is deeper, so entering the block only on the first
        // keeps `- family:` lines flowing while `- asset:` lines are ignored.
        if (block != 'families') {
          block = 'families';
          blockIndent = indent;
        }
        continue;
      }

      if (block == 'assets' && trimmed.startsWith('- ')) {
        assets.add(_unquote(trimmed.substring(2).trim()));
        continue;
      }
      if (block == 'families') {
        final m = RegExp(r'^-?\s*family:\s*(.+)$').firstMatch(trimmed);
        if (m != null) families.add(_unquote(m[1]!.trim()));
      }
    }

    return Pubspec(
      path: path,
      fontFamilies: families,
      assetEntries: assets,
      declaresFlutter: declaresFlutter,
    );
  }

  static String _unquote(String s) {
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}

