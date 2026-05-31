package com.rutin.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WakeUpTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_USER_PRESENT) return

        val prefs = context.getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(SleepModeService.KEY_SLEEP_ACTIVE, false)) return

        val sleepNativePrefs = context.getSharedPreferences(
            "sleep_settings_native", Context.MODE_PRIVATE
        )
        val testTrigger = prefs.getBoolean("test_trigger", false)
        if (!testTrigger) {
            val wakeStart = sleepNativePrefs.getInt("wake_window_start", 300)
            val wakeEnd = sleepNativePrefs.getInt("wake_window_end", 600)
            val cal = java.util.Calendar.getInstance()
            val nowMin = cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + cal.get(java.util.Calendar.MINUTE)
            if (nowMin < wakeStart || nowMin > wakeEnd) return
        }
        prefs.edit().putBoolean("test_trigger", false).apply()

        // Clear sleep_active so the gate only fires once per sleep cycle
        prefs.edit()
            .putBoolean(SleepModeService.KEY_SLEEP_ACTIVE, false)
            .putLong("launch_game_at", System.currentTimeMillis())
            .apply()

        // Launch app — onNewIntent in MainActivity will push the gate route via MethodChannel
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("route", "/morning-gate")
        }
        context.startActivity(launchIntent)
    }
}
