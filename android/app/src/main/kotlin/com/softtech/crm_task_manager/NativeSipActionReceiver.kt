package com.softtech.crm_task_manager

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class NativeSipActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_ANSWER = "com.shamcrm.native_sip.ANSWER"
        const val ACTION_DECLINE = "com.shamcrm.native_sip.DECLINE"
        const val ACTION_HANGUP = "com.shamcrm.native_sip.HANGUP"
        const val ACTION_TOGGLE_MUTE = "com.shamcrm.native_sip.TOGGLE_MUTE"
        const val ACTION_TOGGLE_SPEAKER = "com.shamcrm.native_sip.TOGGLE_SPEAKER"
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
                        val activityIntent = Intent(context, MainActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                            )
                            putExtra("open_sip_call", true)
                            putExtra("sip_notification_action", "answer")
                        }
                        val options = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            ActivityOptions.makeBasic()
                                .setPendingIntentCreatorBackgroundActivityStartMode(
                                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                                )
                                .toBundle()
                        } else null
                        val pendingIntent = PendingIntent.getActivity(
                            context,
                            1007,
                            activityIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                            options,
                        )
                        try {
                            pendingIntent.send()
                        } catch (_: Throwable) {
                            context.startActivity(activityIntent)
                        }
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
            // Hang up from the red icon in the live-call notification.
            ACTION_HANGUP -> NativeSipBridge.hangup()
            // Mic icon: mute if live, unmute if already muted.
            ACTION_TOGGLE_MUTE -> NativeSipBridge.toggleMuted()
            // Speaker icon: loud speaker or earpiece.
            ACTION_TOGGLE_SPEAKER -> NativeSipBridge.toggleSpeaker()
        }
    }
}
