package com.rutin.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val rootAlarmId = intent.getIntExtra("alarm_id", 0)
        val scheduledMinutes = intent.getIntExtra("scheduled_minutes", 0)
        val medicineName = intent.getStringExtra("medicine_name") ?: "Obat"
        val dosage = intent.getStringExtra("dosage")
        val renotifyMinutes = intent.getIntExtra("renotify_minutes", 10)

        if (rootAlarmId == 0) return

        NativeReminderScheduler.cancelLoop(context, rootAlarmId)
        NativeReminderScheduler.schedule(
            context = context,
            rootAlarmId = rootAlarmId,
            triggerAtMillis = System.currentTimeMillis() + (renotifyMinutes * 60_000L),
            scheduledMinutes = scheduledMinutes,
            medicineName = medicineName,
            dosage = dosage,
            renotifyMinutes = renotifyMinutes,
            isLoop = true
        )
    }
}
