import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../models/monitoring_status.dart';
import '../services/detector_service.dart';

class InstagramConnectionCard extends StatelessWidget {
  final MonitoringStatus status;
  final VoidCallback onRefresh;

  const InstagramConnectionCard({
    super.key,
    required this.status,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final detector = DetectorService();
    final isConnected = status.isConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.neonCyan.withValues(alpha: 0.4)
              : AppColors.neonPink.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? AppColors.neonCyan.withValues(alpha: 0.08)
                : AppColors.neonPink.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isConnected
                            ? AppColors.neonCyan.withValues(alpha: 0.4)
                            : AppColors.neonPink.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: isConnected ? AppColors.neonCyan : AppColors.neonPink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSTAGRAM CONNECTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Real-time Reels detection link',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Connected / Disconnected Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.neonCyan.withValues(alpha: 0.15)
                      : AppColors.neonPink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? AppColors.neonCyan : AppColors.neonPink,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? AppColors.neonCyan : AppColors.neonPink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'CONNECTED' : 'ACTION REQUIRED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isConnected ? AppColors.neonCyan : AppColors.neonPink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Permissions Status List
          _buildPermissionItem(
            context: context,
            icon: Icons.accessibility_new_rounded,
            title: 'Android Accessibility Service',
            subtitle: 'Detects Instagram Reels viewer & transition swipes',
            isGranted: status.accessibilityServiceEnabled,
            buttonText: 'Open Accessibility',
            onTap: () async {
              await detector.requestAccessibilityPermission();
              onRefresh();
            },
          ),

          const SizedBox(height: 10),

          _buildPermissionItem(
            context: context,
            icon: Icons.timer_outlined,
            title: 'Usage Access Permission',
            subtitle: 'Measures foreground session time of com.instagram.android',
            isGranted: status.usagePermissionGranted,
            buttonText: 'Open Usage Access',
            onTap: () async {
              await detector.requestUsageAccess();
              onRefresh();
            },
          ),

          const SizedBox(height: 14),

          // Monitored Data Transparency Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.neonCyan.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'What REELLOCK Monitors: Detects when com.instagram.android enters the Reels viewer and counts vertical transitions. Zero personal chats, camera, passwords, or search queries are ever accessed.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted
              ? AppColors.neonCyan.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : icon,
            size: 18,
            color: isGranted ? AppColors.neonCyan : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isGranted)
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            )
          else
            const Icon(Icons.verified_rounded, size: 16, color: AppColors.neonCyan),
        ],
      ),
    );
  }
}
