import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Deliberately bad. Every widget here trips at least one detector rule; this
/// file is the positive fixture for `make detect`. Do not "fix" it.
class SlopHome extends StatelessWidget {
  const SlopHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.6),
                blurRadius: 40,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Text(
                'WHY TEAMS SWITCH',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: 3,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
              const Text(
                'Seamless sync — effortless — always on',
                style: TextStyle(
                  fontSize: 72,
                  letterSpacing: -3.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              Card(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(width: 4, color: Color(0xFFEF4444)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt),
                      ),
                      const Text('Realtime'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
          child: Text(
            'Unlock the power of your workflow'.toUpperCase(),
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 9),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: InkWell(onTap: () {}, child: const Icon(Icons.share)),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () {}),
            CupertinoButton(
              onPressed: () {},
              child: const Text('Continue'),
            ),
          ],
        ),
        Image.network('https://example.invalid/hero.png'),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          width: 200,
          child: const Text('Growing box'),
        ),
      ],
    );
  }
}
