package com.rutin.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class SleepScheduleReceiver : BroadcastReceiver() {

    companion object {
        private const val REQUEST_CODE = 9002

        fun sync(context: Context) {
            val prefs = settings(context)
            if (!prefs.getBoolean("enabled", false)) {
                cancel(context)
                SleepModeService.stop(context)
                return
            }

            val sleepStart = prefs.getInt("sleep_start_min", 1260)
            val wakeEnd = prefs.getInt("wake_window_end", 600)
            if (isWithinNightWindow(nowMinutes(), sleepStart, wakeEnd)) {
                SleepModeService.start(context)
            } else {
                SleepModeService.stop(context)
                scheduleNext(context, sleepStart)
            }
        }

        fun finishNight(context: Context) {
            context.getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(SleepModeService.KEY_SLEEP_ACTIVE, false)
                .apply()
            SleepModeService.stop(context)

            val prefs = settings(context)
            if (prefs.getBoolean("enabled", false)) {
                scheduleNext(context, prefs.getInt("sleep_start_min", 1260))
            }
        }

        fun scheduleNext(context: Context, sleepStartMinutes: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAt = nextOccurrenceMillis(sleepStartMinutes)
            val pendingIntent = pendingIntent(context)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()
            ) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        }

        fun cancel(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pendingIntent(context))
        }

        fun isWithinNightWindow(nowMinutes: Int, sleepStart: Int, wakeEnd: Int): Boolean {
            return if (sleepStart > wakeEnd) {
                nowMinutes >= sleepStart || nowMinutes <= wakeEnd
            } else {
                nowMinutes in sleepStart..wakeEnd
            }
        }

        private fun settings(context: Context) =
            context.getSharedPreferences("sleep_settings_native", Context.MODE_PRIVATE)

        private fun pendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, SleepScheduleReceiver::class.java)
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun nextOccurrenceMillis(minutes: Int): Long {
            val now = Calendar.getInstance()
            val next = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, minutes / 60)
                set(Calendar.MINUTE, minutes % 60)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (!after(now)) add(Calendar.DAY_OF_YEAR, 1)
            }
            return next.timeInMillis
        }

        private fun nowMinutes(): Int {
            val cal = Calendar.getInstance()
            return cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        sync(context)
    }
}
