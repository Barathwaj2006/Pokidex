import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';
import 'connection_screen.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'simulations_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    SimulationsScreen(),
    ProgressScreen(),
    ConnectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: AppColors.primarySurface,
            selectedItemColor: AppColors.primaryAccent,
            unselectedItemColor: AppColors.mutedText,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard, color: AppColors.primaryAccent),
                label: 'Terminal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart, color: AppColors.primaryAccent),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.waves_outlined),
                activeIcon: Icon(Icons.waves, color: AppColors.primaryAccent),
                label: 'Simulations',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_toggle_off_outlined),
                activeIcon: Icon(Icons.history_toggle_off, color: AppColors.primaryAccent),
                label: 'Progress',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sensors_outlined),
                activeIcon: Icon(Icons.sensors, color: AppColors.primaryAccent),
                label: 'Telemetry',
              ),
            ],
          ),
        ),
      ),
    );
  }
}