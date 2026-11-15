import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../services/detector_service.dart';
import '../widgets/quick_sim_bar.dart';
import 'analytics_screen.dart';
import 'home_dashboard_screen.dart';
import 'limit_settings_screen.dart';
import 'settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  final DetectorService _detector = DetectorService();

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    LimitSettingsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show QuickSimBar strictly in debug mode if simulation mode is active
          if (kDebugMode && _detector.isSimulationMode) const QuickSimBar(),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.neonPurple,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shield_outlined),
                activeIcon: Icon(Icons.shield_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune_outlined),
                activeIcon: Icon(Icons.tune_rounded),
                label: 'Quota',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Status',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
