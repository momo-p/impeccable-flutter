import 'dart:io';

import 'target.dart';

/// What a Flutter project already is, before anyone is asked a question.
///
/// The init flow branches on this. A project that already ships an Android TV
/// launcher intent does not need to be asked whether it targets TV, and a
/// project with a real theme file does not need to be walked through building
/// one. Asking about what is already on disk is how a setup flow wastes
/// someone's time.
class Signals {
  Signals({
    required this.root,
    required this.projectName,
    required this.hasPubspec,
    required this.platforms,
    required this.inferredTarget,
    required this.hasProduct,
    required this.hasDesign,
    required this.designPath,
    required this.themeFiles,
    required this.dartFiles,
    required this.screenFiles,
    required this.hasBaseline,
  });

  final String root;
  final String? projectName;
  final bool hasPubspec;

  /// Platform folders present: android, ios, web, linux, macos, windows.
  final List<String> platforms;

  /// The target the project looks like it ships to, or null when it is
  /// ambiguous and the user has to say.
  final Target? inferredTarget;

  final bool hasProduct;
  final bool hasDesign;
  final String? designPath;

  /// Files that define ThemeData / ColorScheme / TextTheme.
  final List<String> themeFiles;

  final int dartFiles;

  /// Files containing a Scaffold: a rough count of screens.
  final int screenFiles;

  final bool hasBaseline;

  bool get isGreenfield => dartFiles <= 1 && themeFiles.isEmpty;
  bool get hasTheme => themeFiles.isNotEmpty;

  Map<String, Object?> toJson() => {
        'root': root,
        'projectName': projectName,
        'hasPubspec': hasPubspec,
        'platforms': platforms,
        'inferredTarget': inferredTarget?.name,
        'setup': {
          'hasProductMd': hasProduct,
          'hasDesignMd': hasDesign,
          'designPath': designPath,
          'hasTheme': hasTheme,
          'themeFiles': themeFiles,
          'hasBaseline': hasBaseline,
        },
        'code': {
          'dartFiles': dartFiles,
          'screenFiles': screenFiles,
          'greenfield': isGreenfield,
        },
      };

  static Signals gather(String root) {
    final dir = Directory(root);
    final pubspec = File('$root/pubspec.yaml');
    String? name;
    if (pubspec.existsSync()) {
      final m = RegExp(r'^name:\s*(\S+)', multiLine: true)
          .firstMatch(pubspec.readAsStringSync());
      name = m?[1];
    }

    final platforms = <String>[];
    for (final p in const ['android', 'ios', 'web', 'linux', 'macos', 'windows']) {
      if (Directory('$root/$p').existsSync()) platforms.add(p);
    }

    final design = _firstExisting(root, const ['DESIGN.md', 'design.md', 'docs/DESIGN.md']);
    final product = _firstExisting(root, const ['PRODUCT.md', 'docs/PRODUCT.md']);

    final themeFiles = <String>[];
    var dartFiles = 0;
    var screenFiles = 0;
    final lib = Directory('$root/lib');
    if (lib.existsSync()) {
      for (final e in lib.listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        if (e.path.endsWith('.g.dart') || e.path.endsWith('.freezed.dart')) continue;
        dartFiles++;
        final text = e.readAsStringSync();
        if (RegExp(r'\b(ThemeData|ColorScheme|TextTheme)\s*\(').hasMatch(text)) {
          themeFiles.add(e.path.substring(root.length + 1));
        }
        if (text.contains('Scaffold(')) screenFiles++;
      }
    }

    return Signals(
      root: dir.absolute.path,
      projectName: name,
      hasPubspec: pubspec.existsSync(),
      platforms: platforms,
      inferredTarget: _inferTarget(root, platforms),
      hasProduct: product != null,
      hasDesign: design != null,
      designPath: design,
      themeFiles: themeFiles,
      dartFiles: dartFiles,
      screenFiles: screenFiles,
      hasBaseline: File('$root/.impeccable-baseline.json').existsSync(),
    );
  }

  static String? _firstExisting(String root, List<String> names) {
    for (final n in names) {
      if (File('$root/$n').existsSync()) return n;
    }
    return null;
  }

  /// An Android TV app declares a LEANBACK_LAUNCHER intent; nothing else does.
  /// That is a fact on disk, so the init flow should read it rather than ask.
  static Target? _inferTarget(String root, List<String> platforms) {
    final manifest = File('$root/android/app/src/main/AndroidManifest.xml');
    if (manifest.existsSync() &&
        manifest.readAsStringSync().contains('LEANBACK_LAUNCHER')) {
      return Target.tv;
    }
    final mobile = platforms.contains('android') || platforms.contains('ios');
    if (mobile) return Target.phone;
    if (platforms.contains('web')) return Target.web;
    return null;
  }
}
