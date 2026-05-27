package com.ilham.habit_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object NativeReminderScheduler {
    private const val ACTION_FIRE = "com.ilham.habit_app.ACTION_FIRE_REMINDER"
    private const val ACTION_FIRE_WATER = "com.ilham.habit_app.ACTION_FIRE_WATER"
    private const val EXTRA_ALARM_ID = "alarm_id"
    private const val EXTRA_MEDICINE_NAME = "medicine_name"
    private const val EXTRA_DOSAGE = "dosage"
    private const val EXTRA_RENOTIFY_MINUTES = "renotify_minutes"

    fun schedule(
        context: Context,
        alarmId: Int,
        triggerAtMillis: Long,
        medicineName: String,
        dosage: String?,
        renotifyMinutes: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(
            context,
            alarmId,
            medicineName,
            dosage,
            renotifyMinutes
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }

    fun cancel(context: Context, alarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = ACTION_FIRE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    fun scheduleWater(
        context: Context,
        alarmId: Int,
        triggerAtMillis: Long,
        intervalMinutes: Int,
        startTimeMinutes: Int,
        endTimeMinutes: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = ACTION_FIRE_WATER
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra("interval_minutes", intervalMinutes)
            putExtra("start_time_minutes", startTimeMinutes)
            putExtra("end_time_minutes", endTimeMinutes)
        }
        val pi = PendingIntent.getBroadcast(
            context, alarmId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
    }

    fun cancelWater(context: Context, alarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = ACTION_FIRE_WATER
        }
        val pi = PendingIntent.getBroadcast(
            context, alarmId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pi)
    }

    private fun pendingIntent(
        context: Context,
        alarmId: Int,
        medicineName: String,
        dosage: String?,
        renotifyMinutes: Int
    ): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_MEDICINE_NAME, medicineName)
            putExtra(EXTRA_DOSAGE, dosage)
            putExtra(EXTRA_RENOTIFY_MINUTES, renotifyMinutes)
        }
        return PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
