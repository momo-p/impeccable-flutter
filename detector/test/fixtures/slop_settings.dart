// A second slop fixture, covering the rules the hero screen does not reach.
// Deliberately bad; this file exists to be flagged.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SlopSettings extends StatelessWidget {
  const SlopSettings({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width > 600) {
      return const _Wide();
    }
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: Column(
          children: [
            ShaderMask(
              shaderCallback: (r) =>
                  const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                      .createShader(r),
              child: const Text('Settings — tuned — for you'),
            ),
            Container(
              color: const Color(0xFFFFFFFF),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(width: 4, color: Color(0xFF8B5CF6))),
              ),
              child: const Text(
                'Everything — exactly — where you left it',
                style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
              ),
            ),
            const Text('Account', style: TextStyle(fontSize: 15)),
            const Text('Privacy', style: TextStyle(fontSize: 16)),
            const Text('Storage', style: TextStyle(fontSize: 17)),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            CupertinoSwitch(value: true, onChanged: (_) {}),
            ListView(children: const [Text('one'), Text('two')]),
          ],
        ),
      ),
    );
  }
}

class _Wide extends StatelessWidget {
  const _Wide();

  @override
  Widget build(BuildContext context) => const Placeholder();
}
