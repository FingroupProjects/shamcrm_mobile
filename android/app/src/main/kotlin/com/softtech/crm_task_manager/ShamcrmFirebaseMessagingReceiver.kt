package com.softtech.crm_task_manager

import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver

/**
 * Wakes the native SIP runtime before Flutter's background isolate starts.
 * The superclass still receives every message, preserving all existing CRM
 * notification and Dart background-handler behavior.
 */
class ShamcrmFirebaseMessagingReceiver : FlutterFirebaseMessagingReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val extras = intent.extras
            if (extras != null) {
                val data = extras.keySet().associateWith { key ->
                    extras.get(key)?.toString().orEmpty()
                }
                if (isIncomingCallPush(data)) {
                    val applicationContext = context.applicationContext
                    NativeSipBridge.initialize(applicationContext)
                    NativeSipBridge.recordDiagnosticEvent(
                        event = "push_received",
                        details = hashMapOf(
                            "source" to "android_native_fcm",
                            "call_id" to pick(data, "call_id", "id"),
                            "caller" to pick(
                                data,
                                "remote_identity",
                                "caller",
                                "caller_name",
                                "phone",
                                "lead_name",
                                "from",
                            ),
                            "priority" to
                                (data["google.delivered_priority"] ?: data["google.priority"]),
                            "hasNotificationPayload" to
                                data.keys.any { it.startsWith("gcm.n.") },
                        ),
                    )

                    val serviceStarted = NativeSipForegroundService.start(applicationContext)
                    val registrationRestored =
                        NativeSipBridge.restoreRegistrationIfNeeded(startService = false)
                    NativeSipBridge.recordDiagnosticEvent(
                        event = "push_wake_result",
                        details = hashMapOf(
                            "serviceStarted" to serviceStarted,
                            "registrationRestored" to registrationRestored,
                            "persistentEnabled" to NativeSipBridge.isPersistentEnabled(),
                        ),
                    )
                }
            }
        } catch (error: Throwable) {
            Log.e(TAG, "Native incoming-call push handling failed", error)
            NativeSipBridge.recordDiagnosticEvent(
                event = "push_wake_failed",
                details = hashMapOf("error" to (error.message ?: error.javaClass.simpleName)),
            )
        }

        super.onReceive(context, intent)
    }

    private fun isIncomingCallPush(data: Map<String, String>): Boolean {
        val type = pick(data, "type", "event")?.lowercase()
        return type == "incoming_call" ||
            type == "call_start" ||
            type == "sip_incoming_call"
    }

    private fun pick(data: Map<String, String>, vararg keys: String): String? {
        for (key in keys) {
            val value = data[key]?.trim()
            if (!value.isNullOrEmpty() && !value.equals("null", ignoreCase = true)) {
                return value
            }
        }
        return null
    }

    companion object {
        private const val TAG = "ShamcrmFcmReceiver"
    }
}
