package com.softtech.crm_task_manager

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.linphone.core.Account
import org.linphone.core.AccountParams
import org.linphone.core.AVPFMode
import org.linphone.core.Call
import org.linphone.core.CallParams
import org.linphone.core.Core
import org.linphone.core.CoreListenerStub
import org.linphone.core.Factory
import org.linphone.core.MediaEncryption
import org.linphone.core.Reason
import org.linphone.core.RegistrationState
import org.linphone.core.TransportType

class NativeSipManager(
    private val context: Context,
) {
    companion object {
        private const val TAG = "NativeSipManager"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventListener: ((HashMap<String, Any?>) -> Unit)? = null
    private var core: Core? = null
    private var coreListener: CoreListenerStub? = null
    private var currentAccount: Account? = null
    private var currentCall: Call? = null
    private var isSpeakerOn = false
    private var currentDomain: String = ""
    private var desiredRegistrationEnabled = false
    private var lastCallState: String = "idle"

    fun setEventListener(listener: ((HashMap<String, Any?>) -> Unit)?) {
        eventListener = listener
    }

    fun initialize(): Boolean {
        ensureCore()
        emit(
            type = "native",
            payload = hashMapOf(
                "state" to "ready",
            ),
        )
        return true
    }

    fun register(
        server: String,
        login: String,
        password: String,
        port: Int,
        transport: String,
        authUser: String?,
    ): Boolean {
        return try {
            Log.d(
                TAG,
                "register start: server=$server, login=$login, port=$port, transport=$transport, authUser=$authUser",
            )
            val sipCore = ensureCore()
            val factory = Factory.instance()
            val trimmedServer = server.trim()
            val trimmedLogin = login.trim()
            val trimmedAuthUser = authUser?.trim().takeUnless { it.isNullOrEmpty() } ?: trimmedLogin
            val transportType = resolveTransport(transport)

            currentDomain = trimmedServer
            currentCall = null
            currentAccount = null
            isSpeakerOn = false
            desiredRegistrationEnabled = true
            markNetworkReachable(sipCore)

            sipCore.clearAccounts()
            sipCore.clearAllAuthInfo()

            val identity = requireNotNull(
                factory.createAddress("sip:$trimmedLogin@$trimmedServer"),
            ) { "Failed to create identity address" }
            identity.setTransport(transportType)
            identity.setPort(port)

            val serverAddress = requireNotNull(
                factory.createAddress("sip:$trimmedServer"),
            ) { "Failed to create server address" }
            serverAddress.setTransport(transportType)
            serverAddress.setPort(port)

            val accountParams: AccountParams = sipCore.createAccountParams()
            accountParams.setIdentityAddress(identity)
            accountParams.setServerAddress(serverAddress)
            accountParams.setRegisterEnabled(true)
            accountParams.setTransport(transportType)
            accountParams.setOutboundProxyEnabled(true)
            accountParams.setAvpfMode(AVPFMode.Disabled)
            accountParams.setAvpfRrInterval(0)
            accountParams.setExpires(300)
            accountParams.setPublishEnabled(false)
            accountParams.setPushNotificationAllowed(false)
            accountParams.setRemotePushNotificationAllowed(false)
            accountParams.setQualityReportingEnabled(false)

            val authInfo = factory.createAuthInfo(
                trimmedAuthUser,
                null,
                password,
                null,
                null,
                trimmedServer,
            )
            sipCore.addAuthInfo(authInfo)

            val account = sipCore.createAccount(accountParams)
            sipCore.addAccount(account)
            sipCore.setDefaultAccount(account)
            currentAccount = account

            emitRegistration("registering", "Подключение телефонии")
            sipCore.start()
            Log.d(TAG, "register invoked core.start()")
            true
        } catch (error: Throwable) {
            Log.e(TAG, "register failed: ${error.message}", error)
            emitRegistration("failed", error.message ?: "Не удалось подключить телефонию")
            false
        }
    }

    fun unregister() {
        desiredRegistrationEnabled = false
        try {
            currentCall?.terminate()
        } catch (_: Throwable) {
        }

        currentCall = null
        isSpeakerOn = false
        lastCallState = "ended"

        try {
            core?.clearAccounts()
            core?.clearAllAuthInfo()
        } catch (_: Throwable) {
        }

        emitRegistration("disconnected", "Телефония отключена")
        emitCallState("ended", null, "Call ended")
    }

    fun maintainRegistration(reason: String): Boolean {
        val sipCore = core ?: return false
        if (!desiredRegistrationEnabled) {
            Log.d(TAG, "maintainRegistration skipped: desiredRegistrationEnabled=false, reason=$reason")
            return false
        }

        return try {
            markNetworkReachable(sipCore)
            sipCore.refreshRegisters()
            Log.d(TAG, "maintainRegistration: core.refreshRegisters(), reason=$reason")
            true
        } catch (error: Throwable) {
            Log.e(TAG, "maintainRegistration failed: ${error.message}, reason=$reason", error)
            false
        }
    }

    fun makeCall(target: String): Boolean {
        return try {
            val sipCore = ensureCore()
            val address = requireNotNull(sipCore.createAddress(target)) {
                "Invalid call target"
            }
            val params: CallParams = requireNotNull(sipCore.createCallParams(null)) {
                "Failed to create call params"
            }
            params.setAudioEnabled(true)
            params.setVideoEnabled(false)
            params.setAvpfEnabled(false)
            params.setCapabilityNegotiationsEnabled(false)
            params.setCapabilityNegotiationReinviteEnabled(false)
            params.setEarlyMediaSendingEnabled(false)
            params.setMicEnabled(true)
            params.setMediaEncryption(MediaEncryption.None)

            val call = sipCore.inviteAddressWithParams(address, params)
            currentCall = call

            if (call == null) {
                emitCallState("failed", target, "Не удалось начать звонок через телефонию")
                false
            } else {
                emitCallState("calling", remoteIdentityFor(call), "Звонок начат")
                true
            }
        } catch (error: Throwable) {
            Log.e(TAG, "makeCall failed: ${error.message}", error)
            emitCallState("failed", target, error.message ?: "Не удалось выполнить звонок")
            false
        }
    }

    fun acceptCall(): Boolean {
        val call = currentCall ?: return false
        return try {
            val params = requireNotNull(core?.createCallParams(call)) {
                "Failed to create accept params"
            }
            params.setAudioEnabled(true)
            params.setVideoEnabled(false)
            params.setAvpfEnabled(false)
            params.setCapabilityNegotiationsEnabled(false)
            params.setCapabilityNegotiationReinviteEnabled(false)
            params.setEarlyMediaSendingEnabled(false)
            params.setMicEnabled(true)
            params.setMediaEncryption(MediaEncryption.None)
            call.acceptWithParams(params)
            currentCall = call
            lastCallState = "in_call"
            emitCallState(
                state = "in_call",
                remoteIdentity = remoteIdentityFor(call),
                message = "Call accepted",
                muted = call.getMicrophoneMuted(),
                speakerOn = isSpeakerOn,
            )
            true
        } catch (error: Throwable) {
            Log.e(TAG, "acceptCall failed: ${error.message}", error)
            emitCallState("failed", remoteIdentityFor(call), error.message ?: "Accept call failed")
            false
        }
    }

    fun declineCall(): Boolean {
        val call = currentCall ?: return false
        return try {
            call.decline(Reason.Declined)
            true
        } catch (error: Throwable) {
            Log.e(TAG, "declineCall failed: ${error.message}", error)
            false
        }
    }

    fun hangup(): Boolean {
        val call = currentCall
        if (call == null) {
            val hasVisibleCall = lastCallState == "incoming" ||
                lastCallState == "calling" ||
                lastCallState == "ringing" ||
                lastCallState == "in_call"
            if (!hasVisibleCall) return false

            isSpeakerOn = false
            lastCallState = "ended"
            emitCallState("ended", null, "Call ended locally")
            return true
        }

        return try {
            val remoteIdentity = remoteIdentityFor(call)
            call.terminate()
            // Do not leave the UI waiting for the PBX to echo End/Released.
            currentCall = null
            isSpeakerOn = false
            lastCallState = "ended"
            emitCallState("ended", remoteIdentity, "Call ended locally")
            true
        } catch (error: Throwable) {
            Log.e(TAG, "hangup failed: ${error.message}", error)
            false
        }
    }

    fun setMuted(muted: Boolean): Boolean {
        val call = currentCall ?: return false
        return try {
            call.setMicrophoneMuted(muted)
            emitCallState(
                state = mapCallState(call.getState().toString()),
                remoteIdentity = remoteIdentityFor(call),
                message = "Mute changed",
                muted = muted,
                speakerOn = isSpeakerOn,
            )
            true
        } catch (error: Throwable) {
            Log.e(TAG, "setMuted failed: ${error.message}", error)
            false
        }
    }

    fun sendDtmf(tone: String): Boolean {
        val normalized = tone.trim().uppercase()
        if (normalized.length != 1 || normalized[0] !in "0123456789*#ABCD") {
            Log.w(TAG, "sendDtmf ignored invalid tone=$tone")
            return false
        }

        val call = currentCall ?: return false
        if (lastCallState != "in_call") return false

        return try {
            val status = call.sendDtmf(normalized[0])
            Log.d(TAG, "sendDtmf tone=$normalized status=$status")
            status == 0
        } catch (error: Throwable) {
            Log.e(TAG, "sendDtmf failed: ${error.message}", error)
            false
        }
    }

    fun setSpeaker(enabled: Boolean): Boolean {
        isSpeakerOn = enabled
        val sipCore = core
        if (sipCore == null) {
            emitCallState(
                state = lastCallState,
                remoteIdentity = remoteIdentityFor(currentCall),
                message = "Speaker preference updated",
                muted = currentCall?.getMicrophoneMuted() ?: false,
                speakerOn = isSpeakerOn,
            )
            return true
        }
        return try {
            val desired = preferredAudioDevice(sipCore, speakerEnabled = enabled)

            if (desired != null) {
                sipCore.setOutputAudioDevice(desired)
                emitAudioRouteState(
                    state = "audio_device_selected",
                    reason = if (enabled) "speaker_enabled" else "speaker_disabled",
                    deviceType = audioDeviceTypeName(desired),
                )
                emitCallState(
                    state = mapCallState(currentCall?.getState()?.toString()),
                    remoteIdentity = remoteIdentityFor(currentCall),
                    message = "Speaker changed",
                    muted = currentCall?.getMicrophoneMuted() ?: false,
                    speakerOn = isSpeakerOn,
                )
                true
            } else {
                emitCallState(
                    state = mapCallState(currentCall?.getState()?.toString()),
                    remoteIdentity = remoteIdentityFor(currentCall),
                    message = "Speaker preference updated",
                    muted = currentCall?.getMicrophoneMuted() ?: false,
                    speakerOn = isSpeakerOn,
                )
                true
            }
        } catch (error: Throwable) {
            Log.e(TAG, "setSpeaker failed: ${error.message}", error)
            false
        }
    }

    fun dispose() {
        desiredRegistrationEnabled = false
        try {
            currentCall?.terminate()
        } catch (_: Throwable) {
        }

        try {
            currentAccount = null
            currentCall = null
            coreListener?.let { listener ->
                core?.removeListener(listener)
            }
            coreListener = null
            core?.stop()
            core = null
        } catch (_: Throwable) {
        }
    }

    fun onAppForeground() {
        try {
            core?.let { sipCore ->
                markNetworkReachable(sipCore)
                sipCore.enterForeground()
                if (desiredRegistrationEnabled) {
                    sipCore.ensureRegistered()
                    Log.d(TAG, "onAppForeground: core.ensureRegistered()")
                }
            }
        } catch (_: Throwable) {
        }
    }

    fun onAppBackground() {
        // Намеренно NO-OP: у нас всегда работает ForegroundService который держит
        // Linphone живым. Вызов core.enterBackground() уменьшает частоту iterate()
        // (обработки SIP-пакетов) — это может привести к пропуску входящих INVITE.
        // ForegroundService И ЕСТЬ наш "foreground контекст" для Linphone.
        // core?.enterBackground()  ← УБРАНО намеренно
    }

    private fun ensureCore(): Core {
        core?.let { return it }

        val factory = Factory.instance()
        val createdCore = factory.createCore(null, null, context)
        createdCore.setAutoIterateEnabled(true)
        createdCore.setKeepAliveEnabled(true)
        createdCore.setRegisterOnlyWhenNetworkIsUp(true)
        createdCore.setMediaEncryption(MediaEncryption.None)
        createdCore.setMediaEncryptionMandatory(false)
        createdCore.setNativeRingingEnabled(false)
        // Incoming ringtone is owned by NativeSipForegroundService.
        // Keeping Linphone ringing enabled creates a second simultaneous melody.
        createdCore.disableCallRinging(true)
        markNetworkReachable(createdCore)

        val natPolicy = createdCore.createNatPolicy()
        natPolicy.setIceEnabled(false)
        natPolicy.setStunEnabled(false)
        natPolicy.setTurnEnabled(false)
        natPolicy.setUpnpEnabled(false)
        createdCore.setNatPolicy(natPolicy)

        val listener = object : CoreListenerStub() {
            override fun onAccountRegistrationStateChanged(
                core: Core,
                account: Account,
                state: RegistrationState,
                message: String,
            ) {
                val rawState = state.toString()
                val mappedState = when {
                    rawState == "Cleared" && desiredRegistrationEnabled -> "registering"
                    else -> mapRegistrationState(rawState)
                }
                val effectiveMessage = when {
                    rawState == "Cleared" && desiredRegistrationEnabled -> "Обновляем подключение телефонии"
                    else -> message.ifEmpty { mappedState }
                }
                Log.d(
                    TAG,
                    "onAccountRegistrationStateChanged: rawState=$rawState, mappedState=$mappedState, message=$effectiveMessage",
                )
                if (rawState == "Ok") {
                    currentAccount = account
                    desiredRegistrationEnabled = true
                }
                emitRegistration(mappedState, effectiveMessage)
            }

            override fun onCallStateChanged(
                core: Core,
                call: Call,
                state: Call.State,
                message: String,
            ) {
                val mappedState = mapCallState(state.toString(), message)
                val previousCallState = lastCallState
                val effectiveMappedState =
                    if (shouldTreatEarlyTerminationAsEnded(mappedState, previousCallState)) {
                        "ended"
                    } else {
                        mappedState
                    }
                val effectiveMessage =
                    if (effectiveMappedState == "ended" &&
                        (isRemoteDeclineMessage(message) || isEarlyCallState(previousCallState))
                    ) {
                        "Call declined by remote party"
                    } else {
                        message.ifEmpty { state.toString() }
                    }
                Log.d(
                    TAG,
                    "onCallStateChanged: rawState=${state.toString()}, mappedState=$mappedState, effectiveMappedState=$effectiveMappedState, previousCallState=$previousCallState, remote=${remoteIdentityFor(call)}, message=$effectiveMessage",
                )
                currentCall = when (effectiveMappedState) {
                    "ended", "failed", "idle" -> null
                    else -> call
                }

                val remoteIdentity = remoteIdentityFor(call)
                if (state.toString() == "End" || state.toString() == "Released") {
                    isSpeakerOn = false
                }

                lastCallState = effectiveMappedState
                if (effectiveMappedState == "calling" ||
                    effectiveMappedState == "ringing" ||
                    effectiveMappedState == "in_call"
                ) {
                    tryApplySpeakerPreference(core)
                }

                emitCallState(
                    state = effectiveMappedState,
                    remoteIdentity = remoteIdentity,
                    message = effectiveMessage,
                    muted = call.getMicrophoneMuted(),
                    speakerOn = isSpeakerOn,
                )
            }
        }

        createdCore.addListener(listener)
        coreListener = listener
        core = createdCore
        return createdCore
    }

    private fun tryApplySpeakerPreference(sipCore: Core) {
        try {
            val desired = preferredAudioDevice(sipCore, speakerEnabled = isSpeakerOn)
            if (desired != null) {
                sipCore.setOutputAudioDevice(desired)
                emitAudioRouteState(
                    state = "audio_device_selected",
                    reason = "call_state_$lastCallState",
                    deviceType = audioDeviceTypeName(desired),
                )
            }
        } catch (error: Throwable) {
            Log.e(TAG, "tryApplySpeakerPreference failed: ${error.message}", error)
        }
    }

    private fun preferredAudioDevice(
        sipCore: Core,
        speakerEnabled: Boolean,
    ) = sipCore.getAudioDevices()
        .map { device -> device to audioDevicePriority(device, speakerEnabled) }
        .filter { (_, priority) -> priority > 0 }
        .maxByOrNull { (_, priority) -> priority }
        ?.first

    private fun audioDevicePriority(device: org.linphone.core.AudioDevice, speakerEnabled: Boolean): Int {
        val typeName = audioDeviceTypeName(device)
        if (speakerEnabled) {
            return if (typeName.contains("speaker", ignoreCase = true)) 100 else 0
        }

        return when {
            typeName.contains("bluetooth", ignoreCase = true) -> 100
            typeName.contains("headset", ignoreCase = true) -> 80
            typeName.contains("headphone", ignoreCase = true) -> 70
            typeName.contains("earpiece", ignoreCase = true) -> 60
            typeName.contains("microphone", ignoreCase = true) -> 0
            typeName.contains("speaker", ignoreCase = true) -> 0
            else -> 10
        }
    }

    private fun audioDeviceTypeName(device: org.linphone.core.AudioDevice): String {
        return device.getType().toString()
    }

    private fun emitAudioRouteState(
        state: String,
        reason: String,
        deviceType: String,
    ) {
        emit(
            type = "audio_session",
            payload = hashMapOf(
                "state" to state,
                "reason" to reason,
                "output" to deviceType.lowercase(),
                "speakerOn" to isSpeakerOn,
                "callState" to lastCallState,
            ),
        )
    }

    private fun emitRegistration(state: String, message: String) {
        emit(
            type = "registration",
            payload = hashMapOf(
                "state" to state,
                "message" to message,
            ),
        )
    }

    private fun emitCallState(
        state: String,
        remoteIdentity: String?,
        message: String,
        muted: Boolean = false,
        speakerOn: Boolean = false,
    ) {
        emit(
            type = "call",
            payload = hashMapOf(
                "state" to state,
                "remoteIdentity" to remoteIdentity,
                "message" to message,
                "muted" to muted,
                "speakerOn" to speakerOn,
            ),
        )
    }

    private fun emit(type: String, payload: HashMap<String, Any?>) {
        payload["type"] = type
        mainHandler.post {
            eventListener?.invoke(payload)
        }
    }

    private fun resolveTransport(transport: String): TransportType {
        return when (transport.lowercase()) {
            "tcp" -> TransportType.Tcp
            else -> TransportType.Udp
        }
    }

    private fun mapRegistrationState(value: String?): String {
        return when (value) {
            "Ok" -> "registered"
            "Progress", "Refreshing" -> "registering"
            "Failed" -> "failed"
            "Cleared" -> "disconnected"
            else -> "disconnected"
        }
    }

    private fun markNetworkReachable(sipCore: Core) {
        try {
            sipCore.setNetworkReachable(true)
            sipCore.setSipNetworkReachable(true)
            sipCore.setMediaNetworkReachable(true)
        } catch (_: Throwable) {
        }
    }

    private fun mapCallState(value: String?, message: String = ""): String {
        return when (value) {
            "IncomingReceived" -> "incoming"
            "OutgoingInit" -> "calling"
            "OutgoingProgress", "OutgoingEarlyMedia", "OutgoingRinging" -> "ringing"
            "Connected", "StreamsRunning", "Paused", "PausedByRemote", "Resuming" -> "in_call"
            "Error" -> if (isRemoteDeclineMessage(message)) "ended" else "failed"
            "End", "Released" -> "ended"
            else -> "idle"
        }
    }

    private fun isEarlyCallState(state: String): Boolean {
        return state == "incoming" || state == "calling" || state == "ringing"
    }

    private fun shouldTreatEarlyTerminationAsEnded(
        mappedState: String,
        previousCallState: String,
    ): Boolean {
        return mappedState == "failed" && isEarlyCallState(previousCallState)
    }

    private fun isRemoteDeclineMessage(message: String?): Boolean {
        val normalized = message?.lowercase()?.trim().orEmpty()
        if (normalized.isEmpty()) {
            return false
        }

        return normalized.contains("486") ||
            normalized.contains("603") ||
            normalized.contains("decline") ||
            normalized.contains("declined") ||
            normalized.contains("busy here") ||
            normalized.contains("busy") ||
            normalized.contains("canceled") ||
            normalized.contains("cancelled") ||
            normalized.contains("request terminated")
    }

    private fun remoteIdentityFor(call: Call?): String? {
        return try {
            call?.getRemoteAddress()?.asStringUriOnly()
                ?: call?.getRemoteAddress()?.asString()
                ?: if (currentDomain.isNotEmpty()) "sip:@$currentDomain" else null
        } catch (_: Throwable) {
            null
        }
    }
}
