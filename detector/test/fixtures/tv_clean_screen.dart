// The TV negative fixture: the same screen built for a remote. Overscan
// margin, focus on entry, a visible focus state, and type sized for three
// metres. The detector must stay silent on this file under --target tv.
import 'package:flutter/material.dart';

class TvCleanHome extends StatelessWidget {
  const TvCleanHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        // TV panels crop the outer band; this is the 5% margin at 1920x1080.
        padding: const EdgeInsets.all(48),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Continue watching', style: theme.textTheme.displaySmall),
              const SizedBox(height: 32),
              const _Tile(label: 'Season 2, Episode 4', autofocus: true),
              const SizedBox(height: 24),
              const _Tile(label: 'Browse all'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.label, this.autofocus = false});

  final String label;
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
            border: Border.fromBorderSide(
              BorderSide(
                color: _focused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(widget.label, style: theme.textTheme.titleMedium),
          ),
        ),
      ),
    );
  }
}
