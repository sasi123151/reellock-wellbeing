import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/daily_history_entry.dart';
import '../models/daily_status.dart';
import '../models/diagnostic_event.dart';
import '../models/monitoring_status.dart';

class DetectorService {
  static const MethodChannel _channel =
      MethodChannel('com.reellock.wellbeing/detector');

  static final DetectorService _instance = DetectorService._internal();
  factory DetectorService() => _instance;
  DetectorService._internal() {
    // Default to simulation on web or non-android platforms
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _simulationMode = true;
    }
  }

  bool _simulationMode = false;
  bool get isSimulationMode => kDebugMode && _simulationMode;

  void setSimulationMode(bool enabled) {
    if (!kDebugMode) return;
    _simulationMode = enabled;
    statusNotifier.value = _simulatedStatus;
  }

  // Reactive notifiers for live UI updates
  final ValueNotifier<DailyStatus> statusNotifier =
      ValueNotifier<DailyStatus>(DailyStatus.initial());

  final ValueNotifier<MonitoringStatus> monitoringNotifier =
      ValueNotifier<MonitoringStatus>(MonitoringStatus.initial());

  // Simulated internal state (strictly for PC/Web testing)
  DailyStatus _simulatedStatus = DailyStatus(
    dailyLimit: 100,
    reelsWatchedToday: 42,
    remainingReels: 58,
    isLimitReached: false,
    lastResetDate: DateTime.now().toIso8601String().substring(0, 10),
    tomorrowLimit: -1,
    lockTimestamp: 0,
    history: [
      DailyHistoryEntry(
        date: DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10),
        reelsWatched: 88,
        limitSet: 100,
        limitReached: false,
      ),
      DailyHistoryEntry(
        date: DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
        reelsWatched: 100,
        limitSet: 100,
        limitReached: true,
      ),
      DailyHistoryEntry(
        date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
        reelsWatched: 65,
        limitSet: 100,
        limitReached: false,
      ),
    ],
  );

  bool _simulatedUsageGranted = false;
  bool _simulatedAccessibilityGranted = false;
  bool _simulatedInsideReels = false;
  final List<DiagnosticEvent> _simulatedEvents = [];

  // ================= 1. PERMISSIONS & MONITORING =================

  Future<bool> checkUsagePermission() async {
    if (_simulationMode) return _simulatedUsageGranted;
    try {
      final bool? granted =
          await _channel.invokeMethod<bool>('checkUsagePermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestUsageAccess() async {
    if (_simulationMode) {
      _simulatedUsageGranted = true;
      await getMonitoringStatus();
      return true;
    }
    try {
      final bool? requested =
          await _channel.invokeMethod<bool>('requestUsageAccess');
      return requested ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestUsagePermission() => requestUsageAccess();

  Future<bool> checkAccessibilityPermission() async {
    if (_simulationMode) return _simulatedAccessibilityGranted;
    try {
      final bool? granted =
          await _channel.invokeMethod<bool>('checkAccessibilityPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestAccessibilityPermission() async {
    if (_simulationMode) {
      _simulatedAccessibilityGranted = true;
      await getMonitoringStatus();
      return true;
    }
    try {
      final bool? requested =
          await _channel.invokeMethod<bool>('requestAccessibilityPermission');
      return requested ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppDetailsSettings() async {
    if (_simulationMode) return true;
    try {
      final bool? res = await _channel.invokeMethod<bool>('openAppDetailsSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<MonitoringStatus> getMonitoringStatus() async {
    if (_simulationMode) {
      final status = MonitoringStatus(
        usagePermissionGranted: _simulatedUsageGranted,
        accessibilityServiceEnabled: _simulatedAccessibilityGranted,
        isCurrentlyInsideReels: _simulatedInsideReels,
        isInstagramInstalled: true,
        isConnected: _simulatedUsageGranted && _simulatedAccessibilityGranted,
        reelsSessionStartMs: _simulatedInsideReels
            ? DateTime.now().millisecondsSinceEpoch - 25000
            : 0,
        detectionConfidence: _simulatedInsideReels ? 'HIGH' : 'NONE',
      );
      monitoringNotifier.value = status;
      return status;
    }

    try {
      final map =
          await _channel.invokeMapMethod<dynamic, dynamic>('getMonitoringStatus');
      if (map != null) {
        final status = MonitoringStatus.fromMap(map);
        monitoringNotifier.value = status;
        return status;
      }
    } catch (_) {}
    return MonitoringStatus.initial();
  }

  // ================= 2. REAL REELS COUNT & QUOTA =================

  Future<int> getReelsCount() async {
    if (_simulationMode) return _simulatedStatus.reelsWatchedToday;
    try {
      final int? count = await _channel.invokeMethod<int>('getReelsCount');
      if (count != null) {
        await getDailyStatus();
        return count;
      }
    } catch (_) {}
    return _simulatedStatus.reelsWatchedToday;
  }

  Future<int> getDailyQuota() async {
    if (_simulationMode) return _simulatedStatus.dailyLimit;
    try {
      final int? quota = await _channel.invokeMethod<int>('getDailyQuota');
      if (quota != null) return quota;
    } catch (_) {}
    return _simulatedStatus.dailyLimit;
  }

  Future<int> getRemainingQuota() async {
    if (_simulationMode) return _simulatedStatus.remainingReels;
    try {
      final int? remaining =
          await _channel.invokeMethod<int>('getRemainingQuota');
      if (remaining != null) return remaining;
    } catch (_) {}
    return _simulatedStatus.remainingReels;
  }

  Future<bool> setDailyQuota(int quota) async {
    if (_simulationMode) {
      if (_simulatedStatus.isLimitReached) {
        return false; // Strict lock rule
      }
      _simulatedStatus = _simulatedStatus.copyWith(
        dailyLimit: quota,
        remainingReels:
            (quota - _simulatedStatus.reelsWatchedToday).clamp(0, 99999),
        isLimitReached: _simulatedStatus.reelsWatchedToday >= quota,
      );
      statusNotifier.value = _simulatedStatus;
      return true;
    }

    try {
      final map = await _channel.invokeMapMethod<dynamic, dynamic>(
        'setDailyQuota',
        {'quota': quota},
      );
      if (map != null) {
        final status = DailyStatus.fromMap(map);
        statusNotifier.value = status;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setDailyLimit(int limit) => setDailyQuota(limit);

  Future<bool> setTomorrowLimit(int limit) async {
    if (_simulationMode) {
      _simulatedStatus = _simulatedStatus.copyWith(tomorrowLimit: limit);
      statusNotifier.value = _simulatedStatus;
      return true;
    }

    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'setTomorrowLimit',
        {'limit': limit},
      );
      if (ok == true) {
        await getDailyStatus();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getLockStatus() async {
    if (_simulationMode) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final remainingMs = tomorrow.difference(now).inMilliseconds;

      return {
        'isLocked': _simulatedStatus.isLimitReached,
        'lockTimestamp': _simulatedStatus.lockTimestamp,
        'remainingTimeUntilMidnightMs': remainingMs,
        'dailyQuota': _simulatedStatus.dailyLimit,
        'reelsWatched': _simulatedStatus.reelsWatchedToday,
        'remainingQuota': _simulatedStatus.remainingReels,
      };
    }

    try {
      final map =
          await _channel.invokeMapMethod<dynamic, dynamic>('getLockStatus');
      if (map != null) {
        return Map<String, dynamic>.from(map);
      }
    } catch (_) {}
    return {
      'isLocked': _simulatedStatus.isLimitReached,
      'lockTimestamp': 0,
      'remainingTimeUntilMidnightMs': 0,
      'dailyQuota': 100,
      'reelsWatched': 0,
      'remainingQuota': 100,
    };
  }

  Future<DailyStatus> getDailyStatus() async {
    if (_simulationMode) {
      statusNotifier.value = _simulatedStatus;
      return _simulatedStatus;
    }

    try {
      final map =
          await _channel.invokeMapMethod<dynamic, dynamic>('getDailyLimitStatus');
      if (map != null) {
        final status = DailyStatus.fromMap(map);
        statusNotifier.value = status;
        return status;
      }
    } catch (_) {}
    statusNotifier.value = _simulatedStatus;
    return _simulatedStatus;
  }

  // ================= 3. DIAGNOSTIC LOGS =================

  Future<List<DiagnosticEvent>> getDiagnosticLogs() async {
    if (_simulationMode) {
      return List.unmodifiable(_simulatedEvents);
    }

    try {
      final List<dynamic>? raw =
          await _channel.invokeListMethod<dynamic>('getDiagnosticLogs');
      if (raw != null) {
        return raw
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => DiagnosticEvent.fromMap(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<DiagnosticEvent>> getRecentEvents() => getDiagnosticLogs();

  Future<void> clearEvents() async {
    if (_simulationMode) {
      _simulatedEvents.clear();
      return;
    }
    try {
      await _channel.invokeMethod('clearRecordedEvents');
    } catch (_) {}
  }

  // ================= 4. PC SIMULATION TRIGGERS =================

  Future<DailyStatus> simulateReelSwipe({int count = 1}) async {
    if (_simulationMode) {
      final newWatched = _simulatedStatus.reelsWatchedToday + count;
      final isReached = _simulatedStatus.isLimitReached ||
          (newWatched >= _simulatedStatus.dailyLimit);

      _simulatedStatus = _simulatedStatus.copyWith(
        reelsWatchedToday: newWatched,
        remainingReels:
            (_simulatedStatus.dailyLimit - newWatched).clamp(0, 99999),
        isLimitReached: isReached,
        lockTimestamp: isReached && _simulatedStatus.lockTimestamp == 0
            ? DateTime.now().millisecondsSinceEpoch
            : _simulatedStatus.lockTimestamp,
      );

      _simulatedEvents.insert(
        0,
        DiagnosticEvent(
          id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: 'REELS_TRANSITION',
          detectionMethod: 'PC_SIMULATION',
          details: 'Simulated Reel swipe (+$count)',
          confidence: 'HIGH',
        ),
      );

      statusNotifier.value = _simulatedStatus;
      return _simulatedStatus;
    }

    try {
      final map = await _channel.invokeMapMethod<dynamic, dynamic>(
        'simulateReelSwipe',
        {'count': count},
      );
      if (map != null) {
        final status = DailyStatus.fromMap(map);
        statusNotifier.value = status;
        return status;
      }
    } catch (_) {}
    return _simulatedStatus;
  }

  Future<void> simulateReelEnter() async {
    _simulatedInsideReels = true;
    if (_simulationMode) {
      _simulatedEvents.insert(
        0,
        DiagnosticEvent(
          id: 'sim_enter_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: 'REELS_ENTERED',
          detectionMethod: 'PC_SIMULATION',
          details: 'Simulated entered Reels interface',
          confidence: 'HIGH',
        ),
      );
      return;
    }

    try {
      await _channel.invokeMethod('simulateReelEnter');
    } catch (_) {}
  }

  Future<void> simulateReelExit({int durationMs = 15000}) async {
    _simulatedInsideReels = false;
    if (_simulationMode) {
      _simulatedEvents.insert(
        0,
        DiagnosticEvent(
          id: 'sim_exit_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: 'REELS_EXITED',
          detectionMethod: 'PC_SIMULATION',
          details: 'Simulated exited Reels interface',
          confidence: 'HIGH',
          durationMs: durationMs,
        ),
      );
      return;
    }

    try {
      await _channel.invokeMethod('simulateReelExit', {'durationMs': durationMs});
    } catch (_) {}
  }

  Future<DailyStatus> simulateMidnightReset({int? newLimit}) async {
    final limitToUse = newLimit ??
        (_simulatedStatus.hasTomorrowLimitScheduled
            ? _simulatedStatus.tomorrowLimit
            : _simulatedStatus.dailyLimit);

    if (_simulationMode) {
      final historyList =
          List<DailyHistoryEntry>.from(_simulatedStatus.history);
      historyList.add(
        DailyHistoryEntry(
          date: _simulatedStatus.lastResetDate,
          reelsWatched: _simulatedStatus.reelsWatchedToday,
          limitSet: _simulatedStatus.dailyLimit,
          limitReached: _simulatedStatus.isLimitReached,
        ),
      );

      _simulatedStatus = DailyStatus(
        dailyLimit: limitToUse,
        reelsWatchedToday: 0,
        remainingReels: limitToUse,
        isLimitReached: false,
        lastResetDate: DateTime.now().toIso8601String().substring(0, 10),
        tomorrowLimit: -1,
        lockTimestamp: 0,
        history: historyList,
      );

      _simulatedEvents.insert(
        0,
        DiagnosticEvent(
          id: 'sim_reset_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: 'MIDNIGHT_RESET',
          detectionMethod: 'PC_SIMULATION',
          details: 'Simulated midnight day reset',
          confidence: 'HIGH',
        ),
      );

      statusNotifier.value = _simulatedStatus;
      return _simulatedStatus;
    }

    try {
      final map = await _channel.invokeMapMethod<dynamic, dynamic>(
        'simulateMidnightReset',
        {'newLimit': limitToUse},
      );
      if (map != null) {
        final status = DailyStatus.fromMap(map);
        statusNotifier.value = status;
        return status;
      }
    } catch (_) {}
    return _simulatedStatus;
  }

  Future<void> openLimitReachedScreen() async {
    if (!_simulationMode) {
      try {
        await _channel.invokeMethod('openLimitReachedScreen');
      } catch (_) {}
    }
  }
}
