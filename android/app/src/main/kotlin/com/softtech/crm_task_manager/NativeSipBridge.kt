package com.softtech.crm_task_manager

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

data class NativeSipStoredConfig(
    val server: String,
    val login: String,
    val password: String,
    val port: Int,
    val transport: String,
    val authUser: String,
    val enabled: Boolean,
)

object NativeSipBridge {
    private const val TAG = "NativeSipBridge"
    private const val PREFS_NAME = "native_sip_bridge"
    private const val KEY_SERVER = "server"
    private const val KEY_LOGIN = "login"
    private const val KEY_PASSWORD = "password"
    private const val KEY_PORT = "port"
    private const val KEY_TRANSPORT = "transport"
    private const val KEY_AUTH_USER = "auth_user"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_PENDING_CALL_UI_OPEN = "pending_call_ui_open"
    private const val KEY_PENDING_CALL_UI_REQUEST_ID = "pending_call_ui_request_id"
    private const val KEY_ACTIVE_CALL_UI_REQUEST_ID = "active_call_ui_request_id"
    private const val DIAGNOSTIC_PREFS = "native_sip_diagnostics"
    private const val KEY_DIAGNOSTIC_LOGS = "logs"
    private const val MAX_DIAGNOSTIC_LOGS = 500

    // Отдельный НЕЗАШИФРОВАННЫЙ файл только для флага enabled.
    // isPersistentEnabled() ДОЛЖЕН читать отсюда, а не из PREFS_NAME!
    // Причина: PREFS_NAME использует EncryptedSharedPreferences — ключи
    // в нём зашифрованы и нечитаемы через обычный getSharedPreferences().
    // Если читать из неправильного файла — всегда возвращается false,
    // и сервис НИКОГДА не перезапускается после гибели процесса.
    private const val PLAIN_FLAGS_PREFS = "native_sip_bridge_flags"

    private val bridgeObservers = linkedSetOf<(HashMap<String, Any?>) -> Unit>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var appContext: Context? = null
    private var prefs: SharedPreferences? = null
    private var nativeSipManager: NativeSipManager? = null
    private var flutterEventSink: EventChannel.EventSink? = null
    private var appInForeground = false
    @Volatile
    private var incomingAnswerPending = false
    private var currentSnapshot = hashMapOf<String, Any?>(
        "registrationState" to "disconnected",
        "callState" to "idle",
        "remoteIdentity" to null,
        "message" to null,
        "muted" to false,
        "speakerOn" to false,
        "persistentEnabled" to false,
        "appForeground" to false,
    )

    private fun startRuntimeServiceIfPossible(reason: String) {
        val context = appContext ?: return
        val started = NativeSipForegroundService.start(context)
        if (!started) {
            currentSnapshot["message"] = "Сервис телефонии не был запущен: $reason"
            Log.w(TAG, "Foreground SIP service was not started: $reason")
        }
    }

    fun initialize(context: Context) {
        if (appContext == null) {
            appContext = context.applicationContext
            // Однократная миграция: если у пользователя уже был включён SIP
            // до этого обновления — перенесём флаг в новый plain-файл.
            migrateEnabledFlagIfNeeded()
            currentSnapshot["persistentEnabled"] = isPersistentEnabled()
        }
    }

    /**
     * Читает KEY_ENABLED из EncryptedSharedPreferences (старый способ хранения)
     * и при необходимости зеркалит его в PLAIN_FLAGS_PREFS.
     * Вызывается один раз при первой инициализации после обновления.
     */
    private fun migrateEnabledFlagIfNeeded() {
        try {
            val plainPrefs = appContext
                ?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
                ?: return

            // Уже мигрировано — выходим
            if (plainPrefs.contains(KEY_ENABLED)) return

            // Пробуем прочитать из EncryptedSharedPreferences
            val encryptedEnabled = getPrefs()?.getBoolean(KEY_ENABLED, false) ?: false
            if (encryptedEnabled) {
                plainPrefs.edit().putBoolean(KEY_ENABLED, true).apply()
                Log.d(TAG, "Migrated SIP enabled=true flag to plain prefs")
            } else {
                // Записываем false чтобы пометить миграцию как выполненную
                plainPrefs.edit().putBoolean(KEY_ENABLED, false).apply()
            }
        } catch (error: Throwable) {
            Log.w(TAG, "SIP enabled flag migration failed (non-critical): ${error.message}")
        }
    }

    fun setFlutterEventSink(eventSink: EventChannel.EventSink?) {
        flutterEventSink = eventSink
        if (eventSink != null && hasPendingCallUiOpen()) {
            dispatchBridgeEvent(buildCallUiRequestEvent("pending-native-intent"))
        }
    }

    @Synchronized
    fun requestFlutterCallUi(source: String): Boolean {
        val context = appContext ?: return false
        val callState = currentSnapshot["callState"]?.toString()
        if (!isActiveCallState(callState)) {
            recordDiagnosticEvent(
                event = "call_ui_request_ignored",
                details = hashMapOf(
                    "source" to source,
                    "callState" to callState,
                ),
            )
            clearCallUiRequestState(clearActiveRequest = true)
            return false
        }

        val flags = context.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
        val existingRequestId = flags.getLong(KEY_ACTIVE_CALL_UI_REQUEST_ID, 0L)
        val requestId = existingRequestId.takeIf { it > 0L } ?: newCallUiRequestId()
        flags
            .edit()
            .putBoolean(KEY_PENDING_CALL_UI_OPEN, true)
            .putLong(KEY_PENDING_CALL_UI_REQUEST_ID, requestId)
            .putLong(KEY_ACTIVE_CALL_UI_REQUEST_ID, requestId)
            .apply()

        if (flutterEventSink != null) {
            dispatchBridgeEvent(buildCallUiRequestEvent(source))
        }
        return true
    }

    private fun buildCallUiRequestEvent(source: String): HashMap<String, Any?> {
        return hashMapOf(
            "type" to "call_ui_request",
            "source" to source,
            "requestId" to pendingCallUiRequestId(),
            "registrationState" to currentSnapshot["registrationState"],
            "callState" to currentSnapshot["callState"],
            "remoteIdentity" to currentSnapshot["remoteIdentity"],
            "message" to currentSnapshot["message"],
            "muted" to currentSnapshot["muted"],
            "speakerOn" to currentSnapshot["speakerOn"],
            "persistentEnabled" to currentSnapshot["persistentEnabled"],
        )
    }

    private fun hasPendingCallUiOpen(): Boolean {
        val flags = appContext
            ?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
            ?: return false
        return flags.getBoolean(KEY_PENDING_CALL_UI_OPEN, false)
    }

    private fun pendingCallUiRequestId(): Long {
        val flags = appContext
            ?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
            ?: return 0L
        return flags.getLong(KEY_PENDING_CALL_UI_REQUEST_ID, 0L)
    }

    fun consumePendingCallUiRequest(): HashMap<String, Any?>? {
        val flags = appContext
            ?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
            ?: return null
        if (!flags.getBoolean(KEY_PENDING_CALL_UI_OPEN, false)) return null

        val event = buildCallUiRequestEvent("flutter-method-consume")
        flags.edit()
            .remove(KEY_PENDING_CALL_UI_OPEN)
            .remove(KEY_PENDING_CALL_UI_REQUEST_ID)
            .apply()
        return event
    }

    fun isIncomingAnswerPending(): Boolean = incomingAnswerPending

    fun addObserver(observer: (HashMap<String, Any?>) -> Unit) {
        bridgeObservers.add(observer)
    }

    fun removeObserver(observer: (HashMap<String, Any?>) -> Unit) {
        bridgeObservers.remove(observer)
    }

    fun register(
        server: String,
        login: String,
        password: String,
        port: Int,
        transport: String,
        authUser: String?,
    ): Boolean {
        val context = requireContext()
        initialize(context)

        val trimmedServer = server.trim()
        val trimmedLogin = login.trim()
        val trimmedAuthUser = authUser?.trim().takeUnless { it.isNullOrEmpty() } ?: trimmedLogin
        val requestedConfig = NativeSipStoredConfig(
            server = trimmedServer,
            login = trimmedLogin,
            password = password,
            port = port,
            transport = transport,
            authUser = trimmedAuthUser,
            enabled = true,
        )
        val currentState = currentSnapshot["registrationState"]?.toString()
        val callState = currentSnapshot["callState"]?.toString()
        if (isActiveCallState(callState)) {
            Log.d(TAG, "register skipped: active call state=$callState")
            return true
        }

        if (
            (currentState == "registering" || currentState == "registered") &&
            isSameConfig(getStoredConfig(), requestedConfig)
        ) {
            Log.d(TAG, "register skipped: state=$currentState for same config")
            startRuntimeServiceIfPossible("register-skip-$currentState")
            SipKeepAliveWorker.schedule(context)
            return true
        }

        persistConfig(requestedConfig)
        markRegistrationStarting("Подключение телефонии")

        val success = ensureManager().register(
            server = trimmedServer,
            login = trimmedLogin,
            password = password,
            port = port,
            transport = transport,
            authUser = trimmedAuthUser,
        )

        if (success) {
            startRuntimeServiceIfPossible("register")
            // Запускаем WorkManager как резервный механизм перезапуска.
            // WorkManager (JobScheduler) надёжнее AlarmManager на Xiaomi HyperOS.
            SipKeepAliveWorker.schedule(context)
        }

        return success
    }

    fun restoreRegistrationIfNeeded(startService: Boolean = true): Boolean {
        val context = requireContext()
        initialize(context)

        val config = getStoredConfig() ?: return false
        if (!config.enabled) {
            return false
        }

        val callState = currentSnapshot["callState"]?.toString()
        if (isActiveCallState(callState)) {
            Log.d(TAG, "restoreRegistrationIfNeeded skipped: active call state=$callState")
            return true
        }

        val registrationState = currentSnapshot["registrationState"]?.toString()
        if (registrationState == "registered" || registrationState == "registering") {
            Log.d(TAG, "restoreRegistrationIfNeeded skipped: registrationState=$registrationState")
            if (startService) {
                startRuntimeServiceIfPossible("restore-already-registered")
                SipKeepAliveWorker.schedule(context)
            }
            return true
        }

        markRegistrationStarting("Восстанавливаем подключение телефонии")
        val success = ensureManager().register(
            server = config.server,
            login = config.login,
            password = config.password,
            port = config.port,
            transport = config.transport,
            authUser = config.authUser,
        )

        if (success && startService) {
            startRuntimeServiceIfPossible("restore")
            SipKeepAliveWorker.schedule(context)
        }

        return success
    }

    fun unregister() {
        val context = requireContext()
        Log.w(TAG, "unregister requested", Throwable("NativeSipBridge.unregister trace"))
        updateEnabled(false)
        ensureManager().unregister()
        currentSnapshot["persistentEnabled"] = false
        currentSnapshot["registrationState"] = "disconnected"
        currentSnapshot["callState"] = "idle"
        currentSnapshot["remoteIdentity"] = null
        currentSnapshot["muted"] = false
        currentSnapshot["speakerOn"] = false
        SipKeepAliveWorker.cancel(context)
        NativeSipForegroundService.stop(context)
    }

    fun makeCall(target: String): Boolean {
        startRuntimeServiceIfPossible("makeCall")
        return ensureManager().makeCall(target)
    }

    fun acceptCall(): Boolean {
        val accepted = ensureManager().acceptCall()
        if (accepted) {
            incomingAnswerPending = true
            startRuntimeServiceIfPossible("acceptCall")
        }
        return accepted
    }

    fun declineCall(): Boolean {
        return ensureManager().declineCall()
    }

    fun hangup(source: String = "native"): Boolean {
        return ensureManager().hangup(source = source)
    }

    fun setMuted(muted: Boolean): Boolean {
        return ensureManager().setMuted(muted)
    }

    fun sendDtmf(tone: String): Boolean {
        return ensureManager().sendDtmf(tone)
    }

    fun setSpeaker(enabled: Boolean): Boolean {
        return ensureManager().setSpeaker(enabled)
    }

    fun getAudioRoutes(): ArrayList<HashMap<String, Any?>> {
        return ensureManager().getAudioRoutes()
    }

    fun setAudioRoute(deviceId: String): Boolean {
        return ensureManager().setAudioRoute(deviceId)
    }

    fun onAppForeground() {
        appInForeground = true
        currentSnapshot["appForeground"] = true
        dispatchBridgeEvent(
            hashMapOf(
                "type" to "app_visibility",
                "appForeground" to true,
                "callState" to currentSnapshot["callState"],
                "remoteIdentity" to currentSnapshot["remoteIdentity"],
            ),
        )
        nativeSipManager?.onAppForeground()
    }

    fun onAppBackground() {
        appInForeground = false
        currentSnapshot["appForeground"] = false
        dispatchBridgeEvent(
            hashMapOf(
                "type" to "app_visibility",
                "appForeground" to false,
                "callState" to currentSnapshot["callState"],
                "remoteIdentity" to currentSnapshot["remoteIdentity"],
            ),
        )
        nativeSipManager?.onAppBackground()
    }

    fun isAppInForeground(): Boolean = appInForeground

    fun maintainRegistration(reason: String): Boolean {
        val context = requireContext()
        initialize(context)
        if (!isPersistentEnabled()) {
            Log.d(TAG, "maintainRegistration skipped: persistent SIP disabled, reason=$reason")
            return false
        }

        val registrationState = currentSnapshot["registrationState"]?.toString()
        val callState = currentSnapshot["callState"]?.toString()
        if (callState == "incoming" || callState == "calling" || callState == "ringing" || callState == "in_call") {
            Log.d(TAG, "maintainRegistration skipped: active call state=$callState, reason=$reason")
            return true
        }

        return when (registrationState) {
            "registered", "registering" -> ensureManager().maintainRegistration(reason)
            else -> restoreRegistrationIfNeeded(startService = false)
        }
    }

    fun getStateSnapshot(): HashMap<String, Any?> {
        currentSnapshot["persistentEnabled"] = isPersistentEnabled()
        return HashMap(currentSnapshot)
    }

    fun isPersistentEnabled(): Boolean {
        // ✅ ИСПРАВЛЕНИЕ: читаем из PLAIN_FLAGS_PREFS (незашифрованный).
        // Старый код читал из PREFS_NAME который является EncryptedSharedPreferences —
        // там все ключи зашифрованы и через getSharedPreferences() не читаются.
        // Из-за этого метод ВСЕГДА возвращал false → сервис никогда не перезапускался.
        val prefs = appContext?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
        return prefs?.getBoolean(KEY_ENABLED, false) == true
    }

    fun getStoredConfig(): NativeSipStoredConfig? {
        val prefs = getPrefs() ?: return null
        val server = prefs.getString(KEY_SERVER, null)?.trim().orEmpty()
        val login = prefs.getString(KEY_LOGIN, null)?.trim().orEmpty()
        val password = prefs.getString(KEY_PASSWORD, null).orEmpty()
        val port = prefs.getInt(KEY_PORT, 5060)
        val transport = prefs.getString(KEY_TRANSPORT, "udp").orEmpty()
        val authUser = prefs.getString(KEY_AUTH_USER, login)?.trim().orEmpty()
        val enabled = prefs.getBoolean(KEY_ENABLED, false)

        if (server.isEmpty() || login.isEmpty() || password.isEmpty()) {
            return null
        }

        return NativeSipStoredConfig(
            server = server,
            login = login,
            password = password,
            port = port,
            transport = transport,
            authUser = authUser.ifEmpty { login },
            enabled = enabled,
        )
    }

    fun getStoredConfigForFlutter(): HashMap<String, Any?>? {
        val config = getStoredConfig() ?: return null
        return hashMapOf(
            "server" to config.server,
            "login" to config.login,
            "password" to config.password,
            "port" to config.port,
            "transport" to config.transport,
            "authUser" to config.authUser,
            "enabled" to config.enabled,
        )
    }

    @Synchronized
    fun getDiagnosticLogs(): List<HashMap<String, Any?>> {
        val context = appContext ?: return emptyList()
        val raw = context.getSharedPreferences(DIAGNOSTIC_PREFS, Context.MODE_PRIVATE)
            .getString(KEY_DIAGNOSTIC_LOGS, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { index ->
                val item = array.getJSONObject(index)
                val detailsJson = item.optJSONObject("details") ?: JSONObject()
                val details = hashMapOf<String, Any?>()
                detailsJson.keys().forEach { key -> details[key] = detailsJson.opt(key) }
                hashMapOf(
                    "timestamp" to item.optDouble("timestamp", 0.0),
                    "event" to item.optString("event", "unknown"),
                    "details" to details,
                )
            }
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to read SIP diagnostics: ${error.message}")
            emptyList()
        }
    }

    @Synchronized
    fun clearDiagnosticLogs() {
        appContext?.getSharedPreferences(DIAGNOSTIC_PREFS, Context.MODE_PRIVATE)
            ?.edit()?.remove(KEY_DIAGNOSTIC_LOGS)?.apply()
    }

    fun recordDiagnosticEvent(
        event: String,
        details: HashMap<String, Any?> = hashMapOf(),
    ) {
        appendDiagnosticEvent(
            hashMapOf<String, Any?>(
                "type" to event,
                *details.entries.map { it.key to it.value }.toTypedArray(),
            ),
        )
    }

    fun disposeRuntime() {
        try {
            nativeSipManager?.dispose()
        } catch (error: Throwable) {
            Log.e(TAG, "disposeRuntime failed: ${error.message}", error)
        } finally {
            nativeSipManager = null
        }
    }

    private fun ensureManager(): NativeSipManager {
        nativeSipManager?.let { return it }

        val context = requireContext()
        val createdManager = NativeSipManager(context)
        createdManager.setEventListener(::handleManagerEvent)
        createdManager.initialize()
        nativeSipManager = createdManager
        return createdManager
    }

    private fun handleManagerEvent(event: HashMap<String, Any?>) {
        Log.d(TAG, "handleManagerEvent: $event")
        updateSnapshotFromEvent(event)
        dispatchBridgeEvent(event)
    }

    private fun dispatchBridgeEvent(event: HashMap<String, Any?>) {
        appendDiagnosticEvent(event)
        mainHandler.post {
            try {
                flutterEventSink?.success(event)
            } catch (error: Throwable) {
                Log.e(TAG, "Flutter event dispatch failed: ${error.message}", error)
            }
            bridgeObservers.toList().forEach { observer ->
                try {
                    observer.invoke(HashMap(event))
                } catch (error: Throwable) {
                    Log.e(TAG, "Bridge observer failed: ${error.message}", error)
                }
            }
        }
    }

    @Synchronized
    private fun appendDiagnosticEvent(event: HashMap<String, Any?>) {
        val context = appContext ?: return
        try {
            val diagnosticPrefs =
                context.getSharedPreferences(DIAGNOSTIC_PREFS, Context.MODE_PRIVATE)
            val array = JSONArray(diagnosticPrefs.getString(KEY_DIAGNOSTIC_LOGS, "[]") ?: "[]")
            val details = JSONObject()
            event.forEach { (key, value) ->
                if (key != "type") details.put(key, value ?: JSONObject.NULL)
            }
            array.put(
                JSONObject()
                    .put("timestamp", System.currentTimeMillis() / 1000.0)
                    .put("event", event["type"]?.toString() ?: "native")
                    .put("details", details)
            )
            while (array.length() > MAX_DIAGNOSTIC_LOGS) array.remove(0)
            diagnosticPrefs.edit().putString(KEY_DIAGNOSTIC_LOGS, array.toString()).apply()
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to append SIP diagnostic event: ${error.message}")
        }
    }

    private fun updateSnapshotFromEvent(event: HashMap<String, Any?>) {
        when (event["type"]?.toString()) {
            "registration" -> {
                val previousState = currentSnapshot["registrationState"]?.toString()
                val incomingState = event["state"]?.toString() ?: "disconnected"
                val isRegisteredRefresh =
                    previousState == "registered" && incomingState == "registering"
                if (!isRegisteredRefresh) {
                    currentSnapshot["registrationState"] = incomingState
                    currentSnapshot["message"] = event["message"]
                }
            }
            "call" -> {
                val callState = event["state"]?.toString() ?: "idle"
                val previousCallState = currentSnapshot["callState"]?.toString()
                if (isActiveCallState(callState) && !isActiveCallState(previousCallState)) {
                    ensureActiveCallUiRequestId()
                } else if (!isActiveCallState(callState)) {
                    clearCallUiRequestState(clearActiveRequest = true)
                }
                if (callState == "incoming" && previousCallState != "incoming") {
                    incomingAnswerPending = false
                } else if (callState == "in_call" || callState == "ended" ||
                    callState == "failed" || callState == "idle"
                ) {
                    incomingAnswerPending = false
                }
                currentSnapshot["callState"] = callState
                currentSnapshot["message"] = event["message"]
                currentSnapshot["remoteIdentity"] = if (
                    callState == "ended" || callState == "failed" || callState == "idle"
                ) {
                    null
                } else {
                    event["remoteIdentity"]
                }
                currentSnapshot["muted"] = event["muted"] ?: false
                currentSnapshot["speakerOn"] = event["speakerOn"] ?: false
            }
            "native" -> {
                currentSnapshot["message"] = event["state"]
            }
            "app_visibility" -> {
                currentSnapshot["appForeground"] = event["appForeground"] ?: false
            }
        }

        currentSnapshot["persistentEnabled"] = isPersistentEnabled()
    }

    private fun isActiveCallState(callState: String?): Boolean {
        return callState == "incoming" ||
            callState == "calling" ||
            callState == "ringing" ||
            callState == "in_call"
    }

    private fun newCallUiRequestId(): Long {
        val now = System.currentTimeMillis()
        return if (now > 0L) now else 1L
    }

    private fun ensureActiveCallUiRequestId(): Long {
        val context = appContext ?: return 0L
        val flags = context.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
        val existing = flags.getLong(KEY_ACTIVE_CALL_UI_REQUEST_ID, 0L)
        if (existing > 0L) return existing

        val requestId = newCallUiRequestId()
        flags.edit().putLong(KEY_ACTIVE_CALL_UI_REQUEST_ID, requestId).apply()
        return requestId
    }

    private fun clearCallUiRequestState(clearActiveRequest: Boolean) {
        val flags = appContext
            ?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
            ?: return
        flags.edit().apply {
            remove(KEY_PENDING_CALL_UI_OPEN)
            remove(KEY_PENDING_CALL_UI_REQUEST_ID)
            if (clearActiveRequest) {
                remove(KEY_ACTIVE_CALL_UI_REQUEST_ID)
            }
        }.apply()
    }

    private fun persistConfig(config: NativeSipStoredConfig) {
        getPrefs()?.edit()?.apply {
            putString(KEY_SERVER, config.server)
            putString(KEY_LOGIN, config.login)
            putString(KEY_PASSWORD, config.password)
            putInt(KEY_PORT, config.port)
            putString(KEY_TRANSPORT, config.transport)
            putString(KEY_AUTH_USER, config.authUser)
            putBoolean(KEY_ENABLED, config.enabled)
        }?.apply()

        // Зеркалим флаг в незашифрованные prefs для isPersistentEnabled().
        // Encrypted prefs нечитаемы через обычный getSharedPreferences().
        writePlainFlag(config.enabled)
        currentSnapshot["persistentEnabled"] = config.enabled
    }

    private fun updateEnabled(enabled: Boolean) {
        getPrefs()?.edit()?.putBoolean(KEY_ENABLED, enabled)?.apply()
        writePlainFlag(enabled)
        currentSnapshot["persistentEnabled"] = enabled
    }

    private fun markRegistrationStarting(message: String) {
        currentSnapshot["registrationState"] = "registering"
        currentSnapshot["message"] = message
        currentSnapshot["persistentEnabled"] = true
    }

    private fun isSameConfig(
        left: NativeSipStoredConfig?,
        right: NativeSipStoredConfig,
    ): Boolean {
        if (left == null) return false
        return left.server == right.server &&
            left.login == right.login &&
            left.password == right.password &&
            left.port == right.port &&
            left.transport.equals(right.transport, ignoreCase = true) &&
            left.authUser == right.authUser
    }

    /**
     * Записывает флаг enabled в отдельный НЕЗАШИФРОВАННЫЙ файл.
     * Это единственный способ надёжно прочитать его из boot receiver,
     * alarm receiver и других мест где EncryptedSharedPreferences может
     * быть недоступен (устройство заблокировано, холодный старт).
     */
    private fun writePlainFlag(enabled: Boolean) {
        try {
            appContext
                ?.getSharedPreferences(PLAIN_FLAGS_PREFS, Context.MODE_PRIVATE)
                ?.edit()
                ?.putBoolean(KEY_ENABLED, enabled)
                ?.apply()
        } catch (_: Throwable) {}
    }

    private fun getPrefs(): SharedPreferences? {
        prefs?.let { return it }

        val context = appContext ?: return null
        prefs = try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
        } catch (error: Throwable) {
            Log.w(
                TAG,
                "EncryptedSharedPreferences unavailable, using default SharedPreferences: ${error.message}",
                error,
            )
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }

        return prefs
    }

    private fun requireContext(): Context {
        return requireNotNull(appContext) {
            "NativeSipBridge is not initialized"
        }
    }
}
