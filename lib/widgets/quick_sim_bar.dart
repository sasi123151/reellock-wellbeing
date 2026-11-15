import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../services/detector_service.dart';
import '../screens/limit_reached_screen.dart';

class QuickSimBar extends StatelessWidget {
  const QuickSimBar({super.key});

  @override
  Widget build(BuildContext context) {
    final detector = DetectorService();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.neonPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'PC SIMULATION CONTROLLER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.neonPurple,
                  ),
                ),
                const Spacer(),
                const Text(
                  'SEPARATE TEST ENGINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _simButton(
                    context: context,
                    label: '+1 Reel',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () async {
                      await detector.simulateReelSwipe(count: 1);
                      if (context.mounted && detector.statusNotifier.value.isLimitReached) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _simButton(
                    context: context,
                    label: '+10 Reels',
                    icon: Icons.fast_forward_rounded,
                    onPressed: () async {
                      await detector.simulateReelSwipe(count: 10);
                      if (context.mounted && detector.statusNotifier.value.isLimitReached) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _simButton(
                    context: context,
                    label: 'Max Limit',
                    icon: Icons.lock_outline_rounded,
                    color: AppColors.neonPink,
                    onPressed: () async {
                      final status = detector.statusNotifier.value;
                      final remaining = status.remainingReels;
                      await detector.simulateReelSwipe(count: remaining > 0 ? remaining : 1);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _simButton(
                    context: context,
                    label: 'Midnight Reset',
                    icon: Icons.restart_alt_rounded,
                    color: AppColors.neonCyan,
                    onPressed: () async {
                      await detector.simulateMidnightReset();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Simulated midnight reset: Daily quota restored!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _simButton(
                    context: context,
                    label: 'Lock UI',
                    icon: Icons.fullscreen_rounded,
                    color: AppColors.neonPurpleLight,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
