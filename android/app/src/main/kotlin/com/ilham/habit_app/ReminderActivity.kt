package com.ilham.habit_app

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class ReminderActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        val alarmId = intent.getIntExtra("alarm_id", 0)
        val medicineName = intent.getStringExtra("medicine_name") ?: "Obat"
        val dosage = intent.getStringExtra("dosage").orEmpty()
        val renotifyMinutes = intent.getIntExtra("renotify_minutes", 10)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        val title = TextView(this).apply {
            text = medicineName
            textSize = 26f
            gravity = Gravity.CENTER
        }
        val dosageText = TextView(this).apply {
            text = dosage
            textSize = 18f
            gravity = Gravity.CENTER
        }
        val takenButton = Button(this).apply {
            text = "Sudah diminum"
            setOnClickListener {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.cancel(alarmId)
                NativeReminderScheduler.cancel(this@ReminderActivity, alarmId)
                finish()
            }
        }
        val snoozeButton = Button(this).apply {
            text = "Tunda 1 menit"
            setOnClickListener {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.cancel(alarmId)
                val trigger = System.currentTimeMillis() + 60_000L
                NativeReminderScheduler.schedule(
                    context = this@ReminderActivity,
                    alarmId = alarmId,
                    triggerAtMillis = trigger,
                    medicineName = medicineName,
                    dosage = if (dosage.isEmpty()) null else dosage,
                    renotifyMinutes = renotifyMinutes
                )
                finish()
            }
        }

        root.addView(title)
        root.addView(dosageText)
        root.addView(takenButton)
        root.addView(snoozeButton)

        setContentView(root)
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Block back.
    }
}
