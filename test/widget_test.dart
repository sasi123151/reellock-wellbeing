import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reellock_wellbeing/main.dart';
import 'package:reellock_wellbeing/models/daily_history_entry.dart';
import 'package:reellock_wellbeing/models/daily_status.dart';
import 'package:reellock_wellbeing/models/diagnostic_event.dart';
import 'package:reellock_wellbeing/models/monitoring_status.dart';
import 'package:reellock_wellbeing/models/update_manifest.dart';
import 'package:reellock_wellbeing/screens/limit_reached_screen.dart';
import 'package:reellock_wellbeing/screens/onboarding_screen.dart';
import 'package:reellock_wellbeing/services/detector_service.dart';
import 'package:reellock_wellbeing/widgets/focus_meter_gauge.dart';
import 'package:reellock_wellbeing/widgets/instagram_connection_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Model Unit Tests', () {
    test('DailyStatus model calculates progress and clarity score correctly', () {
      final status = DailyStatus(
        dailyLimit: 100,
        reelsWatchedToday: 40,
        remainingReels: 60,
        isLimitReached: false,
        lastResetDate: '2026-11-14',
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: const [],
      );

      expect(status.progressFraction, 0.4);
      expect(status.clarityScore, greaterThan(50));
      expect(status.hasTomorrowLimitScheduled, false);

      final lockedStatus = status.copyWith(
        reelsWatchedToday: 100,
        remainingReels: 0,
        isLimitReached: true,
      );
      expect(lockedStatus.progressFraction, 1.0);
      expect(lockedStatus.clarityScore, 20);
    });

    test('DailyHistoryEntry correctly serializes and deserializes', () {
      final entry = DailyHistoryEntry(
        date: '2026-11-13',
        reelsWatched: 95,
        limitSet: 100,
        limitReached: false,
      );

      final map = entry.toMap();
      final fromMap = DailyHistoryEntry.fromMap(map);

      expect(fromMap.date, '2026-11-13');
      expect(fromMap.reelsWatched, 95);
      expect(fromMap.limitSet, 100);
      expect(fromMap.limitReached, false);
    });

    test('MonitoringStatus correctly reports active connection state', () {
      final connected = const MonitoringStatus(
        usagePermissionGranted: true,
        accessibilityServiceEnabled: true,
        isCurrentlyInsideReels: true,
        isInstagramInstalled: true,
        isConnected: true,
        reelsSessionStartMs: 1000,
        detectionConfidence: 'HIGH',
      );
      expect(connected.isMonitoringActive, true);
      expect(connected.isConnected, true);
      expect(connected.detectionConfidence, 'HIGH');

      final disconnected = MonitoringStatus.initial();
      expect(disconnected.isMonitoringActive, false);
      expect(disconnected.isConnected, false);
    });

    test('DiagnosticEvent parses map and confidence correctly', () {
      final event = DiagnosticEvent.fromMap({
        'id': 'diag_1',
        'timestamp': 1700000000000,
        'eventType': 'REELS_TRANSITION',
        'detectionMethod': 'ACCESSIBILITY_CONFIRMED_VIEW_SCROLLED',
        'details': 'Confirmed Reels vertical swipe transition',
        'confidence': 'HIGH',
      });
      expect(event.id, 'diag_1');
      expect(event.eventType, 'REELS_TRANSITION');
      expect(event.confidence, 'HIGH');
    });

    test('UpdateManifest parses and detects newer versions correctly', () {
      final manifest = UpdateManifest(
        latestVersion: '1.0.1',
        latestVersionCode: 2,
        apkDownloadUrl: 'http://10.93.220.123:8000/app-release.apk',
        releaseNotes: 'Milestone 2 update',
      );

      expect(manifest.isNewerThan(1), true);
      expect(manifest.isNewerThan(2), false);

      final jsonStr = manifest.toJson();
      final fromJson = UpdateManifest.fromJson(jsonStr);
      expect(fromJson.latestVersion, '1.0.1');
      expect(fromJson.latestVersionCode, 2);
    });
  });

  group('DetectorService Quota & MethodChannel Logic Tests', () {
    late DetectorService detector;

    setUp(() {
      detector = DetectorService();
      detector.setSimulationMode(true);
    });

    test('Default quota is 100 and swipe increments correctly', () async {
      await detector.simulateMidnightReset(newLimit: 100);

      var status = detector.statusNotifier.value;
      expect(status.dailyLimit, 100);
      expect(status.reelsWatchedToday, 0);

      final remaining = await detector.getRemainingQuota();
      expect(remaining, 100);

      // Simulate swiping 35 reels
      await detector.simulateReelSwipe(count: 35);
      status = detector.statusNotifier.value;
      expect(status.reelsWatchedToday, 35);
      expect(status.remainingReels, 65);
      expect(status.isLimitReached, false);

      // Simulate reaching quota of 100
      await detector.simulateReelSwipe(count: 65);
      status = detector.statusNotifier.value;
      expect(status.reelsWatchedToday, 100);
      expect(status.remainingReels, 0);
      expect(status.isLimitReached, true);

      // Check lock status
      final lockStatus = await detector.getLockStatus();
      expect(lockStatus['isLocked'], true);
      expect(lockStatus['dailyQuota'], 100);

      // Attempting to increase today's quota is strictly blocked
      final changedToday = await detector.setDailyQuota(250);
      expect(changedToday, false);
      expect(detector.statusNotifier.value.dailyLimit, 100);

      // Scheduling tomorrow's quota is allowed
      final scheduled = await detector.setTomorrowLimit(80);
      expect(scheduled, true);
      expect(detector.statusNotifier.value.tomorrowLimit, 80);

      // Midnight auto-reset applies scheduled quota
      await detector.simulateMidnightReset();
      final resetStatus = detector.statusNotifier.value;
      expect(resetStatus.reelsWatchedToday, 0);
      expect(resetStatus.dailyLimit, 80);
      expect(resetStatus.isLimitReached, false);
    });
  });

  group('Widget UI Tests', () {
    testWidgets('InstagramConnectionCard displays status and permission actions', (WidgetTester tester) async {
      final disconnectedStatus = const MonitoringStatus(
        usagePermissionGranted: false,
        accessibilityServiceEnabled: false,
        isCurrentlyInsideReels: false,
        isInstagramInstalled: true,
        isConnected: false,
        reelsSessionStartMs: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstagramConnectionCard(
              status: disconnectedStatus,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('INSTAGRAM CONNECTION'), findsOneWidget);
      expect(find.text('ACTION REQUIRED'), findsOneWidget);
      expect(find.text('Open Accessibility'), findsOneWidget);
      expect(find.text('Open Usage Access'), findsOneWidget);
      expect(find.textContaining('What REELLOCK Monitors'), findsOneWidget);
    });

    testWidgets('FocusMeterGauge renders metrics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FocusMeterGauge(
              watched: 45,
              limit: 100,
              isLimitReached: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('45'), findsOneWidget);
      expect(find.text('OF 100 REELS'), findsOneWidget);
      expect(find.text('55 REMAINING'), findsOneWidget);
    });

    testWidgets('LimitReachedScreen renders YOU HIT YOUR DAILY LIMIT and countdown', (WidgetTester tester) async {
      final detector = DetectorService();
      detector.setSimulationMode(true);
      await detector.simulateMidnightReset(newLimit: 100);
      await detector.simulateReelSwipe(count: 100);

      await tester.pumpWidget(
        const MaterialApp(
          home: LimitReachedScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('YOU HIT YOUR DAILY LIMIT'), findsOneWidget);
      expect(find.textContaining('You set a daily quota of 100 Reels today'), findsOneWidget);
      expect(find.text('AUTOMATIC MIDNIGHT RESET IN'), findsOneWidget);
      expect(find.text('Back to REELLOCK Dashboard'), findsOneWidget);
    });

    testWidgets('OnboardingScreen renders step 1 and navigates', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('REELLOCK'), findsOneWidget);
      expect(find.text('Instagram Reels Addiction Control'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Usage Access Permission'), findsOneWidget);
    });

    testWidgets('App root renders MainShellScreen with tabs, card, and simulation bar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final detector = DetectorService();
      detector.setSimulationMode(true);

      await tester.pumpWidget(const ReelLockWellbeingApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header on dashboard
      expect(find.text('REELLOCK'), findsOneWidget);
      expect(find.text('SIMULATED'), findsOneWidget);

      // Connection Card on dashboard
      expect(find.text('INSTAGRAM CONNECTION'), findsOneWidget);

      // Bottom nav labels
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Quota'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      // Simulation bar buttons
      expect(find.text('+1 Reel'), findsOneWidget);
      expect(find.text('+10 Reels'), findsOneWidget);
      expect(find.text('Max Limit'), findsOneWidget);
      expect(find.text('Midnight Reset'), findsOneWidget);
    });
  });
}
