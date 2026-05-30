package com.ilham.habit_app

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.StateListAnimator
import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Calendar

class ReminderActivity : Activity() {

    private val pink = Color.parseColor("#D93A6E")

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun shadow(tv: TextView) =
        tv.setShadowLayer(dp(6).toFloat(), 0f, dp(2).toFloat(), Color.parseColor("#55000000"))

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Edge-to-edge: let the pink scene fill behind a transparent status/nav
        // bar (the dp(48) top padding keeps content clear of the status bar).
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_STABLE

        val alarmId = intent.getIntExtra("alarm_id", 0)
        val scheduledMinutes = intent.getIntExtra("scheduled_minutes", 0)
        val medicineName = intent.getStringExtra("medicine_name") ?: "Obat"
        val dosage = intent.getStringExtra("dosage").orEmpty()
        val renotifyMinutes = intent.getIntExtra("renotify_minutes", 10)

        // ── Root: full-bleed pink scene with the content layered on top ──────────
        val root = FrameLayout(this)

        val bg = ImageView(this).apply {
            setImageResource(R.drawable.med_reminder_bg)
            scaleType = ImageView.ScaleType.CENTER_CROP
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        root.addView(bg)

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(48), dp(28), dp(28))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        content.addView(spacer(2f))

        // Frosted circular badge with a pill glyph.
        val badge = TextView(this).apply {
            text = "💊" // 💊
            textSize = 34f
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#38FFFFFF"))
                setStroke(dp(2), Color.parseColor("#59FFFFFF"))
            }
            layoutParams = LinearLayout.LayoutParams(dp(96), dp(96))
        }
        content.addView(badge)

        content.addView(label("Waktunya minum", 16f, false, dp(26)))
        content.addView(label(medicineName, 30f, true, dp(8)))
        if (dosage.isNotEmpty()) content.addView(label(dosage, 15f, false, dp(8)))

        val cal = Calendar.getInstance()
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        content.addView(label(two(hour) + ":" + two(minute), 64f, true, dp(26)))
        content.addView(label(period(hour), 16f, true, dp(2)).apply { letterSpacing = 0.2f })

        content.addView(spacer(3f))

        // White primary button.
        content.addView(Button("✓  Sudah diminum", Color.WHITE, pink).apply {
            setOnClickListener {
                writePendingTaken(alarmId, scheduledMinutes)
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.cancel(alarmId)
                NativeReminderScheduler.cancelLoop(this@ReminderActivity, alarmId)
                finish()
            }
        })

        // Outlined snooze button.
        content.addView(View(this).apply { layoutParams = LinearLayout.LayoutParams(0, dp(14)) })
        content.addView(OutlinedButton("⏰  Tunda 1 menit").apply {
            setOnClickListener {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.cancel(alarmId)
                val trigger = System.currentTimeMillis() + 60_000L
                NativeReminderScheduler.schedule(
                    context = this@ReminderActivity,
                    rootAlarmId = alarmId,
                    triggerAtMillis = trigger,
                    scheduledMinutes = scheduledMinutes,
                    medicineName = medicineName,
                    dosage = if (dosage.isEmpty()) null else dosage,
                    renotifyMinutes = renotifyMinutes,
                    isLoop = true
                )
                finish()
            }
        })

        content.addView(label("↻  Pengingat berulang sampai dikonfirmasi.", 12f, false, dp(16))
            .apply { alpha = 0.75f })

        root.addView(content)
        setContentView(root)
    }

    // ── small UI builders ───────────────────────────────────────────────────────
    private fun spacer(weight: Float) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, weight
        )
    }

    private fun label(text: String, size: Float, bold: Boolean, topMargin: Int): TextView {
        return TextView(this).apply {
            this.text = text
            textSize = size
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            if (bold) setTypeface(typeface, Typeface.BOLD)
            shadow(this)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { this.topMargin = topMargin }
        }
    }

    private fun Button(text: String, bg: Int, fg: Int): TextView {
        val radius = dp(18).toFloat()
        val content = GradientDrawable().apply { cornerRadius = radius; setColor(bg) }
        val mask = GradientDrawable().apply { cornerRadius = radius; setColor(Color.WHITE) }
        return TextView(this).apply {
            this.text = text
            textSize = 17f
            setTextColor(fg)
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            // Ripple keyed to the brand pink for the white button.
            background = RippleDrawable(
                ColorStateList.valueOf(Color.parseColor("#33D93A6E")), content, mask)
            stateListAnimator = pressAnimator()
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(58)
            )
        }
    }

    private fun OutlinedButton(text: String): TextView {
        val radius = dp(18).toFloat()
        val content = GradientDrawable().apply {
            cornerRadius = radius
            setColor(Color.parseColor("#1FFFFFFF"))
            setStroke(dp(1), Color.parseColor("#73FFFFFF"))
        }
        val mask = GradientDrawable().apply { cornerRadius = radius; setColor(Color.WHITE) }
        return TextView(this).apply {
            this.text = text
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            background = RippleDrawable(
                ColorStateList.valueOf(Color.parseColor("#40FFFFFF")), content, mask)
            stateListAnimator = pressAnimator()
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(54)
            )
        }
    }

    // Press feedback: scale down while held, spring back on release. Driven by
    // the pressed state so it composes with the ripple instead of fighting it.
    private fun pressAnimator(): StateListAnimator {
        val sla = StateListAnimator()
        val pressed = AnimatorSet().apply {
            duration = 90L
            playTogether(
                ObjectAnimator.ofFloat(null, "scaleX", 0.96f),
                ObjectAnimator.ofFloat(null, "scaleY", 0.96f)
            )
        }
        val released = AnimatorSet().apply {
            duration = 130L
            playTogether(
                ObjectAnimator.ofFloat(null, "scaleX", 1f),
                ObjectAnimator.ofFloat(null, "scaleY", 1f)
            )
        }
        sla.addState(intArrayOf(android.R.attr.state_pressed), pressed)
        sla.addState(IntArray(0), released)
        return sla
    }

    // ── bridge: queue a "taken" event for Dart to drain into Hive ────────────────
    private fun writePendingTaken(alarmId: Int, scheduledMinutes: Int) {
        val prefs = getSharedPreferences("medicine_pending", Context.MODE_PRIVATE)
        val current = prefs.getStringSet("pending_taken", emptySet()) ?: emptySet()
        val updated = HashSet(current)
        updated.add("$alarmId|$scheduledMinutes|${System.currentTimeMillis()}")
        prefs.edit().putStringSet("pending_taken", updated).apply()
    }

    private fun two(n: Int): String = if (n < 10) "0$n" else "$n"

    private fun period(hour: Int): String = when {
        hour < 11 -> "PAGI"
        hour < 15 -> "SIANG"
        hour < 19 -> "SORE"
        else -> "MALAM"
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Block back — the reminder must be acknowledged.
    }
}
