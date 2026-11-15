package com.reellock.wellbeing.reellock_wellbeing

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class LimitReachedActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val status = DailyLimitManager.getStatus(applicationContext)
        val limit = status["dailyLimit"] as? Int ?: 100
        val watched = status["reelsWatchedToday"] as? Int ?: limit

        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#050505"))
            setPadding(64, 80, 64, 80)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        // Lock / Warning Icon
        val iconView = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_lock_lock)
            setColorFilter(Color.parseColor("#FFD166"))
            val iconSize = (72 * resources.displayMetrics.density).toInt()
            layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                bottomMargin = (32 * resources.displayMetrics.density).toInt()
            }
        }
        rootLayout.addView(iconView)

        // Main Title: YOU HIT YOUR DAILY LIMIT
        val titleView = TextView(this).apply {
            text = "YOU HIT YOUR DAILY LIMIT"
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            letterSpacing = 0.08f
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = (16 * resources.displayMetrics.density).toInt()
            }
        }
        rootLayout.addView(titleView)

        // Explanation text
        val messageView = TextView(this).apply {
            text = "You reached your limit of $limit Reels today ($watched watched).\n\nInstagram Reels is locked to preserve your time and focus. You cannot bypass or increase today's limit."
            textSize = 15f
            setTextColor(Color.parseColor("#9E9E9E"))
            gravity = Gravity.CENTER
            setLineSpacing(6f, 1.2f)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = (40 * resources.displayMetrics.density).toInt()
            }
        }
        rootLayout.addView(messageView)

        // Reset Notice
        val resetNotice = TextView(this).apply {
            text = "Auto-resets at local midnight (00:00)"
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#FFD166"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = (36 * resources.displayMetrics.density).toInt()
            }
        }
        rootLayout.addView(resetNotice)

        // Return button
        val returnButton = Button(this).apply {
            text = "Open REELLOCK Wellbeing"
            setTextColor(Color.parseColor("#050505"))
            setBackgroundColor(Color.parseColor("#FFD166"))
            typeface = Typeface.DEFAULT_BOLD
            setPadding(48, 24, 48, 24)
            setOnClickListener {
                val intent = Intent(this@LimitReachedActivity, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                startActivity(intent)
                finish()
            }
        }
        rootLayout.addView(returnButton)

        setContentView(rootLayout)
    }

    override fun onBackPressed() {
        // Enforce limit: navigating back goes to home screen or dashboard, NOT back to Instagram Reels
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        startActivity(intent)
        finish()
    }
}
