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
            subtitle: status.accessibilityServiceEnabled
                ? 'Active: Real-time Reels viewer & transition detector'
                : 'Controlled by restricted setting on Android 13+? Tap for 2-step fix',
            isGranted: status.accessibilityServiceEnabled,
            buttonText: 'Open Accessibility',
            onTap: () {
              _showRestrictedSettingsGuide(context, detector);
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

  void _showRestrictedSettingsGuide(BuildContext context, DetectorService detector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonPink.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: AppColors.neonPink, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enable Accessibility (Android 13+)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'On Samsung One UI and Android 13/14+, downloaded APKs are initially flagged with "Controlled by restricted setting". Follow these 2 steps to grant access safely:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Step 1
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.neonPink,
                          child: Text('1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Step 1: Allow Restricted Settings',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'In App Info, tap the top-right three dots (⋮) menu, then select "Allow restricted settings". Authenticate with your phone PIN or fingerprint.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await detector.openAppDetailsSettings();
                          onRefresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.settings_applications_rounded, size: 16),
                        label: const Text('Open App Info (Step 1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Step 2
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.neonCyan,
                          child: Text('2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Step 2: Turn ON REELLOCK Service',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Go to Accessibility → Installed apps → REELLOCK Wellbeing → Toggle switch ON.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await detector.requestAccessibilityPermission();
                          onRefresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.accessibility_new_rounded, size: 16),
                        label: const Text('Open Accessibility (Step 2)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onRefresh();
                  },
                  child: const Text('I\'ve Completed Both Steps • Refresh Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
