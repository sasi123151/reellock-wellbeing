import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../models/daily_status.dart';
import '../services/detector_service.dart';
import '../widgets/metric_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final detector = DetectorService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<DailyStatus>(
          valueListenable: detector.statusNotifier,
          builder: (context, status, _) {
            final score = status.clarityScore;
            final isReached = status.isLimitReached;

            // 1. Dynamic Blocked Attempts: count of days in history with limitReached + today if reached
            final int blockedAttempts = status.history.where((e) => e.limitReached).length + (isReached ? 1 : 0);

            // 2. Dynamic Time Preserved: calculated from actual saved Reels (average ~45 seconds doomscroll saved per Reel)
            int savedMinutes = 0;
            for (final entry in status.history) {
              if (entry.reelsWatched > 0 && entry.reelsWatched < entry.limitSet) {
                savedMinutes += ((entry.limitSet - entry.reelsWatched) * 45 / 60).round();
              } else if (entry.limitReached) {
                savedMinutes += 30; // Estimated 30m doomscrolling avoided by locking
              }
            }
            if (isReached) {
              savedMinutes += 30;
            } else if (status.reelsWatchedToday > 0 && status.reelsWatchedToday < status.dailyLimit) {
              savedMinutes += ((status.dailyLimit - status.reelsWatchedToday) * 45 / 60).round();
            }

            final String timePreservedStr;
            if (savedMinutes <= 0) {
              timePreservedStr = '0m';
            } else if (savedMinutes < 60) {
              timePreservedStr = '${savedMinutes}m';
            } else {
              final h = savedMinutes ~/ 60;
              final m = savedMinutes % 60;
              timePreservedStr = m > 0 ? '${h}h ${m}m' : '${h}h';
            }

            // 3. Dynamic 7-day weekly bars from actual calendar dates and persisted history
            final now = DateTime.now();
            final List<_WeeklyDayStat> weekStats = [];
            const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

            for (int i = 6; i >= 0; i--) {
              final dayDate = now.subtract(Duration(days: i));
              final dateStr =
                  '${dayDate.year.toString().padLeft(4, '0')}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
              final isDayToday = (i == 0);
              final dayLabel = isDayToday ? 'Today' : dayLetters[dayDate.weekday - 1];

              if (isDayToday) {
                weekStats.add(_WeeklyDayStat(
                  label: dayLabel,
                  value: status.reelsWatchedToday,
                  limit: status.dailyLimit,
                  reached: isReached,
                  isToday: true,
                ));
              } else {
                final matchingList = status.history.where((e) => e.date == dateStr);
                if (matchingList.isNotEmpty) {
                  final entry = matchingList.first;
                  weekStats.add(_WeeklyDayStat(
                    label: dayLabel,
                    value: entry.reelsWatched,
                    limit: entry.limitSet,
                    reached: entry.limitReached,
                    isToday: false,
                  ));
                } else {
                  weekStats.add(_WeeklyDayStat(
                    label: dayLabel,
                    value: 0,
                    limit: status.dailyLimit,
                    reached: false,
                    isToday: false,
                  ));
                }
              }
            }

            final bool hasAnyActivity = status.history.isNotEmpty || status.reelsWatchedToday > 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Clarity Score Banner (Neon Cyan / Pink)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isReached
                            ? AppColors.neonPink.withValues(alpha: 0.4)
                            : AppColors.neonCyan.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Clarity Arc Indicator
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceElevated,
                            border: Border.all(
                              color: isReached ? AppColors.neonPink : AppColors.neonCyan,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isReached
                                    ? AppColors.neonPink.withValues(alpha: 0.25)
                                    : AppColors.neonCyan.withValues(alpha: 0.25),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isReached ? AppColors.neonPink : AppColors.neonCyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                score >= 80
                                    ? 'Optimal Focus State'
                                    : (score >= 50 ? 'Moderate Balance' : 'Dopamine Fatigue'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isReached
                                    ? 'Daily quota exhausted. Reels locked until midnight.'
                                    : 'Under daily quota. Mindful consumption active.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4 Grid Stats (All Dynamic)
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Blocked Attempts',
                          value: '$blockedAttempts',
                          subtitle: blockedAttempts == 0
                              ? 'No locks triggered'
                              : '$blockedAttempts lock ${blockedAttempts == 1 ? 'session' : 'sessions'}',
                          icon: Icons.shield_rounded,
                          accentColor: AppColors.neonPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Resistance Rate',
                          value:
                              '${(100 - (status.reelsWatchedToday * 100 / (status.dailyLimit > 0 ? status.dailyLimit : 1)).clamp(0, 100)).toInt()}%',
                          subtitle: 'Impulse control metric',
                          icon: Icons.verified_user_rounded,
                          accentColor: AppColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Reels Today',
                          value: '${status.reelsWatchedToday}',
                          subtitle: 'Of ${status.dailyLimit} allowed',
                          icon: Icons.movie_filter_rounded,
                          accentColor: isReached ? AppColors.neonPink : AppColors.neonPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Time Preserved',
                          value: timePreservedStr,
                          subtitle: 'Saved from endless doomscroll',
                          icon: Icons.access_time_filled_rounded,
                          accentColor: AppColors.neonPurpleLight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Weekly Activity Chart Card (Dynamic)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'THIS WEEK\'S REELS CONSUMPTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'QUOTA: ${status.dailyLimit}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neonPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!hasAnyActivity) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.bar_chart_rounded, size: 36, color: AppColors.textTertiary),
                                SizedBox(height: 10),
                                Text(
                                  'No weekly activity recorded yet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your daily consumption chart will appear here as you browse Instagram.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Dynamic 7-day bars
                          SizedBox(
                            height: 130,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: weekStats.map((stat) {
                                return _buildBar(
                                  stat.label,
                                  stat.value,
                                  stat.limit,
                                  stat.reached,
                                  isToday: stat.isToday,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Daily History List
                  const Text(
                    'DAILY CONSUMPTION HISTORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (status.history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Center(
                        child: Text(
                          'No archived days yet. Your daily usage history will appear here after midnight resets.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...status.history.reversed.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              entry.limitReached ? Icons.lock_clock_rounded : Icons.check_circle_rounded,
                              size: 18,
                              color: entry.limitReached ? AppColors.neonPink : AppColors.neonCyan,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.date,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entry.reelsWatched} of ${entry.limitSet} Reels watched',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.limitReached
                                    ? AppColors.neonPink.withValues(alpha: 0.15)
                                    : AppColors.neonCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.limitReached ? 'HIT LIMIT' : 'UNDER QUOTA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: entry.limitReached ? AppColors.neonPink : AppColors.neonCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBar(String dayLabel, int value, int limit, bool reached, {bool isToday = false}) {
    final double fraction = (limit > 0 ? (value / limit) : 0.0).clamp(0.0, 1.0);
    final double barHeight = value == 0 ? 4.0 : (fraction * 85).clamp(8.0, 85.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: reached
                ? AppColors.neonPink
                : (isToday
                    ? AppColors.neonCyan
                    : (value > 0 ? AppColors.textSecondary : AppColors.textTertiary)),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 22,
          height: barHeight,
          decoration: BoxDecoration(
            color: reached
                ? AppColors.neonPink
                : (isToday
                    ? (value > 0 ? AppColors.neonCyan : AppColors.neonCyan.withValues(alpha: 0.3))
                    : (value > 0 ? AppColors.surfaceHighlight : AppColors.surfaceElevated)),
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: AppColors.neonCyanLight, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? AppColors.neonCyan : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _WeeklyDayStat {
  final String label;
  final int value;
  final int limit;
  final bool reached;
  final bool isToday;

  const _WeeklyDayStat({
    required this.label,
    required this.value,
    required this.limit,
    required this.reached,
    this.isToday = false,
  });
}
