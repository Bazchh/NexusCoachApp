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
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class OverlayService : Service() {
    companion object {
        const val ACTION_START = "com.nexuscoach.nexuscoach.START_OVERLAY"
        const val ACTION_STOP = "com.nexuscoach.nexuscoach.STOP_OVERLAY"

        private const val CHANNEL_ID = "nexuscoach_overlay"
        private const val NOTIFICATION_ID = 2201
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var menuView: View? = null
    private var menuCloseButton: View? = null
    private var menuAppButton: View? = null
    private var removeView: View? = null
    private var removeParams: WindowManager.LayoutParams? = null
    private var bubbleSizePx = 0
    private var menuButtonPx = 0
    private var menuGapPx = 0
    private var overlaySizePx = 0
    private var removeSizePx = 0
    private var removeOffsetPx = 0
    private var removeMagnetDistance = 0
    private var removeHighlighted = false
    private var menuVisible = false
    private var snapAnimator: ValueAnimator? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> showOverlay()
            ACTION_STOP -> stopSelf()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    private fun showOverlay() {
        if (overlayView != null) return
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        bubbleSizePx = dpToPx(56)
        menuButtonPx = dpToPx(40)
        menuGapPx = dpToPx(10)
        overlaySizePx = bubbleSizePx + 2 * (menuButtonPx + menuGapPx)
        removeSizePx = dpToPx(72)
        removeOffsetPx = dpToPx(96)
        removeMagnetDistance = removeSizePx / 2 + dpToPx(32)

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

        bubble.setOnClickListener { toggleMenu() }
        return bubble
    }

    private fun buildMenu(): View {
        val container = FrameLayout(this).apply {
            visibility = View.GONE
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(16).toFloat()
                setColor(0x22111115.toInt())
            }
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

        container.addView(
            closeButton,
            FrameLayout.LayoutParams(menuButtonPx, menuButtonPx, Gravity.TOP or Gravity.CENTER_HORIZONTAL).apply {
                topMargin = menuGapPx
            }
        )

        container.addView(
            appButton,
            FrameLayout.LayoutParams(menuButtonPx, menuButtonPx, Gravity.CENTER_VERTICAL or Gravity.END).apply {
                rightMargin = menuGapPx
            }
        )

        menuCloseButton = closeButton
        menuAppButton = appButton
        return container
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

    private fun showMenu() {
        if (menuVisible) return
        menuVisible = true
        val container = menuView ?: return
        val closeButton = menuCloseButton
        val appButton = menuAppButton
        val closeOffset = overlaySizePx / 2f - (menuGapPx + menuButtonPx / 2f)
        val appOffset = overlaySizePx / 2f - (overlaySizePx - menuGapPx - menuButtonPx / 2f)

        container.visibility = View.VISIBLE
        container.alpha = 0f
        container.scaleX = 0.9f
        container.scaleY = 0.9f

        closeButton?.translationY = closeOffset
        appButton?.translationX = appOffset

        container.animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(160)
            .start()

        closeButton?.animate()?.translationY(0f)?.setDuration(200)?.setInterpolator(OvershootInterpolator())?.start()
        appButton?.animate()?.translationX(0f)?.setDuration(200)?.setInterpolator(OvershootInterpolator())?.start()
    }

    private fun hideMenu() {
        if (!menuVisible) return
        menuVisible = false
        val container = menuView ?: return
        val closeButton = menuCloseButton
        val appButton = menuAppButton
        val closeOffset = overlaySizePx / 2f - (menuGapPx + menuButtonPx / 2f)
        val appOffset = overlaySizePx / 2f - (overlaySizePx - menuGapPx - menuButtonPx / 2f)

        closeButton?.animate()?.translationY(closeOffset)?.setDuration(120)?.start()
        appButton?.animate()?.translationX(appOffset)?.setDuration(120)?.start()

        container.animate()
            .alpha(0f)
            .scaleX(0.9f)
            .scaleY(0.9f)
            .setDuration(140)
            .withEndAction { container.visibility = View.GONE }
            .start()
    }

    private fun openApp() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (launchIntent != null) startActivity(launchIntent)
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

        bubble.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    hideMenu()
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
                    val isClick = abs(lastTouchX - initialTouchX) < 10 && abs(lastTouchY - initialTouchY) < 10
                    if (isClick) {
                        bubble.performClick()
                    } else {
                        snapToEdge(params)
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    bubble.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
                    hideRemoveView()
                    updateRemoveHighlight(false)
                    lastTouchNearRemove = false
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

        removeView = target
        removeParams = params
    }

    private fun showRemoveView() {
        ensureRemoveView()
        val target = removeView ?: return
        if (target.parent == null) {
            windowManager?.addView(target, removeParams)
        }
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

    private fun isInRemoveZone(params: WindowManager.LayoutParams): Boolean {
        val metrics = Resources.getSystem().displayMetrics
        val centerX = params.x + overlaySizePx / 2
        val centerY = params.y + overlaySizePx / 2
        val targetX = metrics.widthPixels / 2
        val targetY = metrics.heightPixels - removeOffsetPx - removeSizePx / 2
        val dx = centerX - targetX
        val dy = centerY - targetY
        val radius = removeSizePx / 2
        return dx * dx + dy * dy <= radius * radius
    }

    private fun isTouchNearRemoveZone(centerX: Int, centerY: Int): Boolean {
        val metrics = Resources.getSystem().displayMetrics
        val targetX = metrics.widthPixels / 2
        val targetY = metrics.heightPixels - removeOffsetPx - removeSizePx / 2
        val dx = centerX - targetX
        val dy = centerY - targetY
        return dx * dx + dy * dy <= removeMagnetDistance * removeMagnetDistance
    }

    private fun applyMagnet(params: WindowManager.LayoutParams) {
        val metrics = Resources.getSystem().displayMetrics
        val targetX = metrics.widthPixels / 2 - overlaySizePx / 2
        val targetY = metrics.heightPixels - removeOffsetPx - overlaySizePx / 2
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
