package com.softtech.crm_task_manager

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class IncomingCallOverlayController(
    private val context: Context,
) {
    companion object {
        private const val TAG = "IncomingCallOverlay"
    }

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var overlayView: View? = null

    fun isShowing(): Boolean = overlayView != null

    fun show(
        callerName: String,
        onAnswer: () -> Unit,
        onDecline: () -> Unit,
    ) {
        try {
            val existingView = overlayView
            if (existingView != null) {
                existingView.findViewById<TextView>(R.id.tvCallerName).text = callerName
                return
            }

            val view = LayoutInflater.from(context).inflate(R.layout.activity_incoming_call, null)
            view.findViewById<TextView>(R.id.tvCallerName).text = callerName
            view.findViewById<LinearLayout>(R.id.btnAnswer).setOnClickListener { onAnswer.invoke() }
            view.findViewById<LinearLayout>(R.id.btnDecline).setOnClickListener { onDecline.invoke() }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                overlayWindowType(),
                overlayFlags(),
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    layoutInDisplayCutoutMode =
                        WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }

            windowManager.addView(view, params)
            overlayView = view
            Log.d(TAG, "Incoming call overlay shown")
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to show incoming call overlay: ${error.message}", error)
        }
    }

    fun hide() {
        val view = overlayView ?: return
        overlayView = null

        try {
            windowManager.removeViewImmediate(view)
            Log.d(TAG, "Incoming call overlay hidden")
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to hide incoming call overlay: ${error.message}", error)
        }
    }

    private fun overlayWindowType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun overlayFlags(): Int {
        return WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
    }
}
