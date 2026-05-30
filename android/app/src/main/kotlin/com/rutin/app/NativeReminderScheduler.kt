package com.rutin.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object NativeReminderScheduler {
    private const val ACTION_FIRE_BASE = "com.rutin.app.ACTION_FIRE_REMINDER_BASE"
    private const val ACTION_FIRE_LOOP = "com.rutin.app.ACTION_FIRE_REMINDER_LOOP"
    private const val EXTRA_ROOT_ALARM_ID = "root_alarm_id"
    private const val EXTRA_SCHEDULED_MINUTES = "scheduled_minutes"
    private const val EXTRA_MEDICINE_NAME = "medicine_name"
    private const val EXTRA_DOSAGE = "dosage"
    private const val EXTRA_RENOTIFY_MINUTES = "renotify_minutes"
    private const val EXTRA_IS_LOOP = "is_loop"
    private const val DEBUG_PREFS = "medicine_alarm_debug"

    fun schedule(
        context: Context,
        rootAlarmId: Int,
        triggerAtMillis: Long,
        scheduledMinutes: Int,
        medicineName: String,
        dosage: String?,
        renotifyMinutes: Int,
        isLoop: Boolean
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(
            context,
            rootAlarmId,
            scheduledMinutes,
            medicineName,
            dosage,
            renotifyMinutes,
            isLoop
        )

        val showIntent = PendingIntent.getActivity(
            context,
            rootAlarmId,
            Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("open_tab", "medicine")
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        // AlarmClockInfo keeps medicine reminders in the alarm-grade lane on
        // OEM builds that aggressively batch exact alarms, especially the
        // repeat-until-taken loop.
        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent),
            pendingIntent
        )
        rememberScheduled(context, rootAlarmId, triggerAtMillis, isLoop)
    }

    fun cancel(context: Context, rootAlarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(cancelIntent(context, rootAlarmId, false))
        alarmManager.cancel(cancelIntent(context, rootAlarmId, true))
        clearScheduled(context, rootAlarmId, false)
        clearScheduled(context, rootAlarmId, true)
    }

    fun cancelLoop(context: Context, rootAlarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(cancelIntent(context, rootAlarmId, true))
        clearScheduled(context, rootAlarmId, true)
    }

    fun debugState(context: Context, rootAlarmId: Int): Map<String, Long> {
        val prefs = context.getSharedPreferences(DEBUG_PREFS, Context.MODE_PRIVATE)
        val out = linkedMapOf<String, Long>()
        val base = prefs.getLong("base_$rootAlarmId", 0L)
        val loop = prefs.getLong("loop_$rootAlarmId", 0L)
        if (base > 0L) out["baseMillis"] = base
        if (loop > 0L) out["loopMillis"] = loop
        return out
    }

    private fun pendingIntent(
        context: Context,
        rootAlarmId: Int,
        scheduledMinutes: Int,
        medicineName: String,
        dosage: String?,
        renotifyMinutes: Int,
        isLoop: Boolean
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = if (isLoop) ACTION_FIRE_LOOP else ACTION_FIRE_BASE
            putExtra(EXTRA_ROOT_ALARM_ID, rootAlarmId)
            putExtra(EXTRA_SCHEDULED_MINUTES, scheduledMinutes)
            putExtra(EXTRA_MEDICINE_NAME, medicineName)
            putExtra(EXTRA_DOSAGE, dosage)
            putExtra(EXTRA_RENOTIFY_MINUTES, renotifyMinutes)
            putExtra(EXTRA_IS_LOOP, isLoop)
        }
        return PendingIntent.getBroadcast(
            context,
            rootAlarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun cancelIntent(
        context: Context,
        rootAlarmId: Int,
        isLoop: Boolean
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = if (isLoop) ACTION_FIRE_LOOP else ACTION_FIRE_BASE
        }
        return PendingIntent.getBroadcast(
            context,
            rootAlarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun rememberScheduled(
        context: Context,
        rootAlarmId: Int,
        triggerAtMillis: Long,
        isLoop: Boolean
    ) {
        context.getSharedPreferences(DEBUG_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putLong(debugKey(rootAlarmId, isLoop), triggerAtMillis)
            .apply()
    }

    private fun clearScheduled(
        context: Context,
        rootAlarmId: Int,
        isLoop: Boolean
    ) {
        context.getSharedPreferences(DEBUG_PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(debugKey(rootAlarmId, isLoop))
            .apply()
    }

    private fun debugKey(rootAlarmId: Int, isLoop: Boolean): String =
        if (isLoop) "loop_$rootAlarmId" else "base_$rootAlarmId"
}
