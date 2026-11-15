import 'daily_history_entry.dart';

class DailyStatus {
  final int dailyLimit;
  final int reelsWatchedToday;
  final int remainingReels;
  final bool isLimitReached;
  final String lastResetDate;
  final int tomorrowLimit;
  final int lockTimestamp;
  final List<DailyHistoryEntry> history;

  const DailyStatus({
    required this.dailyLimit,
    required this.reelsWatchedToday,
    required this.remainingReels,
    required this.isLimitReached,
    required this.lastResetDate,
    required this.tomorrowLimit,
    required this.lockTimestamp,
    required this.history,
  });

  double get progressFraction {
    if (dailyLimit <= 0) return 0.0;
    final ratio = reelsWatchedToday / dailyLimit;
    return ratio > 1.0 ? 1.0 : (ratio < 0.0 ? 0.0 : ratio);
  }

  int get clarityScore {
    if (isLimitReached) return 20;
    final remainingRatio = (dailyLimit - reelsWatchedToday) / (dailyLimit == 0 ? 1 : dailyLimit);
    final score = (remainingRatio * 100).round();
    return score.clamp(15, 98);
  }

  bool get hasTomorrowLimitScheduled => tomorrowLimit > 0;

  factory DailyStatus.initial() {
    return DailyStatus(
      dailyLimit: 100,
      reelsWatchedToday: 0,
      remainingReels: 100,
      isLimitReached: false,
      lastResetDate: DateTime.now().toIso8601String().substring(0, 10),
      tomorrowLimit: -1,
      lockTimestamp: 0,
      history: const [],
    );
  }

  factory DailyStatus.fromMap(Map<dynamic, dynamic> map) {
    final historyList = <DailyHistoryEntry>[];
    if (map['history'] is List) {
      for (final item in map['history'] as List) {
        if (item is Map) {
          historyList.add(DailyHistoryEntry.fromMap(item));
        }
      }
    }

    return DailyStatus(
      dailyLimit: (map['dailyLimit'] as num?)?.toInt() ?? 100,
      reelsWatchedToday: (map['reelsWatchedToday'] as num?)?.toInt() ?? 0,
      remainingReels: (map['remainingReels'] as num?)?.toInt() ?? 100,
      isLimitReached: map['isLimitReached'] == true,
      lastResetDate: map['lastResetDate']?.toString() ?? '',
      tomorrowLimit: (map['tomorrowLimit'] as num?)?.toInt() ?? -1,
      lockTimestamp: (map['lockTimestamp'] as num?)?.toInt() ?? 0,
      history: historyList,
    );
  }

  DailyStatus copyWith({
    int? dailyLimit,
    int? reelsWatchedToday,
    int? remainingReels,
    bool? isLimitReached,
    String? lastResetDate,
    int? tomorrowLimit,
    int? lockTimestamp,
    List<DailyHistoryEntry>? history,
  }) {
    return DailyStatus(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      reelsWatchedToday: reelsWatchedToday ?? this.reelsWatchedToday,
      remainingReels: remainingReels ?? this.remainingReels,
      isLimitReached: isLimitReached ?? this.isLimitReached,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      tomorrowLimit: tomorrowLimit ?? this.tomorrowLimit,
      lockTimestamp: lockTimestamp ?? this.lockTimestamp,
      history: history ?? this.history,
    );
  }
}
