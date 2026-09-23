import 'design_system.dart';
import 'pubspec.dart';

/// What the detector knows about the project a file belongs to, beyond the
/// file itself. Both parts are optional: a rule that needs one stands down
/// when it is absent rather than guessing.
class ProjectContext {
  const ProjectContext({this.design, this.pubspec});

  /// Tokens declared in DESIGN.md, when the project has one.
  final DesignSystem? design;

  /// Fonts and assets declared in pubspec.yaml, when one was found.
  final Pubspec? pubspec;

  static const ProjectContext empty = ProjectContext();

  /// Finds both by walking up from [path].
  factory ProjectContext.discover(String path) => ProjectContext(
        design: DesignSystem.discover(path),
        pubspec: Pubspec.discover(path),
      );
}
