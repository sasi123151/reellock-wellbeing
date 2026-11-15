package com.reellock.wellbeing.reellock_wellbeing

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import java.util.Calendar

object UsageStatsHelper {
    const val INSTAGRAM_PACKAGE = "com.instagram.android"

    fun hasUsageStatsPermission(context: Context): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
                ?: return false
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Calculates total Instagram foreground duration for the current calendar day (from 00:00:00 to now).
     */
    fun getInstagramForegroundDurationTodayMs(context: Context): Long {
        if (!hasUsageStatsPermission(context)) return 0L

        return try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                ?: return 0L

            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val startOfDay = calendar.timeInMillis
            val now = System.currentTimeMillis()

            val usageEvents = usageStatsManager.queryEvents(startOfDay, now)
            var totalTimeMs = 0L
            var lastForegroundTime = 0L
            var isForeground = false

            val event = UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                if (event.packageName == INSTAGRAM_PACKAGE) {
                    when (event.eventType) {
                        UsageEvents.Event.ACTIVITY_RESUMED -> {
                            isForeground = true
                            lastForegroundTime = event.timeStamp
                        }
                        UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.ACTIVITY_STOPPED -> {
                            if (isForeground && lastForegroundTime > 0) {
                                totalTimeMs += (event.timeStamp - lastForegroundTime)
                                isForeground = false
                                lastForegroundTime = 0L
                            }
                        }
                    }
                }
            }

            // If Instagram is still in foreground right now
            if (isForeground && lastForegroundTime > 0) {
                totalTimeMs += (now - lastForegroundTime)
            }

            // Fallback: If queryEvents returns 0, query aggregated stats
            if (totalTimeMs == 0L) {
                val stats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startOfDay,
                    now
                )
                val igStat = stats.firstOrNull { it.packageName == INSTAGRAM_PACKAGE }
                if (igStat != null) {
                    totalTimeMs = igStat.totalTimeInForeground
                }
            }

            totalTimeMs
        } catch (e: Exception) {
            e.printStackTrace()
            0L
        }
    }

    /**
     * Returns the timestamp (ms) when Instagram was last in foreground, or 0 if unavailable.
     */
    fun getLastTimeInstagramUsed(context: Context): Long {
        if (!hasUsageStatsPermission(context)) return 0L

        return try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                ?: return 0L

            val calendar = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -7)
            }
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                calendar.timeInMillis,
                System.currentTimeMillis()
            )
            val igStat = stats.filter { it.packageName == INSTAGRAM_PACKAGE }
                .maxByOrNull { it.lastTimeUsed }
            igStat?.lastTimeUsed ?: 0L
        } catch (e: Exception) {
            0L
        }
    }
}

