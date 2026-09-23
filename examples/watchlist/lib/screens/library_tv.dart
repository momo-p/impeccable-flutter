// The same watchlist on a television. The detector reports nothing here under
// `--target tv`, which is a different bar from the phone screen: no touch, a
// focus ring instead of a cursor, and a picture whose edges may be cropped.
import 'package:flutter/material.dart';

import '../models.dart';

class LibraryTv extends StatelessWidget {
  const LibraryTv({super.key, required this.entries});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        // TV panels crop the outer band. SafeArea does not know about this.
        padding: const EdgeInsets.all(48),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Continue watching', style: theme.textTheme.displaySmall),
              const SizedBox(height: 32),
              SizedBox(
                height: 400,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 24),
                  itemBuilder: (context, i) => _Tile(
                    entry: entries[i],
                    // Something takes focus on entry, or the first press of
                    // the remote does nothing and the app reads as frozen.
                    autofocus: i == 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.entry, this.autofocus = false});

  final Entry entry;
  final bool autofocus;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => null),
      },
      child: AnimatedScale(
        scale: _focused ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(
              BorderSide(
                // Scale alone is not enough across a room, and colour alone
                // fails for colour-blind viewers, so this does both.
                color: _focused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        widget.entry.poster,
                        width: 240,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        errorBuilder: (context, error, stack) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: const SizedBox(width: 240),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.entry.title,
                    // Sized for three metres, not arm's length.
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.note,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
