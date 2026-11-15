package com.reellock.wellbeing.reellock_wellbeing

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

object DailyLimitManager {
    private const val PREFS_NAME = "reellock_daily_limit_prefs"
    private const val KEY_DAILY_LIMIT = "daily_limit"
    private const val KEY_REELS_WATCHED = "reels_watched"
    private const val KEY_IS_LIMIT_REACHED = "is_limit_reached"
    private const val KEY_LAST_RESET_DATE = "last_reset_date"
    private const val KEY_TOMORROW_LIMIT = "tomorrow_limit"
    private const val KEY_LOCK_TIMESTAMP = "lock_timestamp"
    private const val KEY_HISTORY = "history_entries"

    const val DEFAULT_DAILY_LIMIT = 100

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun getTodayDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    @Synchronized
    fun checkAndResetIfNewDay(context: Context) {
        val prefs = getPrefs(context)
        val today = getTodayDateString()
        val lastDate = prefs.getString(KEY_LAST_RESET_DATE, null)

        if (lastDate == null) {
            // First run initialization
            prefs.edit()
                .putString(KEY_LAST_RESET_DATE, today)
                .putInt(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
                .putInt(KEY_REELS_WATCHED, 0)
                .putBoolean(KEY_IS_LIMIT_REACHED, false)
                .putInt(KEY_TOMORROW_LIMIT, -1)
                .putLong(KEY_LOCK_TIMESTAMP, 0L)
                .apply()
            return
        }

        if (lastDate != today) {
            // Record yesterday's summary into history
            val prevWatched = prefs.getInt(KEY_REELS_WATCHED, 0)
            val prevLimit = prefs.getInt(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
            val prevReached = prefs.getBoolean(KEY_IS_LIMIT_REACHED, false)
            saveHistoryEntry(context, lastDate, prevWatched, prevLimit, prevReached)

            // Check if tomorrow's limit was scheduled
            val tomorrowLimit = prefs.getInt(KEY_TOMORROW_LIMIT, -1)
            val newDailyLimit = if (tomorrowLimit > 0) tomorrowLimit else prevLimit

            // Perform midnight reset
            prefs.edit()
                .putString(KEY_LAST_RESET_DATE, today)
                .putInt(KEY_DAILY_LIMIT, newDailyLimit)
                .putInt(KEY_REELS_WATCHED, 0)
                .putBoolean(KEY_IS_LIMIT_REACHED, false)
                .putInt(KEY_TOMORROW_LIMIT, -1)
                .putLong(KEY_LOCK_TIMESTAMP, 0L)
                .apply()
        }
    }

    @Synchronized
    fun getReelsCount(context: Context): Int {
        checkAndResetIfNewDay(context)
        return getPrefs(context).getInt(KEY_REELS_WATCHED, 0)
    }

    @Synchronized
    fun getDailyQuota(context: Context): Int {
        checkAndResetIfNewDay(context)
        return getPrefs(context).getInt(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
    }

    @Synchronized
    fun getRemainingQuota(context: Context): Int {
        checkAndResetIfNewDay(context)
        val limit = getDailyQuota(context)
        val watched = getReelsCount(context)
        return (limit - watched).coerceAtLeast(0)
    }

    @Synchronized
    fun setDailyQuota(context: Context, newLimit: Int): Boolean {
        checkAndResetIfNewDay(context)
        val prefs = getPrefs(context)
        val isReached = prefs.getBoolean(KEY_IS_LIMIT_REACHED, false)

        // Strict rule: once reached today, today's limit cannot be increased or bypassed
        if (isReached) {
            return false
        }

        if (newLimit <= 0) return false

        prefs.edit().putInt(KEY_DAILY_LIMIT, newLimit).apply()
        return true
    }

    @Synchronized
    fun setTomorrowLimit(context: Context, tomorrowLimit: Int): Boolean {
        checkAndResetIfNewDay(context)
        if (tomorrowLimit <= 0) return false
        getPrefs(context).edit().putInt(KEY_TOMORROW_LIMIT, tomorrowLimit).apply()
        return true
    }

    @Synchronized
    fun incrementReelsCount(context: Context, amount: Int = 1): Map<String, Any> {
        checkAndResetIfNewDay(context)
        val prefs = getPrefs(context)
        var watched = prefs.getInt(KEY_REELS_WATCHED, 0) + amount
        val limit = prefs.getInt(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
        val wasReached = prefs.getBoolean(KEY_IS_LIMIT_REACHED, false)
        val isNowReached = wasReached || (watched >= limit)

        val editor = prefs.edit()
        editor.putInt(KEY_REELS_WATCHED, watched)
        if (isNowReached && !wasReached) {
            editor.putBoolean(KEY_IS_LIMIT_REACHED, true)
            editor.putLong(KEY_LOCK_TIMESTAMP, System.currentTimeMillis())
        }
        editor.apply()

        return getStatus(context)
    }

    @Synchronized
    fun isLimitReached(context: Context): Boolean {
        checkAndResetIfNewDay(context)
        val prefs = getPrefs(context)
        return prefs.getBoolean(KEY_IS_LIMIT_REACHED, false)
    }

    @Synchronized
    fun getLockStatus(context: Context): Map<String, Any> {
        checkAndResetIfNewDay(context)
        val prefs = getPrefs(context)
        val isReached = prefs.getBoolean(KEY_IS_LIMIT_REACHED, false)
        val lockTimestamp = prefs.getLong(KEY_LOCK_TIMESTAMP, 0L)
        val limit = prefs.getInt(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
        val watched = prefs.getInt(KEY_REELS_WATCHED, 0)

        // Calculate remaining time until midnight
        val now = Calendar.getInstance()
        val midnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val remainingMs = (midnight.timeInMillis - now.timeInMillis).coerceAtLeast(0L)

        return mapOf(
            "isLocked" to isReached,
            "lockTimestamp" to lockTimestamp,
            "remainingTimeUntilMidnightMs" to remainingMs,
            "dailyQuota" to limit,
            "reelsWatched" to watched,
            "remainingQuota" to (limit - watched).coerceAtLeast(0)
        )
    }

    @Synchronized
    fun getStatus(context: Context): Map<String, Any> {
        checkAndResetIfNewDay(context)
        val prefs = getPrefs(context)
        val limit = prefs.getInt(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
        val watched = prefs.getInt(KEY_REELS_WATCHED, 0)
        val isReached = prefs.getBoolean(KEY_IS_LIMIT_REACHED, false)
        val lastDate = prefs.getString(KEY_LAST_RESET_DATE, getTodayDateString()) ?: getTodayDateString()
        val tomorrowLimit = prefs.getInt(KEY_TOMORROW_LIMIT, -1)
        val lockTimestamp = prefs.getLong(KEY_LOCK_TIMESTAMP, 0L)
        val historyList = getHistoryEntries(context)

        return mapOf(
            "dailyLimit" to limit,
            "reelsWatchedToday" to watched,
            "remainingReels" to (limit - watched).coerceAtLeast(0),
            "isLimitReached" to isReached,
            "lastResetDate" to lastDate,
            "tomorrowLimit" to tomorrowLimit,
            "lockTimestamp" to lockTimestamp,
            "history" to historyList
        )
    }

    @Synchronized
    fun forceResetForTesting(context: Context, newLimit: Int = DEFAULT_DAILY_LIMIT): Map<String, Any> {
        val today = getTodayDateString()
        getPrefs(context).edit()
            .putString(KEY_LAST_RESET_DATE, today)
            .putInt(KEY_DAILY_LIMIT, newLimit)
            .putInt(KEY_REELS_WATCHED, 0)
            .putBoolean(KEY_IS_LIMIT_REACHED, false)
            .putInt(KEY_TOMORROW_LIMIT, -1)
            .putLong(KEY_LOCK_TIMESTAMP, 0L)
            .apply()
        return getStatus(context)
    }

    private fun saveHistoryEntry(context: Context, date: String, watched: Int, limit: Int, reached: Boolean) {
        try {
            val prefs = getPrefs(context)
            val jsonStr = prefs.getString(KEY_HISTORY, "[]")
            val array = JSONArray(jsonStr)

            val entry = JSONObject().apply {
                put("date", date)
                put("reelsWatched", watched)
                put("limitSet", limit)
                put("limitReached", reached)
            }
            array.put(entry)

            // Keep only last 14 days
            val trimmed = JSONArray()
            val startIdx = (array.length() - 14).coerceAtLeast(0)
            for (i in startIdx until array.length()) {
                trimmed.put(array.getJSONObject(i))
            }

            prefs.edit().putString(KEY_HISTORY, trimmed.toString()).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getHistoryEntries(context: Context): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        try {
            val jsonStr = getPrefs(context).getString(KEY_HISTORY, "[]")
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    mapOf(
                        "date" to obj.optString("date"),
                        "reelsWatched" to obj.optInt("reelsWatched"),
                        "limitSet" to obj.optInt("limitSet"),
                        "limitReached" to obj.optBoolean("limitReached")
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
    }
}
