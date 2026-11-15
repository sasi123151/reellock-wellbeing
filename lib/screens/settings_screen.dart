import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../models/diagnostic_event.dart';
import '../models/monitoring_status.dart';
import '../services/detector_service.dart';
import '../services/update_service.dart';
import '../widgets/update_banner.dart';
import 'limit_reached_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DetectorService _detector = DetectorService();
  MonitoringStatus _status = MonitoringStatus.initial();
  List<DiagnosticEvent> _logs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final s = await _detector.getMonitoringStatus();
    final logs = await _detector.getDiagnosticLogs();
    if (mounted) {
      setState(() {
        _status = s;
        _logs = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonPurple),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Android Monitoring & Permissions Section
              const Text(
                'ANDROID MONITORING PERMISSIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildStatusRow(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Accessibility Service',
                      subtitle: 'Detects Reels swipe transitions & triggers lock',
                      isOk: _status.accessibilityServiceEnabled,
                      actionLabel: 'Open Settings',
                      onAction: () async {
                        await _detector.requestAccessibilityPermission();
                        await _refreshStatus();
                      },
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    _buildStatusRow(
                      icon: Icons.timer_outlined,
                      title: 'Usage Access Permission',
                      subtitle: 'Measures foreground time of com.instagram.android',
                      isOk: _status.usagePermissionGranted,
                      actionLabel: 'Open Settings',
                      onAction: () async {
                        await _detector.requestUsageAccess();
                        await _refreshStatus();
                      },
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    _buildStatusRow(
                      icon: Icons.install_mobile_rounded,
                      title: 'Target: com.instagram.android',
                      subtitle: _status.isInstagramInstalled
                          ? 'Installed and detected on Samsung device'
                          : 'Not detected on device',
                      isOk: _status.isInstagramInstalled,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 2. Real-time Detection Diagnostics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DETECTION DIAGNOSTIC LOGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.neonCyan,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await _detector.clearEvents();
                      await _refreshStatus();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 14, color: AppColors.textTertiary),
                    label: const Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_logs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Center(
                    child: Text(
                      'No events logged yet. Swipe Reels in Instagram on your device to view live event detection and confidence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                ..._logs.take(6).map((e) {
                  final isHigh = e.confidence == 'HIGH';
                  final isMedium = e.confidence == 'MEDIUM';
                  final badgeColor = isHigh ? AppColors.neonCyan : (isMedium ? AppColors.neonPurple : AppColors.textTertiary);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            e.confidence,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.eventType} • ${e.formattedTime}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.details,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              if (kDebugMode) ...[
                const SizedBox(height: 28),

                // 3. PC Simulation Mode Switch & Controller (Debug Only)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PC SIMULATION MODE (SEPARATE)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.neonPurple,
                      ),
                    ),
                    Switch(
                      value: _detector.isSimulationMode,
                      activeThumbColor: AppColors.neonPurple,
                      activeTrackColor: AppColors.neonPurpleDark.withValues(alpha: 0.5),
                      onChanged: (val) {
                        setState(() {
                          _detector.setSimulationMode(val);
                        });
                        _refreshStatus();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Simulation mode is strictly separated from real Android monitoring. It generates synthetic events so you can test dashboard UI and lockout transitions without affecting actual device counters.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulation Action Triggers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              await _detector.simulateReelSwipe(count: 1);
                              if (!mounted) return;
                              if (_detector.statusNotifier.value.isLimitReached) {
                                navigator.push(
                                  MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('+1 Simulated Swipe'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              await _detector.simulateReelSwipe(count: 10);
                              if (!mounted) return;
                              if (_detector.statusNotifier.value.isLimitReached) {
                                navigator.push(
                                  MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                                );
                              }
                            },
                            icon: const Icon(Icons.fast_forward_rounded, size: 16),
                            label: const Text('+10 Simulated Reels'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final status = _detector.statusNotifier.value;
                              await _detector.simulateReelSwipe(
                                count: status.remainingReels > 0 ? status.remainingReels : 1,
                              );
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                              );
                            },
                            icon: const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.neonPink),
                            label: const Text('Hit Quota (Lock)', style: TextStyle(color: AppColors.neonPink)),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await _detector.simulateMidnightReset();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Simulated midnight reset applied!')),
                              );
                            },
                            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.neonCyan),
                            label: const Text('Midnight Reset', style: TextStyle(color: AppColors.neonCyan)),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LimitReachedScreen()),
                              );
                            },
                            icon: const Icon(Icons.fullscreen_rounded, size: 16),
                            label: const Text('Preview Lock Screen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // 4. In-App Updates System
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'APP UPDATES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.neonCyan,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await UpdateService().checkForUpdate();
                    },
                    icon: const Icon(Icons.sync_rounded, size: 14, color: AppColors.neonCyan),
                    label: const Text('Check Now', style: TextStyle(fontSize: 11, color: AppColors.neonCyan)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Installed Version',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'v${UpdateService().currentVersionName} (${UpdateService().currentVersionCode})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.neonCyan),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: UpdateService().updateStatusNotifier,
                      builder: (context, statusText, _) {
                        return Text(
                          statusText,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const UpdateBanner(),

              const SizedBox(height: 28),

              // 5. Honest Technical Limitations & Samsung Android Notice
              const Text(
                'HONEST TECHNICAL DISCLOSURE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DisclosureItem(
                      title: 'Targeted Reels vs Whole App Lock Fallback',
                      description:
                          'Detection targets Instagram Reels viewer nodes (clips_video_container, clips_viewer, search result clips). If Instagram modifies its internal layout or obfuscates nodes, REELLOCK falls back to global back enforcement to prevent infinite scrolling.',
                    ),
                    SizedBox(height: 12),
                    _DisclosureItem(
                      title: 'Samsung Background & Battery Optimization',
                      description:
                          'On Samsung One UI devices, ensure REELLOCK Wellbeing is excluded from "Sleeping Apps" in Device Care settings to prevent the system from pausing the AccessibilityService during background transitions.',
                    ),
                    SizedBox(height: 12),
                    _DisclosureItem(
                      title: 'Zero Remote Data Leakage',
                      description:
                          'All detection, transition counting, confidence scoring, and quotas are computed strictly on-device in Android SharedPreferences. No private chats, feeds, or credentials are monitored or transmitted.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isOk,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOk
                  ? AppColors.neonCyan.withValues(alpha: 0.15)
                  : AppColors.neonPink.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOk ? Icons.check_rounded : icon,
              size: 18,
              color: isOk ? AppColors.neonCyan : AppColors.neonPink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isOk && actionLabel != null && onAction != null) ...[
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.neonPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOk
                    ? AppColors.neonCyan.withValues(alpha: 0.15)
                    : AppColors.neonPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOk ? 'ACTIVE' : 'MISSING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isOk ? AppColors.neonCyan : AppColors.neonPink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisclosureItem extends StatelessWidget {
  final String title;
  final String description;

  const _DisclosureItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
