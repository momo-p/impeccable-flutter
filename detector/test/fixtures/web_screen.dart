// A Flutter web screen carrying the defaults the framework ships with.
// Deliberately bad under --target web; this file exists to be flagged.
import 'package:flutter/material.dart';

void main() {
  // No usePathUrlStrategy(), so every route lives under a # fragment.
  runApp(const WebApp());
}

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          // No SelectionArea, so none of this copy can be selected or copied.
          child: ListView(
            children: const [
              Text(
                'Everything you put here stays on your own machine and syncs '
                'only when you ask it to.',
              ),
              Text(
                'Changes land on your other devices within about a second, '
                'and queue up while you are offline.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
