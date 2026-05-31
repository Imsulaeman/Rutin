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

        // Restart sleep mode service if it was enabled before reboot.
        // NOTE: On Android 14 FBE devices BOOT_COMPLETED fires AFTER the first unlock,
        // so this re-arms the gate for the SECOND unlock onward, not the first morning wake.
        val sleepPrefs = context.getSharedPreferences("sleep_settings_native", Context.MODE_PRIVATE)
        if (sleepPrefs.getBoolean("enabled", false)) {
            runCatching { SleepModeService.start(context) }
        }
    }
}
