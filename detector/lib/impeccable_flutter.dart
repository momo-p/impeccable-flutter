/// Deterministic design detector for Flutter source.
///
/// The rule catalog carries over pbakaus/impeccable's registry where a rule
/// survives the move from a rendered DOM to Dart source, and adds the Flutter
/// platform rules the web engine has no place for. See `lib/src/registry.dart`.
library;

export 'src/colors.dart' show Rgb, contrastRatio, parseColor;
export 'src/finding.dart';
export 'src/registry.dart';
export 'src/scanner.dart';
export 'src/source.dart' show DartSource, WidgetCall;
