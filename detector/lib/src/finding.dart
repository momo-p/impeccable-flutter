import 'target.dart';

/// The finding shape mirrors upstream impeccable's `foundation::findings::Finding`
/// (`antipattern, name, description, severity, category, file, line, snippet`)
/// so reports read the same whether they came from the web engine or this one.
class Finding {
  Finding({
    required this.rule,
    required this.file,
    required this.line,
    required this.snippet,
    this.detail,
  });

  final Rule rule;
  final String file;
  final int line;
  final String snippet;

  /// The measured value that tripped the rule, e.g. `fontSize: 72`.
  final String? detail;

  bool get advisory => rule.severity == Severity.advisory;

  Map<String, Object?> toJson() => {
        'antipattern': rule.id,
        'name': rule.name,
        'description': rule.description,
        'severity': rule.severity.name,
        'category': rule.category.name,
        'file': file,
        'line': line,
        'snippet': snippet,
        if (detail != null) 'detail': detail,
        'advisory': advisory,
        if (rule.portOf != null) 'portOf': rule.portOf,
      };
}

enum Severity { error, warning, advisory }

/// `slop` is a taste failure, `quality` is a defect a user feels, `platform`
/// is a Flutter/Material/HIG contract this codebase breaks. The third is new
/// here: the web engine has no platform layer to violate.
enum Category { slop, quality, platform }

class Rule {
  const Rule({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    this.severity = Severity.warning,
    this.portOf,
    this.section,
    this.targets,
  });

  final String id;
  final Category category;
  final Severity severity;
  final String name;
  final String description;

  /// The upstream impeccable rule id this one is a Flutter port of, when the
  /// web engine has an equivalent. Null means the rule is Flutter-only.
  final String? portOf;

  /// The reference playbook section that explains the fix.
  final String? section;

  /// The targets this rule applies to. Null means every target: most design
  /// failures are failures everywhere. A non-null set is for rules that only
  /// make sense given a particular input model, such as a D-pad.
  final Set<Target>? targets;

  bool appliesTo(Target target) => targets == null || targets!.contains(target);
}
