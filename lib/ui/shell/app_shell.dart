import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/identity_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/today_screen.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../services/geofence_manager.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    IdentityScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    GeofenceManager().init();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Habit>>>(habitListProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        GeofenceManager().updateGeofences(next.value!);
      }
    });

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Identity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
