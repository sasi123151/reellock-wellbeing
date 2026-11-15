import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../models/daily_status.dart';
import '../models/monitoring_status.dart';
import '../services/detector_service.dart';
import '../widgets/focus_meter_gauge.dart';
import '../widgets/instagram_connection_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/update_banner.dart';
import 'limit_reached_screen.dart';
import 'limit_settings_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> with WidgetsBindingObserver {
  final DetectorService _detector = DetectorService();
  MonitoringStatus _monitoringStatus = MonitoringStatus.initial();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final status = await _detector.getMonitoringStatus();
    await _detector.getDailyStatus();
    if (mounted) {
      setState(() {
        _monitoringStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<DailyStatus>(
          valueListenable: _detector.statusNotifier,
          builder: (context, status, _) {
            final isReached = status.isLimitReached;

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.neonPurple,
              backgroundColor: AppColors.surfaceElevated,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Bar (Neon themed header)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'REELLOCK',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _detector.isSimulationMode
                                    ? AppColors.neonPurple.withValues(alpha: 0.2)
                                    : (_monitoringStatus.isConnected
                                        ? AppColors.neonCyan.withValues(alpha: 0.2)
                                        : AppColors.neonPink.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _detector.isSimulationMode
                                      ? AppColors.neonPurple.withValues(alpha: 0.6)
                                      : (_monitoringStatus.isConnected
                                          ? AppColors.neonCyan.withValues(alpha: 0.6)
                                          : AppColors.neonPink.withValues(alpha: 0.6)),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                _detector.isSimulationMode
                                    ? 'SIMULATED'
                                    : (_monitoringStatus.isConnected
                                        ? 'LIVE ANDROID'
                                        : 'DISCONNECTED'),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: _detector.isSimulationMode
                                      ? AppColors.neonPurpleLight
                                      : (_monitoringStatus.isConnected
                                          ? AppColors.neonCyan
                                          : AppColors.neonPink),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Focus Score Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: AppColors.neonCyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${status.clarityScore}% CLARITY',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // In-App Update Banner (Persistent until updated)
                    const UpdateBanner(),

                    const SizedBox(height: 12),

                    // 1. Instagram Connection Card
                    InstagramConnectionCard(
                      status: _monitoringStatus,
                      onRefresh: _refresh,
                    ),

                    const SizedBox(height: 24),

                    // Central Glowing Focus Meter (Neon Purple/Cyan/Pink Arc)
                    FocusMeterGauge(
                      watched: status.reelsWatchedToday,
                      limit: status.dailyLimit,
                      isLimitReached: isReached,
                      size: 240,
                    ),

                    const SizedBox(height: 24),

                    // Real Status & Lock Banner
                    if (isReached)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.neonPink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, color: AppColors.neonPink, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DAILY LIMIT HIT — REELS LOCKED',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: AppColors.neonPink,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Instagram Reels access is blocked until midnight. Tap for lock screen.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.neonPink, size: 20),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppColors.neonCyan, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _monitoringStatus.isConnected
                                    ? 'Real Android Monitoring Active • Quota Enforced'
                                    : 'Enable permissions above to activate real Reels tracking.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 4 Grid Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: 'Daily Quota',
                            value: '${status.dailyLimit}',
                            subtitle: 'Allowed Reels',
                            icon: Icons.flag_rounded,
                            accentColor: AppColors.neonPurple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LimitSettingsScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'Remaining',
                            value: '${status.remainingReels}',
                            subtitle: 'Reels left today',
                            icon: Icons.hourglass_top_rounded,
                            accentColor: isReached ? AppColors.neonPink : AppColors.neonCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: 'Clarity Score',
                            value: '${status.clarityScore}%',
                            subtitle: 'Attention strength',
                            icon: Icons.psychology_rounded,
                            accentColor: AppColors.neonCyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'Estimated Saved',
                            value: '${(status.dailyLimit > status.reelsWatchedToday ? (status.dailyLimit - status.reelsWatchedToday) * 0.5 : 0).toStringAsFixed(0)}m',
                            subtitle: 'Time preserved',
                            icon: Icons.trending_up_rounded,
                            accentColor: AppColors.neonPurpleLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Quota Action Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.neonPurple),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daily Quota Settings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReached
                                      ? 'Locked today. Schedule tomorrow\'s limit.'
                                      : 'Default: 100 Reels. Adjust allowance.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LimitSettingsScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated,
                              foregroundColor: AppColors.neonPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.neonPurple, width: 1),
                              ),
                            ),
                            child: const Text('Manage', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
