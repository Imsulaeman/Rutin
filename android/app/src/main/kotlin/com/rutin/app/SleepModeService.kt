package com.rutin.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.os.IBinder

class SleepModeService : Service() {

    companion object {
        const val PREFS = "sleep_mode_prefs"
        const val KEY_SLEEP_ACTIVE = "sleep_active"
        const val KEY_SERVICE_RUNNING = "service_running"
        const val KEY_SCREEN_OFF_TIME = "screen_off_time_ms"

        const val ACTION_SLEEP_TRIGGER = "com.rutin.app.SLEEP_TRIGGER"
        const val ACTION_AUDIO_CHECK = "com.rutin.app.AUDIO_CHECK"

        private const val NOTIF_ID = 9001
        const val MORNING_GATE_NOTIF_ID = 9002
        private const val CHANNEL_ID = "sleep_mode_service"
        private const val MORNING_GATE_CHANNEL_ID = "morning_gate"
        private const val RC_SLEEP_TRIGGER = 9003
        private const val RC_AUDIO_CHECK = 9004
        private const val RC_MORNING_GATE = 9006

        const val SLEEP_TRIGGER_DELAY_MS = 10 * 60 * 1000L  // 10 min silence → sleep
        const val AUDIO_CHECK_INTERVAL_MS = 5 * 60 * 1000L  // poll while audio plays
        const val AUDIO_MAX_WAIT_MS = 3 * 60 * 60 * 1000L   // 3h audio fallback

        fun start(context: Context) {
            val intent = Intent(context, SleepModeService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SleepModeService::class.java))
        }

        fun isRunning(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_SERVICE_RUNNING, false)

        fun refreshNotification(context: Context) {
            if (!isRunning(context)) return
            context.startService(
                Intent(context, SleepModeService::class.java)
                    .setAction("com.rutin.app.REFRESH_NOTIFICATION")
            )
        }

        fun postMorningGateNotification(context: Context) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val ch = NotificationChannel(
                    MORNING_GATE_CHANNEL_ID,
                    NativeStrings.morningGateChannel(context),
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { setShowBadge(true) }
                nm.createNotificationChannel(ch)
            }
            val tapIntent = PendingIntent.getActivity(
                context, RC_MORNING_GATE,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("route", "/morning-gate")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notif = androidx.core.app.NotificationCompat.Builder(context, MORNING_GATE_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(NativeStrings.morningGateTitle(context))
                .setContentText(NativeStrings.morningGateBody(context))
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_MAX)
                .setCategory(androidx.core.app.NotificationCompat.CATEGORY_REMINDER)
                .setContentIntent(tapIntent)
                .setFullScreenIntent(tapIntent, true)
                .setAutoCancel(false)
                .setOngoing(true)
                .build()
            nm.notify(MORNING_GATE_NOTIF_ID, notif)
        }

        fun cancelMorningGateNotification(context: Context) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(MORNING_GATE_NOTIF_ID)
        }

        fun cancelAllAlarms(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(makeSleepTriggerPI(context))
            am.cancel(makeAudioCheckPI(context))
        }

        fun scheduleAlarm(context: Context, pi: PendingIntent, delayMs: Long) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val at = System.currentTimeMillis() + delayMs
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms() ->
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
                else -> am.setExact(AlarmManager.RTC_WAKEUP, at, pi)
            }
        }

        fun makeSleepTriggerPI(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, RC_SLEEP_TRIGGER,
                Intent(context, SleepTriggerReceiver::class.java).setAction(ACTION_SLEEP_TRIGGER),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        fun makeAudioCheckPI(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, RC_AUDIO_CHECK,
                Intent(context, SleepTriggerReceiver::class.java).setAction(ACTION_AUDIO_CHECK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }

    private var screenReceiver: BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
        registerScreenReceiver()
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putBoolean(KEY_SERVICE_RUNNING, true).apply()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "com.rutin.app.REFRESH_NOTIFICATION") {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIF_ID, buildNotification())
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        screenReceiver?.let { runCatching { unregisterReceiver(it) } }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putBoolean(KEY_SERVICE_RUNNING, false).apply()
        // Alarms intentionally NOT cancelled here: if Android kills the service before the
        // user wakes up, the pending alarm must still fire to set sleep_active.
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerScreenReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_OFF -> onScreenOff()
                    Intent.ACTION_SCREEN_ON -> onScreenOn()
                    Intent.ACTION_USER_PRESENT -> onUserPresent(ctx)
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, filter)
        }
        screenReceiver = receiver
    }

    private fun onScreenOff() {
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putLong(KEY_SCREEN_OFF_TIME, System.currentTimeMillis()).apply()

        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        if (audio.isMusicActive) {
            scheduleAlarm(this, makeAudioCheckPI(this), AUDIO_CHECK_INTERVAL_MS)
        } else {
            scheduleAlarm(this, makeSleepTriggerPI(this), SLEEP_TRIGGER_DELAY_MS)
        }
    }

    private fun onScreenOn() {
        cancelAllAlarms(this)
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .remove(KEY_SCREEN_OFF_TIME).apply()
    }

    private fun onUserPresent(ctx: Context) {
        val prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SLEEP_ACTIVE, false)) return
        prefs.edit()
            .putBoolean(KEY_SLEEP_ACTIVE, false)
            .remove(KEY_SCREEN_OFF_TIME)
            .apply()
        // Post a persistent notification — on Android 10+ apps can't start activities
        // from background services, so we use a full-screen intent notification instead.
        // It appears as a heads-up/full-screen alert immediately on unlock.
        postMorningGateNotification(ctx)
        runCatching { SleepScheduleReceiver.sync(ctx) }
    }

    private fun buildNotification(): Notification =
        Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(NativeStrings.sleepActive(this))
            .setContentText(NativeStrings.sleepWaiting(this))
            .setOngoing(true)
            .build()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val ch = NotificationChannel(
                CHANNEL_ID,
                NativeStrings.sleepChannel(this),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = NativeStrings.sleepDescription(this@SleepModeService)
                setShowBadge(false)
            }
            nm.createNotificationChannel(ch)
        }
    }
}
