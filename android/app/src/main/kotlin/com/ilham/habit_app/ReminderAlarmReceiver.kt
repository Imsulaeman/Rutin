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
