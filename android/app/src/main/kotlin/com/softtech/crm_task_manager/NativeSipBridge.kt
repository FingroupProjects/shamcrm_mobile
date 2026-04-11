package com.softtech.crm_task_manager

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.EventChannel

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
    private var currentSnapshot = hashMapOf<String, Any?>(
        "registrationState" to "disconnected",
        "callState" to "idle",
        "remoteIdentity" to null,
        "message" to null,
        "muted" to false,
        "speakerOn" to false,
        "persistentEnabled" to false,
        "systemAlertWindowGranted" to true,
    )

    private fun startRuntimeServiceIfPossible(reason: String) {
        val context = appContext ?: return
        val started = NativeSipForegroundService.start(context)
        if (!started) {
            currentSnapshot["message"] = "Foreground SIP service was not started: $reason"
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
    }

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

        persistConfig(
            NativeSipStoredConfig(
                server = trimmedServer,
                login = trimmedLogin,
                password = password,
                port = port,
                transport = transport,
                authUser = trimmedAuthUser,
                enabled = true,
            ),
        )

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

        val registrationState = currentSnapshot["registrationState"]?.toString()
        if (registrationState == "registered" || registrationState == "registering") {
            return true
        }

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
        }

        return success
    }

    fun unregister() {
        val context = requireContext()
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
        startRuntimeServiceIfPossible("acceptCall")
        return ensureManager().acceptCall()
    }

    fun declineCall(): Boolean {
        return ensureManager().declineCall()
    }

    fun hangup(): Boolean {
        return ensureManager().hangup()
    }

    fun setMuted(muted: Boolean): Boolean {
        return ensureManager().setMuted(muted)
    }

    fun setSpeaker(enabled: Boolean): Boolean {
        return ensureManager().setSpeaker(enabled)
    }

    fun onAppForeground() {
        nativeSipManager?.onAppForeground()
    }

    fun onAppBackground() {
        nativeSipManager?.onAppBackground()
    }

    fun getStateSnapshot(): HashMap<String, Any?> {
        currentSnapshot["persistentEnabled"] = isPersistentEnabled()
        currentSnapshot["systemAlertWindowGranted"] = checkSystemAlertWindowPermission()
        return HashMap(currentSnapshot)
    }

    private fun checkSystemAlertWindowPermission(): Boolean {
        val context = appContext ?: return true
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.provider.Settings.canDrawOverlays(context)
        } else {
            true
        }
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
        updateSnapshotFromEvent(event)

        mainHandler.post {
            flutterEventSink?.success(event)
            bridgeObservers.toList().forEach { observer ->
                observer.invoke(HashMap(event))
            }
        }
    }

    private fun updateSnapshotFromEvent(event: HashMap<String, Any?>) {
        when (event["type"]?.toString()) {
            "registration" -> {
                currentSnapshot["registrationState"] = event["state"]?.toString() ?: "disconnected"
                currentSnapshot["message"] = event["message"]
            }
            "call" -> {
                val callState = event["state"]?.toString() ?: "idle"
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
        }

        currentSnapshot["persistentEnabled"] = isPersistentEnabled()
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
