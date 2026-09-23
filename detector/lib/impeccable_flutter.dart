/// Deterministic design detector for Flutter source.
///
/// The rule catalog carries over pbakaus/impeccable's registry where a rule
/// survives the move from a rendered DOM to Dart source, and adds the Flutter
/// platform rules the web engine has no place for. See `lib/src/registry.dart`.
library;

export 'src/baseline.dart';
export 'src/colors.dart' show Rgb, contrastRatio, parseColor;
export 'src/context.dart';
export 'src/pubspec.dart';
export 'src/design_system.dart';
export 'src/finding.dart';
export 'src/fixes.dart';
export 'src/registry.dart';
export 'src/scanner.dart';
export 'src/signals.dart';
export 'src/target.dart';
export 'src/source.dart' show DartSource, StringLiteral, WidgetCall;
