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
                if (ChatQuickReplyManager.isChatMessagePush(data)) {
                    ChatQuickReplyManager.showNotification(context, data)
                    return
                }
                if (isIncomingCallPush(data)) {
                    val applicationContext = context.applicationContext
                    NativeSipBridge.initialize(applicationContext)
                    if (!NativeSipBridge.isPersistentEnabled()) {
                        NativeSipBridge.recordDiagnosticEvent(
                            event = "push_wake_skipped_not_enabled",
                            details = hashMapOf(
                                "source" to "android_native_fcm",
                                "call_id" to pick(data, "call_id", "id"),
                            ),
                        )
                        super.onReceive(context, intent)
                        return
                    }
                    if (isExpiredIncomingCallPush(data)) {
                        NativeSipBridge.recordDiagnosticEvent(
                            event = "push_received_expired",
                            details = hashMapOf(
                                "source" to "android_native_fcm",
                                "call_id" to pick(data, "call_id", "id"),
                                "issued_at_ms" to incomingPushIssuedAtMs(data),
                                "max_age_ms" to MAXIMUM_INCOMING_PUSH_AGE_MS,
                            ),
                        )
                        // Regular CRM delivery remains owned by the superclass.
                        super.onReceive(context, intent)
                        return
                    }
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

    private fun isExpiredIncomingCallPush(data: Map<String, String>): Boolean {
        val issuedAtMs = incomingPushIssuedAtMs(data) ?: return false
        return System.currentTimeMillis() - issuedAtMs > MAXIMUM_INCOMING_PUSH_AGE_MS
    }

    private fun incomingPushIssuedAtMs(data: Map<String, String>): Long? {
        val raw = pick(
            data,
            "call_started_at_ms", "created_at_ms", "sent_at_ms", "issued_at_ms", "timestamp_ms",
            "call_started_at", "created_at", "sent_at", "issued_at", "timestamp",
            "google.sent_time",
        )?.toLongOrNull() ?: return null
        return if (raw in 1..9_999_999_999L) raw * 1000 else raw
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
        private const val MAXIMUM_INCOMING_PUSH_AGE_MS = 2 * 60 * 1000L
    }
}
