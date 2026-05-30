package com.rutin.app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.view.accessibility.AccessibilityEvent

class RutinAccessibilityService : AccessibilityService() {

    private fun prefs() =
        getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Update last_interaction_ms for sleep detection
        prefs().edit()
            .putLong(SleepModeService.KEY_LAST_INTERACTION, System.currentTimeMillis())
            .apply()

        // During game: if user navigates to another app, force back
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val sleepPrefs = prefs()
            val gameActive = sleepPrefs.getBoolean("game_active", false)
            val dismissedNormally = sleepPrefs.getBoolean("game_dismissed_normally", false)

            if (gameActive && !dismissedNormally) {
                val pkg = event.packageName?.toString() ?: return
                if (pkg != "com.rutin.app") {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                }
            }
        }
    }

    override fun onInterrupt() {}
}
