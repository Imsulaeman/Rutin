package com.ilham.habit_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.ilham.habit_app.ACTION_FIRE_WATER") {
            handleWater(context, intent)
        } else {
            handleMedicine(context, intent)
        }
    }

    private fun handleMedicine(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val medicineName = intent.getStringExtra("medicine_name") ?: "Obat"
        val dosage = intent.getStringExtra("dosage")
        val renotifyMinutes = intent.getIntExtra("renotify_minutes", 10)

        showFullScreenNotification(context, alarmId, medicineName, dosage, renotifyMinutes)

        val nextTrigger = System.currentTimeMillis() + (renotifyMinutes * 60_000L)
        NativeReminderScheduler.schedule(
            context = context,
            alarmId = alarmId,
            triggerAtMillis = nextTrigger,
            medicineName = medicineName,
            dosage = dosage,
            renotifyMinutes = renotifyMinutes
        )
    }

    private fun handleWater(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val intervalMinutes = intent.getIntExtra("interval_minutes", 120)
        val startTimeMinutes = intent.getIntExtra("start_time_minutes", 420)
        val endTimeMinutes = intent.getIntExtra("end_time_minutes", 1320)

        val cal = java.util.Calendar.getInstance()
        val nowMinutes = cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + cal.get(java.util.Calendar.MINUTE)

        if (nowMinutes in startTimeMinutes..endTimeMinutes) {
            showWaterNotification(context, alarmId)
        }

        // Reschedule next tick — receiver stops itself naturally after endTimeMinutes
        // because next day the user re-enables from the screen (or boot receiver later)
        val nextTrigger = System.currentTimeMillis() + (intervalMinutes * 60_000L)
        val nextCal = java.util.Calendar.getInstance().apply { timeInMillis = nextTrigger }
        val nextMinutes = nextCal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + nextCal.get(java.util.Calendar.MINUTE)
        if (nextMinutes <= endTimeMinutes) {
            NativeReminderScheduler.scheduleWater(
                context = context,
                alarmId = alarmId,
                triggerAtMillis = nextTrigger,
                intervalMinutes = intervalMinutes,
                startTimeMinutes = startTimeMinutes,
                endTimeMinutes = endTimeMinutes
            )
        }
    }

    private fun showWaterNotification(context: Context, alarmId: Int) {
        val channelId = "water_reminder"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, "Pengingat Air", NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = "Ingatkan minum air" }
            nm.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Waktunya minum air")
            .setContentText("Sudah minum segelas belum?")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        nm.notify(alarmId, notification)
    }

    private fun showFullScreenNotification(
        context: Context,
        alarmId: Int,
        medicineName: String,
        dosage: String?,
        renotifyMinutes: Int
    ) {
        val channelId = "medicine_alarm"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Pengingat Obat",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm minum obat"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }

        val activityIntent = Intent(context, ReminderActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("alarm_id", alarmId)
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("renotify_minutes", renotifyMinutes)
        }
        val fullScreenPi = PendingIntent.getActivity(
            context,
            alarmId,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val body = if (!dosage.isNullOrEmpty()) "$medicineName – $dosage" else medicineName

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Waktunya minum obat")
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPi, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        nm.notify(alarmId, notification)
    }
}
