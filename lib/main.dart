import 'package:material_ui/material_ui.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_shell_screen.dart';
import 'services/detector_service.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize detector service & fetch initial state
  final detector = DetectorService();
  await detector.getDailyStatus();

  // Initialize in-app update service
  await UpdateService().initialize();

  runApp(const ReelLockWellbeingApp());
}

class ReelLockWellbeingApp extends StatelessWidget {
  const ReelLockWellbeingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REELLOCK Wellbeing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShellScreen(),
    );
  }
}
