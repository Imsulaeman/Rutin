package com.rutin.app

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
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class SleepModeService : Service() {

    companion object {
        const val PREFS = "sleep_mode_prefs"
        const val KEY_SLEEP_ACTIVE = "sleep_active"
        const val KEY_LAST_INTERACTION = "last_interaction_ms"
        const val KEY_AUDIO_WAS_PLAYING = "audio_was_playing"
        const val KEY_SERVICE_RUNNING = "service_running"
        const val ACTION_STILL_AWAKE = "com.rutin.app.STILL_AWAKE"
        private const val NOTIF_ID = 9001
        private const val CHANNEL_ID = "sleep_mode_service"
        private const val POLL_INTERVAL_MS = 5 * 60 * 1000L // 5 min

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

        fun isRunning(context: Context): Boolean {
            return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_SERVICE_RUNNING, false)
        }

        fun refreshNotification(context: Context) {
            if (!isRunning(context)) return
            context.startService(
                Intent(context, SleepModeService::class.java)
                    .setAction("com.rutin.app.REFRESH_NOTIFICATION")
            )
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wakeUpReceiver: WakeUpTriggerReceiver? = null
    private var stillAwakeReceiver: BroadcastReceiver? = null

    private val pollRunnable = object : Runnable {
        override fun run() {
            checkSleepState()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification(false))
        registerWakeUpReceiver()
        registerStillAwakeReceiver()
        handler.post(pollRunnable)
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putBoolean(KEY_SERVICE_RUNNING, true)
            .putLong(KEY_LAST_INTERACTION, System.currentTimeMillis())
            .apply()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "com.rutin.app.REFRESH_NOTIFICATION") {
            updateNotification(false)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(pollRunnable)
        wakeUpReceiver?.let { runCatching { unregisterReceiver(it) } }
        stillAwakeReceiver?.let { runCatching { unregisterReceiver(it) } }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putBoolean(KEY_SERVICE_RUNNING, false)
            .putBoolean(KEY_SLEEP_ACTIVE, false)
            .apply()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerWakeUpReceiver() {
        val receiver = WakeUpTriggerReceiver()
        val filter = IntentFilter(Intent.ACTION_USER_PRESENT)
        registerAppReceiver(receiver, filter)
        wakeUpReceiver = receiver
    }

    private fun registerStillAwakeReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == ACTION_STILL_AWAKE) {
                    // Pause detection for 30 min
                    val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
                    val pauseUntil = System.currentTimeMillis() + 30 * 60 * 1000L
                    prefs.edit()
                        .putLong("pause_until_ms", pauseUntil)
                        .putBoolean(KEY_SLEEP_ACTIVE, false)
                        .apply()
                    updateNotification(true)
                }
            }
        }
        registerAppReceiver(receiver, IntentFilter(ACTION_STILL_AWAKE))
        stillAwakeReceiver = receiver
    }

    private fun registerAppReceiver(receiver: BroadcastReceiver, filter: IntentFilter) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
    }

    private fun checkSleepState() {
        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)

        // Respect "still awake" pause
        val pauseUntil = prefs.getLong("pause_until_ms", 0L)
        if (System.currentTimeMillis() < pauseUntil) return

        val sleepStartPrefs = applicationContext.getSharedPreferences(
            "sleep_settings_native", MODE_PRIVATE
        )
        val sleepStartMin = sleepStartPrefs.getInt("sleep_start_min", 1260)
        val wakeEndMin = sleepStartPrefs.getInt("wake_window_end", 600)
        val nowMin = nowMinutes()
        if (!SleepScheduleReceiver.isWithinNightWindow(nowMin, sleepStartMin, wakeEndMin)) {
            SleepScheduleReceiver.finishNight(this)
            return
        }

        val now = System.currentTimeMillis()
        val lastInteraction = prefs.getLong(KEY_LAST_INTERACTION, now)
        val idleMs = now - lastInteraction
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        val audioPlaying = audioManager.isMusicActive
        val audioWasPlaying = prefs.getBoolean(KEY_AUDIO_WAS_PLAYING, false)

        val sleepTriggered = when {
            // Case 1: idle, no audio, >60 min
            !audioPlaying && idleMs > 60 * 60 * 1000L -> true
            // Case 2: audio just stopped, >15 min idle
            audioWasPlaying && !audioPlaying && idleMs > 15 * 60 * 1000L -> true
            // Case 3: audio still playing but >2h idle (fell asleep with media)
            audioPlaying && idleMs > 2 * 60 * 60 * 1000L -> true
            else -> false
        }

        prefs.edit().putBoolean(KEY_AUDIO_WAS_PLAYING, audioPlaying).apply()

        if (sleepTriggered && !prefs.getBoolean(KEY_SLEEP_ACTIVE, false)) {
            prefs.edit().putBoolean(KEY_SLEEP_ACTIVE, true).apply()
        }
    }

    private fun nowMinutes(): Int {
        val cal = java.util.Calendar.getInstance()
        return cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + cal.get(java.util.Calendar.MINUTE)
    }

    private fun buildNotification(paused: Boolean): Notification {
        val stillAwakeIntent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(ACTION_STILL_AWAKE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(if (paused) NativeStrings.sleepPaused(this) else NativeStrings.sleepActive(this))
            .setContentText(NativeStrings.sleepWaiting(this))
            .setOngoing(true)
            .addAction(
                Notification.Action.Builder(
                    null,
                    NativeStrings.stillAwake(this),
                    stillAwakeIntent
                ).build()
            )
            .build()
    }

    private fun updateNotification(paused: Boolean) {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(paused))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                NativeStrings.sleepChannel(this),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = NativeStrings.sleepDescription(this@SleepModeService)
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }
    }
}
