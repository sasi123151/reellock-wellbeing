package com.reellock.wellbeing.reellock_wellbeing

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.reellock.wellbeing/detector"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        WellbeingEventRepository.init(applicationContext)
        DailyLimitManager.checkAndResetIfNewDay(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // 1. Permissions & Monitoring Status
                "getMonitoringStatus" -> {
                    val usageGranted = UsageStatsHelper.hasUsageStatsPermission(applicationContext)
                    val accessEnabled = isAccessibilityServiceEnabled(applicationContext, ReelsAccessibilityService::class.java) || ReelsAccessibilityService.isServiceRunning
                    val isIgInstalled = checkAppInstalled(UsageStatsHelper.INSTAGRAM_PACKAGE)
                    val isConnected = usageGranted && accessEnabled

                    val statusMap = mapOf(
                        "usagePermissionGranted" to usageGranted,
                        "accessibilityServiceEnabled" to accessEnabled,
                        "isCurrentlyInsideReels" to ReelsAccessibilityService.isCurrentlyInsideReels,
                        "isInstagramInstalled" to isIgInstalled,
                        "isConnected" to isConnected,
                        "reelsSessionStartMs" to ReelsAccessibilityService.currentReelsSessionStartTime,
                        "detectionConfidence" to ReelsAccessibilityService.lastConfidenceScore
                    )
                    result.success(statusMap)
                }

                "checkUsagePermission" -> {
                    val hasPerm = UsageStatsHelper.hasUsageStatsPermission(applicationContext)
                    result.success(hasPerm)
                }

                "requestUsageAccess", "requestUsagePermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }

                "checkAccessibilityPermission" -> {
                    val isEnabled = isAccessibilityServiceEnabled(applicationContext, ReelsAccessibilityService::class.java)
                    result.success(isEnabled || ReelsAccessibilityService.isServiceRunning)
                }

                "requestAccessibilityPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }

                "isInstagramInstalled" -> {
                    val isInstalled = checkAppInstalled(UsageStatsHelper.INSTAGRAM_PACKAGE)
                    result.success(isInstalled)
                }

                // 2. Real Reels Count & Quota Methods
                "getReelsCount" -> {
                    val count = DailyLimitManager.getReelsCount(applicationContext)
                    result.success(count)
                }

                "getDailyQuota" -> {
                    val quota = DailyLimitManager.getDailyQuota(applicationContext)
                    result.success(quota)
                }

                "getRemainingQuota" -> {
                    val remaining = DailyLimitManager.getRemainingQuota(applicationContext)
                    result.success(remaining)
                }

                "setDailyQuota", "setDailyLimit" -> {
                    val quota = call.argument<Int>("quota") ?: call.argument<Int>("limit") ?: DailyLimitManager.DEFAULT_DAILY_LIMIT
                    val ok = DailyLimitManager.setDailyQuota(applicationContext, quota)
                    if (ok) {
                        result.success(DailyLimitManager.getStatus(applicationContext))
                    } else {
                        result.error("LOCKED", "Cannot change daily limit after limit is reached today.", null)
                    }
                }

                "setTomorrowLimit" -> {
                    val limit = call.argument<Int>("limit") ?: DailyLimitManager.DEFAULT_DAILY_LIMIT
                    val ok = DailyLimitManager.setTomorrowLimit(applicationContext, limit)
                    result.success(ok)
                }

                "getLockStatus" -> {
                    val lockMap = DailyLimitManager.getLockStatus(applicationContext)
                    result.success(lockMap)
                }

                "getDailyLimitStatus" -> {
                    val status = DailyLimitManager.getStatus(applicationContext)
                    result.success(status)
                }

                // 3. Diagnostic Logs & Events
                "getDiagnosticLogs", "getRecentEvents" -> {
                    val events = WellbeingEventRepository.getEvents(applicationContext)
                    result.success(events)
                }

                "clearRecordedEvents" -> {
                    WellbeingEventRepository.clearEvents(applicationContext)
                    result.success(true)
                }

                "getUsageStatsSummary" -> {
                    val igTimeMs = UsageStatsHelper.getInstagramForegroundDurationTodayMs(applicationContext)
                    val reelsTimeMs = WellbeingEventRepository.getEstimatedReelsTimeMs(applicationContext)
                    val reelsCount = DailyLimitManager.getReelsCount(applicationContext)
                    val lastUsedMs = UsageStatsHelper.getLastTimeInstagramUsed(applicationContext)

                    val summary = mapOf(
                        "instagramForegroundDurationMs" to igTimeMs,
                        "estimatedReelsDurationMs" to reelsTimeMs,
                        "estimatedReelsTransitionCount" to reelsCount,
                        "lastTimeInstagramUsedMs" to lastUsedMs
                    )
                    result.success(summary)
                }

                // 4. Testing & Simulation support (kept separate for PC testing)
                "simulateReelSwipe" -> {
                    val count = call.argument<Int>("count") ?: 1
                    val status = DailyLimitManager.incrementReelsCount(applicationContext, count)
                    WellbeingEventRepository.recordEvent(
                        applicationContext,
                        WellbeingEvent(
                            id = "sim_swipe_${System.currentTimeMillis()}",
                            timestamp = System.currentTimeMillis(),
                            eventType = "REELS_TRANSITION",
                            detectionMethod = "PC_SIMULATION",
                            details = "Simulated Reel consumption (+$count)",
                            confidence = "HIGH"
                        )
                    )
                    result.success(status)
                }

                "simulateReelEnter" -> {
                    WellbeingEventRepository.recordEvent(
                        applicationContext,
                        WellbeingEvent(
                            id = "sim_enter_${System.currentTimeMillis()}",
                            timestamp = System.currentTimeMillis(),
                            eventType = "REELS_ENTERED",
                            detectionMethod = "PC_SIMULATION",
                            details = "Simulated enter Reels interface",
                            confidence = "HIGH"
                        )
                    )
                    result.success(true)
                }

                "simulateReelExit" -> {
                    val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 12000L
                    WellbeingEventRepository.recordEvent(
                        applicationContext,
                        WellbeingEvent(
                            id = "sim_exit_${System.currentTimeMillis()}",
                            timestamp = System.currentTimeMillis(),
                            eventType = "REELS_EXITED",
                            detectionMethod = "PC_SIMULATION",
                            details = "Simulated exit Reels interface",
                            confidence = "HIGH",
                            durationMs = durationMs
                        )
                    )
                    result.success(true)
                }

                "simulateMidnightReset" -> {
                    val newLimit = call.argument<Int>("newLimit") ?: DailyLimitManager.DEFAULT_DAILY_LIMIT
                    val status = DailyLimitManager.forceResetForTesting(applicationContext, newLimit)
                    WellbeingEventRepository.recordEvent(
                        applicationContext,
                        WellbeingEvent(
                            id = "sim_reset_${System.currentTimeMillis()}",
                            timestamp = System.currentTimeMillis(),
                            eventType = "MIDNIGHT_RESET",
                            detectionMethod = "PC_SIMULATION",
                            details = "Simulated midnight reset",
                            confidence = "HIGH"
                        )
                    )
                    result.success(status)
                }

                "openLimitReachedScreen" -> {
                    try {
                        val intent = Intent(applicationContext, LimitReachedActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // In-App Auto-Update Management Channel
        val UPDATER_CHANNEL = "com.reellock.wellbeing/updater"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        val vCode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            pInfo.longVersionCode.toInt()
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode
                        }
                        val vName = pInfo.versionName ?: "1.0.0"
                        result.success(mapOf("versionCode" to vCode, "versionName" to vName))
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.localizedMessage, null)
                    }
                }
                "canRequestPackageInstalls" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSetting" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = android.net.Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "APK file path cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    val file = java.io.File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "APK file not found at: $filePath", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = androidx.core.content.FileProvider.getUriForFile(
                            applicationContext,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.localizedMessage, null)
                    }
                }
                "getCacheDirectory" -> {
                    result.success(applicationContext.cacheDir.absolutePath)
                }
                "verifySha256" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val expectedHash = call.argument<String>("expectedHash") ?: ""
                    val file = java.io.File(filePath)
                    if (!file.exists()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val digest = java.security.MessageDigest.getInstance("SHA-256")
                        file.inputStream().use { fis ->
                            val buffer = ByteArray(65536)
                            var bytesRead: Int
                            while (fis.read(buffer).also { bytesRead = it } != -1) {
                                digest.update(buffer, 0, bytesRead)
                            }
                        }
                        val actualHash = digest.digest().joinToString("") { "%02x".format(it) }
                        result.success(actualHash.equals(expectedHash, ignoreCase = true))
                    } catch (e: Exception) {
                        result.error("HASH_ERROR", e.localizedMessage, null)
                    }
                }
                "showUpdateNotification" -> {
                    val version = call.argument<String>("version") ?: "New Version"
                    val notes = call.argument<String>("notes") ?: "A new update for REELLOCK is available."
                    showUpdateSystemNotification(version, notes)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context, serviceClass: Class<*>): Boolean {
        val expectedComponentName = "${context.packageName}/${serviceClass.name}"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)

        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedComponentName, ignoreCase = true) ||
                componentName.contains(serviceClass.simpleName, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun showUpdateSystemNotification(version: String, notes: String) {
        try {
            val channelId = "reellock_updates"
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val channel = android.app.NotificationChannel(
                    channelId,
                    "REELLOCK Updates",
                    android.app.NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Notifications for REELLOCK Wellbeing app updates"
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            } else {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = android.app.PendingIntent.getActivity(applicationContext, 2001, launchIntent, flags)

            val builder = androidx.core.app.NotificationCompat.Builder(applicationContext, channelId)
                .setSmallIcon(android.R.drawable.stat_sys_download_done)
                .setContentTitle("REELLOCK Update Available: v$version")
                .setContentText(notes)
                .setStyle(androidx.core.app.NotificationCompat.BigTextStyle().bigText(notes))
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                    notificationManager.notify(2001, builder.build())
                }
            } else {
                notificationManager.notify(2001, builder.build())
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to display update system notification: ${e.message}")
        }
    }
}
