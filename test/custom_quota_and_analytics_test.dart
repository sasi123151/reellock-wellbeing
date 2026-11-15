import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reellock_wellbeing/models/daily_history_entry.dart';
import 'package:reellock_wellbeing/models/daily_status.dart';
import 'package:reellock_wellbeing/screens/analytics_screen.dart';
import 'package:reellock_wellbeing/screens/limit_settings_screen.dart';
import 'package:reellock_wellbeing/services/detector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Custom Quota & Analytics Dynamic Verification', () {
    late DetectorService detector;

    setUp(() {
      detector = DetectorService();
      detector.setSimulationMode(true);
    });

    testWidgets('Custom Quota chips render and Custom dialog validates positive integers',
        (WidgetTester tester) async {
      detector.statusNotifier.value = DailyStatus(
        dailyLimit: 100,
        reelsWatchedToday: 10,
        remainingReels: 90,
        isLimitReached: false,
        lastResetDate: '2026-11-15',
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: const [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: LimitSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify preset chips exist
      expect(find.widgetWithText(ChoiceChip, '25'), findsNWidgets(2)); // Today and tomorrow
      expect(find.widgetWithText(ChoiceChip, '50'), findsNWidgets(2));
      expect(find.widgetWithText(ChoiceChip, '100'), findsNWidgets(2));
      expect(find.widgetWithText(ChoiceChip, '500'), findsNWidgets(2));

      // Verify Custom chips exist
      expect(find.text('Custom'), findsNWidgets(2));

      // Tap Custom for Today's Quota (first Custom chip)
      await tester.tap(find.text('Custom').first);
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Custom Daily Quota'), findsOneWidget);
      expect(find.text('Save Quota'), findsOneWidget);

      // Enter 0 (invalid)
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Save Quota'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Quota must be a positive integer (> 0)'), findsOneWidget);

      // Enter valid custom quota 175
      await tester.enterText(find.byType(TextField), '175');
      await tester.tap(find.text('Save Quota'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Custom Daily Quota'), findsNothing);
      expect(find.text('175'), findsOneWidget);
      expect(find.text('Custom (175)'), findsOneWidget);
    });

    testWidgets('Analytics Screen shows clean honest empty state for new user with zero fake data',
        (WidgetTester tester) async {
      detector.statusNotifier.value = DailyStatus(
        dailyLimit: 100,
        reelsWatchedToday: 0,
        remainingReels: 100,
        isLimitReached: false,
        lastResetDate: '2026-11-15',
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: const [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify NO fake dummy values exist
      expect(find.text('1h 45m'), findsNothing); // Dummy saved time must be gone!
      expect(find.text('3'), findsNothing); // Dummy blocked attempts must be gone!

      // Verify honest dynamic stats
      expect(find.text('0'), findsWidgets); // 0 blocked attempts, 0 reels today
      expect(find.text('0m'), findsOneWidget); // Honest 0m saved
      expect(find.text('No locks triggered'), findsOneWidget);

      // Verify honest empty state in Weekly Chart
      expect(find.text('No weekly activity recorded yet'), findsOneWidget);
      expect(find.textContaining('Your daily consumption chart will appear here'), findsOneWidget);

      // Verify honest empty state in History list
      expect(find.textContaining('No archived days yet'), findsOneWidget);
    });

    testWidgets('Analytics Screen dynamically renders 7-day bars when activity exists',
        (WidgetTester tester) async {
      detector.statusNotifier.value = DailyStatus(
        dailyLimit: 100,
        reelsWatchedToday: 25,
        remainingReels: 75,
        isLimitReached: false,
        lastResetDate: '2026-11-15',
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: [
          DailyHistoryEntry(
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
            reelsWatched: 80,
            limitSet: 100,
            limitReached: false,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Empty state is NOT shown
      expect(find.text('No weekly activity recorded yet'), findsNothing);

      // Today's dynamic bar is rendered
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('25'), findsWidgets); // Today's reels and bar label

      // Saved time is calculated dynamically:
      // Yesterday saved: 100 - 80 = 20 reels * 45s = 15 mins.
      // Today saved: 100 - 25 = 75 reels * 45s = 56.25 mins.
      // Total = ~71 mins = 1h 11m.
      expect(find.text('1h 11m'), findsOneWidget);
    });
  });
}
