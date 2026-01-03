package com.nexuscoach.nexuscoach

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val minimapChannel = "nexuscoach/minimap"
    private val overlayChannel = "nexuscoach/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, minimapChannel)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, overlayChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canDrawOverlays" -> {
                        val allowed = Settings.canDrawOverlays(this)
                        Log.d("OverlayChannel", "canDrawOverlays=$allowed")
                        result.success(allowed)
                    }
                    "requestPermission" -> {
                        Log.d("OverlayChannel", "requestPermission")
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    }
                    "start" -> {
                        val allowed = Settings.canDrawOverlays(this)
                        if (!allowed) {
                            Log.w("OverlayChannel", "request to start overlay without permission")
                            result.error("PERMISSION", "Overlay permission missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            Log.d("OverlayChannel", "start overlay service")
                            startOverlayService()
                            result.success(true)
                        } catch (error: Exception) {
                            Log.e("OverlayChannel", "start overlay failed", error)
                            result.error("START_FAILED", error.message, null)
                        }
                    }
                    "stop" -> {
                        try {
                            Log.d("OverlayChannel", "stop overlay service")
                            stopOverlayService()
                            result.success(true)
                        } catch (error: Exception) {
                            Log.e("OverlayChannel", "stop overlay failed", error)
                            result.error("STOP_FAILED", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startMinimapService(intervalSeconds: Int, message: String, locale: String) {
        val intent = Intent(this, MinimapReminderService::class.java).apply {
            action = MinimapReminderService.ACTION_START
            putExtra(MinimapReminderService.EXTRA_INTERVAL_MS, intervalSeconds.toLong() * 1000)
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

    private fun startOverlayService() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopOverlayService() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_STOP
        }
        startService(intent)
    }
}
