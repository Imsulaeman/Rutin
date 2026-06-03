package com.rutin.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.Context
import android.view.accessibility.AccessibilityEvent

class RutinAccessibilityService : AccessibilityService() {

    private fun prefs() =
        getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == "com.rutin.app") return  // already in our app

        val sleepPrefs = prefs()
        val gameActive = sleepPrefs.getBoolean("game_active", false)
        val dismissedNormally = sleepPrefs.getBoolean("game_dismissed_normally", false)
        val sleepActive = sleepPrefs.getBoolean(SleepModeService.KEY_SLEEP_ACTIVE, false)

        when {
            // Gate is open — keep it in focus if user navigates away
            gameActive && !dismissedNormally -> startActivity(
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                }
            )
            // Sleep triggered — show gate on first window change after unlock
            sleepActive -> startActivity(
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("route", "/morning-gate")
                }
            )
        }
    }

    override fun onInterrupt() {}
}
