package com.nexuscoach.nexuscoach

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import androidx.core.app.NotificationCompat
import java.util.Locale

class WardReminderService : Service(), TextToSpeech.OnInitListener {
    companion object {
        const val ACTION_START = "com.nexuscoach.nexuscoach.START_WARD"
        const val ACTION_STOP = "com.nexuscoach.nexuscoach.STOP_WARD"
        const val EXTRA_INTERVAL_MS = "interval_ms"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_LOCALE = "locale"

        private const val CHANNEL_ID = "nexuscoach_ward"
        private const val NOTIFICATION_ID = 2002
    }

    private val handler = Handler(Looper.getMainLooper())
    private var intervalMs = 90000L
    private var message = "Coloque uma ward"
    private var locale: Locale = Locale("pt", "BR")
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    private val reminderRunnable = object : Runnable {
        override fun run() {
            speak()
            handler.postDelayed(this, intervalMs)
        }
    }

    override fun onCreate() {
        super.onCreate()
        tts = TextToSpeech(this, this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startReminder(intent)
            ACTION_STOP -> stopSelf()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(reminderRunnable)
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onInit(status: Int) {
        ttsReady = status == TextToSpeech.SUCCESS
        if (ttsReady) {
            tts?.language = locale
        }
    }

    private fun startReminder(intent: Intent) {
        intervalMs = intent.getLongExtra(EXTRA_INTERVAL_MS, intervalMs)
        message = intent.getStringExtra(EXTRA_MESSAGE) ?: message
        locale = parseLocale(intent.getStringExtra(EXTRA_LOCALE))

        if (ttsReady) {
            tts?.language = locale
        }

        startForeground(NOTIFICATION_ID, buildNotification())
        handler.removeCallbacks(reminderRunnable)
        handler.postDelayed(reminderRunnable, intervalMs)
    }

    private fun speak() {
        if (!ttsReady) {
            return
        }
        tts?.speak(message, TextToSpeech.QUEUE_FLUSH, null, "ward")
    }

    private fun buildNotification(): Notification {
        createChannelIfNeeded()
        val intent = Intent(this, MainActivity::class.java)
        val pending = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NexusCoach")
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pending)
            .build()
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "NexusCoach Ward",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun parseLocale(tag: String?): Locale {
        if (tag.isNullOrBlank()) {
            return locale
        }
        val parts = tag.split("-")
        return if (parts.size >= 2) {
            Locale(parts[0], parts[1])
        } else {
            Locale(tag)
        }
    }
}
