import 'package:flutter/material.dart';

import 'models.dart';
import 'screens/library_after.dart';
import 'screens/library_tv.dart';
import 'theme.dart';

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

void main() => runApp(const WatchlistApp());

class WatchlistApp extends StatelessWidget {
  const WatchlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watchlist',
      theme: buildWatchlistTheme(Brightness.light),
      darkTheme: buildWatchlistTheme(Brightness.dark),
      home: const LibraryAfter(entries: _entries),
    );
  }
}

/// The TV entry point. A real app picks one at launch from the platform; both
/// are kept here so the pair can be read side by side.
class WatchlistTvApp extends StatelessWidget {
  const WatchlistTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watchlist',
      theme: buildWatchlistTheme(Brightness.dark),
      home: const LibraryTv(entries: _entries),
    );
  }
}
