package com.nexuscoach.nexuscoach

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "nexuscoach/minimap"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val intervalSeconds = call.argument<Int>("intervalSeconds") ?: 45
                        val message = call.argument<String>("message") ?: "Olhe o minimapa"
                        val locale = call.argument<String>("locale") ?: "pt-BR"
                        startMinimapService(intervalSeconds, message, locale)
                        result.success(null)
                    }
                    "stop" -> {
                        stopMinimapService()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startMinimapService(intervalSeconds: Int, message: String, locale: String) {
        val intent = Intent(this, MinimapReminderService::class.java).apply {
            action = MinimapReminderService.ACTION_START
            putExtra(
                MinimapReminderService.EXTRA_INTERVAL_MS,
                intervalSeconds.toLong() * 1000
            )
            putExtra(MinimapReminderService.EXTRA_MESSAGE, message)
            putExtra(MinimapReminderService.EXTRA_LOCALE, locale)
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopMinimapService() {
        val intent = Intent(this, MinimapReminderService::class.java).apply {
            action = MinimapReminderService.ACTION_STOP
        }
        startService(intent)
    }
}
