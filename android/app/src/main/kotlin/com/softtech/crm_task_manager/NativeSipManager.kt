package com.softtech.crm_task_manager

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import org.linphone.core.Account
import org.linphone.core.AccountParams
import org.linphone.core.AVPFMode
import org.linphone.core.AudioDevice
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
        private const val DUPLICATE_INCOMING_WINDOW_MS = 5_000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventListener: ((HashMap<String, Any?>) -> Unit)? = null
    private var core: Core? = null
    private var coreListener: CoreListenerStub? = null
    private var currentAccount: Account? = null
    private var currentCall: Call? = null
    private var isSpeakerOn = false
    private var selectedAudioDeviceId: String? = null
    private var applyingAudioRoute = false
    private var currentDomain: String = ""
    private var desiredRegistrationEnabled = false
    private var lastCallState: String = "idle"
    private var currentIncomingRemote: String? = null
    private var currentIncomingConnected = false
    private var lastUnansweredIncomingRemote: String? = null
    private var lastUnansweredIncomingEndedAtMs = 0L
    private var answerInProgress = false
    private var proximityWakeLock: PowerManager.WakeLock? = null

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
            params.setToneIndicationsEnabled(true)
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

    @Synchronized
    fun acceptCall(): Boolean {
        if (answerInProgress) {
            Log.d(TAG, "acceptCall coalesced: answer already in progress")
            return true
        }
        val call = currentCall ?: try {
            core?.getCalls()?.firstOrNull { candidate ->
                candidate.getState().toString() == "IncomingReceived"
            }
        } catch (_: Throwable) {
            null
        } ?: return false
        return try {
            val stateBeforeAccept = call.getState().toString()
            if (stateBeforeAccept == "Connected" ||
                stateBeforeAccept == "StreamsRunning"
            ) {
                currentCall = call
                return true
            }
            if (stateBeforeAccept != "IncomingReceived") {
                Log.w(TAG, "acceptCall ignored for state=$stateBeforeAccept")
                return false
            }
            answerInProgress = true
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
            val acceptStatus = call.acceptWithParams(params)
            if (acceptStatus != 0) {
                answerInProgress = false
                Log.e(TAG, "acceptCall rejected by Linphone: status=$acceptStatus")
                emit(
                    type = "answer_action",
                    payload = hashMapOf(
                        "result" to "rejected",
                        "status" to acceptStatus,
                        "callState" to call.getState().toString(),
                        "remoteIdentity" to remoteIdentityFor(call),
                    ),
                )
                emitCallState(
                    state = "failed",
                    remoteIdentity = remoteIdentityFor(call),
                    message = "Accept call failed (status=$acceptStatus)",
                    muted = call.getMicrophoneMuted(),
                    speakerOn = isSpeakerOn,
                )
                return false
            }

            // acceptWithParams() may synchronously deliver Connected, Error or
            // End through onCallStateChanged(). Never overwrite that callback
            // with a synthetic in_call state: the UI must open the conversation
            // only after Linphone confirms Connected/StreamsRunning.
            val stateAfterAccept = call.getState().toString()
            if (stateAfterAccept == "End" ||
                stateAfterAccept == "Released" ||
                stateAfterAccept == "Error"
            ) {
                Log.w(
                    TAG,
                    "acceptCall completed after terminal callback: state=$stateAfterAccept",
                )
                emit(
                    type = "answer_action",
                    payload = hashMapOf(
                        "result" to "terminal",
                        "status" to acceptStatus,
                        "callState" to stateAfterAccept,
                        "remoteIdentity" to remoteIdentityFor(call),
                    ),
                )
                answerInProgress = false
                return false
            }
            Log.d(TAG, "acceptCall requested successfully: state=$stateAfterAccept")
            emit(
                type = "answer_action",
                payload = hashMapOf(
                    "result" to "requested",
                    "status" to acceptStatus,
                    "callState" to stateAfterAccept,
                    "remoteIdentity" to remoteIdentityFor(call),
                ),
            )
            true
        } catch (error: Throwable) {
            answerInProgress = false
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

    @Synchronized
    fun hangup(): Boolean {
        val call = currentCall?.takeUnless { candidate ->
            val state = candidate.getState().toString()
            state == "End" || state == "Released" || state == "Error"
        } ?: try {
            core?.getCalls()?.firstOrNull { candidate ->
                val state = candidate.getState().toString()
                state != "End" && state != "Released" && state != "Error"
            }
        } catch (_: Throwable) {
            null
        }

        if (call == null) {
            // An already released call is a successful idempotent hangup.
            // Flutter can still show "calling" when a terminal event races
            // with the makeCall method result, so always converge to ended.
            currentCall = null
            isSpeakerOn = false
            lastCallState = "ended"
            emitCallState("ended", null, "Call already ended locally")
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
        selectedAudioDeviceId = null
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
            applyingAudioRoute = true
            val desired = preferredAudioDevice(sipCore, speakerEnabled = enabled)

            if (desired != null) {
                applyAudioDevicePair(sipCore, desired)
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
        } finally {
            applyingAudioRoute = false
        }
    }

    fun getAudioRoutes(): ArrayList<HashMap<String, Any?>> {
        val sipCore = core ?: return arrayListOf()
        val selectedId = try {
            sipCore.getOutputAudioDevice()?.getId()
        } catch (_: Throwable) {
            null
        }

        return sipCore.getAudioDevices()
            .filter { device ->
                try {
                    device.hasCapability(AudioDevice.Capabilities.CapabilityPlay)
                } catch (_: Throwable) {
                    audioRouteTypeKey(device) != "microphone"
                }
            }
            .distinctBy { it.getId() }
            .sortedByDescending { audioRoutePriority(it) }
            .mapTo(arrayListOf()) { device ->
                hashMapOf<String, Any?>(
                    "id" to device.getId(),
                    "type" to audioRouteTypeKey(device),
                    "name" to audioRouteDisplayName(device),
                    "selected" to (device.getId() == selectedId),
                )
            }
    }

    fun setAudioRoute(deviceId: String): Boolean {
        val sipCore = core ?: return false
        val normalizedId = deviceId.trim()
        if (normalizedId.isEmpty()) return false

        return try {
            applyingAudioRoute = true
            val devices = sipCore.getAudioDevices().toList()
            val outputDevice = devices.firstOrNull { device ->
                device.getId() == normalizedId &&
                    device.hasCapability(AudioDevice.Capabilities.CapabilityPlay)
            } ?: return false

            applyAudioDevicePair(sipCore, outputDevice)
            val routeType = audioRouteTypeKey(outputDevice)

            selectedAudioDeviceId = outputDevice.getId()
            isSpeakerOn = routeType == "speaker"
            emitAudioRouteState(
                state = "audio_device_selected",
                reason = "user_selected",
                deviceType = audioDeviceTypeName(outputDevice),
                deviceId = outputDevice.getId(),
                deviceName = audioRouteDisplayName(outputDevice),
            )
            emitCallState(
                state = lastCallState,
                remoteIdentity = remoteIdentityFor(currentCall),
                message = "Audio route changed",
                muted = currentCall?.getMicrophoneMuted() ?: false,
                speakerOn = isSpeakerOn,
            )
            true
        } catch (error: Throwable) {
            Log.e(TAG, "setAudioRoute failed: ${error.message}", error)
            false
        } finally {
            applyingAudioRoute = false
        }
    }

    fun dispose() {
        desiredRegistrationEnabled = false
        updateProximityScreenOff(callState = "ended", reason = "dispose")
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
                sipCore.enterForeground()
                val hasActiveCall = lastCallState == "incoming" ||
                    lastCallState == "calling" ||
                    lastCallState == "ringing" ||
                    lastCallState == "in_call"
                if (desiredRegistrationEnabled && !hasActiveCall) {
                    sipCore.ensureRegistered()
                    Log.d(TAG, "onAppForeground: core.ensureRegistered()")
                } else if (hasActiveCall) {
                    Log.d(TAG, "onAppForeground: registration refresh skipped during $lastCallState")
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
        // ВАЖНО: не вызывать core.setNetworkReachable(true) вручную.
        // Публичный сеттер НАВСЕГДА отключает встроенный мониторинг сети
        // Linphone (AndroidPlatformHelper + ConnectivityManager). Без него
        // переключение Wi-Fi <-> мобильный интернет не перепривязывает сокеты
        // и не запускает re-REGISTER, что рвёт звонки при смене сети.

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
                val rawState = state.toString()
                val rawMessage = message.ifEmpty { rawState }
                val remoteIdentity = remoteIdentityFor(call)
                if (rawState == "IncomingReceived") {
                    val now = System.currentTimeMillis()
                    val elapsedSinceUnanswered =
                        now - lastUnansweredIncomingEndedAtMs
                    val duplicateBurst =
                        lastUnansweredIncomingEndedAtMs > 0L &&
                            elapsedSinceUnanswered in 0..DUPLICATE_INCOMING_WINDOW_MS &&
                            normalizedRemoteIdentity(remoteIdentity) ==
                            normalizedRemoteIdentity(lastUnansweredIncomingRemote)
                    if (duplicateBurst) {
                        lastUnansweredIncomingEndedAtMs = now
                        Log.w(
                            TAG,
                            "Suppressing duplicate incoming burst: remote=$remoteIdentity, elapsedMs=$elapsedSinceUnanswered",
                        )
                        emit(
                            type = "incoming_duplicate_suppressed",
                            payload = hashMapOf(
                                "remoteIdentity" to remoteIdentity,
                                "elapsedMs" to elapsedSinceUnanswered,
                                "windowMs" to DUPLICATE_INCOMING_WINDOW_MS,
                            ),
                        )
                        try {
                            call.terminate()
                        } catch (error: Throwable) {
                            Log.w(TAG, "Failed to terminate duplicate incoming call: ${error.message}")
                        }
                        return
                    }
                    currentIncomingRemote = remoteIdentity
                    currentIncomingConnected = false
                }
                val callReason = try {
                    call.getReason().toString()
                } catch (_: Throwable) {
                    null
                }
                val errorInfo = try {
                    call.getErrorInfo()
                } catch (_: Throwable) {
                    null
                }
                val mappedState = mapCallState(rawState, message)
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
                    "onCallStateChanged: rawState=$rawState, mappedState=$mappedState, effectiveMappedState=$effectiveMappedState, previousCallState=$previousCallState, remote=$remoteIdentity, rawMessage=$rawMessage, effectiveMessage=$effectiveMessage, reason=$callReason, protocol=${errorInfo?.getProtocol()}, protocolCode=${errorInfo?.getProtocolCode()}, phrase=${errorInfo?.getPhrase()}",
                )
                val protocolCode = errorInfo?.getProtocolCode()
                val phrase = errorInfo?.getPhrase().orEmpty()
                val reasonText = callReason.orEmpty()
                val busySignal = protocolCode == 486 ||
                    protocolCode == 600 ||
                    protocolCode == 603 ||
                    reasonText.contains("Busy", ignoreCase = true) ||
                    phrase.contains("busy", ignoreCase = true) ||
                    rawMessage.contains("486") ||
                    effectiveMessage.contains("busy", ignoreCase = true)
                NativeSipBridge.recordDiagnosticEvent(
                    "[VOIP] CALL_STATE_CHANGED",
                    hashMapOf(
                        "raw_state" to rawState,
                        "mapped_state" to effectiveMappedState,
                        "previous_state" to previousCallState,
                        "remote" to remoteIdentity,
                        "message" to effectiveMessage,
                        "sip_reason" to callReason,
                        "protocol" to errorInfo?.getProtocol(),
                        "protocol_code" to protocolCode,
                        "phrase" to phrase,
                        "busy_signal" to busySignal,
                    ),
                )
                if (busySignal) {
                    NativeSipBridge.recordDiagnosticEvent(
                        "[VOIP] BUSY_SIGNAL_DETECTED",
                        hashMapOf(
                            "raw_state" to rawState,
                            "protocol_code" to protocolCode,
                            "phrase" to phrase,
                            "sip_reason" to callReason,
                            "remote" to remoteIdentity,
                        ),
                    )
                }
                if (rawState == "OutgoingEarlyMedia") {
                    NativeSipBridge.recordDiagnosticEvent(
                        "[VOIP] EARLY_MEDIA",
                        hashMapOf(
                            "remote" to remoteIdentity,
                            "protocol_code" to protocolCode,
                            "phrase" to phrase,
                        ),
                    )
                }
                currentCall = when (effectiveMappedState) {
                    "ended", "failed", "idle" -> null
                    else -> call
                }

                if (effectiveMappedState == "ended" ||
                    effectiveMappedState == "failed"
                ) {
                    answerInProgress = false
                }
                if (effectiveMappedState == "in_call") {
                    answerInProgress = false
                    currentIncomingConnected = true
                } else if ((effectiveMappedState == "ended" ||
                        effectiveMappedState == "failed") &&
                    previousCallState == "incoming" &&
                    !currentIncomingConnected
                ) {
                    lastUnansweredIncomingRemote =
                        currentIncomingRemote ?: remoteIdentity
                    lastUnansweredIncomingEndedAtMs = System.currentTimeMillis()
                    currentIncomingRemote = null
                    currentIncomingConnected = false
                } else if (effectiveMappedState == "ended" ||
                    effectiveMappedState == "failed"
                ) {
                    currentIncomingRemote = null
                    currentIncomingConnected = false
                }
                if (state.toString() == "End" || state.toString() == "Released") {
                    isSpeakerOn = false
                    selectedAudioDeviceId = null
                }

                lastCallState = effectiveMappedState
                if (effectiveMappedState == "calling" ||
                    effectiveMappedState == "ringing" ||
                    effectiveMappedState == "early_media" ||
                    effectiveMappedState == "in_call"
                ) {
                    tryApplySpeakerPreference(core)
                }

                if (effectiveMappedState == "in_call" &&
                    (previousCallState == "calling" ||
                        previousCallState == "ringing" ||
                        previousCallState == "early_media")
                ) {
                    NativeSipBridge.recordDiagnosticEvent(
                        "[VOIP] OUTGOING_NETWORK_MEDIA",
                        hashMapOf(
                            "previous_state" to previousCallState,
                            "raw_state" to rawState,
                            "speaker_on" to isSpeakerOn,
                            "remote" to remoteIdentity,
                        ),
                    )
                }

                emitCallState(
                    state = effectiveMappedState,
                    remoteIdentity = remoteIdentity,
                    message = when {
                        busySignal &&
                            (effectiveMappedState == "ended" || effectiveMappedState == "failed") ->
                            "Абонент занят"
                        effectiveMappedState == "early_media" ->
                            "Outgoing early media"
                        effectiveMappedState == "in_call" &&
                            (previousCallState == "calling" ||
                                previousCallState == "ringing" ||
                                previousCallState == "early_media") ->
                            "Network media connected"
                        else -> effectiveMessage
                    },
                    muted = call.getMicrophoneMuted(),
                    speakerOn = isSpeakerOn,
                    diagnostics = hashMapOf(
                        "rawState" to rawState,
                        "raw_state" to rawState,
                        "rawMessage" to rawMessage,
                        "previousCallState" to previousCallState,
                        "reason" to callReason,
                        "sip_reason" to callReason,
                        "protocol" to errorInfo?.getProtocol(),
                        "protocolCode" to errorInfo?.getProtocolCode(),
                        "protocol_code" to errorInfo?.getProtocolCode(),
                        "phrase" to errorInfo?.getPhrase(),
                        "warnings" to errorInfo?.getWarnings(),
                        "busy_signal" to busySignal,
                        "outgoing_network_media" to (
                            effectiveMappedState == "early_media" ||
                                (effectiveMappedState == "in_call" &&
                                    (previousCallState == "calling" ||
                                        previousCallState == "ringing" ||
                                        previousCallState == "early_media"))
                            ),
                    ),
                )
            }

            override fun onAudioDeviceChanged(core: Core, audioDevice: AudioDevice) {
                // Linphone reports input and output device changes through the
                // same callback. A Bluetooth capture endpoint is a microphone,
                // not a valid playback route. Treating it as the output caused
                // ringback and speech to be routed through the wrong endpoint.
                if (!audioDevice.hasCapability(
                        AudioDevice.Capabilities.CapabilityPlay,
                    )
                ) {
                    return
                }
                if (applyingAudioRoute) {
                    return
                }
                val routeType = audioRouteTypeKey(audioDevice)
                val speakerObserved = routeType == "speaker"
                val inCall = isEarlyCallState(lastCallState) || lastCallState == "in_call"
                val matchesUserPreference = selectedAudioDeviceId?.let { selectedId ->
                    audioDevice.getId() == selectedId
                } ?: (speakerObserved == isSpeakerOn)

                if (inCall && !matchesUserPreference) {
                    tryApplySpeakerPreference(core)
                    return
                }

                isSpeakerOn = speakerObserved
                updateProximityScreenOff(
                    callState = lastCallState,
                    reason = "audio_device_changed",
                )
                emitAudioRouteState(
                    state = "audio_device_selected",
                    reason = "device_changed",
                    deviceType = audioDeviceTypeName(audioDevice),
                    deviceId = audioDevice.getId(),
                    deviceName = audioRouteDisplayName(audioDevice),
                )
            }

            override fun onAudioDevicesListUpdated(core: Core) {
                if (!isEarlyCallState(lastCallState) && lastCallState != "in_call") {
                    return
                }
                val selectedStillAvailable = selectedAudioDeviceId?.let { selectedId ->
                    core.getAudioDevices().any { it.getId() == selectedId }
                } ?: true
                if (!selectedStillAvailable) {
                    selectedAudioDeviceId = null
                    isSpeakerOn = false
                }
                tryApplySpeakerPreference(core)
            }
        }

        createdCore.addListener(listener)
        coreListener = listener
        core = createdCore
        return createdCore
    }

    private fun tryApplySpeakerPreference(sipCore: Core) {
        if (applyingAudioRoute) {
            return
        }
        applyingAudioRoute = true
        try {
            val desired = selectedAudioDeviceId?.let { selectedId ->
                sipCore.getAudioDevices().firstOrNull { it.getId() == selectedId }
            } ?: preferredAudioDevice(sipCore, speakerEnabled = isSpeakerOn)
            if (desired != null) {
                applyAudioDevicePair(sipCore, desired)
                emitAudioRouteState(
                    state = "audio_device_selected",
                    reason = "call_state_$lastCallState",
                    deviceType = audioDeviceTypeName(desired),
                )
            }
        } catch (error: Throwable) {
            Log.e(TAG, "tryApplySpeakerPreference failed: ${error.message}", error)
        } finally {
            applyingAudioRoute = false
        }
    }

    private fun applyAudioDevicePair(sipCore: Core, outputDevice: AudioDevice) {
        sipCore.setOutputAudioDevice(outputDevice)
        val devices = sipCore.getAudioDevices()
        val routeType = audioRouteTypeKey(outputDevice)
        val inputDevice = devices.firstOrNull { device ->
            device.getId() == outputDevice.getId() &&
                device.hasCapability(AudioDevice.Capabilities.CapabilityRecord)
        } ?: devices.firstOrNull { device ->
            audioRouteTypeKey(device) == routeType &&
                device.hasCapability(AudioDevice.Capabilities.CapabilityRecord)
        } ?: devices.firstOrNull { device ->
            audioRouteTypeKey(device) == "microphone" &&
                device.hasCapability(AudioDevice.Capabilities.CapabilityRecord)
        }
        if (inputDevice != null) {
            sipCore.setInputAudioDevice(inputDevice)
        }
    }

    private fun preferredAudioDevice(
        sipCore: Core,
        speakerEnabled: Boolean,
    ) = sipCore.getAudioDevices()
        .filter { device ->
            device.hasCapability(AudioDevice.Capabilities.CapabilityPlay)
        }
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

    private fun audioRouteTypeKey(device: AudioDevice): String {
        return when (device.getType().toString().lowercase()) {
            "bluetooth", "bluetootha2dp", "hearingaid" -> "bluetooth"
            "earpiece", "telephony" -> "earpiece"
            "speaker" -> "speaker"
            "headset", "headphones", "auxline", "genericusb" -> "headset"
            "microphone" -> "microphone"
            else -> "other"
        }
    }

    private fun audioRouteDisplayName(device: AudioDevice): String {
        val deviceName = device.getDeviceName().trim()
        return when (audioRouteTypeKey(device)) {
            "bluetooth" -> deviceName.ifEmpty { "Bluetooth-наушники" }
            "earpiece" -> "Телефон"
            "speaker" -> "Громкая связь"
            "headset" -> deviceName.ifEmpty { "Проводные наушники" }
            else -> deviceName.ifEmpty { "Аудиоустройство" }
        }
    }

    private fun audioRoutePriority(device: AudioDevice): Int {
        return when (audioRouteTypeKey(device)) {
            "bluetooth" -> 50
            "headset" -> 40
            "earpiece" -> 30
            "speaker" -> 20
            else -> 10
        }
    }

    private fun emitAudioRouteState(
        state: String,
        reason: String,
        deviceType: String,
        deviceId: String? = null,
        deviceName: String? = null,
    ) {
        emit(
            type = "audio_session",
            payload = hashMapOf(
                "state" to state,
                "reason" to reason,
                "output" to deviceType.lowercase(),
                "outputDeviceId" to deviceId,
                "outputDeviceName" to deviceName,
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
        diagnostics: HashMap<String, Any?> = hashMapOf(),
    ) {
        updateProximityScreenOff(callState = state, reason = "call_state_changed")
        val payload = hashMapOf<String, Any?>(
                "state" to state,
                "remoteIdentity" to remoteIdentity,
                "message" to message,
                "muted" to muted,
                "speakerOn" to speakerOn,
        )
        payload.putAll(diagnostics)
        emit(type = "call", payload = payload)
    }

    private fun updateProximityScreenOff(callState: String, reason: String) {
        val outputRoute = try {
            core?.getOutputAudioDevice()?.let(::audioRouteTypeKey)
        } catch (_: Throwable) {
            null
        }
        val shouldEnable = callState == "in_call" && outputRoute == "earpiece"
        val currentWakeLock = proximityWakeLock

        if (shouldEnable) {
            if (currentWakeLock?.isHeld == true) return
            try {
                val powerManager =
                    context.getSystemService(Context.POWER_SERVICE) as PowerManager
                if (!powerManager.isWakeLockLevelSupported(
                        PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                    )
                ) {
                    Log.d(TAG, "Proximity screen-off wake lock is not supported")
                    return
                }
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                    "$TAG:proximity",
                )
                wakeLock.setReferenceCounted(false)
                wakeLock.acquire()
                proximityWakeLock = wakeLock
                Log.d(
                    TAG,
                    "Proximity screen-off enabled: reason=$reason, route=$outputRoute",
                )
            } catch (error: Throwable) {
                Log.e(TAG, "Failed to enable proximity screen-off", error)
            }
            return
        }

        if (currentWakeLock?.isHeld != true) {
            proximityWakeLock = null
            return
        }
        try {
            currentWakeLock.release()
            Log.d(
                TAG,
                "Proximity screen-off disabled: reason=$reason, route=$outputRoute",
            )
        } catch (error: Throwable) {
            Log.e(TAG, "Failed to disable proximity screen-off", error)
        } finally {
            proximityWakeLock = null
        }
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

    private fun mapCallState(value: String?, message: String = ""): String {
        return when (value) {
            "IncomingReceived" -> "incoming"
            "OutgoingInit" -> "calling"
            "OutgoingProgress", "OutgoingRinging" -> "ringing"
            "OutgoingEarlyMedia" -> "early_media"
            "Connected", "StreamsRunning", "Paused", "PausedByRemote", "Resuming" -> "in_call"
            "Error" -> if (isRemoteDeclineMessage(message)) "ended" else "failed"
            "End", "Released" -> "ended"
            else -> "idle"
        }
    }

    private fun isEarlyCallState(state: String): Boolean {
        return state == "incoming" || state == "calling" || state == "ringing" || state == "early_media"
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

    private fun normalizedRemoteIdentity(value: String?): String {
        return value?.trim()?.lowercase().orEmpty()
    }
}
