// A TV screen built as if it were a phone screen. Every focus rule fires here.
// Deliberately bad; this file exists to be flagged under --target tv.
import 'package:flutter/material.dart';

class TvHome extends StatelessWidget {
  const TvHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // No Focus around it: a remote cannot reach this at all.
            GestureDetector(
              onTap: () {},
              child: const Text('Continue watching'),
            ),
            // Focusable, but nothing in the subtree reacts to focus, so the
            // user cannot see where the ring is.
            Focus(
              child: Container(
                color: Colors.black,
                child: const Text('Browse'),
              ),
            ),
            // Hover with no focus equivalent: dead on a remote.
            MouseRegion(
              onEnter: (_) {},
              child: const Text('Settings'),
            ),
            // Readable at arm's length, a blur at three metres.
            const Text('Season 2', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
