package com.softtech.crm_task_manager

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log

/**
 * Self-managed Telecom account for live SIP calls.
 *
 * Android 14+ treats a phoneCall foreground service as a real call only when
 * Telecom owns a Connection. That keeps the conversation alive if the user
 * swipes shamCRM from recents, and it also exposes Bluetooth in the system
 * volume/route UI the same way WhatsApp does.
 */
object SipTelecom {
    private const val TAG = "SipTelecom"
    private const val ACCOUNT_ID = "shamcrm_sip"
    const val EXTRA_REMOTE_IDENTITY = "com.shamcrm.sip.REMOTE_IDENTITY"
    const val EXTRA_OUTGOING = "com.shamcrm.sip.OUTGOING"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var accountRegistered = false

    @Volatile
    var connection: SipConnection? = null
        private set

    private var pendingRemote: String? = null
    private var pendingOutgoing = false
    private var lastCallState: String = "idle"

    fun phoneAccountHandle(context: Context): PhoneAccountHandle {
        return PhoneAccountHandle(
            ComponentName(context, SipConnectionService::class.java),
            ACCOUNT_ID,
        )
    }

    fun ensureAccount(context: Context) {
        if (accountRegistered) return
        val appContext = context.applicationContext
        try {
            val telecom = telecomManager(appContext) ?: return
            val handle = phoneAccountHandle(appContext)
            val account = PhoneAccount.builder(handle, "shamCRM")
                .setCapabilities(PhoneAccount.CAPABILITY_SELF_MANAGED)
                .setSupportedUriSchemes(
                    listOf(
                        PhoneAccount.SCHEME_TEL,
                        PhoneAccount.SCHEME_SIP,
                    ),
                )
                .setHighlightColor(0xFF1E88E5.toInt())
                .setShortDescription("Телефония shamCRM")
                .build()
            telecom.registerPhoneAccount(account)
            accountRegistered = true
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to register Telecom account: ${error.message}")
        }
    }

    fun syncCallState(context: Context, callState: String, remoteIdentity: String?) {
        mainHandler.post {
            ensureAccount(context)
            lastCallState = callState
            when (callState) {
                // Incoming is registered with Telecom so Android can keep the
                // process alive. Outgoing must NOT call placeCall(): Linphone
                // already owns the SIP session, and a second Telecom call shows
                // "this will end the shamCRM call" / "another call is connecting".
                "incoming" -> startIncoming(context, remoteIdentity)
                "calling", "ringing", "early_media" -> {
                    connection?.applyIdentity(remoteIdentity)
                    connection?.setDialing()
                }
                "in_call" -> {
                    connection?.applyIdentity(remoteIdentity)
                    markActive()
                }
                else -> disconnect(local = false)
            }
        }
    }

    fun attachConnection(created: SipConnection) {
        connection = created
        val remote = pendingRemote
        if (!remote.isNullOrBlank()) {
            created.applyIdentity(remote)
        }
        when (lastCallState) {
            "in_call" -> created.setActive()
            "calling", "ringing", "early_media" -> created.setDialing()
            else -> created.setRinging()
        }
    }

    fun detachConnection(created: SipConnection) {
        if (connection === created) {
            connection = null
        }
        pendingRemote = null
        pendingOutgoing = false
    }

    fun onUserAnsweredFromSystem() {
        NativeSipBridge.acceptCall()
        NativeSipBridge.requestFlutterCallUi("telecom-answer")
    }

    fun onUserRejectedFromSystem() {
        NativeSipBridge.declineCall()
    }

    fun onUserHangupFromSystem() {
        NativeSipBridge.hangup()
    }

    fun onMuteChangedFromSystem(muted: Boolean) {
        NativeSipBridge.setMuted(muted)
    }

    private fun startIncoming(context: Context, remoteIdentity: String?) {
        if (connection != null) {
            connection?.applyIdentity(remoteIdentity)
            connection?.setRinging()
            return
        }
        if (!pendingOutgoing && pendingRemote != null) {
            // addNewIncomingCall is already in flight.
            pendingRemote = remoteIdentity ?: pendingRemote
            return
        }
        pendingRemote = remoteIdentity
        pendingOutgoing = false
        addIncomingCall(context, remoteIdentity)
    }

    private fun markActive() {
        val current = connection
        if (current == null) {
            return
        }
        current.setActive()
    }

    private fun disconnect(local: Boolean) {
        lastCallState = "idle"
        val current = connection ?: return
        connection = null
        pendingRemote = null
        pendingOutgoing = false
        try {
            current.setDisconnected(
                android.telecom.DisconnectCause(
                    if (local) {
                        android.telecom.DisconnectCause.LOCAL
                    } else {
                        android.telecom.DisconnectCause.REMOTE
                    },
                ),
            )
            current.destroy()
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to disconnect Telecom call: ${error.message}")
        }
    }

    private fun addIncomingCall(context: Context, remoteIdentity: String?) {
        val appContext = context.applicationContext
        val telecom = telecomManager(appContext) ?: return
        try {
            val extras = Bundle().apply {
                putString(EXTRA_REMOTE_IDENTITY, remoteIdentity)
                putBoolean(EXTRA_OUTGOING, false)
                putParcelable(
                    TelecomManager.EXTRA_INCOMING_CALL_ADDRESS,
                    callUri(remoteIdentity),
                )
            }
            telecom.addNewIncomingCall(phoneAccountHandle(appContext), extras)
        } catch (error: Throwable) {
            Log.w(TAG, "addNewIncomingCall failed: ${error.message}")
        }
    }

    fun callUri(remoteIdentity: String?): Uri {
        val normalized = remoteIdentity
            ?.trim()
            ?.removePrefix("sip:")
            ?.substringBefore("@")
            ?.trim()
            .orEmpty()
        val value = if (normalized.isEmpty()) "unknown" else normalized
        val digitsOnly = normalized.all { it.isDigit() || it == '+' }
        return if (digitsOnly && normalized.isNotEmpty()) {
            Uri.fromParts(PhoneAccount.SCHEME_TEL, value, null)
        } else {
            Uri.fromParts(PhoneAccount.SCHEME_SIP, value, null)
        }
    }

    private fun telecomManager(context: Context): TelecomManager? {
        return context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
    }
}
