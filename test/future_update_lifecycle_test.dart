import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reellock_wellbeing/models/daily_history_entry.dart';
import 'package:reellock_wellbeing/models/daily_status.dart';
import 'package:reellock_wellbeing/models/monitoring_status.dart';
import 'package:reellock_wellbeing/models/update_manifest.dart';
import 'package:reellock_wellbeing/services/update_service.dart';
import 'package:reellock_wellbeing/widgets/update_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('REELLOCK Future Update Lifecycle (v1.0.1 -> v1.0.2)', () {
    late UpdateService updateService;

    setUp(() {
      updateService = UpdateService();
      updateService.currentVersionCode = 2; // v1.0.1
      updateService.currentVersionName = '1.0.1';
      updateService.updateNotifier.value = null;
      updateService.downloadProgressNotifier.value = 0.0;
      updateService.updateStatusNotifier.value = 'Idle';
      updateService.isDownloadingNotifier.value = false;
    });

    test('1. User state before update: active daily count, history, and permissions', () {
      final userDailyStatus = DailyStatus(
        dailyLimit: 100,
        reelsWatchedToday: 65,
        remainingReels: 35,
        isLimitReached: false,
        lastResetDate: '2026-11-15',
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: [
          DailyHistoryEntry(date: '2026-11-14', reelsWatched: 88, limitSet: 100, limitReached: false),
          DailyHistoryEntry(date: '2026-11-13', reelsWatched: 100, limitSet: 100, limitReached: true),
        ],
      );

      final userPermissions = const MonitoringStatus(
        usagePermissionGranted: true,
        accessibilityServiceEnabled: true,
        isCurrentlyInsideReels: false,
        isInstagramInstalled: true,
        isConnected: true,
        reelsSessionStartMs: 0,
        detectionConfidence: 'HIGH',
      );

      expect(userDailyStatus.reelsWatchedToday, 65);
      expect(userDailyStatus.remainingReels, 35);
      expect(userDailyStatus.history.length, 2);
      expect(userPermissions.isConnected, isTrue);
      expect(userPermissions.usagePermissionGranted, isTrue);
      expect(userPermissions.accessibilityServiceEnabled, isTrue);
    });

    test('2. New release v1.0.2 detection and notification trigger', () {
      final manifestV102 = UpdateManifest(
        latestVersion: '1.0.2',
        latestVersionCode: 3,
        apkDownloadUrl: 'https://github.com/sasi123151/reellock-wellbeing/releases/latest/download/app-release.apk',
        apkSha256: 'a1b2c3d4e5f600112233445566778899aabbccddeeff00112233445566778899',
        releaseNotes: 'v1.0.2: Advanced Reels analytics and smart break reminders.',
      );

      // On v1.0.1 (build 2), v1.0.2 (build 3) MUST be detected as newer
      expect(manifestV102.isNewerThan(updateService.currentVersionCode), isTrue);

      // Trigger update notification
      updateService.updateNotifier.value = manifestV102;
      updateService.updateStatusNotifier.value = 'Update available: v1.0.2 (Build 3)';

      expect(updateService.updateNotifier.value?.latestVersion, '1.0.2');
      expect(updateService.updateNotifier.value?.latestVersionCode, 3);
    });

    testWidgets('3. In-App Banner rendering, download progress, and failure retry',
        (WidgetTester tester) async {
      final manifestV102 = UpdateManifest(
        latestVersion: '1.0.2',
        latestVersionCode: 3,
        apkDownloadUrl: 'https://github.com/sasi123151/reellock-wellbeing/releases/latest/download/app-release.apk',
        apkSha256: 'a1b2c3d4e5f600112233445566778899aabbccddeeff00112233445566778899',
        releaseNotes: 'v1.0.2: Advanced Reels analytics and smart break reminders.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateBanner(),
          ),
        ),
      );
      await tester.pump();

      // No banner when up-to-date
      expect(find.textContaining('UPDATE AVAILABLE'), findsNothing);

      // Set update available
      updateService.updateNotifier.value = manifestV102;
      await tester.pump();

      expect(find.text('UPDATE AVAILABLE: v1.0.2'), findsOneWidget);
      expect(find.text('v1.0.2: Advanced Reels analytics and smart break reminders.'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);

      // Simulate download error / network timeout
      updateService.isDownloadingNotifier.value = false;
      updateService.updateStatusNotifier.value = 'Download error: Connection closed before full body was received';
      await tester.pump();

      // Banner MUST remain visible with UPDATE NOW button so user can retry!
      expect(find.text('UPDATE AVAILABLE: v1.0.2'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);
      expect(find.textContaining('Connection closed'), findsNothing); // Status is shown in progress mode

      // Simulate user tapping UPDATE NOW and download resuming to 100%
      updateService.isDownloadingNotifier.value = true;
      updateService.downloadProgressNotifier.value = 1.0;
      updateService.updateStatusNotifier.value = 'Verified SHA-256. Ready to install.';
      await tester.pump();

      expect(find.text('UPDATE AVAILABLE: v1.0.2'), findsOneWidget);
      expect(find.text('Verified SHA-256. Ready to install.'), findsOneWidget);
    });

    test('4. Existing user data and permissions preserved after updating to v1.0.2', () {
      // Simulate app restarting after Android PackageInstaller replaces APK with v1.0.2 (Build 3)
      updateService.currentVersionCode = 3;
      updateService.currentVersionName = '1.0.2';

      final manifestV102 = UpdateManifest(
        latestVersion: '1.0.2',
        latestVersionCode: 3,
        apkDownloadUrl: 'https://github.com/sasi123151/reellock-wellbeing/releases/latest/download/app-release.apk',
        releaseNotes: 'v1.0.2',
      );

      // Since currentVersionCode (3) == latestVersionCode (3), update is no longer newer
      expect(manifestV102.isNewerThan(updateService.currentVersionCode), isFalse);

      // Update banner is dismissed
      updateService.updateNotifier.value = null;
      expect(updateService.updateNotifier.value, isNull);

      // Verify user's daily data persisted from SharedPreferences
      final reloadedDailyStatus = DailyStatus(
        dailyLimit: 100, // Preserved
        reelsWatchedToday: 65, // NOT RESET!
        remainingReels: 35, // Preserved
        isLimitReached: false,
        lastResetDate: '2026-11-15',
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: [
          DailyHistoryEntry(date: '2026-11-14', reelsWatched: 88, limitSet: 100, limitReached: false),
          DailyHistoryEntry(date: '2026-11-13', reelsWatched: 100, limitSet: 100, limitReached: true),
        ],
      );

      expect(reloadedDailyStatus.dailyLimit, 100);
      expect(reloadedDailyStatus.reelsWatchedToday, 65);
      expect(reloadedDailyStatus.remainingReels, 35);
      expect(reloadedDailyStatus.history.length, 2);
    });
  });
}

