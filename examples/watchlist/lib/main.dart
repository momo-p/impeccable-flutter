import 'package:flutter/material.dart';

import 'models.dart';
import 'screens/library_after.dart';
import 'screens/library_tv.dart';
import 'theme.dart';

const _entries = [
  Entry(
    title: 'The General',
    note: 'Saved last week. 1h 18m.',
    poster: 'assets/posters/the-general.png',
  ),
  Entry(
    title: 'His Girl Friday',
    note: 'Added Tuesday. 1h 32m.',
    poster: 'assets/posters/his-girl-friday.jpg',
  ),
  Entry(
    title: 'Night of the Living Dead',
    note: '38 minutes left.',
    poster: 'assets/posters/night-of-the-living-dead.jpg',
    progress: 0.6,
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
