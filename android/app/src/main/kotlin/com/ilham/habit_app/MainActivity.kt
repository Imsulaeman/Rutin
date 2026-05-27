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
                    else -> result.notImplemented()
                }
            }
    }
}
