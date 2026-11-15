package com.reellock.wellbeing.reellock_wellbeing

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

data class WellbeingEvent(
    val id: String,
    val timestamp: Long,
    val eventType: String,       // e.g. "REELS_ENTERED", "REELS_TRANSITION", "REELS_EXITED", "FEED_IGNORED"
    val detectionMethod: String, // e.g. "ACCESSIBILITY_CLIPS_VIEWER", "SEARCH_REEL_PAGER", "USAGE_STATS"
    val details: String,
    val confidence: String = "HIGH", // "HIGH", "MEDIUM", "LOW"
    val durationMs: Long = 0
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "id" to id,
            "timestamp" to timestamp,
            "eventType" to eventType,
            "detectionMethod" to detectionMethod,
            "details" to details,
            "confidence" to confidence,
            "durationMs" to durationMs
        )
    }

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("id", id)
            put("timestamp", timestamp)
            put("eventType", eventType)
            put("detectionMethod", detectionMethod)
            put("details", details)
            put("confidence", confidence)
            put("durationMs", durationMs)
        }
    }

    companion object {
        fun fromJson(json: JSONObject): WellbeingEvent {
            return WellbeingEvent(
                id = json.optString("id", System.currentTimeMillis().toString()),
                timestamp = json.optLong("timestamp", System.currentTimeMillis()),
                eventType = json.optString("eventType", "UNKNOWN"),
                detectionMethod = json.optString("detectionMethod", "NONE"),
                details = json.optString("details", ""),
                confidence = json.optString("confidence", "HIGH"),
                durationMs = json.optLong("durationMs", 0)
            )
        }
    }
}

object WellbeingEventRepository {
    private const val PREFS_NAME = "reellock_wellbeing_prefs"
    private const val KEY_EVENTS = "stored_events"
    private const val MAX_EVENTS = 200

    private val inMemoryEvents = mutableListOf<WellbeingEvent>()
    private var isInitialized = false

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    @Synchronized
    fun init(context: Context) {
        if (isInitialized) return
        inMemoryEvents.clear()
        val prefs = getPrefs(context)
        val jsonStr = prefs.getString(KEY_EVENTS, null)
        if (!jsonStr.isNullOrEmpty()) {
            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    inMemoryEvents.add(WellbeingEvent.fromJson(array.getJSONObject(i)))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        isInitialized = true
    }

    @Synchronized
    fun recordEvent(context: Context, event: WellbeingEvent) {
        init(context)
        inMemoryEvents.add(0, event) // most recent first
        if (inMemoryEvents.size > MAX_EVENTS) {
            inMemoryEvents.removeAt(inMemoryEvents.size - 1)
        }
        persist(context)
    }

    @Synchronized
    private fun persist(context: Context) {
        try {
            val array = JSONArray()
            for (ev in inMemoryEvents) {
                array.put(ev.toJson())
            }
            getPrefs(context).edit().putString(KEY_EVENTS, array.toString()).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @Synchronized
    fun getEvents(context: Context): List<Map<String, Any>> {
        init(context)
        return inMemoryEvents.map { it.toMap() }
    }

    @Synchronized
    fun getReelsTransitionCount(context: Context): Int {
        init(context)
        return inMemoryEvents.count { it.eventType == "REELS_TRANSITION" }
    }

    @Synchronized
    fun getEstimatedReelsTimeMs(context: Context): Long {
        init(context)
        return inMemoryEvents
            .filter { it.eventType == "REELS_EXITED" }
            .sumOf { it.durationMs }
    }

    @Synchronized
    fun clearEvents(context: Context) {
        inMemoryEvents.clear()
        getPrefs(context).edit().remove(KEY_EVENTS).apply()
    }
}
