package com.rutin.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
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

        // During the gate/game flow: if user navigates away, force the
        // morning gate route back to the front instead of the normal app home.
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val sleepPrefs = prefs()
            val gameActive = sleepPrefs.getBoolean("game_active", false)
            val dismissedNormally = sleepPrefs.getBoolean("game_dismissed_normally", false)

            if (gameActive && !dismissedNormally) {
                val pkg = event.packageName?.toString() ?: return
                if (pkg != "com.rutin.app") {
                    val launchIntent = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    }
                    startActivity(launchIntent)
                }
            }
        }
    }

    override fun onInterrupt() {}
}
