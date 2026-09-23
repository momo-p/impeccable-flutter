// The same screen built against the skill. The detector reports nothing here,
// on any target. Every colour and size comes from the theme, which comes from
// DESIGN.md.
import 'package:flutter/material.dart';

import '../models.dart';

class LibraryAfter extends StatelessWidget {
  const LibraryAfter({super.key, required this.entries});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Watchlist', style: theme.textTheme.titleLarge)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Branching on the space this widget was given, never on the
            // window size, so split view and foldables work for free.
            final wide = constraints.maxWidth >= 600;
            return switch (entries.isEmpty) {
              true => const _Empty(),
              false => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _EntryRow(entry: entries[i], wide: wide),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.wide});

  final Entry entry;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Open ${entry.title}',
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  entry.poster,
                  width: 64,
                  height: 96,
                  // Decoded at the size it is drawn, not the size it ships at.
                  cacheWidth: 128,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const SizedBox(width: 64, height: 96),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.note,
                      style: theme.textTheme.bodyMedium,
                      maxLines: wide ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The screen a new user sees first, so it says what goes here and how.
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
              style: theme.textTheme.bodyMedium,
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
