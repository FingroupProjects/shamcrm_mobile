package com.softtech.crm_task_manager

import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log

class SipConnectionService : ConnectionService() {
    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ): Connection {
        val remote = request?.extras?.getString(SipTelecom.EXTRA_REMOTE_IDENTITY)
            ?: request?.address?.schemeSpecificPart
        val connection = SipConnection(remote, outgoing = false)
        SipTelecom.attachConnection(connection)
        return connection
    }

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ): Connection {
        val remote = request?.extras?.getString(SipTelecom.EXTRA_REMOTE_IDENTITY)
            ?: request?.address?.schemeSpecificPart
        val connection = SipConnection(remote, outgoing = true)
        SipTelecom.attachConnection(connection)
        return connection
    }

    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        Log.w(TAG, "Incoming Telecom connection failed")
    }

    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        Log.w(TAG, "Outgoing Telecom connection failed")
    }

    companion object {
        private const val TAG = "SipConnectionService"
    }
}

class SipConnection(
    remoteIdentity: String?,
    private val outgoing: Boolean,
) : Connection() {
    init {
        connectionProperties = PROPERTY_SELF_MANAGED
        // Hold is not implemented. Mute is enough for the system call UI.
        connectionCapabilities = CAPABILITY_MUTE
        audioModeIsVoip = true
        applyIdentity(remoteIdentity)
        setExtras(
            android.os.Bundle().apply {
                putBoolean(SipTelecom.EXTRA_OUTGOING, outgoing)
            },
        )
    }

    fun applyIdentity(remoteIdentity: String?) {
        val address = SipTelecom.callUri(remoteIdentity)
        val display = remoteIdentity
            ?.trim()
            ?.removePrefix("sip:")
            ?.substringBefore("@")
            ?.trim()
            .orEmpty()
            .ifEmpty { "shamCRM" }
        setAddress(address, TelecomManager.PRESENTATION_ALLOWED)
        setCallerDisplayName(display, TelecomManager.PRESENTATION_ALLOWED)
    }

    override fun onShowIncomingCallUi() {
        // Incoming UI stays in NativeSipForegroundService / IncomingCallActivity.
    }

    override fun onAnswer() {
        SipTelecom.onUserAnsweredFromSystem()
        setActive()
    }

    override fun onReject() {
        SipTelecom.onUserRejectedFromSystem()
        setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
        destroy()
        SipTelecom.detachConnection(this)
    }

    override fun onDisconnect() {
        val owned = SipTelecom.connection === this
        SipTelecom.detachConnection(this)
        if (owned) {
            SipTelecom.onUserHangupFromSystem()
        }
        try {
            setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            destroy()
        } catch (_: Throwable) {
        }
    }

    override fun onAbort() {
        onDisconnect()
    }

    override fun onHold() {
        // SIP hold is not implemented. Keep the connection active so the
        // system does not drop audio when the user opens another app.
        setActive()
    }

    override fun onUnhold() {
        setActive()
    }

    override fun onMuteStateChanged(isMuted: Boolean) {
        SipTelecom.onMuteChangedFromSystem(isMuted)
    }

    override fun onCallAudioStateChanged(state: android.telecom.CallAudioState?) {
        super.onCallAudioStateChanged(state)
        // Telecom now owns Bluetooth/earpiece/speaker. Linphone is synced
        // from NativeSipManager when the audio device list updates.
    }
}
