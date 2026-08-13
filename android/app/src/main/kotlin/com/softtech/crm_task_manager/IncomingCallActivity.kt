package com.softtech.crm_task_manager

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class IncomingCallActivity : Activity() {

    companion object {
        private const val TAG = "IncomingCallActivity"
        const val EXTRA_CALLER_NAME = "caller_name"
        @Volatile
        private var visible = false

        fun isVisible(): Boolean = visible
    }

    private var closingRequested = false
    private var flutterCallUiOpened = false

    private val bridgeObserver: (HashMap<String, Any?>) -> Unit = { event ->
        runOnUiThread {
            if (event["type"]?.toString() == "call") {
                val state = event["state"]?.toString()
                when (state) {
                    "incoming" -> {
                        Log.d(TAG, "Call is still incoming, keep full-screen UI visible")
                    }
                    "calling", "ringing", "in_call" -> {
                        Log.d(TAG, "Call state changed to $state, opening in-call Flutter UI")
                        openFlutterCallUi()
                        requestClose("call-state-$state")
                    }
                    "ended", "failed", "idle", "disconnected", null -> {
                        Log.d(TAG, "Call state changed to $state, closing IncomingCallActivity")
                        requestClose("call-state-$state")
                    }
                    else -> {
                        Log.d(TAG, "Call state changed to $state, keeping activity until resolved")
                    }
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "onCreate IncomingCallActivity, caller=${intent.getStringExtra(EXTRA_CALLER_NAME)}")

        // Пробуждение экрана и показ поверх блокировки
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }

        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_incoming_call)

        val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Неизвестный номер"
        findViewById<TextView>(R.id.tvCallerName).text = callerName

        findViewById<LinearLayout>(R.id.btnAnswer).setOnClickListener {
            Log.d(TAG, "User accepted call via Native UI")
            if (NativeSipBridge.acceptCall()) {
                openFlutterCallUi()
                requestClose("user-accepted")
            } else {
                Log.w(TAG, "Native acceptCall returned false, keeping incoming UI open")
                NativeSipBridge.recordDiagnosticEvent(
                    event = "incoming_answer_failed",
                    details = hashMapOf("source" to "incoming-activity"),
                )
                Toast.makeText(
                    this,
                    "Подключение звонка ещё не готово. Попробуйте ещё раз.",
                    Toast.LENGTH_SHORT,
                ).show()
            }
        }

        findViewById<LinearLayout>(R.id.btnDecline).setOnClickListener {
            Log.d(TAG, "User declined call via Native UI")
            NativeSipBridge.declineCall()
            requestClose("user-declined")
        }

        NativeSipBridge.addObserver(bridgeObserver)
        val snapshot = NativeSipBridge.getStateSnapshot()
        Log.d(TAG, "Initial bridge snapshot in IncomingCallActivity: $snapshot")
        val callState = snapshot["callState"]?.toString()
        if (callState != "incoming") {
            Log.d(TAG, "IncomingCallActivity opened without incoming call, closing. state=$callState")
            requestClose("stale-launch-$callState")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Неизвестный номер"
        findViewById<TextView>(R.id.tvCallerName).text = callerName
        Log.d(TAG, "onNewIntent IncomingCallActivity, caller=$callerName")
    }

    override fun onStart() {
        super.onStart()
        visible = true
        Log.d(TAG, "onStart IncomingCallActivity")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume IncomingCallActivity")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy IncomingCallActivity")
        visible = false
        super.onDestroy()
        NativeSipBridge.removeObserver(bridgeObserver)
    }

    override fun onStop() {
        visible = false
        super.onStop()
    }
    
    // Блокируем кнопку назад
    override fun onBackPressed() {
        // Ничего не делаем, чтобы нельзя было случайно закрыть вызов
    }

    private fun openFlutterCallUi() {
        if (flutterCallUiOpened) {
            Log.d(TAG, "Flutter call UI already opened, skip duplicate launch")
            return
        }
        flutterCallUiOpened = true
        val flutterIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
            putExtra("open_sip_call", true)
        }
        startActivity(flutterIntent)
    }

    private fun requestClose(reason: String) {
        if (closingRequested || isFinishing) {
            Log.d(TAG, "IncomingCallActivity close already requested, skip duplicate finish. reason=$reason")
            return
        }
        closingRequested = true
        Log.d(TAG, "Closing IncomingCallActivity, reason=$reason")
        finishAndRemoveTask()
    }
}
