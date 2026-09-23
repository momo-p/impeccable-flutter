// Screenshot entry point. One web build serves every variant, chosen by the
// `?shot=` query parameter, so `tool/screenshots.sh` can capture them all
// without rebuilding between each one.
//
// This is not the app. `lib/main.dart` is.
import 'package:flutter/material.dart';
import 'package:watchlist/models.dart';
import 'package:watchlist/screens/library_after.dart';
import 'package:watchlist/screens/library_before.dart';
import 'package:watchlist/screens/library_tv.dart';
import 'package:watchlist/theme.dart';

const _entries = [
  Entry(
    title: 'Paris, Texas',
    note: 'Saved last week. 2h 25m.',
    poster: 'assets/posters/paris-texas.png',
  ),
  Entry(
    title: 'A Brighter Summer Day',
    note: 'Four hours. Start it early.',
    poster: 'assets/posters/brighter-summer-day.png',
  ),
];

void main() {
  final shot = Uri.base.queryParameters['shot'] ?? 'after-light';
  runApp(ShotApp(shot: shot));
}

class ShotApp extends StatelessWidget {
  const ShotApp({super.key, required this.shot});

  final String shot;

  @override
  Widget build(BuildContext context) {
    final dark = shot.endsWith('-dark') || shot == 'tv';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildWatchlistTheme(dark ? Brightness.dark : Brightness.light),
      home: switch (shot) {
        'before' => const LibraryBefore(),
        'tv' => const LibraryTv(entries: _entries),
        _ => const LibraryAfter(entries: _entries),
      },
    );
  }
}
