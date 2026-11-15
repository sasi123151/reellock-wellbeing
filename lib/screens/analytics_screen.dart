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

                  // 4 Grid Stats
                  Row(
                    children: [
                      const Expanded(
                        child: MetricCard(
                          label: 'Blocked Attempts',
                          value: '3',
                          subtitle: 'Reels launches blocked',
                          icon: Icons.shield_rounded,
                          accentColor: AppColors.neonPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Resistance Rate',
                          value: '${(100 - (status.reelsWatchedToday * 100 / (status.dailyLimit > 0 ? status.dailyLimit : 1)).clamp(0, 100)).toInt()}%',
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
                      const Expanded(
                        child: MetricCard(
                          label: 'Time Preserved',
                          value: '1h 45m',
                          subtitle: 'Saved from endless doomscroll',
                          icon: Icons.access_time_filled_rounded,
                          accentColor: AppColors.neonPurpleLight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Weekly Activity Chart Card
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
                        // 7 Day Bars
                        SizedBox(
                          height: 130,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar('M', 45, 100, false),
                              _buildBar('T', 68, 100, false),
                              _buildBar('W', 100, 100, true),
                              _buildBar('T', 35, 100, false),
                              _buildBar('F', 82, 100, false),
                              _buildBar('S', 95, 100, false),
                              _buildBar('Today', status.reelsWatchedToday, status.dailyLimit, isReached, isToday: true),
                            ],
                          ),
                        ),
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
    final double fraction = (limit > 0 ? (value / limit) : 0.0).clamp(0.08, 1.0);
    final double barHeight = fraction * 85;

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
                : (isToday ? AppColors.neonCyan : AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 22,
          height: barHeight,
          decoration: BoxDecoration(
            color: reached
                ? AppColors.neonPink
                : (isToday ? AppColors.neonCyan : AppColors.surfaceHighlight),
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
