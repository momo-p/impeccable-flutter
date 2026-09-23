// Third slop fixture: the marketing-shaped screen, covering the second wave of
// ported rules. Deliberately bad; this file exists to be flagged.
import 'package:flutter/material.dart';

class SlopMarketing extends StatefulWidget {
  const SlopMarketing({super.key});

  @override
  State<SlopMarketing> createState() => _SlopMarketingState();
}

class _SlopMarketingState extends State<SlopMarketing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(
        decoration: BoxDecoration(
          // Warm off-white reached for by reflex.
          color: const Color(0xFFF5F0E6),
          // A hairline edge and a wide soft shadow: two answers to one question.
          border: Border.all(width: 1, color: const Color(0xFFE5E5E5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF8B5CF6), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(fontSize: 12, letterSpacing: 2),
                    ),
                  ),
                  const Text(
                    'Beautifully made',
                    style: TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 48,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Gray text dropped on a saturated surface.
            Container(
              color: const Color(0xFF2E5AAC),
              child: const Text(
                'Trusted by teams everywhere',
                style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
              ),
            ),

            // Running text opened up like a caps label.
            const Text(
              'Your files stay where you put them, always.',
              style: TextStyle(fontSize: 16, letterSpacing: 1.6),
            ),

            // The same label pasted twice and never filled in.
            const Text('Import your data'),
            const Text('Import your data'),

            // A screen numbering its own chapters.
            const Text('01'),
            const Text('Import'),
            const Text('02'),
            const Text('Review'),

            // The rebuttal cadence, three times over.
            const Text('Not a database. Just your files.'),
            const Text('No accounts. Just a link.'),
            const Text('Not magic. It is plain sync.'),
            const Text('Most security theater ends here.'),

            // Liveness simulated rather than reported.
            FadeTransition(
              opacity: _loop,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
            FadeTransition(opacity: _loop, child: const Text('|')),
            SlideTransition(
              position: _loop.drive(Tween(begin: Offset.zero, end: const Offset(-1, 0))),
              child: const Text('logos scrolling forever'),
            ),

            // Stripes as surface decoration.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  tileMode: TileMode.repeated,
                  colors: [Color(0xFF101010), Color(0xFF181818)],
                ),
              ),
              child: SizedBox(height: 4),
            ),

            // Functional text under the legibility floor.
            TextButton(
              onPressed: () {},
              child: const Text('Save', style: TextStyle(fontSize: 11)),
            ),

            // Web-only: an image that moves under the pointer.
            MouseRegion(
              onEnter: (_) {},
              onExit: (_) {},
              child: AnimatedScale(
                scale: 1.05,
                duration: const Duration(milliseconds: 200),
                child: Image.asset('assets/hero.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
