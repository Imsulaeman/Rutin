package com.ilham.habit_app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class HabitAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val CHANNEL_ID = "habit_reminder"
        private const val EXTRA_NOTIF_ID = "notif_id"
        private const val EXTRA_TITLE = "title"

        fun schedule(context: Context, notifId: Int, triggerMs: Long, title: String) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = pendingIntent(context, notifId, title)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerMs, pi)
            }
        }

        fun cancel(context: Context, notifId: Int) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(pendingIntent(context, notifId, ""))
        }

        private fun pendingIntent(context: Context, notifId: Int, title: String): PendingIntent {
            val intent = Intent(context, HabitAlarmReceiver::class.java).apply {
                putExtra(EXTRA_NOTIF_ID, notifId)
                putExtra(EXTRA_TITLE, title)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            return PendingIntent.getBroadcast(context, notifId, intent, flags)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: return

        showNotification(context, notifId, title)

        // Reschedule for same time tomorrow
        val nextTrigger = System.currentTimeMillis() + 24 * 60 * 60 * 1000L
        schedule(context, notifId, nextTrigger, title)
    }

    private fun showNotification(context: Context, notifId: Int, title: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Pengingat Kebiasaan", NotificationManager.IMPORTANCE_HIGH)
            nm.createNotificationChannel(channel)
        }
        val openIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(
            context, notifId, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
        val notif = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("Waktunya melakukan kebiasaanmu!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        nm.notify(notifId, notif)
    }
}
