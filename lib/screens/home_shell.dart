import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/ui.dart';
import 'explore_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

/// Hosts the top drawer menu and the four main sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _sections = <(String, IconData)>[
    ('Explore', Icons.explore_rounded),
    ('Map', Icons.map_rounded),
    ('Saved', Icons.favorite_rounded),
    ('Profile', Icons.person_rounded),
  ];

  // IndexedStack keeps each section alive (the map keeps its position).
  static const _pages = <Widget>[
    ExploreScreen(),
    MapScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hidden Tunisia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                color: AppColors.forest,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.travel_explore_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Hidden Tunisia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Discover your next destination',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _sections.length; i++)
                ListTile(
                  selected: _index == i,
                  selectedColor: AppColors.forest,
                  selectedTileColor: AppColors.light,
                  leading: Icon(_sections[i].$2),
                  title: Text(_sections[i].$1),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (i == _index) return;
                    setState(() => _index = i);
                    showMessage(context, 'Showing ${_sections[i].$1}.');
                  },
                ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}
