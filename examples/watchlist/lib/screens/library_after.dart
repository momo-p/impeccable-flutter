// The same screen built against the skill. The detector reports nothing here,
// on any target, and every colour and size comes from the theme.
//
// Passing the rules is the floor, not the design. What carries this screen is
// the artwork leading, a serif for titles against a grotesque for everything
// else, and a rhythm that groups rather than spaces evenly: one resumable film
// given room, the rest as a rail you flick through.
import 'package:flutter/material.dart';

import '../models.dart';

class LibraryAfter extends StatelessWidget {
  const LibraryAfter({super.key, required this.entries});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) return const Scaffold(body: SafeArea(child: _Empty()));

    final resuming = entries.where((e) => e.progress != null).toList();
    final saved = entries.where((e) => e.progress == null).toList();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Branching on the space this widget was given, never on the
            // window size, so split view and foldables work for free.
            final wide = constraints.maxWidth >= 600;
            return ListView(
              padding: EdgeInsets.fromLTRB(wide ? 48 : 24, 32, wide ? 48 : 24, 48),
              children: [
                Text('Watchlist', style: theme.textTheme.displaySmall),
                const SizedBox(height: 4),
                Text(
                  '${entries.length} films',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (resuming.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _SectionHeading('Continue watching'),
                  const SizedBox(height: 12),
                  _ResumeCard(entry: resuming.first),
                ],
                if (saved.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  _SectionHeading('Saved'),
                  const SizedBox(height: 12),
                  _SavedRail(entries: saved),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleLarge);
}

/// The one film you are part-way through, given the room to be picked up.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Resume ${entry.title}',
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(entry: entry, width: 124),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.note,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.progress,
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything else, as artwork you flick through rather than a list to read.
class _SavedRail extends StatelessWidget {
  const _SavedRail({required this.entries});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 268,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final entry = entries[i];
          return Semantics(
            button: true,
            label: 'Open ${entry.title}',
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Poster(entry: entry, width: 132),
                    const SizedBox(height: 12),
                    Text(
                      entry.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Poster art at a real 2:3, decoded at the size it is drawn.
class _Poster extends StatelessWidget {
  const _Poster({required this.entry, required this.width});

  final Entry entry;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = width * 3 / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        entry.poster,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: (width * 2).round(),
        errorBuilder: (context, error, stack) => ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: SizedBox(width: width, height: height),
        ),
      ),
    );
  }
}

/// The screen a new user sees first, so it says what goes there and how.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nothing saved yet', style: theme.textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(
              'Films you save turn up here, ready for the evening.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {},
              child: const Text('Find something to watch'),
            ),
          ],
        ),
      ),
    );
  }
}
