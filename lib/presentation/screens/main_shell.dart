import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/debug/demo_controls_sheet.dart';
import 'patterns_screen.dart';
import 'profile_screen.dart';
import 'today/today_screen.dart';

/// Bottom-tab shell: Today / Patterns / Profile. Replaces the old top-header
/// + patient-stepper `MainLayout`. A long-press on the "SEEN" wordmark opens
/// the dev-only demo controls (profile switching + clinician portal) — a
/// real user has no visible entry point to either.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;

  static const _screens = [TodayScreen(), PatternsScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: GestureDetector(
          onLongPress: () => showModalBottomSheet(
            context: context,
            builder: (_) => const DemoControlsSheet(),
          ),
          child: const Text(
            'SEEN',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 3.0,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_tabIndex),
            child: _screens[_tabIndex],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_outlined),
            activeIcon: Icon(Icons.auto_graph),
            label: 'Patterns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
