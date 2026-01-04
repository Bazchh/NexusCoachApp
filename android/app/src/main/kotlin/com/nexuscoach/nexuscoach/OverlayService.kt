package com.nexuscoach.nexuscoach

import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.Resources
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import org.json.JSONObject
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.ContextCompat

class OverlayService : Service() {
    private data class MenuItem(
        val view: View,
        val offsetX: Float,
        val offsetY: Float,
        val index: Int,
    )
    companion object {
        const val ACTION_START = "com.nexuscoach.nexuscoach.START_OVERLAY"
        const val ACTION_STOP = "com.nexuscoach.nexuscoach.STOP_OVERLAY"

        const val EXTRA_SESSION_ID = "session_id"
        const val EXTRA_API_BASE_URL = "api_base_url"
        const val EXTRA_LOCALE = "locale"

        private const val CHANNEL_ID = "nexuscoach_overlay"
        private const val NOTIFICATION_ID = 2201
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var menuView: View? = null
    private var menuCloseButton: View? = null
    private var menuAppButton: View? = null
    private var menuMinimapButton: View? = null
    private var menuWardButton: View? = null
    private var menuMicButton: TextView? = null
    private var removeView: View? = null
    private var minimapEnabled = false
    private var wardEnabled = false
    private lateinit var prefs: SharedPreferences
    private var removeParams: WindowManager.LayoutParams? = null
    private var bubbleSizePx = 0
    private var menuButtonPx = 0
    private var menuGapPx = 0
    private var overlaySizePx = 0
    private var removeSizePx = 0
    private var removeOffsetPx = 0
    private var removeMagnetDistance = 0
    private var removeTargetX = 0
    private var removeTargetY = 0
    private var removeHighlighted = false
    private var menuVisible = false
    private var snapAnimator: ValueAnimator? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var micListening = false
    private var awaitingFinal = false
    private var lastTranscript = ""
    private var sessionId: String? = null
    private var apiBaseUrl: String? = null
    private var localeTag: String = "pt-BR"
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private val menuItemCount = 5

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        tts = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) {
                tts?.language = parseLocale(localeTag)
            }
        }
        if (SpeechRecognizer.isRecognitionAvailable(this)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}

                    override fun onError(error: Int) {
                        micListening = false
                        awaitingFinal = false
                        updateMicButton(false)
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        val items =
                            partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        if (!items.isNullOrEmpty()) {
                            lastTranscript = items.first()
                        }
                    }

                    override fun onResults(results: Bundle?) {
                        val items =
                            results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        if (!items.isNullOrEmpty()) {
                            lastTranscript = items.first()
                        }
                        micListening = false
                        updateMicButton(false)
                        if (awaitingFinal && lastTranscript.isNotBlank()) {
                            awaitingFinal = false
                            sendTurn(lastTranscript)
                        }
                    }
                })
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra(EXTRA_SESSION_ID)?.let { sessionId = it }
        intent?.getStringExtra(EXTRA_API_BASE_URL)?.let { apiBaseUrl = it }
        intent?.getStringExtra(EXTRA_LOCALE)?.let {
            localeTag = it
            if (ttsReady) {
                tts?.language = parseLocale(localeTag)
            }
        }
        when (intent?.action) {
            ACTION_START -> showOverlay()
            ACTION_STOP -> stopSelf()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        speechRecognizer?.destroy()
        speechRecognizer = null
        tts?.stop()
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }

    private fun showOverlay() {
        if (overlayView != null) return
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return
        }

        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        minimapEnabled = prefs.getBoolean("flutter.minimap_reminder", false)
        wardEnabled = prefs.getBoolean("flutter.ward_reminder", false)
        localeTag = prefs.getString("flutter.language", localeTag) ?: localeTag
        if (ttsReady) {
            tts?.language = parseLocale(localeTag)
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        bubbleSizePx = dpToPx(56)
        menuButtonPx = dpToPx(40)
        menuGapPx = dpToPx(10)
        val menuSpacing = menuButtonPx + dpToPx(6)
        val menuSpan = (menuItemCount - 1) * menuSpacing + menuButtonPx
        val baseSize = bubbleSizePx + 2 * (menuButtonPx + menuGapPx)
        overlaySizePx = max(baseSize, menuSpan + 2 * menuGapPx)
        removeSizePx = dpToPx(72)
        removeOffsetPx = dpToPx(96)
        removeMagnetDistance = removeSizePx / 2 + dpToPx(40)

        val overlay = FrameLayout(this)
        val menu = buildMenu()
        val bubble = buildBubble()

        overlay.addView(
            menu,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )
        overlay.addView(
            bubble,
            FrameLayout.LayoutParams(
                bubbleSizePx,
                bubbleSizePx,
                Gravity.CENTER
            )
        )

        val params = WindowManager.LayoutParams(
            overlaySizePx,
            overlaySizePx,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = dpToPx(24)
        params.y = dpToPx(180)

        attachDragHandler(bubble, overlay, params)

        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        windowManager?.addView(overlay, params)
        overlayView = overlay
        overlayParams = params
        menuView = menu
    }

    private fun removeOverlay() {
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
        overlayParams = null
        removeView?.let { windowManager?.removeView(it) }
        removeView = null
        snapAnimator?.cancel()
    }

    private fun buildBubble(): View {
        val bubble = FrameLayout(this)
        val bubbleBackground = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            gradientType = GradientDrawable.LINEAR_GRADIENT
            orientation = GradientDrawable.Orientation.TL_BR
            setColors(intArrayOf(0xFF2EFFD4.toInt(), 0xFF0D1419.toInt()))
            setStroke(dpToPx(2), 0xFF1E1E24.toInt())
        }
        bubble.background = bubbleBackground
        bubble.elevation = dpToPx(12).toFloat()

        val glow = View(this).apply {
            val glowBackground = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                gradientType = GradientDrawable.RADIAL_GRADIENT
                setGradientCenter(0.5f, 0.5f)
                setColors(intArrayOf(0x332EFFD4, 0x001C1C1C))
            }
            background = glowBackground
        }

        val text = TextView(this).apply {
            this.text = "N"
            setTextColor(0xFF05070A.toInt())
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

        bubble.addView(
            glow,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )
        bubble.addView(
            text,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        return bubble
    }

    private fun buildMenu(): View {
        val container = FrameLayout(this).apply {
            visibility = View.GONE
            // Sem background - totalmente transparente
        }

        val micButton = buildToggleButton("MIC", micListening) {
            toggleMic()
        }
        val closeButton = buildMenuButton(
            label = "\u2715",
            backgroundColor = 0xFF1B1F25.toInt(),
            textColor = 0xFFEBF2F7.toInt(),
            textSize = 16f
        ) {
            stopSelf()
        }
        val appButton = buildMenuButton(
            label = "\u2699",
            backgroundColor = 0xFF101216.toInt(),
            textColor = 0xFF9EFFCB.toInt(),
            textSize = 20f
        ) {
            openApp()
        }

        // Botão toggle minimapa - M com cor baseada no estado
        val minimapButton = buildToggleButton("M", minimapEnabled) {
            minimapEnabled = !minimapEnabled
            prefs.edit().putBoolean("flutter.minimap_reminder", minimapEnabled).apply()
            updateToggleButtonStyle(menuMinimapButton as? TextView, minimapEnabled)
            syncMinimapService()
        }

        // Botão toggle ward - W com cor baseada no estado
        val wardButton = buildToggleButton("W", wardEnabled) {
            wardEnabled = !wardEnabled
            prefs.edit().putBoolean("flutter.ward_reminder", wardEnabled).apply()
            updateToggleButtonStyle(menuWardButton as? TextView, wardEnabled)
            syncWardService()
        }

        val centerParams = FrameLayout.LayoutParams(
            menuButtonPx,
            menuButtonPx,
            Gravity.CENTER
        )
        container.addView(closeButton, centerParams)
        container.addView(appButton, centerParams)
        container.addView(micButton, centerParams)
        container.addView(minimapButton, centerParams)
        container.addView(wardButton, centerParams)

        menuMicButton = micButton as TextView
        menuCloseButton = closeButton
        menuAppButton = appButton
        menuMinimapButton = minimapButton
        menuWardButton = wardButton
        return container
    }

    private fun buildToggleButton(label: String, enabled: Boolean, onClick: () -> Unit): View {
        val button = TextView(this).apply {
            text = label
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setOnClickListener { onClick() }
        }
        updateToggleButtonStyle(button, enabled)
        return button
    }

    private fun updateToggleButtonStyle(button: TextView?, enabled: Boolean) {
        button ?: return
        val bgColor = if (enabled) 0xFF1A3D2E.toInt() else 0xFF1B1F25.toInt()
        val textColor = if (enabled) 0xFF2EFFD4.toInt() else 0xFF6B7280.toInt()
        val strokeColor = if (enabled) 0xFF2EFFD4.toInt() else 0x33FFFFFF.toInt()

        button.setTextColor(textColor)
        val background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(bgColor)
            setStroke(dpToPx(2), strokeColor)
        }
        button.background = background
        button.elevation = dpToPx(6).toFloat()
    }

    private fun syncMinimapService() {
        val intervalSeconds = prefs.getLong("flutter.minimap_interval", 45L).toInt()
        val language = prefs.getString("flutter.language", "pt-BR") ?: "pt-BR"
        val message = if (language.startsWith("en")) "Check the minimap" else "Olhe o minimapa"

        if (minimapEnabled) {
            val intent = Intent(this, MinimapReminderService::class.java).apply {
                action = MinimapReminderService.ACTION_START
                putExtra(MinimapReminderService.EXTRA_INTERVAL_MS, intervalSeconds * 1000L)
                putExtra(MinimapReminderService.EXTRA_MESSAGE, message)
                putExtra(MinimapReminderService.EXTRA_LOCALE, language)
            }
            ContextCompat.startForegroundService(this, intent)
        } else {
            val intent = Intent(this, MinimapReminderService::class.java).apply {
                action = MinimapReminderService.ACTION_STOP
            }
            startService(intent)
        }
    }

    private fun syncWardService() {
        val language = prefs.getString("flutter.language", "pt-BR") ?: "pt-BR"
        val message = if (language.startsWith("en")) "Place a ward" else "Coloque uma ward"

        if (wardEnabled) {
            val intent = Intent(this, WardReminderService::class.java).apply {
                action = WardReminderService.ACTION_START
                putExtra(WardReminderService.EXTRA_INTERVAL_MS, 50000L) // Fixo em 50 segundos
                putExtra(WardReminderService.EXTRA_MESSAGE, message)
                putExtra(WardReminderService.EXTRA_LOCALE, language)
            }
            ContextCompat.startForegroundService(this, intent)
        } else {
            val intent = Intent(this, WardReminderService::class.java).apply {
                action = WardReminderService.ACTION_STOP
            }
            startService(intent)
        }
    }

    private fun buildMenuButton(
        label: String,
        backgroundColor: Int,
        textColor: Int,
        textSize: Float,
        onClick: () -> Unit
    ): View {
        val button = TextView(this).apply {
            text = label
            setTextColor(textColor)
            this.textSize = textSize
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setOnClickListener { onClick() }
        }

        val background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            gradientType = GradientDrawable.LINEAR_GRADIENT
            orientation = GradientDrawable.Orientation.TL_BR
            setColors(
                intArrayOf(
                    backgroundColor,
                    (backgroundColor and 0x00FFFFFF) or 0x22000000
                )
            )
            setStroke(dpToPx(1), 0x33FFFFFF.toInt())
        }
        button.background = background
        button.elevation = dpToPx(6).toFloat()
        return button
    }

    private fun toggleMenu() {
        if (menuVisible) hideMenu() else showMenu()
    }

    private fun buildMenuItems(): List<MenuItem> {
        val items = listOfNotNull(
            menuCloseButton,
            menuAppButton,
            menuMicButton,
            menuMinimapButton,
            menuWardButton,
        )
        if (items.isEmpty()) return emptyList()

        val spacing = menuButtonPx + dpToPx(6)
        val startY = -((items.size - 1) * spacing) / 2f
        val baseOffset = bubbleSizePx / 2f + menuGapPx + menuButtonPx / 2f
        val direction = if (shouldOpenLeft()) -1f else 1f
        val offsetX = direction * baseOffset

        return items.mapIndexed { index, view ->
            MenuItem(view, offsetX, startY + index * spacing, index)
        }
    }

    private fun shouldOpenLeft(): Boolean {
        val params = overlayParams ?: return false
        val metrics = Resources.getSystem().displayMetrics
        val centerX = params.x + overlaySizePx / 2
        return centerX > metrics.widthPixels / 2
    }

    private fun showMenu() {
        if (menuVisible) return
        menuVisible = true
        val container = menuView ?: return
        val items = buildMenuItems()
        val step = dpToPx(12).toFloat()

        container.visibility = View.VISIBLE
        container.alpha = 1f
        container.scaleX = 1f
        container.scaleY = 1f

        items.forEach { item ->
            item.view.alpha = 0f
            item.view.scaleX = 0.85f
            item.view.scaleY = 0.85f
            item.view.translationX = item.offsetX
            item.view.translationY = item.offsetY - step
        }

        items.forEach { item ->
            item.view.animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .translationY(item.offsetY)
                .setStartDelay((item.index * 60).toLong())
                .setDuration(180)
                .setInterpolator(OvershootInterpolator())
                .start()
        }
    }

    private fun hideMenu() {
        if (!menuVisible) return
        menuVisible = false
        val container = menuView ?: return
        val items = buildMenuItems()
        val step = dpToPx(12).toFloat()
        val delay = if (items.isEmpty()) 0L else (items.size - 1) * 60L

        items.forEach { item ->
            item.view.animate()
                .alpha(0f)
                .scaleX(0.85f)
                .scaleY(0.85f)
                .translationY(item.offsetY - step)
                .setDuration(140)
                .start()
        }

        container.postDelayed({ container.visibility = View.GONE }, delay + 160)
    }

    private fun openApp() {
        hideMenu()
        // Cria intent diretamente para a MainActivity (singleTask garante reutilização)
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        }
        startActivity(intent)
        // Para o overlay ao abrir o app - ele será reiniciado quando o app voltar ao background
        stopSelf()
    }

    private fun toggleMic() {
        if (micListening) {
            stopListening()
        } else {
            startListening()
        }
    }

    private fun startListening() {
        if (speechRecognizer == null) return
        lastTranscript = ""
        awaitingFinal = false
        micListening = true
        updateMicButton(true)

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeTag)
        }
        speechRecognizer?.startListening(intent)
    }

    private fun stopListening() {
        if (speechRecognizer == null) return
        awaitingFinal = true
        micListening = false
        updateMicButton(false)
        speechRecognizer?.stopListening()
    }

    private fun updateMicButton(active: Boolean) {
        val button = menuMicButton ?: return
        button.text = if (active) "STOP" else "MIC"
        updateToggleButtonStyle(button, active)
    }

    private fun sendTurn(text: String) {
        val session = sessionId
        val baseUrl = apiBaseUrl
        if (session.isNullOrBlank() || baseUrl.isNullOrBlank()) {
            return
        }
        Thread {
            try {
                val url = URL(baseUrl.trimEnd('/') + "/turn")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true

                val payload = JSONObject()
                payload.put("session_id", session)
                payload.put("text", text)
                conn.outputStream.use { stream ->
                    stream.write(payload.toString().toByteArray(Charsets.UTF_8))
                }

                if (conn.responseCode in 200..299) {
                    val responseText = BufferedReader(InputStreamReader(conn.inputStream)).use { it.readText() }
                    val json = JSONObject(responseText)
                    val data = json.optJSONObject("data")
                    val reply = data?.optString("reply_text") ?: ""
                    if (reply.isNotBlank()) {
                        speak(reply)
                    }
                }
                conn.disconnect()
            } catch (_: Exception) {
            }
        }.start()
    }

    private fun speak(text: String) {
        if (!ttsReady) return
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "overlay")
    }

    private fun parseLocale(tag: String?): Locale {
        if (tag.isNullOrBlank()) {
            return Locale("pt", "BR")
        }
        val parts = tag.split("-")
        return if (parts.size >= 2) {
            Locale(parts[0], parts[1])
        } else {
            Locale(tag)
        }
    }

    private fun attachDragHandler(
        bubble: View,
        overlay: View,
        params: WindowManager.LayoutParams
    ) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var lastTouchX = 0f
        var lastTouchY = 0f
        var lastTouchNearRemove = false
        var menuWasVisibleOnDown = false
        var isDragging = false
        val touchSlop = ViewConfiguration.get(bubble.context).scaledTouchSlop

        bubble.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    // Guarda o estado do menu ANTES de qualquer modificação
                    menuWasVisibleOnDown = menuVisible
                    isDragging = false
                    snapAnimator?.cancel()
                    bubble.animate().scaleX(0.92f).scaleY(0.92f).setDuration(80).start()
                    showRemoveView()
                    lastTouchNearRemove = false
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    lastTouchX = event.rawX
                    lastTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()

                    // Detecta início de arrasto
                    if (!isDragging && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                        isDragging = true
                        // Esconde o menu ao começar a arrastar
                        hideMenu()
                    }

                    params.x = initialX + dx
                    params.y = initialY + dy
                    clampToScreen(params)
                    val centerX = params.x + overlaySizePx / 2
                    val centerY = params.y + overlaySizePx / 2
                    val near = isTouchNearRemoveZone(centerX, centerY)
                    lastTouchNearRemove = near
                    if (near) applyMagnet(params)
                    windowManager?.updateViewLayout(overlay, params)
                    lastTouchX = event.rawX
                    lastTouchY = event.rawY
                    updateRemoveHighlight(near)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    bubble.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
                    val inRemove = lastTouchNearRemove && isInRemoveZone(params)
                    hideRemoveView()
                    updateRemoveHighlight(false)
                    if (inRemove) {
                        stopSelf()
                        return@setOnTouchListener true
                    }

                    val dx = abs(lastTouchX - initialTouchX)
                    val dy = abs(lastTouchY - initialTouchY)
                    val isClick = dx < touchSlop && dy < touchSlop

                    if (isClick) {
                        // Foi um clique: toggle baseado no estado que o menu tinha quando o toque começou
                        if (menuWasVisibleOnDown) {
                            hideMenu()
                        } else {
                            showMenu()
                        }
                    } else {
                        // Foi arrasto: snap para a borda (menu já foi escondido no ACTION_MOVE)
                        snapToEdge(params)
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    bubble.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
                    hideRemoveView()
                    updateRemoveHighlight(false)
                    lastTouchNearRemove = false
                    isDragging = false
                    true
                }
                else -> false
            }
        }
    }

    private fun clampToScreen(params: WindowManager.LayoutParams) {
        val metrics = Resources.getSystem().displayMetrics
        params.x = max(0, min(params.x, metrics.widthPixels - overlaySizePx))
        params.y = max(0, min(params.y, metrics.heightPixels - overlaySizePx))
    }

    private fun snapToEdge(params: WindowManager.LayoutParams) {
        val metrics = Resources.getSystem().displayMetrics
        val centerX = params.x + overlaySizePx / 2
        val targetX = if (centerX < metrics.widthPixels / 2) 0 else metrics.widthPixels - overlaySizePx
        val startX = params.x
        if (startX == targetX) return
        snapAnimator?.cancel()
        snapAnimator = ValueAnimator.ofInt(startX, targetX).apply {
            duration = 220
            interpolator = OvershootInterpolator()
            addUpdateListener { animator ->
                val value = animator.animatedValue as Int
                params.x = value
                windowManager?.updateViewLayout(overlayView, params)
            }
            start()
        }
    }

    private fun ensureRemoveView() {
        if (removeView != null) return
        val target = FrameLayout(this)
        val background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(0x1AFFFFFF.toInt())
            setStroke(dpToPx(2), 0x44FFFFFF.toInt())
        }
        target.background = background

        val text = TextView(this).apply {
            text = "X"
            setTextColor(0xFFB1B3B8.toInt())
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

        target.addView(
            text,
            FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
        )

        val params = WindowManager.LayoutParams(
            removeSizePx,
            removeSizePx,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        params.y = removeOffsetPx

        val metrics = Resources.getSystem().displayMetrics
        removeTargetX = metrics.widthPixels / 2
        removeTargetY = metrics.heightPixels - removeOffsetPx - removeSizePx / 2

        removeView = target
        removeParams = params
    }

    private fun showRemoveView() {
        ensureRemoveView()
        val target = removeView ?: return
        if (target.parent == null) {
            windowManager?.addView(target, removeParams)
        }
        target.post { updateRemoveTargetFromView(target) }
        val drop = dpToPx(12).toFloat()
        target.alpha = 0f
        target.scaleX = 0.7f
        target.scaleY = 0.7f
        target.translationY = drop
        target.visibility = View.VISIBLE
        target.animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .translationY(0f)
            .setDuration(180)
            .start()
    }

    private fun hideRemoveView() {
        val drop = dpToPx(12).toFloat()
        removeView?.animate()
            ?.alpha(0f)
            ?.scaleX(0.7f)
            ?.scaleY(0.7f)
            ?.translationY(drop)
            ?.setDuration(160)
            ?.withEndAction { removeView?.visibility = View.GONE }
            ?.start()
    }

    private fun updateRemoveHighlight(isOver: Boolean) {
        if (removeHighlighted == isOver) return
        removeHighlighted = isOver
        val target = removeView as? FrameLayout ?: return
        val background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(if (isOver) 0x55FFFFFF.toInt() else 0x2AFFFFFF.toInt())
            setStroke(dpToPx(1), if (isOver) 0xB3FFFFFF.toInt() else 0x66FFFFFF.toInt())
        }
        target.background = background
        target.animate()
            .scaleX(if (isOver) 1.08f else 1f)
            .scaleY(if (isOver) 1.08f else 1f)
            .setDuration(120)
            .start()
    }

    private fun updateRemoveTargetFromView(target: View) {
        val location = IntArray(2)
        target.getLocationOnScreen(location)
        val width = target.width
        val height = target.height
        if (width > 0 && height > 0) {
            removeTargetX = location[0] + width / 2
            removeTargetY = location[1] + height / 2
            return
        }
        val metrics = Resources.getSystem().displayMetrics
        removeTargetX = metrics.widthPixels / 2
        removeTargetY = metrics.heightPixels - removeOffsetPx - removeSizePx / 2
    }

    private fun isInRemoveZone(params: WindowManager.LayoutParams): Boolean {
        val centerX = params.x + overlaySizePx / 2
        val centerY = params.y + overlaySizePx / 2
        val dx = centerX - removeTargetX
        val dy = centerY - removeTargetY
        val radius = removeSizePx / 2
        return dx * dx + dy * dy <= radius * radius
    }

    private fun isTouchNearRemoveZone(centerX: Int, centerY: Int): Boolean {
        val dx = centerX - removeTargetX
        val dy = centerY - removeTargetY
        return dx * dx + dy * dy <= removeMagnetDistance * removeMagnetDistance
    }

    private fun applyMagnet(params: WindowManager.LayoutParams) {
        val targetX = removeTargetX - overlaySizePx / 2
        val targetY = removeTargetY - overlaySizePx / 2
        params.x += ((targetX - params.x) * 0.3f).toInt()
        params.y += ((targetY - params.y) * 0.3f).toInt()
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
            .setContentText("Overlay on")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pending)
            .build()
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "NexusCoach",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun dpToPx(dp: Int): Int {
        val density = Resources.getSystem().displayMetrics.density
        return (dp * density).toInt()
    }
}
