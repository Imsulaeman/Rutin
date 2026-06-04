package com.benihstudio.rutin

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WaterActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(WaterAlarmReceiver.NOTIFICATION_ID)

        val prefs = context.getSharedPreferences("water_pending", Context.MODE_PRIVATE)
        val current = prefs.getInt("pending_glasses", 0)
        prefs.edit().putInt("pending_glasses", current + 1).apply()
    }
}

