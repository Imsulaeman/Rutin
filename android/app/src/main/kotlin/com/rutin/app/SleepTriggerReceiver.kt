package com.rutin.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager

class SleepTriggerReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            SleepModeService.ACTION_SLEEP_TRIGGER -> handleSleepTrigger(context)
            SleepModeService.ACTION_AUDIO_CHECK -> handleAudioCheck(context)
        }
    }

    private fun handleSleepTrigger(context: Context) {
        val prefs = context.getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)
        // Screen came back on and cleared the key — don't activate
        if (!prefs.contains(SleepModeService.KEY_SCREEN_OFF_TIME)) return
        prefs.edit().putBoolean(SleepModeService.KEY_SLEEP_ACTIVE, true).apply()
    }

    private fun handleAudioCheck(context: Context) {
        val prefs = context.getSharedPreferences(SleepModeService.PREFS, Context.MODE_PRIVATE)
        // Screen came back on — alarm fired just after cancel, ignore
        if (!prefs.contains(SleepModeService.KEY_SCREEN_OFF_TIME)) return

        val screenOffTime = prefs.getLong(SleepModeService.KEY_SCREEN_OFF_TIME, 0L)
        val elapsed = System.currentTimeMillis() - screenOffTime
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        when {
            !audio.isMusicActive -> {
                // Audio finished → start 10-min silence countdown
                SleepModeService.scheduleAlarm(
                    context,
                    SleepModeService.makeSleepTriggerPI(context),
                    SleepModeService.SLEEP_TRIGGER_DELAY_MS,
                )
            }
            elapsed >= SleepModeService.AUDIO_MAX_WAIT_MS -> {
                // 3h of audio → fell asleep with media playing
                prefs.edit().putBoolean(SleepModeService.KEY_SLEEP_ACTIVE, true).apply()
            }
            else -> {
                // Still playing → check again in 5 min
                SleepModeService.scheduleAlarm(
                    context,
                    SleepModeService.makeAudioCheckPI(context),
                    SleepModeService.AUDIO_CHECK_INTERVAL_MS,
                )
            }
        }
    }
}
