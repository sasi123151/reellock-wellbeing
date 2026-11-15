package com.reellock.wellbeing.reellock_wellbeing

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class ReelsAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "ReelsAccessibility"
        const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val DEBOUNCE_SWIPE_MS = 850L

        @Volatile
        var isServiceRunning: Boolean = false
            private set

        @Volatile
        var isCurrentlyInsideReels: Boolean = false
            private set

        @Volatile
        var currentReelsSessionStartTime: Long = 0L
            private set

        var activeReelCandidateCount: Int = 0
            private set

        @Volatile
        var lastConfidenceScore: String = "NONE"
            private set
    }

    private var lastScrollTimestamp: Long = 0L
    private var lastEnforcementTimestamp: Long = 0L
    private lateinit var overlayManager: ReelsOverlayManager

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        overlayManager = ReelsOverlayManager(this)
        Log.i(TAG, "ReelsAccessibilityService connected and ready on Android.")
        checkRemoteUpdateInBackground()
        WellbeingEventRepository.recordEvent(
            applicationContext,
            WellbeingEvent(
                id = "srv_${System.currentTimeMillis()}",
                timestamp = System.currentTimeMillis(),
                eventType = "SERVICE_CONNECTED",
                detectionMethod = "LIFECYCLE",
                details = "AccessibilityService bound and active on Samsung/Android system",
                confidence = "HIGH"
            )
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return

        // If user is outside Instagram
        if (pkg != INSTAGRAM_PACKAGE) {
            if (::overlayManager.isInitialized) {
                overlayManager.removeAll()
            }
            if (isCurrentlyInsideReels) {
                exitReelsSession("APP_SWITCH_TO_$pkg")
            }
            return
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChanged(event)
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                handleViewScrolled(event)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                evaluateReelsPresence(event)
            }
        }

        val root = rootInActiveWindow
        if (root != null) {
            evaluateExplorePresence(root)
        }
    }

    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val className = event.className?.toString() ?: ""
        evaluateReelsPresence(event, className)
    }

    private fun handleViewScrolled(event: AccessibilityEvent) {
        val root = rootInActiveWindow ?: return

        // Check if user is in ordinary Instagram Feed or Direct messages
        if (isFeedOrDirectWindow(root)) {
            // Strictly reject feed scrolling: do not count ordinary post feed
            if (isCurrentlyInsideReels) {
                exitReelsSession("NAVIGATED_TO_FEED")
            }
            return
        }

        // Re-evaluate Reels presence if not marked inside
        if (!isCurrentlyInsideReels) {
            evaluateReelsPresence(event)
        }

        if (isCurrentlyInsideReels) {
            // Check if limit is already reached
            if (DailyLimitManager.isLimitReached(applicationContext)) {
                enforceLimitReached()
                return
            }

            val now = SystemClock.elapsedRealtime()
            if (now - lastScrollTimestamp > DEBOUNCE_SWIPE_MS) {
                lastScrollTimestamp = now
                activeReelCandidateCount++

                // Increment real daily count
                val status = DailyLimitManager.incrementReelsCount(applicationContext, 1)
                val isReached = status["isLimitReached"] as? Boolean ?: false
                val watched = status["reelsWatchedToday"] as? Int ?: activeReelCandidateCount

                val author = extractAuthorOrAudio(root)
                val confidence = lastConfidenceScore

                val details = if (author.isNotEmpty()) {
                    "Confirmed Reels vertical swipe transition ($author) [Total today: $watched]"
                } else {
                    "Confirmed Reels vertical swipe transition [Total today: $watched]"
                }

                WellbeingEventRepository.recordEvent(
                    applicationContext,
                    WellbeingEvent(
                        id = "trans_${System.currentTimeMillis()}",
                        timestamp = System.currentTimeMillis(),
                        eventType = "REELS_TRANSITION",
                        detectionMethod = "ACCESSIBILITY_CONFIRMED_VIEW_SCROLLED",
                        details = details,
                        confidence = confidence
                    )
                )
                Log.d(TAG, "Reel counted: $details (Confidence: $confidence)")

                if (isReached) {
                    enforceLimitReached()
                }
            }
        }
    }

    private fun evaluateReelsPresence(event: AccessibilityEvent, classNameHint: String = "") {
        val root = rootInActiveWindow ?: return

        // 1. Check if definitely in feed or messages
        if (isFeedOrDirectWindow(root)) {
            if (isCurrentlyInsideReels) {
                exitReelsSession("FEED_OR_DIRECT_DETECTED")
            }
            return
        }

        // 2. Detect Reels Viewer (Dedicated Tab or Search Result Viewer)
        val (isReels, confidence) = detectReelsSignatureWithConfidence(root, classNameHint)

        if (isReels) {
            lastConfidenceScore = confidence
            if (!isCurrentlyInsideReels) {
                enterReelsSession("SIGNATURE_MATCH ($confidence): $classNameHint")
            }

            // Immediately enforce if limit is already exhausted
            if (DailyLimitManager.isLimitReached(applicationContext)) {
                enforceLimitReached()
            }
        } else if (isCurrentlyInsideReels) {
            exitReelsSession("REELS_SIGNATURE_LOST")
        }
    }

    private fun detectReelsSignatureWithConfidence(root: AccessibilityNodeInfo, classNameHint: String): Pair<Boolean, String> {
        // High Confidence 1: Class name explicitly mentions ClipsViewer or ReelViewer
        if (classNameHint.contains("ClipsViewer", ignoreCase = true) ||
            classNameHint.contains("ReelViewerFragment", ignoreCase = true) ||
            classNameHint.contains("ClipsViewerFragment", ignoreCase = true)) {
            return Pair(true, "HIGH")
        }

        // High Confidence 2: Primary Instagram Clips video container resource IDs
        val clipsContainerNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_video_container")
        if (clipsContainerNodes.isNotEmpty()) return Pair(true, "HIGH")

        val clipsViewerNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_viewer")
        if (clipsViewerNodes.isNotEmpty()) return Pair(true, "HIGH")

        val reelViewerNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/reel_viewer")
        if (reelViewerNodes.isNotEmpty()) return Pair(true, "HIGH")

        val feedClipsHolder = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/feed_clips_view_holder")
        if (feedClipsHolder.isNotEmpty()) return Pair(true, "HIGH")

        val clipsSwipeLayout = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_swipe_refresh_layout")
        if (clipsSwipeLayout.isNotEmpty()) return Pair(true, "HIGH")

        // Search / Explore Reels Result Viewers
        val clipsMediaComponent = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_action_bar_button")
        if (clipsMediaComponent.isNotEmpty()) return Pair(true, "HIGH")

        // Medium Confidence: Content description or text markers inside Instagram
        val reelsTextNodes = root.findAccessibilityNodeInfosByText("Reels")
        if (reelsTextNodes.isNotEmpty()) {
            for (node in reelsTextNodes) {
                val desc = node.contentDescription?.toString() ?: ""
                val text = node.text?.toString() ?: ""
                if (desc.contains("Reels", ignoreCase = true) || text.equals("Reels", ignoreCase = true)) {
                    // Check that it's an active video viewer, not just the tab button
                    if (hasVerticalVideoIndicators(root)) {
                        return Pair(true, "MEDIUM")
                    }
                }
            }
        }

        // Audio tag detection commonly present on Reels overlay
        val audioNodes = root.findAccessibilityNodeInfosByText("Original audio")
        if (audioNodes.isNotEmpty()) {
            return Pair(true, "MEDIUM")
        }

        return Pair(false, "NONE")
    }

    private fun hasVerticalVideoIndicators(root: AccessibilityNodeInfo): Boolean {
        // Looks for audio, like, comment, share, bookmark buttons stacked vertically
        val likeNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/like_button")
        val commentNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/comment_button")
        val shareNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/direct_share_button")
        return likeNodes.isNotEmpty() || commentNodes.isNotEmpty() || shareNodes.isNotEmpty()
    }

    private fun isFeedOrDirectWindow(root: AccessibilityNodeInfo): Boolean {
        // Direct messages
        val directNodes = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/direct_message_list")
        if (directNodes.isNotEmpty()) return true

        // Main Feed recyclerView when clips_video_container is not active
        val feedRecycler = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/feed_recycler_view")
        val clipsContainer = root.findAccessibilityNodeInfosByViewId("com.instagram.android:id/clips_video_container")
        if (feedRecycler.isNotEmpty() && clipsContainer.isEmpty()) {
            return true
        }

        return false
    }

    private fun extractAuthorOrAudio(root: AccessibilityNodeInfo?): String {
        if (root == null) return ""
        try {
            val audioNodes = root.findAccessibilityNodeInfosByText("audio")
            if (audioNodes.isNotEmpty()) {
                val nodeText = audioNodes.first().text?.toString() ?: ""
                if (nodeText.isNotEmpty()) return "Audio: $nodeText"
            }
        } catch (_: Exception) {}
        return ""
    }

    private fun enterReelsSession(triggerReason: String) {
        isCurrentlyInsideReels = true
        currentReelsSessionStartTime = System.currentTimeMillis()
        activeReelCandidateCount = 0

        WellbeingEventRepository.recordEvent(
            applicationContext,
            WellbeingEvent(
                id = "enter_${System.currentTimeMillis()}",
                timestamp = currentReelsSessionStartTime,
                eventType = "REELS_ENTERED",
                detectionMethod = "ACCESSIBILITY_SIGNATURE",
                details = "Entered Instagram Reels interface ($triggerReason)",
                confidence = lastConfidenceScore
            )
        )
        Log.i(TAG, "Entered Reels: $triggerReason (Confidence: $lastConfidenceScore)")
    }

    private fun exitReelsSession(reason: String) {
        if (!isCurrentlyInsideReels) return
        val now = System.currentTimeMillis()
        val durationMs = if (currentReelsSessionStartTime > 0) now - currentReelsSessionStartTime else 0L

        isCurrentlyInsideReels = false
        currentReelsSessionStartTime = 0L

        if (::overlayManager.isInitialized) {
            overlayManager.removeReelsOverlay()
        }

        WellbeingEventRepository.recordEvent(
            applicationContext,
            WellbeingEvent(
                id = "exit_${System.currentTimeMillis()}",
                timestamp = now,
                eventType = "REELS_EXITED",
                detectionMethod = "ACCESSIBILITY_SIGNATURE",
                details = "Exited Instagram Reels (Reason: $reason)",
                confidence = lastConfidenceScore,
                durationMs = durationMs
            )
        )
        Log.i(TAG, "Exited Reels: $reason, duration=${durationMs}ms")
    }

    private fun enforceLimitReached() {
        val now = SystemClock.elapsedRealtime()
        if (now - lastEnforcementTimestamp < 1000L) {
            return
        }
        lastEnforcementTimestamp = now

        val status = DailyLimitManager.getStatus(applicationContext)
        val limit = status["dailyLimit"] as? Int ?: 100
        val watched = status["reelsWatchedToday"] as? Int ?: limit

        Log.w(TAG, "ENFORCING REELS LIMIT: Attaching native in-place accessibility overlay")
        if (::overlayManager.isInitialized) {
            overlayManager.showReelsOverlay(limit, watched)
        }
    }

    private fun evaluateExplorePresence(root: AccessibilityNodeInfo) {
        if (!::overlayManager.isInitialized) return

        // 1. Only enforce when daily limit is exhausted
        if (!DailyLimitManager.isLimitReached(applicationContext)) {
            overlayManager.removeExploreOverlay()
            return
        }

        // 2. If inside full Reels viewer, Reels overlay handles it
        if (isCurrentlyInsideReels) {
            overlayManager.removeExploreOverlay()
            return
        }

        // 3. If in main Feed or Direct messages, not in Explore
        if (isFeedOrDirectWindow(root)) {
            overlayManager.removeExploreOverlay()
            return
        }

        // 4. Find Search Bar Node in Instagram
        val searchNode = findSearchBarNode(root)
        if (searchNode != null) {
            // If the search bar is focused, user is searching
            if (searchNode.isFocused) {
                overlayManager.removeExploreOverlay()
                return
            }

            val searchRect = android.graphics.Rect()
            searchNode.getBoundsInScreen(searchRect)

            val displayMetrics = resources.displayMetrics
            val screenHeight = displayMetrics.heightPixels

            val bottomNavNode = findBottomNavNode(root)
            var bottomNavTop = -1
            if (bottomNavNode != null) {
                val bRect = android.graphics.Rect()
                bottomNavNode.getBoundsInScreen(bRect)
                if (bRect.top > searchRect.bottom && bRect.top < screenHeight) {
                    bottomNavTop = bRect.top
                }
            }

            val topY = if (searchRect.bottom > 50) searchRect.bottom else (80 * displayMetrics.density).toInt()
            val height = if (bottomNavTop > topY) (bottomNavTop - topY) else android.view.WindowManager.LayoutParams.MATCH_PARENT

            val status = DailyLimitManager.getStatus(applicationContext)
            val limit = status["dailyLimit"] as? Int ?: 100
            val watched = status["reelsWatchedToday"] as? Int ?: limit

            overlayManager.showExploreOverlay(topY, height, limit, watched)
        } else {
            overlayManager.removeExploreOverlay()
        }
    }

    private fun findSearchBarNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val ids = listOf(
            "com.instagram.android:id/action_bar_search_edit_text",
            "com.instagram.android:id/search_edit_text",
            "com.instagram.android:id/action_bar_title"
        )
        for (id in ids) {
            val nodes = root.findAccessibilityNodeInfosByViewId(id)
            if (nodes.isNotEmpty()) return nodes.first()
        }

        val textMatches = root.findAccessibilityNodeInfosByText("Search with Meta AI")
        if (textMatches.isNotEmpty()) return textMatches.first()

        val textSearch = root.findAccessibilityNodeInfosByText("Search")
        for (node in textSearch) {
            val rect = android.graphics.Rect()
            node.getBoundsInScreen(rect)
            if (rect.top < resources.displayMetrics.heightPixels / 4) {
                return node
            }
        }
        return null
    }

    private fun findBottomNavNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val ids = listOf(
            "com.instagram.android:id/tab_bar",
            "com.instagram.android:id/bottom_navigation_bar"
        )
        for (id in ids) {
            val nodes = root.findAccessibilityNodeInfosByViewId(id)
            if (nodes.isNotEmpty()) return nodes.first()
        }

        val bottomThreshold = (resources.displayMetrics.heightPixels * 0.85).toInt()
        val homeNodes = root.findAccessibilityNodeInfosByText("Home")
        for (node in homeNodes) {
            val rect = android.graphics.Rect()
            node.getBoundsInScreen(rect)
            if (rect.bottom >= bottomThreshold) {
                return node.parent ?: node
            }
        }
        return null
    }

    override fun onInterrupt() {
        Log.w(TAG, "ReelsAccessibilityService interrupted.")
        if (::overlayManager.isInitialized) {
            overlayManager.removeAll()
        }
        if (isCurrentlyInsideReels) {
            exitReelsSession("SERVICE_INTERRUPTED")
        }
        isServiceRunning = false
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::overlayManager.isInitialized) {
            overlayManager.removeAll()
        }
        if (isCurrentlyInsideReels) {
            exitReelsSession("SERVICE_DESTROYED")
        }
        isServiceRunning = false
    }

    private fun checkRemoteUpdateInBackground() {
        Thread {
            try {
                val prefs = getSharedPreferences("reellock_updater_bg_prefs", Context.MODE_PRIVATE)
                val lastCheckTime = prefs.getLong("last_check_ms", 0L)
                val now = System.currentTimeMillis()
                // Throttle background check to once every 4 hours
                if (now - lastCheckTime < 4 * 60 * 60 * 1000L) {
                    return@Thread
                }
                prefs.edit().putLong("last_check_ms", now).apply()

                val url = java.net.URL("https://raw.githubusercontent.com/sasi123151/reellock-wellbeing/main/update_manifest.json")
                val conn = url.openConnection() as java.net.HttpURLConnection
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                conn.setRequestProperty("User-Agent", "REELLOCK-Wellbeing/1.0.1 (Android-AccessibilityService)")

                if (conn.responseCode == 200) {
                    val stream = conn.inputStream.bufferedReader()
                    val text = stream.readText()
                    stream.close()
                    val json = org.json.JSONObject(text)
                    val remoteVersionCode = json.optInt("latestVersionCode", 0)
                    val remoteVersionName = json.optString("latestVersion", "")
                    val releaseNotes = json.optString("releaseNotes", "New update available")

                    val pInfo = packageManager.getPackageInfo(packageName, 0)
                    val localVersionCode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                        pInfo.longVersionCode.toInt()
                    } else {
                        @Suppress("DEPRECATION")
                        pInfo.versionCode
                    }

                    if (remoteVersionCode > localVersionCode) {
                        postUpdateNotification(remoteVersionName, releaseNotes)
                    }
                }
                conn.disconnect()
            } catch (e: Exception) {
                Log.d(TAG, "Background update check skipped/failed: ${e.message}")
            }
        }.start()
    }

    private fun postUpdateNotification(version: String, notes: String) {
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
                if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    notificationManager.notify(2001, builder.build())
                }
            } else {
                notificationManager.notify(2001, builder.build())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to post update notification: ${e.message}")
        }
    }
}
