/// The little bit of domain the screens read from.
class Entry {
  const Entry({
    required this.title,
    required this.note,
    required this.poster,
    this.progress,
  });

  final String title;
  final String note;
  final String poster;

  /// How far in, from 0 to 1. Null means never started.
  final double? progress;
}
