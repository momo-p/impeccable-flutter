// A screen in a project that HAS a DESIGN.md, using values the document never
// declares. Deliberately off-system; this file exists to be flagged.
// Its sibling DESIGN.md is what the design-system rules check against.
import 'package:flutter/material.dart';

class OffSystem extends StatelessWidget {
  const OffSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Not the declared primary (#1B7F5C).
      color: const Color(0xFF6366F1),
      child: ClipRRect(
        // The radius scale is 4, 8, 12.
        borderRadius: BorderRadius.circular(20),
        child: Column(children: [
          // Declared nowhere under flutter: assets:.
          Image.asset('assets/missing.png'),
          const Text(
          'Off the system',
          style: TextStyle(
            // Neither declared face is Inter.
            fontFamily: 'Inter',
            // The ramp is 36, 24, 18, 16, 13.
            fontSize: 17,
            ),
          ),
        ]),
      ),
    );
  }
}
