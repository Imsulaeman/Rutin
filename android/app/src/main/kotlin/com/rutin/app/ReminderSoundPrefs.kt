package com.rutin.app

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.provider.Settings

object ReminderSoundPrefs {
    private const val PREFS = "reminder_sound_settings"
    private const val KEY_NOTIFICATION = "notification_sound"
    private const val KEY_ALARM = "alarm_sound"

    const val SOUND_DROP = "chime"    // notif_chime.ogg — Rutin Drop
    const val SOUND_RING = "ringtone" // ringtone.ogg    — Rutin Ring
    const val SOUND_SYSTEM = "system"

    fun notificationSound(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return normalize(prefs.getString(KEY_NOTIFICATION, SOUND_DROP) ?: SOUND_DROP)
    }

    fun alarmSound(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return normalize(prefs.getString(KEY_ALARM, SOUND_RING) ?: SOUND_RING)
    }

    fun saveNotificationSound(context: Context, value: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_NOTIFICATION, value).apply()
    }

    fun saveAlarmSound(context: Context, value: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_ALARM, value).apply()
    }

    fun notificationUri(context: Context): Uri =
        soundUri(context, notificationSound(context), isAlarm = false)

    fun alarmUri(context: Context): Uri =
        soundUri(context, alarmSound(context), isAlarm = true)

    fun soundUri(context: Context, value: String, isAlarm: Boolean): Uri = when (value) {
        SOUND_SYSTEM -> (if (isAlarm) Settings.System.DEFAULT_RINGTONE_URI
                         else Settings.System.DEFAULT_NOTIFICATION_URI)
                        ?: rawUri(context, R.raw.notif_chime)
        SOUND_RING   -> rawUri(context, R.raw.ringtone)
        else         -> rawUri(context, R.raw.notif_chime) // SOUND_DROP + legacy 'app'
    }

    // Migrate legacy 'app' value to new constant
    private fun normalize(value: String) = if (value == "app") SOUND_DROP else value

    private fun rawUri(context: Context, res: Int): Uri =
        Uri.parse("${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/$res")
}
