package com.rutin.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import androidx.core.app.NotificationCompat

class HabitAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val CHANNEL_ID = "habit_reminder_v2"
        private const val EXTRA_NOTIF_ID = "notif_id"
        private const val EXTRA_TITLE = "title"
        private const val PREFS = "habit_alarm_settings"
        private const val KEY_PREFIX = "habit_alarm_"

        fun schedule(context: Context, notifId: Int, triggerMs: Long, title: String) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = pendingIntent(context, notifId, title)
            persist(context, notifId, title)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerMs, pi)
            }
        }

        fun cancel(context: Context, notifId: Int) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(pendingIntent(context, notifId, ""))
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove("$KEY_PREFIX$notifId")
                .apply()
        }

        fun rescheduleAll(context: Context) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            for ((key, value) in prefs.all) {
                if (!key.startsWith(KEY_PREFIX) || value !is String) continue
                val notifId = key.removePrefix(KEY_PREFIX).toIntOrNull() ?: continue
                schedule(context, notifId, nextTriggerMillis(notifId), value)
            }
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

        private fun persist(context: Context, notifId: Int, title: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString("$KEY_PREFIX$notifId", title)
                .apply()
        }

        private fun nextTriggerMillis(notifId: Int): Long {
            val minutes = notifId and 0x7FF
            val now = java.util.Calendar.getInstance()
            val next = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
                set(java.util.Calendar.HOUR_OF_DAY, minutes / 60)
                set(java.util.Calendar.MINUTE, minutes % 60)
                if (!after(now)) {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
            }
            return next.timeInMillis
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: return

        showNotification(context, notifId, title)

        // Reschedule for same time tomorrow
        schedule(context, notifId, nextTriggerMillis(notifId), title)
    }

    private fun showNotification(context: Context, notifId: Int, title: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.deleteNotificationChannel("habit_reminder")
            val audioAttrs = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()
            val channel = NotificationChannel(
                CHANNEL_ID, NativeStrings.habitChannel(context), NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(ReminderSoundPrefs.notificationUri(context), audioAttrs)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250)
            }
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
            .setContentText(NativeStrings.habitBody(context))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        nm.notify(notifId, notif)
    }
}
