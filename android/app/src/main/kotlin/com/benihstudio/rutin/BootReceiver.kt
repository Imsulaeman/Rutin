package com.benihstudio.rutin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON"
        ) return

        NativeReminderScheduler.rescheduleAll(context)

        val waterPrefs = context.getSharedPreferences("water_settings", Context.MODE_PRIVATE)
        if (waterPrefs.getBoolean("reminder_active", false)) {
            val intervalMs = waterPrefs.getLong("interval_ms", 120 * 60_000L)
            WaterAlarmReceiver.schedule(context, intervalMs)
        }

        HabitAlarmReceiver.rescheduleAll(context)

        runCatching { SleepScheduleReceiver.sync(context) }

        // If sleep was active when the phone died and sync() didn't start the service
        // (boot happened outside the sleep window), start it anyway to catch the first
        // ACTION_USER_PRESENT and show the morning gate.
        val sleepPrefs = context.getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)
        if (sleepPrefs.getBoolean(SleepModeService.KEY_SLEEP_ACTIVE, false) &&
            !SleepModeService.isRunning(context)
        ) {
            SleepModeService.start(context)
        }
    }
}

