package com.rutin.app

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.provider.Settings

object ReminderSoundPrefs {
    private const val PREFS = "reminder_sound_settings"
    private const val KEY_NOTIFICATION = "notification_sound"
    private const val KEY_ALARM = "alarm_sound"

    const val SOUND_APP = "app"
    const val SOUND_SYSTEM = "system"

    fun notificationSound(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getString(KEY_NOTIFICATION, SOUND_APP) ?: SOUND_APP
    }

    fun alarmSound(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getString(KEY_ALARM, SOUND_APP) ?: SOUND_APP
    }

    fun saveNotificationSound(context: Context, value: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_NOTIFICATION, value)
            .apply()
    }

    fun saveAlarmSound(context: Context, value: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ALARM, value)
            .apply()
    }

    fun notificationUri(context: Context): Uri {
        return if (notificationSound(context) == SOUND_SYSTEM) {
            Settings.System.DEFAULT_NOTIFICATION_URI ?: appNotificationUri(context)
        } else {
            appNotificationUri(context)
        }
    }

    fun alarmUri(context: Context): Uri {
        return if (alarmSound(context) == SOUND_SYSTEM) {
            Settings.System.DEFAULT_RINGTONE_URI ?: appAlarmUri(context)
        } else {
            appAlarmUri(context)
        }
    }

    private fun appNotificationUri(context: Context): Uri {
        return Uri.parse(
            "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/${R.raw.notif_chime}"
        )
    }

    private fun appAlarmUri(context: Context): Uri {
        return Uri.parse(
            "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/${R.raw.ringtone}"
        )
    }
}
