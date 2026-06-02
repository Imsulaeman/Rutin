package com.rutin.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        NativeReminderScheduler.rescheduleAll(context)

        val waterPrefs = context.getSharedPreferences("water_settings", Context.MODE_PRIVATE)
        if (waterPrefs.getBoolean("reminder_active", false)) {
            val intervalMs = waterPrefs.getLong("interval_ms", 120 * 60_000L)
            WaterAlarmReceiver.schedule(context, intervalMs)
        }

        HabitAlarmReceiver.rescheduleAll(context)

        // Re-arm bedtime scheduling without showing an all-day foreground notification.
        runCatching { SleepScheduleReceiver.sync(context) }
    }
}
