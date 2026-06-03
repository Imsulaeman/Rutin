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
        private const val RC_BEDTIME = 9002
        private const val RC_WAKE_END = 9005

        fun sync(context: Context) {
            val prefs = settings(context)
            if (!prefs.getBoolean("enabled", false)) {
                cancelBedtime(context)
                cancelWakeEnd(context)
                SleepModeService.cancelAllAlarms(context)
                SleepModeService.stop(context)
                return
            }

            val sleepStart = prefs.getInt("sleep_start_min", 1260)
            val wakeEnd = prefs.getInt("wake_window_end", 600)
            if (isWithinNightWindow(nowMinutes(), sleepStart, wakeEnd)) {
                SleepModeService.start(context)
                scheduleWakeEnd(context, wakeEnd)
            } else {
                SleepModeService.stop(context)
                scheduleNext(context, sleepStart)
            }
        }

        fun finishNight(context: Context) {
            context.getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(SleepModeService.KEY_SLEEP_ACTIVE, false)
                .remove(SleepModeService.KEY_SCREEN_OFF_TIME)
                .apply()
            SleepModeService.cancelMorningGateNotification(context)
            SleepModeService.cancelAllAlarms(context)
            cancelWakeEnd(context)
            SleepModeService.stop(context)

            val prefs = settings(context)
            if (prefs.getBoolean("enabled", false)) {
                scheduleNext(context, prefs.getInt("sleep_start_min", 1260))
            }
        }

        fun scheduleNext(context: Context, sleepStartMinutes: Int) {
            scheduleAlarm(context, bedtimePendingIntent(context), sleepStartMinutes)
        }

        fun cancelBedtime(context: Context) {
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
                .cancel(bedtimePendingIntent(context))
        }

        // Keep old name for call sites that use cancel()
        fun cancel(context: Context) = cancelBedtime(context)

        fun isWithinNightWindow(nowMinutes: Int, sleepStart: Int, wakeEnd: Int): Boolean =
            if (sleepStart > wakeEnd) nowMinutes >= sleepStart || nowMinutes <= wakeEnd
            else nowMinutes in sleepStart..wakeEnd

        private fun scheduleWakeEnd(context: Context, wakeEndMinutes: Int) {
            scheduleAlarm(context, wakeEndPendingIntent(context), wakeEndMinutes)
        }

        private fun cancelWakeEnd(context: Context) {
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
                .cancel(wakeEndPendingIntent(context))
        }

        private fun scheduleAlarm(context: Context, pi: PendingIntent, atMinutes: Int) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAt = nextOccurrenceMillis(atMinutes)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }

        private fun settings(context: Context) =
            context.getSharedPreferences("sleep_settings_native", Context.MODE_PRIVATE)

        private fun bedtimePendingIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, RC_BEDTIME,
                Intent(context, SleepScheduleReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        private fun wakeEndPendingIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, RC_WAKE_END,
                Intent(context, SleepScheduleReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

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
