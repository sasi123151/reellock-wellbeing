package com.reellock.wellbeing.reellock_wellbeing

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

class ReelsOverlayManager(private val service: AccessibilityService) {

    companion object {
        private const val TAG = "ReelsOverlayManager"
    }

    private val windowManager = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var reelsOverlayView: View? = null
    private var isReelsOverlayVisible = false

    private var exploreOverlayView: View? = null
    private var isExploreOverlayVisible = false
    private var lastExploreTopY = -1
    private var lastExploreHeight = -1

    fun showReelsOverlay(dailyLimit: Int, watched: Int) {
        mainHandler.post {
            try {
                if (isReelsOverlayVisible && reelsOverlayView != null) {
                    return@post
                }

                removeReelsOverlayInternal()

                val view = createBrandedLockView(
                    isFullScreen = true,
                    dailyLimit = dailyLimit,
                    watched = watched,
                    onOpenApp = {
                        val intent = Intent(service, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        service.startActivity(intent)
                    },
                    onBackToInstagram = {
                        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
                    }
                )

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.CENTER
                }

                windowManager.addView(view, params)
                reelsOverlayView = view
                isReelsOverlayVisible = true
                Log.i(TAG, "Reels lock overlay attached successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to show Reels overlay", e)
            }
        }
    }

    fun removeReelsOverlay() {
        mainHandler.post {
            removeReelsOverlayInternal()
        }
    }

    private fun removeReelsOverlayInternal() {
        try {
            if (isReelsOverlayVisible && reelsOverlayView != null) {
                windowManager.removeViewImmediate(reelsOverlayView)
                Log.i(TAG, "Reels lock overlay removed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove Reels overlay", e)
        } finally {
            reelsOverlayView = null
            isReelsOverlayVisible = false
        }
    }

    fun showExploreOverlay(topY: Int, height: Int, dailyLimit: Int, watched: Int) {
        mainHandler.post {
            try {
                if (isExploreOverlayVisible && exploreOverlayView != null &&
                    lastExploreTopY == topY && lastExploreHeight == height) {
                    return@post
                }

                removeExploreOverlayInternal()

                val view = createBrandedLockView(
                    isFullScreen = false,
                    dailyLimit = dailyLimit,
                    watched = watched,
                    onOpenApp = {
                        val intent = Intent(service, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        service.startActivity(intent)
                    },
                    onBackToInstagram = null
                )

                val effectiveHeight = if (height > 200) height else WindowManager.LayoutParams.MATCH_PARENT

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    effectiveHeight,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    x = 0
                    y = topY
                }

                windowManager.addView(view, params)
                exploreOverlayView = view
                isExploreOverlayVisible = true
                lastExploreTopY = topY
                lastExploreHeight = height
                Log.i(TAG, "Explore lock overlay attached at y=$topY, height=$effectiveHeight")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to show Explore overlay", e)
            }
        }
    }

    fun removeExploreOverlay() {
        mainHandler.post {
            removeExploreOverlayInternal()
        }
    }

    private fun removeExploreOverlayInternal() {
        try {
            if (isExploreOverlayVisible && exploreOverlayView != null) {
                windowManager.removeViewImmediate(exploreOverlayView)
                Log.i(TAG, "Explore lock overlay removed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove Explore overlay", e)
        } finally {
            exploreOverlayView = null
            isExploreOverlayVisible = false
            lastExploreTopY = -1
            lastExploreHeight = -1
        }
    }

    fun removeAll() {
        mainHandler.post {
            removeReelsOverlayInternal()
            removeExploreOverlayInternal()
        }
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            service.resources.displayMetrics
        ).toInt()
    }

    private fun createBrandedLockView(
        isFullScreen: Boolean,
        dailyLimit: Int,
        watched: Int,
        onOpenApp: () -> Unit,
        onBackToInstagram: (() -> Unit)?
    ): View {
        val root = ScrollView(service).apply {
            isFillViewport = true
            setBackgroundColor(Color.parseColor("#08080A"))
            isClickable = true
            isFocusable = true
            setOnTouchListener { _, _ -> true } // Consume all touches to protect reels underneath
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        val contentLayout = LinearLayout(service).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dpToPx(32f), dpToPx(24f), dpToPx(32f), dpToPx(24f))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        // 1. Lock Icon
        val iconSize = dpToPx(if (isFullScreen) 68f else 54f)
        val iconView = ImageView(service).apply {
            setImageResource(android.R.drawable.ic_lock_lock)
            setColorFilter(Color.parseColor("#FFD166"))
            layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                bottomMargin = dpToPx(16f)
            }
        }
        contentLayout.addView(iconView)

        // 2. Title
        val titleView = TextView(service).apply {
            text = "YOU HIT YOUR DAILY LIMIT"
            textSize = if (isFullScreen) 21f else 18f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            letterSpacing = 0.08f
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(12f)
            }
        }
        contentLayout.addView(titleView)

        // 3. Message
        val messageText = "You reached your daily limit of $dailyLimit Reels today.\n\n" +
                "Instagram Reels is locked to preserve your time and focus."
        val messageView = TextView(service).apply {
            text = messageText
            textSize = 14f
            setTextColor(Color.parseColor("#A0A0A0"))
            gravity = Gravity.CENTER
            setLineSpacing(dpToPx(3f).toFloat(), 1.15f)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(18f)
            }
        }
        contentLayout.addView(messageView)

        // 4. Midnight Reset Notice
        val resetNotice = TextView(service).apply {
            text = "Auto-resets at local midnight (00:00)"
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#FFD166"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(24f)
            }
        }
        contentLayout.addView(resetNotice)

        // 5. Open REELLOCK Wellbeing Button
        val openAppButton = Button(service).apply {
            text = "Open REELLOCK Wellbeing"
            setTextColor(Color.parseColor("#050505"))
            typeface = Typeface.DEFAULT_BOLD
            textSize = 13f
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#FFD166"))
                cornerRadius = dpToPx(12f).toFloat()
            }
            background = bg
            setPadding(dpToPx(24f), dpToPx(12f), dpToPx(24f), dpToPx(12f))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(12f)
            }
            setOnClickListener {
                onOpenApp()
            }
        }
        contentLayout.addView(openAppButton)

        // 6. Optional: Back to Instagram Home (for full screen Reels overlay)
        if (onBackToInstagram != null) {
            val backButton = Button(service).apply {
                text = "Back to Home Feed"
                setTextColor(Color.parseColor("#FFD166"))
                textSize = 13f
                typeface = Typeface.DEFAULT_BOLD
                val bg = GradientDrawable().apply {
                    setColor(Color.TRANSPARENT)
                    setStroke(dpToPx(1.5f), Color.parseColor("#FFD166"))
                    cornerRadius = dpToPx(12f).toFloat()
                }
                background = bg
                setPadding(dpToPx(24f), dpToPx(10f), dpToPx(24f), dpToPx(10f))
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
                setOnClickListener {
                    onBackToInstagram()
                }
            }
            contentLayout.addView(backButton)
        }

        root.addView(contentLayout)
        return root
    }
}

