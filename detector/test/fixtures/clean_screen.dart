// The negative fixture: a screen built against the skill. The detector must
// report nothing here. A rule that fires on this file is a false positive.
import 'package:flutter/material.dart';

class CleanScreen extends StatelessWidget {
  const CleanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 600;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Text('Your account', style: theme.textTheme.displaySmall),
                const SizedBox(height: 12),
                Text(
                  'Signed in as you@example.com.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Semantics(
                  button: true,
                  label: 'Manage storage',
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Storage', style: theme.textTheme.titleMedium),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                if (wide)
                  Text('Two-column layout', style: theme.textTheme.labelSmall),
              ],
            );
          },
        ),
      ),
    );
  }
}
