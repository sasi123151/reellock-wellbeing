import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/update_manifest.dart';

class UpdateService {
  static const MethodChannel _channel = MethodChannel('com.reellock.wellbeing/updater');

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String defaultManifestUrl =
      'https://github.com/sasi123151/reellock-wellbeing/releases/latest/download/update_manifest.json';

  int currentVersionCode = 1;
  String currentVersionName = '1.0.0';

  final ValueNotifier<UpdateManifest?> updateNotifier = ValueNotifier<UpdateManifest?>(null);
  final ValueNotifier<double> downloadProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> updateStatusNotifier = ValueNotifier<String>('Idle');
  final ValueNotifier<bool> isDownloadingNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final versionInfo = await _channel.invokeMapMethod<String, dynamic>('getAppVersion');
        if (versionInfo != null) {
          currentVersionCode = (versionInfo['versionCode'] as num?)?.toInt() ?? 1;
          currentVersionName = versionInfo['versionName']?.toString() ?? '1.0.0';
        }
      }
    } catch (e) {
      debugPrint('UpdateService.initialize: Failed to fetch app version: $e');
    }

    // Load any persisted update manifest
    await _loadPersistedManifest();

    // Proactively check for updates on startup in background
    unawaited(checkForUpdate());
  }

  Future<File?> _getPersistedManifestFile() async {
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
      final cacheDir = await _channel.invokeMethod<String>('getCacheDirectory');
      if (cacheDir == null) return null;
      return File('$cacheDir/persisted_update_manifest.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadPersistedManifest() async {
    try {
      final file = await _getPersistedManifestFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final manifest = UpdateManifest.fromJson(content);
          if (manifest.isNewerThan(currentVersionCode)) {
            updateNotifier.value = manifest;
            updateStatusNotifier.value = 'Update available: v${manifest.latestVersion}';
          } else {
            // Already updated, remove stale persisted file
            await file.delete();
            updateNotifier.value = null;
          }
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Error loading persisted manifest: $e');
    }
  }

  Future<void> _persistManifest(UpdateManifest manifest) async {
    try {
      final file = await _getPersistedManifestFile();
      if (file != null) {
        await file.writeAsString(manifest.toJson());
      }
    } catch (e) {
      debugPrint('UpdateService: Error saving persisted manifest: $e');
    }
  }

  Future<UpdateManifest?> checkForUpdate({String? customUrl}) async {
    final urlStr = customUrl ?? defaultManifestUrl;
    updateStatusNotifier.value = 'Checking for updates...';

    try {
      final uri = Uri.parse(urlStr);
      final client = HttpClient();
      client.userAgent = 'REELLOCK-Wellbeing/1.0.1 (Android)';
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final manifest = UpdateManifest.fromJson(body);

        if (manifest.isNewerThan(currentVersionCode)) {
          updateNotifier.value = manifest;
          updateStatusNotifier.value = 'Update available: v${manifest.latestVersion} (Build ${manifest.latestVersionCode})';
          await _persistManifest(manifest);
          return manifest;
        } else {
          updateNotifier.value = null;
          updateStatusNotifier.value = 'App is up to date (v$currentVersionName)';
          final file = await _getPersistedManifestFile();
          if (file != null && await file.exists()) {
            await file.delete();
          }
          return null;
        }
      } else {
        updateStatusNotifier.value = 'Server returned HTTP ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('UpdateService: checkForUpdate failed: $e');
      updateStatusNotifier.value = 'Update check offline';
    }
    return updateNotifier.value;
  }

  Future<bool> downloadAndInstallUpdate(UpdateManifest manifest) async {
    if (isDownloadingNotifier.value) return false;

    isDownloadingNotifier.value = true;
    downloadProgressNotifier.value = 0.0;
    updateStatusNotifier.value = 'Starting download...';

    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        updateStatusNotifier.value = 'Updates only supported on Android';
        isDownloadingNotifier.value = false;
        return false;
      }

      final cacheDirPath = await _channel.invokeMethod<String>('getCacheDirectory');
      if (cacheDirPath == null) {
        updateStatusNotifier.value = 'Failed to locate app cache directory';
        isDownloadingNotifier.value = false;
        return false;
      }

      final targetFile = File('$cacheDirPath/reellock_update.apk');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final uri = Uri.parse(manifest.apkDownloadUrl);
      final client = HttpClient();
      client.userAgent = 'REELLOCK-Wellbeing/1.0.1 (Android)';
      client.connectionTimeout = const Duration(seconds: 15);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        updateStatusNotifier.value = 'Download failed: HTTP ${response.statusCode}';
        isDownloadingNotifier.value = false;
        return false;
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;

      final sink = targetFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          downloadProgressNotifier.value = progress;
          updateStatusNotifier.value = 'Downloading: ${(progress * 100).toInt()}% (${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB)';
        } else {
          updateStatusNotifier.value = 'Downloading: ${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }

      await sink.flush();
      await sink.close();

      if (!await targetFile.exists() || await targetFile.length() == 0) {
        updateStatusNotifier.value = 'Downloaded file is empty or corrupted';
        isDownloadingNotifier.value = false;
        return false;
      }

      // Verify SHA-256 integrity checksum if specified in manifest
      if (manifest.apkSha256.isNotEmpty) {
        updateStatusNotifier.value = 'Verifying SHA-256 package integrity...';
        final isHashValid = await _channel.invokeMethod<bool>('verifySha256', {
          'filePath': targetFile.path,
          'expectedHash': manifest.apkSha256,
        }) ?? false;

        if (!isHashValid) {
          updateStatusNotifier.value = 'Security Alert: SHA-256 checksum mismatch! Aborting.';
          isDownloadingNotifier.value = false;
          return false;
        }
      }

      updateStatusNotifier.value = 'Launching package installer...';
      downloadProgressNotifier.value = 1.0;

      // Check Android 8.0+ Unknown App Sources permission
      final canInstall = await _channel.invokeMethod<bool>('canRequestPackageInstalls') ?? true;
      if (!canInstall) {
        updateStatusNotifier.value = 'Grant install permission in Settings to continue';
        await _channel.invokeMethod('openInstallPermissionSetting');
        // Wait briefly for user before launching intent
        await Future.delayed(const Duration(seconds: 2));
      }

      // Launch official Android PackageInstaller via FileProvider
      final installResult = await _channel.invokeMethod<bool>('installApk', {
        'filePath': targetFile.path,
      });

      if (installResult == true) {
        updateStatusNotifier.value = 'Installer opened successfully';
        isDownloadingNotifier.value = false;
        return true;
      } else {
        updateStatusNotifier.value = 'Failed to launch Android package installer';
        isDownloadingNotifier.value = false;
        return false;
      }
    } catch (e) {
      debugPrint('UpdateService: downloadAndInstallUpdate failed: $e');
      updateStatusNotifier.value = 'Download error: $e';
      isDownloadingNotifier.value = false;
      return false;
    }
  }
}

