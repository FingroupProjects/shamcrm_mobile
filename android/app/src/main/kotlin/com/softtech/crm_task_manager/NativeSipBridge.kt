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
            currentSnapshot["persistentEnabled"] = isPersistentEnabled()
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
        return HashMap(currentSnapshot)
    }

    fun isPersistentEnabled(): Boolean {
        val prefs = appContext?.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
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

        currentSnapshot["persistentEnabled"] = config.enabled
    }

    private fun updateEnabled(enabled: Boolean) {
        getPrefs()?.edit()?.putBoolean(KEY_ENABLED, enabled)?.apply()
        currentSnapshot["persistentEnabled"] = enabled
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
