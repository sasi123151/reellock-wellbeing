import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../services/detector_service.dart';

class LimitReachedScreen extends StatefulWidget {
  const LimitReachedScreen({super.key});

  @override
  State<LimitReachedScreen> createState() => _LimitReachedScreenState();
}

class _LimitReachedScreenState extends State<LimitReachedScreen> {
  Timer? _timer;
  Duration _timeUntilMidnight = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeUntilMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTimeUntilMidnight();
        });
      }
    });
  }

  void _updateTimeUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _timeUntilMidnight = tomorrow.difference(now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final detector = DetectorService();
    final status = detector.statusNotifier.value;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.pureBlack,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Lock Emblem with Neon Pink glow
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(
                      color: AppColors.neonPink.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPink.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 48,
                      color: AppColors.neonPink,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Main Warning Heading
                const Text(
                  'YOU HIT YOUR DAILY LIMIT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle explanation
                Text(
                  'You set a daily quota of ${status.dailyLimit} Reels today (${status.reelsWatchedToday} confirmed transitions).\n\nInstagram Reels is locked for the remainder of today to protect your attention and dopamine baseline.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),

                // Countdown Box to midnight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.08),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'AUTOMATIC MIDNIGHT RESET IN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.neonCyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_timeUntilMidnight),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Return to dashboard button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: AppColors.neonPurple.withValues(alpha: 0.5),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Back to REELLOCK Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Android Lock Enforcement: Attempting to enter Reels will kick back to this screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
