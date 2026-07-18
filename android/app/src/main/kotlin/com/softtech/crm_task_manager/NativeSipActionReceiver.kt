package com.softtech.crm_task_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NativeSipActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_ANSWER = "com.shamcrm.native_sip.ANSWER"
        const val ACTION_DECLINE = "com.shamcrm.native_sip.DECLINE"
        const val ACTION_HANGUP = "com.shamcrm.native_sip.HANGUP"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        NativeSipBridge.initialize(context.applicationContext)

        when (intent?.action) {
            ACTION_ANSWER -> {
                val accepted = NativeSipBridge.acceptCall()
                NativeSipBridge.recordDiagnosticEvent(
                    event = if (accepted) "incoming_answered" else "incoming_answer_failed",
                    details = hashMapOf("source" to "notification-action"),
                )
                if (accepted) {
                    try {
                        context.startActivity(
                            Intent(context, MainActivity::class.java).apply {
                                addFlags(
                                    Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                                )
                                putExtra("open_sip_call", true)
                            },
                        )
                    } catch (error: Throwable) {
                        NativeSipBridge.recordDiagnosticEvent(
                            event = "incoming_call_ui_open_failed",
                            details = hashMapOf(
                                "source" to "notification-action",
                                "error" to (error.message ?: error.javaClass.simpleName),
                            ),
                        )
                    }
                }
            }
            ACTION_DECLINE -> NativeSipBridge.declineCall()
            ACTION_HANGUP -> NativeSipBridge.hangup()
        }
    }
}
