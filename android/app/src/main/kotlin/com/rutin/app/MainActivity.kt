package com.rutin.app

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
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
                        val scheduledMinutes = call.argument<Int>("scheduledMinutes") ?: 0
                        val medicineName = call.argument<String>("medicineName") ?: "Obat"
                        val dosage = call.argument<String>("dosage")
                        val renotifyMinutes = call.argument<Int>("renotifyMinutes") ?: 10
                        val isLoop = call.argument<Boolean>("isLoop") ?: false
                        NativeReminderScheduler.schedule(
                            context = applicationContext,
                            rootAlarmId = alarmId,
                            triggerAtMillis = triggerAtMillis,
                            scheduledMinutes = scheduledMinutes,
                            medicineName = medicineName,
                            dosage = dosage,
                            renotifyMinutes = renotifyMinutes,
                            isLoop = isLoop
                        )
                        result.success(true)
                    }
                    "cancelReminder" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        NativeReminderScheduler.cancel(applicationContext, alarmId)
                        result.success(true)
                    }
                    "cancelDoseLoop" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        NativeReminderScheduler.cancelLoop(applicationContext, alarmId)
                        result.success(true)
                    }
                    "getReminderDebug" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        result.success(HashMap(NativeReminderScheduler.debugState(applicationContext, alarmId)))
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
                    "getPendingTaken" -> {
                        val prefs = applicationContext.getSharedPreferences("medicine_pending", android.content.Context.MODE_PRIVATE)
                        val set = prefs.getStringSet("pending_taken", emptySet()) ?: emptySet()
                        val list = ArrayList(set)
                        prefs.edit().putStringSet("pending_taken", emptySet()).apply()
                        result.success(list)
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
                    "vibrateImpact" -> {
                        val durationMs = call.argument<Int>("durationMs") ?: 45
                        val amplitude = call.argument<Int>("amplitude") ?: 255
                        vibrateImpact(durationMs, amplitude)
                        result.success(null)
                    }
                    "vibratePattern" -> {
                        val timings = (call.argument<List<Int>>("timings") ?: emptyList()).map { it.toLong() }.toLongArray()
                        val amplitudes = (call.argument<List<Int>>("amplitudes") ?: emptyList()).toIntArray()
                        vibratePattern(timings, amplitudes)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun vibrateImpact(durationMs: Int, amplitude: Int) {
        val vib = vibrator() ?: return
        if (!vib.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vib.vibrate(
                VibrationEffect.createOneShot(
                    durationMs.toLong(),
                    amplitude.coerceIn(1, 255)
                )
            )
        } else {
            @Suppress("DEPRECATION")
            vib.vibrate(durationMs.toLong())
        }
    }

    private fun vibratePattern(timings: LongArray, amplitudes: IntArray) {
        val vib = vibrator() ?: return
        if (!vib.hasVibrator() || timings.isEmpty()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val safeAmplitudes = if (amplitudes.size == timings.size) {
                amplitudes.map { it.coerceIn(0, 255) }.toIntArray()
            } else {
                IntArray(timings.size) { if (it == 0) 0 else 255 }
            }
            vib.vibrate(VibrationEffect.createWaveform(timings, safeAmplitudes, -1))
        } else {
            @Suppress("DEPRECATION")
            vib.vibrate(timings, -1)
        }
    }
}
