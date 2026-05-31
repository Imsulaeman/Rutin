package com.rutin.app

import android.app.Notification
import android.app.NotificationChannel
import android.content.ContentResolver
import android.media.AudioAttributes
import android.net.Uri
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val rootAlarmId = intent.getIntExtra("root_alarm_id", intent.getIntExtra("alarm_id", 0))
        val scheduledMinutes = intent.getIntExtra("scheduled_minutes", 0)
        val medicineName = intent.getStringExtra("medicine_name") ?: NativeStrings.medicineFallback(context)
        val dosage = intent.getStringExtra("dosage")
        val renotifyMinutes = intent.getIntExtra("renotify_minutes", 10)
        val isLoop = intent.getBooleanExtra("is_loop", false)

        if (!isLoop && scheduledMinutes >= 0) {
            NativeReminderScheduler.schedule(
                context = context,
                rootAlarmId = rootAlarmId,
                triggerAtMillis = nextDayTrigger(scheduledMinutes),
                scheduledMinutes = scheduledMinutes,
                medicineName = medicineName,
                dosage = dosage,
                renotifyMinutes = renotifyMinutes,
                isLoop = false
            )
        }

        showFullScreenNotification(
            context,
            rootAlarmId,
            scheduledMinutes,
            medicineName,
            dosage,
            renotifyMinutes
        )

        val nextTrigger = System.currentTimeMillis() + (renotifyMinutes * 60_000L)
        NativeReminderScheduler.schedule(
            context = context,
            rootAlarmId = rootAlarmId,
            triggerAtMillis = nextTrigger,
            scheduledMinutes = scheduledMinutes,
            medicineName = medicineName,
            dosage = dosage,
            renotifyMinutes = renotifyMinutes,
            isLoop = true
        )
    }

    private fun showFullScreenNotification(
        context: Context,
        rootAlarmId: Int,
        scheduledMinutes: Int,
        medicineName: String,
        dosage: String?,
        renotifyMinutes: Int
    ) {
        val channelId = "medicine_alarm_v2"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.deleteNotificationChannel("medicine_alarm")
            val soundUri = Uri.parse(
                "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/${R.raw.ringtone}"
            )
            val audioAttrs = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()
            val channel = NotificationChannel(
                channelId,
                NativeStrings.medicineChannel(context),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = NativeStrings.medicineDescription(context)
                setSound(soundUri, audioAttrs)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 400, 200, 400, 200, 400)
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }

        val activityIntent = Intent(context, ReminderActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("alarm_id", rootAlarmId)
            putExtra("scheduled_minutes", scheduledMinutes)
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("renotify_minutes", renotifyMinutes)
        }
        val fullScreenPi = PendingIntent.getActivity(
            context,
            rootAlarmId,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val deleteIntent = Intent(context, ReminderDismissReceiver::class.java).apply {
            putExtra("alarm_id", rootAlarmId)
            putExtra("scheduled_minutes", scheduledMinutes)
            putExtra("medicine_name", medicineName)
            putExtra("dosage", dosage)
            putExtra("renotify_minutes", renotifyMinutes)
        }
        val deletePi = PendingIntent.getBroadcast(
            context,
            rootAlarmId,
            deleteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val body = if (!dosage.isNullOrEmpty()) "$medicineName - $dosage" else medicineName

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(NativeStrings.medicineTitle(context))
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPi, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDeleteIntent(deletePi)
            .build()

        nm.notify(rootAlarmId, notification)
    }

    private fun nextDayTrigger(scheduledMinutes: Int): Long {
        val now = java.util.Calendar.getInstance()
        val next = now.clone() as java.util.Calendar
        next.set(java.util.Calendar.HOUR_OF_DAY, scheduledMinutes / 60)
        next.set(java.util.Calendar.MINUTE, scheduledMinutes % 60)
        next.set(java.util.Calendar.SECOND, 0)
        next.set(java.util.Calendar.MILLISECOND, 0)
        if (!next.after(now)) {
            next.add(java.util.Calendar.DAY_OF_YEAR, 1)
        } else {
            next.add(java.util.Calendar.DAY_OF_YEAR, 1)
        }
        return next.timeInMillis
    }
}
