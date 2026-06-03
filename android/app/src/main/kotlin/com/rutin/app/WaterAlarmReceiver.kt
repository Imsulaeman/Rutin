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

class WaterAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val NOTIFICATION_ID = 800000
        private const val CHANNEL_ID = "water_reminder_v2"
        private const val REQUEST_CODE = 800001

        fun schedule(context: Context, delayMs: Long) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = buildPendingIntent(context)
            val triggerAt = System.currentTimeMillis() + delayMs
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms() ->
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                else -> am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }

        fun cancel(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildPendingIntent(context))
            context.getSharedPreferences("water_settings", Context.MODE_PRIVATE)
                .edit().putBoolean("reminder_active", false).apply()
        }

        private fun buildPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, WaterAlarmReceiver::class.java)
            return PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("water_settings", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("reminder_active", false)) return

        val debug = prefs.getBoolean("debug", false)
        val startMin = prefs.getInt("start_min", 420)
        val endMin = prefs.getInt("end_min", 1320)
        val intervalMs = prefs.getLong("interval_ms", 120 * 60_000L)

        val cal = java.util.Calendar.getInstance()
        val nowMin = cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + cal.get(java.util.Calendar.MINUTE)

        if (debug || nowMin in startMin..endMin) {
            showNotification(context)
        }

        // Reschedule
        val nextMin = nowMin + (intervalMs / 60_000L).toInt()
        when {
            debug || nextMin <= endMin -> schedule(context, intervalMs)
            else -> {
                // Last reminder of the day — re-arm for tomorrow's start of window
                val next = java.util.Calendar.getInstance().apply {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                    set(java.util.Calendar.HOUR_OF_DAY, startMin / 60)
                    set(java.util.Calendar.MINUTE, startMin % 60)
                    set(java.util.Calendar.SECOND, 0)
                    set(java.util.Calendar.MILLISECOND, 0)
                }
                val delayMs = (next.timeInMillis - System.currentTimeMillis()).coerceAtLeast(60_000L)
                schedule(context, delayMs)
            }
        }
    }

    private fun showNotification(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.deleteNotificationChannel("water_reminder_native")
            val audioAttrs = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()
            val channel = NotificationChannel(
                CHANNEL_ID, NativeStrings.waterChannel(context), NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(ReminderSoundPrefs.notificationUri(context), audioAttrs)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250)
            }
            nm.createNotificationChannel(channel)
        }

        val actionIntent = Intent(context, WaterActionReceiver::class.java)
        val actionPi = PendingIntent.getBroadcast(
            context, 0, actionIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(NativeStrings.waterTitle(context))
            .setContentText(NativeStrings.waterBody(context))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .addAction(0, NativeStrings.waterTaken(context), actionPi)
            .build()

        nm.notify(NOTIFICATION_ID, notification)
    }
}
