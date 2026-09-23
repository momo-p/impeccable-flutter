// The screen as a model reaches for it by default. Every finding here is real
// and the detector reports all of them. Kept so the difference is legible;
// `library_after.dart` is the same screen built against the skill.
import 'package:flutter/material.dart';

class LibraryBefore extends StatelessWidget {
  const LibraryBefore({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                  'YOUR LIBRARY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    letterSpacing: 3,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                const Text(
                  'Seamless viewing, effortlessly',
                  style: TextStyle(fontSize: 72, letterSpacing: -3.5, height: 1.0),
                ),
              ],
            ),
          ),
          Card(
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
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
                      child: const Icon(Icons.movie),
                    ),
                    const Text('Continue watching'),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: Text(
              'Unlock the power of your evenings'.toUpperCase(),
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
            ],
          ),
          Image.asset('assets/hero.png', width: 64, height: 64),
          ListView(children: const [Text('one'), Text('two')]),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            width: 200,
            child: const Text('Growing box'),
          ),
        ],
      ),
    );
  }
}
