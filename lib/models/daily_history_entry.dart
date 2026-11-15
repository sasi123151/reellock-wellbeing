class DailyHistoryEntry {
  final String date;
  final int reelsWatched;
  final int limitSet;
  final bool limitReached;

  const DailyHistoryEntry({
    required this.date,
    required this.reelsWatched,
    required this.limitSet,
    required this.limitReached,
  });

  factory DailyHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return DailyHistoryEntry(
      date: map['date']?.toString() ?? '',
      reelsWatched: (map['reelsWatched'] as num?)?.toInt() ?? 0,
      limitSet: (map['limitSet'] as num?)?.toInt() ?? 100,
      limitReached: map['limitReached'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'reelsWatched': reelsWatched,
      'limitSet': limitSet,
      'limitReached': limitReached,
    };
  }
}
