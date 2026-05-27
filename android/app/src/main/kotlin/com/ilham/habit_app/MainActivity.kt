package com.ilham.habit_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "habit_app/native_reminder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleReminder" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val medicineName = call.argument<String>("medicineName") ?: "Obat"
                        val dosage = call.argument<String>("dosage")
                        val renotifyMinutes = call.argument<Int>("renotifyMinutes") ?: 10
                        NativeReminderScheduler.schedule(
                            context = applicationContext,
                            alarmId = alarmId,
                            triggerAtMillis = triggerAtMillis,
                            medicineName = medicineName,
                            dosage = dosage,
                            renotifyMinutes = renotifyMinutes
                        )
                        result.success(true)
                    }
                    "cancelReminder" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        NativeReminderScheduler.cancel(applicationContext, alarmId)
                        result.success(true)
                    }
                    "scheduleWaterAlarm" -> {
                        val delayMs = (call.argument<Any>("delayMs") as? Number)?.toLong() ?: 15_000L
                        WaterAlarmReceiver.schedule(applicationContext, delayMs)
                        result.success(null)
                    }
                    "cancelWaterAlarm" -> {
                        WaterAlarmReceiver.cancel(applicationContext)
                        result.success(null)
                    }
                    "saveWaterSettings" -> {
                        val startMin = call.argument<Int>("startMin") ?: 420
                        val endMin = call.argument<Int>("endMin") ?: 1320
                        val intervalMs = (call.argument<Any>("intervalMs") as? Number)?.toLong() ?: 120 * 60_000L
                        val reminderActive = call.argument<Boolean>("reminderActive") ?: false
                        val debug = call.argument<Boolean>("debug") ?: false
                        applicationContext.getSharedPreferences("water_settings", android.content.Context.MODE_PRIVATE)
                            .edit()
                            .putInt("start_min", startMin)
                            .putInt("end_min", endMin)
                            .putLong("interval_ms", intervalMs)
                            .putBoolean("reminder_active", reminderActive)
                            .putBoolean("debug", debug)
                            .apply()
                        result.success(null)
                    }
                    "getPendingWaterLogs" -> {
                        val prefs = applicationContext.getSharedPreferences("water_pending", android.content.Context.MODE_PRIVATE)
                        val count = prefs.getInt("pending_glasses", 0)
                        prefs.edit().putInt("pending_glasses", 0).apply()
                        result.success(count)
                    }
                    "minimizeApp" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    "scheduleHabitAlarm" -> {
                        val notifId = call.argument<Int>("notifId") ?: 0
                        val triggerMs = (call.argument<Any>("triggerMs") as? Number)?.toLong() ?: 0L
                        val title = call.argument<String>("title") ?: ""
                        HabitAlarmReceiver.schedule(applicationContext, notifId, triggerMs, title)
                        result.success(null)
                    }
                    "cancelHabitAlarm" -> {
                        val notifId = call.argument<Int>("notifId") ?: 0
                        HabitAlarmReceiver.cancel(applicationContext, notifId)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
