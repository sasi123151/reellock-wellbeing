import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../models/update_manifest.dart';
import '../services/update_service.dart';

class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final updateService = UpdateService();

    return ValueListenableBuilder<UpdateManifest?>(
      valueListenable: updateService.updateNotifier,
      builder: (context, manifest, _) {
        if (manifest == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: updateService.isDownloadingNotifier,
            builder: (context, isDownloading, _) {
              return ValueListenableBuilder<double>(
                valueListenable: updateService.downloadProgressNotifier,
                builder: (context, progress, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: updateService.updateStatusNotifier,
                    builder: (context, statusText, _) {
                      return Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.system_update_rounded,
                                    size: 18,
                                    color: AppColors.neonCyan,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'UPDATE AVAILABLE: v${manifest.latestVersion}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: AppColors.neonCyan,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        manifest.releaseNotes,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                            if (isDownloading) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress > 0.0 ? progress : null,
                                backgroundColor: AppColors.surface,
                                color: AppColors.neonCyan,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    statusText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (progress > 0.0)
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.neonCyan,
                                      ),
                                    ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      updateService.downloadAndInstallUpdate(manifest);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.neonCyan,
                                      foregroundColor: AppColors.background,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: const Text(
                                      'UPDATE NOW',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

