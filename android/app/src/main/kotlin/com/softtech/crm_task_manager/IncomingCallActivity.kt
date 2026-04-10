package com.softtech.crm_task_manager

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class IncomingCallActivity : Activity() {

    companion object {
        private const val TAG = "IncomingCallActivity"
        const val EXTRA_CALLER_NAME = "caller_name"
    }

    private val bridgeObserver: (HashMap<String, Any?>) -> Unit = { event ->
        runOnUiThread {
            if (event["type"]?.toString() == "call") {
                val state = event["state"]?.toString()
                if (state != "incoming") {
                    // Звонок больше не входящий (возможно, собеседник сбросил)
                    Log.d(TAG, "Call state changed to $state, closing IncomingCallActivity")
                    finishAndRemoveTask()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "onCreate IncomingCallActivity")

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

        setContentView(R.layout.activity_incoming_call)

        val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Неизвестный номер"
        findViewById<TextView>(R.id.tvCallerName).text = callerName

        findViewById<LinearLayout>(R.id.btnAnswer).setOnClickListener {
            Log.d(TAG, "User accepted call via Native UI")
            NativeSipBridge.acceptCall()
            
            // Запускаем Flutter визуализацию
            val flutterIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("open_sip_call", true)
            }
            startActivity(flutterIntent)
            finishAndRemoveTask()
        }

        findViewById<LinearLayout>(R.id.btnDecline).setOnClickListener {
            Log.d(TAG, "User declined call via Native UI")
            NativeSipBridge.declineCall()
            finishAndRemoveTask()
        }

        NativeSipBridge.addObserver(bridgeObserver)
        
        // Дополнительная проверка, если State уже не incoming (гонка состояний)
        val snapshot = NativeSipBridge.getStateSnapshot()
        if (snapshot["callState"]?.toString() != "incoming") {
            Log.d(TAG, "Call is no longer incoming on create, closing")
            finishAndRemoveTask()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        NativeSipBridge.removeObserver(bridgeObserver)
    }
    
    // Блокируем кнопку назад
    override fun onBackPressed() {
        // Ничего не делаем, чтобы нельзя было случайно закрыть вызов
    }
}
