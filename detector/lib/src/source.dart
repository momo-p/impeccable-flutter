/// A lightweight model of one Dart file.
///
/// Upstream impeccable's static path is regex over source text
/// (`detect/src/detect_text.rs`); the browser does the structural work. There
/// is no browser here, so the structure has to come from the source. This
/// masks comments and string bodies to a same-length blank run, which keeps
/// every offset aligned with the raw text while stopping a regex from matching
/// a widget name inside a doc comment.
class DartSource {
  DartSource._(this.path, this.text, this.masked, this.strings, this._lineStarts);

  factory DartSource.parse(String path, String text) {
    final mask = StringBuffer();
    final strings = <StringLiteral>[];
    var i = 0;
    final n = text.length;

    void blank(int count) => mask.write(' ' * count);

    while (i < n) {
      final c = text[i];
      final next = i + 1 < n ? text[i + 1] : '';

      if (c == '/' && next == '/') {
        final end = text.indexOf('\n', i);
        final stop = end == -1 ? n : end;
        blank(stop - i);
        i = stop;
        continue;
      }
      if (c == '/' && next == '*') {
        var depth = 1;
        var j = i + 2;
        while (j < n && depth > 0) {
          if (text.startsWith('/*', j)) {
            depth++;
            j += 2;
          } else if (text.startsWith('*/', j)) {
            depth--;
            j += 2;
          } else {
            j++;
          }
        }
        // Newlines inside the comment must survive so line numbers hold.
        for (var k = i; k < j; k++) {
          mask.write(text[k] == '\n' ? '\n' : ' ');
        }
        i = j;
        continue;
      }
      if (c == '"' || c == "'") {
        final raw = i > 0 && text[i - 1] == 'r';
        final triple = text.startsWith(c * 3, i);
        final quote = triple ? c * 3 : c;
        final start = i;
        var j = i + quote.length;
        final body = StringBuffer();
        while (j < n) {
          if (!raw && text[j] == r'\') {
            body.write(text[j]);
            j += 2;
            continue;
          }
          if (text.startsWith(quote, j)) {
            j += quote.length;
            break;
          }
          body.write(text[j]);
          j++;
        }
        strings.add(StringLiteral(start, body.toString()));
        for (var k = start; k < j && k < n; k++) {
          mask.write(text[k] == '\n' ? '\n' : ' ');
        }
        i = j;
        continue;
      }
      mask.write(c);
      i++;
    }

    return DartSource._(path, text, mask.toString(), strings, _computeLineStarts(text));
  }

  final String path;

  /// The file as written.
  final String text;

  /// Same length as [text], with comment and string-literal bodies blanked.
  final String masked;

  final List<StringLiteral> strings;
  final List<int> _lineStarts;

  static List<int> _computeLineStarts(String text) {
    final starts = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '\n') starts.add(i + 1);
    }
    return starts;
  }

  /// 1-indexed line for a character offset.
  int lineAt(int offset) {
    var lo = 0;
    var hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  String lineText(int line) {
    final start = _lineStarts[line - 1];
    final end = line < _lineStarts.length ? _lineStarts[line] - 1 : text.length;
    return text.substring(start, end).trim();
  }

  /// Lines the author waived with `// impeccable-disable[: rule-id,…]`, either
  /// on the offending line or the line above it, plus every line when the file
  /// carries `// impeccable-disable-file`. Mirrors upstream's inline ignores.
  late final Map<int, Set<String>?> waivers = _collectWaivers();

  late final bool fileWaived = RegExp(r'//\s*impeccable-disable-file\b').hasMatch(text);

  Map<int, Set<String>?> _collectWaivers() {
    final out = <int, Set<String>?>{};
    final re = RegExp(r'//\s*impeccable-disable(?:-next-line)?\s*(?::\s*([\w\-, /]+))?');
    for (final m in re.allMatches(text)) {
      if (text.startsWith('//', m.start) &&
          RegExp(r'impeccable-disable-file').hasMatch(m[0]!)) {
        continue;
      }
      final ids = m[1]
          ?.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      final line = lineAt(m.start);
      // A comment alone on its line waives the line below; a trailing comment
      // waives its own line.
      final onOwnLine = lineText(line).startsWith('//');
      out[onOwnLine ? line + 1 : line] = ids;
    }
    return out;
  }

  bool isWaived(int line, String ruleId) {
    if (fileWaived) return true;
    if (!waivers.containsKey(line)) return false;
    final ids = waivers[line];
    return ids == null || ids.isEmpty || ids.contains(ruleId);
  }

  /// Every `Identifier(` call whose name starts uppercase — in practice the
  /// widget and value constructors — with the source range of its argument
  /// list, nested innermost-last.
  late final List<WidgetCall> calls = _collectCalls();

  List<WidgetCall> _collectCalls() {
    final out = <WidgetCall>[];
    final re = RegExp(r'\b([A-Z][A-Za-z0-9_]*)(?:\.([a-z][A-Za-z0-9_]*))?\s*\(');
    for (final m in re.allMatches(masked)) {
      final open = m.end - 1;
      final close = _matchParen(open);
      if (close == null) continue;
      out.add(WidgetCall(
        name: m[1]!,
        constructor: m[2],
        start: m.start,
        argsStart: open + 1,
        end: close,
        source: this,
      ));
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  int? _matchParen(int open) {
    var depth = 0;
    for (var i = open; i < masked.length; i++) {
      final c = masked[i];
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }
}

class StringLiteral {
  const StringLiteral(this.offset, this.value);
  final int offset;
  final String value;
}

class WidgetCall {
  WidgetCall({
    required this.name,
    required this.constructor,
    required this.start,
    required this.argsStart,
    required this.end,
    required this.source,
  });

  final String name;

  /// The named constructor, e.g. `network` in `Image.network(...)`.
  final String? constructor;
  final int start;
  final int argsStart;
  final int end;
  final DartSource source;

  int get line => source.lineAt(start);

  /// The argument list, with comments and string bodies blanked.
  String get args => source.masked.substring(argsStart, end);

  /// The argument list as written.
  String get rawArgs => source.text.substring(argsStart, end);

  bool contains(WidgetCall other) =>
      other.start > start && other.end <= end;

  /// The value of a named argument of THIS call. Only a `name:` sitting at
  /// depth 0 of the argument list counts, so an outer widget never claims a
  /// nested one's arguments, and the value ends at the comma that closes it.
  String? arg(String name) {
    final re = RegExp(r'\b' + RegExp.escape(name) + r'\s*:');
    for (final m in re.allMatches(args)) {
      if (_depthAt(m.start) != 0) continue;
      var depth = 0;
      for (var i = m.end; i < args.length; i++) {
        final c = args[i];
        if (c == '(' || c == '[' || c == '{') depth++;
        if (c == ')' || c == ']' || c == '}') depth--;
        if (c == ',' && depth == 0) return args.substring(m.end, i).trim();
      }
      return args.substring(m.end).trim();
    }
    return null;
  }

  int _depthAt(int index) {
    var depth = 0;
    for (var i = 0; i < index; i++) {
      final c = args[i];
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') depth--;
    }
    return depth;
  }

  double? numArg(String name) {
    final v = arg(name);
    if (v == null) return null;
    return double.tryParse(v.trim());
  }

  @override
  String toString() => '$name${constructor == null ? '' : '.$constructor'}@$line';
}
