import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reellock_wellbeing/models/update_manifest.dart';
import 'package:reellock_wellbeing/services/update_service.dart';
import 'package:reellock_wellbeing/widgets/update_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService & UpdateBanner Verification (Items 4 & 5)', () {
    late UpdateService updateService;

    setUp(() {
      updateService = UpdateService();
      updateService.updateNotifier.value = null;
      updateService.downloadProgressNotifier.value = 0.0;
      updateService.updateStatusNotifier.value = 'Idle';
      updateService.isDownloadingNotifier.value = false;
    });

    test('Item 4: Update detection logic correctly identifies newer releases', () {
      final manifestV2 = UpdateManifest(
        latestVersion: '1.0.1',
        latestVersionCode: 2,
        apkDownloadUrl: 'https://github.com/sasi123151/reellock-wellbeing/releases/latest/download/app-release.apk',
        apkSha256: '9ef2902e77fe56f9c0147e00baed43083258f82e8bec92700ad505766501f803',
        releaseNotes: 'Production UX and Explore Lock',
      );

      // Current version code 1 (initial release) -> newer version available
      expect(manifestV2.isNewerThan(1), isTrue,
          reason: 'VersionCode 2 must be detected as newer than VersionCode 1');

      // Current version code 2 (already updated) -> no update needed
      expect(manifestV2.isNewerThan(2), isFalse,
          reason: 'VersionCode 2 must not trigger update when already on VersionCode 2');

      // Current version code 3 (future build) -> no update needed
      expect(manifestV2.isNewerThan(3), isFalse,
          reason: 'VersionCode 2 must not trigger update when on VersionCode 3');
    });

    testWidgets('Item 5: UPDATE AVAILABLE banner renders and remains visible until update succeeds',
        (WidgetTester tester) async {
      final manifestV2 = UpdateManifest(
        latestVersion: '1.0.1',
        latestVersionCode: 2,
        apkDownloadUrl: 'https://github.com/sasi123151/reellock-wellbeing/releases/latest/download/app-release.apk',
        apkSha256: '9ef2902e77fe56f9c0147e00baed43083258f82e8bec92700ad505766501f803',
        releaseNotes: 'Production UX and Explore Lock',
      );

      // Initially no update
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateBanner(),
          ),
        ),
      );
      await tester.pump();

      // Banner should be hidden initially
      expect(find.textContaining('UPDATE AVAILABLE'), findsNothing);

      // Simulate UpdateService detecting the new release (Item 4)
      updateService.currentVersionCode = 1;
      updateService.currentVersionName = '1.0.0';
      updateService.updateNotifier.value = manifestV2;
      updateService.updateStatusNotifier.value = 'Update available: v1.0.1';
      await tester.pump();

      // Banner MUST be visible now (Item 5)
      expect(find.text('UPDATE AVAILABLE: v1.0.1'), findsOneWidget);
      expect(find.text('Production UX and Explore Lock'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);

      // Simulate download starting: banner remains visible, shows progress bar
      updateService.isDownloadingNotifier.value = true;
      updateService.downloadProgressNotifier.value = 0.45;
      updateService.updateStatusNotifier.value = 'Downloading: 45.0% (76.1 MB / 168.9 MB)';
      await tester.pump();

      expect(find.text('UPDATE AVAILABLE: v1.0.1'), findsOneWidget);
      expect(find.text('Downloading: 45.0% (76.1 MB / 168.9 MB)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // When download finishes, but not yet installed, banner still shows UPDATE NOW or progress 100%
      updateService.isDownloadingNotifier.value = false;
      updateService.downloadProgressNotifier.value = 1.0;
      updateService.updateStatusNotifier.value = 'Verified SHA-256. Ready to install.';
      await tester.pump();

      expect(find.text('UPDATE AVAILABLE: v1.0.1'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);

      // Now simulate successful installation where app restarts with currentVersionCode = 2
      updateService.currentVersionCode = 2;
      updateService.currentVersionName = '1.0.1';
      // When app restarts with version 2, manifest is no longer newer than currentVersionCode
      if (!manifestV2.isNewerThan(updateService.currentVersionCode)) {
        updateService.updateNotifier.value = null;
      }
      await tester.pump();

      // Banner is now cleanly dismissed
      expect(find.textContaining('UPDATE AVAILABLE'), findsNothing);
    });
  });
}
