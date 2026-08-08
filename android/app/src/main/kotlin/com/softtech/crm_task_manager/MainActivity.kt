package com.softtech.crm_task_manager

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.enableEdgeToEdge
import androidx.core.content.FileProvider
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    
    private val CHANNEL = "com.softtech.crm_task_manager/widget"
    private val NETWORK_EVENT_CHANNEL = "com.shamcrm/network_status"
    private val IN_APP_UPDATE_METHOD_CHANNEL = "com.shamcrm/in_app_update/methods"
    private val IN_APP_UPDATE_EVENT_CHANNEL = "com.shamcrm/in_app_update/events"
    private val NATIVE_SIP_METHOD_CHANNEL = "com.shamcrm/native_sip/methods"
    private val NATIVE_SIP_EVENT_CHANNEL = "com.shamcrm/native_sip/events"
    
    private var methodChannel: MethodChannel? = null
    private var networkEventChannel: EventChannel? = null
    private var inAppUpdateMethodChannel: MethodChannel? = null
    private var inAppUpdateEventChannel: EventChannel? = null
    private var nativeSipMethodChannel: MethodChannel? = null
    private var nativeSipEventChannel: EventChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private var networkEventSink: EventChannel.EventSink? = null
    private var inAppUpdateEventSink: EventChannel.EventSink? = null
    private var nativeSipEventSink: EventChannel.EventSink? = null
    private val connectivityManager by lazy {
        getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }
    private lateinit var appUpdateManager: AppUpdateManager
    private var updateListenerRegistered = false
    
    // ✅ Отслеживаем есть ли ХОТЬ ОДНА сеть
    private var hasAnyNetwork = false

    private val installStateUpdatedListener = InstallStateUpdatedListener { state ->
        val downloadedBytes = state.bytesDownloaded()
        val totalBytes = state.totalBytesToDownload()
        val progress = if (totalBytes > 0) {
            ((downloadedBytes * 100) / totalBytes).toInt()
        } else {
            0
        }

        when (state.installStatus()) {
            InstallStatus.PENDING -> sendInAppUpdateEvent("pending", 0, downloadedBytes, totalBytes)
            InstallStatus.DOWNLOADING -> sendInAppUpdateEvent("downloading", progress, downloadedBytes, totalBytes)
            InstallStatus.DOWNLOADED -> sendInAppUpdateEvent("downloaded", 100, downloadedBytes, totalBytes)
            InstallStatus.INSTALLING -> sendInAppUpdateEvent("installing", 100, downloadedBytes, totalBytes)
            InstallStatus.INSTALLED -> sendInAppUpdateEvent("installed", 100, downloadedBytes, totalBytes)
            InstallStatus.CANCELED -> sendInAppUpdateEvent("canceled", progress, downloadedBytes, totalBytes, "Обновление отменено.")
            InstallStatus.FAILED -> sendInAppUpdateEvent("failed", progress, downloadedBytes, totalBytes, "Не удалось загрузить обновление.")
            else -> Unit
        }
    }

    private val updateFlowLauncher = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        if (result.resultCode != RESULT_OK) {
            sendInAppUpdateEvent(
                "canceled",
                0,
                null,
                null,
                "Пользователь отменил обновление."
            )
        }
    }
    
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            Log.d("MainActivity", "🤖 Network AVAILABLE")
            hasAnyNetwork = true
            sendNetworkStatus(true)
        }
        
        override fun onLost(network: Network) {
            Log.d("MainActivity", "🤖 Network LOST")
            
            // ✅ КРИТИЧНО: Проверяем есть ли ДРУГИЕ сети
            handler.postDelayed({
                val hasOtherNetworks = checkHasAnyNetwork()
                Log.d("MainActivity", "🤖 Проверка других сетей: $hasOtherNetworks")
                
                if (!hasOtherNetworks) {
                    // ❌ НЕТ ВООБЩЕ НИКАКИХ СЕТЕЙ - показываем overlay
                    Log.d("MainActivity", "❌ НЕТ СЕТЕЙ - показываем overlay")
                    hasAnyNetwork = false
                    sendNetworkStatus(false)
                } else {
                    // ✅ Есть другие сети - всё ок
                    Log.d("MainActivity", "✅ Есть другие сети - всё ок")
                    hasAnyNetwork = true
                }
            }, 500) // Ждем 0.5 секунды чтобы система успела переключиться
        }
        
        override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
            // ✅ ИГНОРИРУЕМ ВАЛИДАЦИЮ - просто проверяем есть ли сеть
            val hasInternet = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            
            Log.d("MainActivity", "🤖 Capabilities: hasInternet=$hasInternet")
            
            if (hasInternet) {
                hasAnyNetwork = true
                // НЕ отправляем событие - пусть onAvailable/onLost управляют
            }
        }
    }
    
    companion object {
        private const val PREFS_NAME = "WidgetNavigation"
        private const val KEY_PENDING_SCREEN = "pending_screen"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // ✅ Фильтруем предупреждения BLASTBufferQueue из логов
        // Это предупреждение Android системы о буферах рендеринга, не критично
        // Устанавливаем уровень логирования для подавления избыточных предупреждений
        try {
            System.setProperty("log.tag.BLASTBufferQueue", "ASSERT") // ASSERT = самый высокий уровень, скрывает все
            System.setProperty("log.tag.SurfaceView", "ASSERT")
        } catch (e: Exception) {
            // Игнорируем ошибки при настройке фильтра
        }
        
        Log.d("MainActivity", "=== onCreate ===")
        appUpdateManager = AppUpdateManagerFactory.create(this)
        NativeSipBridge.initialize(applicationContext)

        if (Build.VERSION.SDK_INT >= 35) {
            enableEdgeToEdge()
        }
        
        handleWidgetIntent(intent)
        updateIncomingCallWindowMode(intent)
        handleSipNotificationAction(intent, "activity-create")
        handleSipCallIntent(intent, "activity-create")
        
        val screenIdentifier = intent?.getStringExtra("screen_identifier")
        if (!screenIdentifier.isNullOrEmpty()) {
            handler.postDelayed({
                sendScreenToFlutter(screenIdentifier)
            }, 500)
        }
        
        startNetworkMonitoring()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("MainActivity", "=== configureFlutterEngine ===")
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    updateWidget()
                    result.success(true)
                }
                "getPendingNavigation" -> {
                    val pending = getPendingNavigation()
                    clearPendingNavigation()
                    result.success(pending)
                }
                "shareExportFile" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title")
                    val text = call.argument<String>("text")
                    val mimeType =
                        call.argument<String>("mimeType") ?: "application/json"

                    if (path.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "Path is empty", null)
                    } else {
                        shareExportFile(path, title, text, mimeType, result)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        networkEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NETWORK_EVENT_CHANNEL
        )
        
        networkEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d("MainActivity", "✅ onListen called for network events")
                networkEventSink = events
                
                handler.post {
                    val hasNetwork = checkHasAnyNetwork()
                    events?.success(hasNetwork)
                    Log.d("MainActivity", "✅ Network event sink attached, hasNetwork: $hasNetwork")
                }
            }
            
            override fun onCancel(arguments: Any?) {
                Log.d("MainActivity", "✅ onCancel called for network events")
                networkEventSink = null
            }
        })

        inAppUpdateMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IN_APP_UPDATE_METHOD_CHANNEL
        )

        inAppUpdateMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> handleIsInAppUpdateSupported(result)
                "startFlexibleUpdate" -> startFlexibleUpdate(result)
                "completeFlexibleUpdate" -> completeFlexibleUpdate(result)
                else -> result.notImplemented()
            }
        }

        inAppUpdateEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IN_APP_UPDATE_EVENT_CHANNEL
        )

        inAppUpdateEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                inAppUpdateEventSink = events
                registerInstallStateListenerIfNeeded()
                emitDownloadedStateIfNeeded()
            }

            override fun onCancel(arguments: Any?) {
                inAppUpdateEventSink = null
            }
        })

        nativeSipMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NATIVE_SIP_METHOD_CHANNEL
        )

        nativeSipMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    result.success(true)
                }
                "register" -> {
                    val server = call.argument<String>("server")
                    val login = call.argument<String>("login")
                    val password = call.argument<String>("password")
                    val port = call.argument<Int>("port")
                    val transport = call.argument<String>("transport")
                    val authUser = call.argument<String>("authUser")

                    if (server.isNullOrBlank() ||
                        login.isNullOrBlank() ||
                        password.isNullOrBlank() ||
                        port == null ||
                        transport.isNullOrBlank()
                    ) {
                        result.error("INVALID_ARGS", "Missing native SIP registration args", null)
                    } else {
                        result.success(
                            NativeSipBridge.register(
                                server = server,
                                login = login,
                                password = password,
                                port = port,
                                transport = transport,
                                authUser = authUser,
                            )
                        )
                    }
                }
                "unregister" -> {
                    NativeSipBridge.unregister()
                    result.success(true)
                }
                "getStateSnapshot" -> {
                    result.success(NativeSipBridge.getStateSnapshot())
                }
                "getStoredConfig" -> {
                    result.success(NativeSipBridge.getStoredConfigForFlutter())
                }
                "getDiagnosticLogs" -> {
                    result.success(NativeSipBridge.getDiagnosticLogs())
                }
                "clearDiagnosticLogs" -> {
                    NativeSipBridge.clearDiagnosticLogs()
                    result.success(true)
                }
                "appendDiagnosticLog" -> {
                    val event = call.argument<String>("event")?.trim().orEmpty()
                    val rawDetails = call.argument<Map<String, Any?>>("details")
                    if (event.isEmpty()) {
                        result.error("INVALID_EVENT", "Diagnostic event is empty", null)
                    } else {
                        NativeSipBridge.recordDiagnosticEvent(
                            event = event,
                            details = HashMap(rawDetails ?: emptyMap()),
                        )
                        result.success(true)
                    }
                }
                "restoreRegistrationIfNeeded" -> {
                    result.success(NativeSipBridge.restoreRegistrationIfNeeded())
                }
                "consumePendingCallUiRequest" -> {
                    result.success(NativeSipBridge.consumePendingCallUiRequest())
                }
                "makeCall" -> {
                    val target = call.argument<String>("target")
                    if (target.isNullOrBlank()) {
                        result.error("INVALID_TARGET", "Target is empty", null)
                    } else {
                        result.success(NativeSipBridge.makeCall(target))
                    }
                }
                "acceptCall" -> result.success(NativeSipBridge.acceptCall())
                "declineCall" -> result.success(NativeSipBridge.declineCall())
                "hangup" -> {
                    val source = call.argument<String>("source")?.trim().orEmpty()
                    result.success(
                        NativeSipBridge.hangup(
                            source = source.ifEmpty { "flutter" },
                        ),
                    )
                }
                "setMuted" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    result.success(NativeSipBridge.setMuted(muted))
                }
                "sendDtmf" -> {
                    val tone = call.argument<String>("tone")
                    if (tone.isNullOrBlank()) {
                        result.error("INVALID_TONE", "DTMF tone is empty", null)
                    } else {
                        result.success(NativeSipBridge.sendDtmf(tone))
                    }
                }
                "setSpeaker" -> {
                    val speakerOn = call.argument<Boolean>("speakerOn") ?: false
                    result.success(NativeSipBridge.setSpeaker(speakerOn))
                }
                "getAudioRoutes" -> {
                    result.success(NativeSipBridge.getAudioRoutes())
                }
                "setAudioRoute" -> {
                    val deviceId = call.argument<String>("deviceId")?.trim().orEmpty()
                    if (deviceId.isEmpty()) {
                        result.error("INVALID_AUDIO_ROUTE", "Audio device id is empty", null)
                    } else {
                        result.success(NativeSipBridge.setAudioRoute(deviceId))
                    }
                }
                "requestBackgroundReliabilitySettings" -> {
                    result.success(requestBackgroundReliabilitySettings())
                }
                "requestIncomingCallFullScreenSettings" -> {
                    result.success(requestIncomingCallFullScreenSettings())
                }
                "openXiaomiSettings" -> {
                    result.success(openXiaomiSettings())
                }
                "dispose" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        nativeSipEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NATIVE_SIP_EVENT_CHANNEL
        )

        nativeSipEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                nativeSipEventSink = events
                NativeSipBridge.setFlutterEventSink(object : EventChannel.EventSink {
                    override fun success(event: Any?) {
                        handler.post {
                            nativeSipEventSink?.success(event)
                        }
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        handler.post {
                            nativeSipEventSink?.error(code, message, details)
                        }
                    }

                    override fun endOfStream() {
                        handler.post {
                            nativeSipEventSink?.endOfStream()
                        }
                    }
                })
            }

            override fun onCancel(arguments: Any?) {
                nativeSipEventSink = null
                NativeSipBridge.setFlutterEventSink(null)
            }
        })

        Log.d("MainActivity", "✅ Channels configured")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        setIntent(intent)
        handleWidgetIntent(intent)
        updateIncomingCallWindowMode(intent)
        handleSipNotificationAction(intent, "activity-new-intent")
        handleSipCallIntent(intent, "activity-new-intent")
        
        val screenIdentifier = intent.getStringExtra("screen_identifier")
        if (!screenIdentifier.isNullOrEmpty()) {
            handler.postDelayed({
                sendScreenToFlutter(screenIdentifier)
            }, 100)
        }
    }
    
    override fun onDestroy() {
        unregisterInstallStateListener()
        super.onDestroy()
        stopNetworkMonitoring()
    }

    override fun onResume() {
        super.onResume()
        NativeSipBridge.onAppForeground()
    }

    override fun onPause() {
        NativeSipBridge.onAppBackground()
        super.onPause()
    }

    // ✅ Network monitoring methods
    
    private fun startNetworkMonitoring() {
        try {
            val networkRequest = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()
            
            connectivityManager.registerNetworkCallback(networkRequest, networkCallback)
            Log.d("MainActivity", "✅ Network monitoring started")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Failed to start network monitoring: ${e.message}")
        }
    }
    
    private fun stopNetworkMonitoring() {
        try {
            connectivityManager.unregisterNetworkCallback(networkCallback)
            Log.d("MainActivity", "✅ Network monitoring stopped")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Failed to stop network monitoring: ${e.message}")
        }
    }

    private fun requestBackgroundReliabilitySettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (powerManager.isIgnoringBatteryOptimizations(packageName)) {
            return false
        }

        return try {
            startActivity(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            true
        } catch (error: Throwable) {
            Log.e(
                "MainActivity",
                "Failed to open background reliability settings: ${error.message}",
                error,
            )
            false
        }
    }

    private fun requestIncomingCallFullScreenSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return false
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        if (notificationManager.canUseFullScreenIntent()) {
            return false
        }

        return try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            true
        } catch (error: Throwable) {
            Log.e(
                "MainActivity",
                "Failed to open full-screen incoming-call settings: ${error.message}",
                error,
            )
            false
        }
    }

    private fun openXiaomiSettings(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val isXiaomiDevice = listOf(manufacturer, brand).any {
            it.contains("xiaomi") || it.contains("redmi") || it.contains("poco")
        }
        if (!isXiaomiDevice) {
            return false
        }

        val intents = listOf(
            Intent("miui.intent.action.OP_AUTO_START").apply {
                component = ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                )
            },
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            },
        )

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (error: Throwable) {
                Log.w("MainActivity", "Xiaomi settings intent unavailable", error)
            }
        }
        return false
    }

    private fun updateIncomingCallWindowMode(intent: Intent?) {
        val shouldWakeForCall = intent?.getBooleanExtra("open_sip_call", false) == true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(shouldWakeForCall)
            setTurnScreenOn(shouldWakeForCall)
        } else {
            if (shouldWakeForCall) {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                )
            } else {
                window.clearFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                )
            }
        }

        if (shouldWakeForCall) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun handleSipCallIntent(intent: Intent?, source: String) {
        if (intent?.getBooleanExtra("open_sip_call", false) != true) return
        intent.removeExtra("open_sip_call")
        val snapshot = NativeSipBridge.getStateSnapshot()
        val callState = snapshot["callState"]?.toString()
        NativeSipBridge.recordDiagnosticEvent(
            event = "call_ui_intent_received",
            details = hashMapOf(
                "source" to source,
                "callState" to callState,
                "registrationState" to snapshot["registrationState"],
            ),
        )
        val activeCall = callState == "incoming" ||
            callState == "calling" ||
            callState == "ringing" ||
            callState == "in_call"
        if (activeCall) {
            NativeSipBridge.requestFlutterCallUi(source)
        } else {
            NativeSipBridge.recordDiagnosticEvent(
                event = "call_ui_intent_ignored",
                details = hashMapOf(
                    "source" to source,
                    "callState" to callState,
                ),
            )
        }
    }

    private fun handleSipNotificationAction(intent: Intent?, source: String) {
        if (intent?.getStringExtra("sip_notification_action") != "answer" &&
            intent?.action != NativeSipActionReceiver.ACTION_ANSWER
        ) {
            return
        }
        intent.removeExtra("sip_notification_action")
        intent.action = null
        val accepted = NativeSipBridge.acceptCall()
        NativeSipBridge.recordDiagnosticEvent(
            event = if (accepted) "incoming_answered" else "incoming_answer_failed",
            details = hashMapOf(
                "source" to "notification-activity",
                "activitySource" to source,
            ),
        )
    }

    private fun checkHasAnyNetwork(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // ✅ Проверяем ВСЕ сети (WiFi, Mobile, Ethernet)
            val allNetworks = connectivityManager.allNetworks
            
            Log.d("MainActivity", "🔍 Всего сетей: ${allNetworks.size}")
            
            for (network in allNetworks) {
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                if (capabilities != null && 
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                    Log.d("MainActivity", "✅ Найдена сеть с интернетом")
                    return true
                }
            }
            
            Log.d("MainActivity", "❌ Нет сетей с интернетом")
            false
        } else {
            @Suppress("DEPRECATION")
            val networkInfo = connectivityManager.activeNetworkInfo
            @Suppress("DEPRECATION")
            networkInfo?.isConnected == true
        }
    }
    
    private fun sendNetworkStatus(hasNetwork: Boolean) {
        handler.post {
            networkEventSink?.success(hasNetwork)
            Log.d("MainActivity", "📡 Sent to Flutter: $hasNetwork")
        }
    }

    private fun handleIsInAppUpdateSupported(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener {
                result.success(true)
            }
            .addOnFailureListener { error ->
                Log.e("MainActivity", "In-app update unsupported: ${error.message}", error)
                result.success(false)
            }
    }

    private fun startFlexibleUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { appUpdateInfo ->
                val updateAvailable =
                    appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                val flexibleAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)

                if (!updateAvailable || !flexibleAllowed) {
                    sendInAppUpdateEvent(
                        "unavailable",
                        0,
                        null,
                        null,
                        "Встроенное обновление через Google Play недоступно."
                    )
                    result.success(false)
                    return@addOnSuccessListener
                }

                registerInstallStateListenerIfNeeded()

                try {
                    val started = appUpdateManager.startUpdateFlowForResult(
                        appUpdateInfo,
                        updateFlowLauncher,
                        AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build()
                    )

                    if (started) {
                        sendInAppUpdateEvent(
                            "pending",
                            0,
                            null,
                            null,
                            "Подготавливаем загрузку обновления..."
                        )
                    }

                    result.success(started)
                } catch (error: Exception) {
                    Log.e("MainActivity", "Failed to start flexible update: ${error.message}", error)
                    sendInAppUpdateEvent(
                        "failed",
                        0,
                        null,
                        null,
                        "Не удалось запустить обновление."
                    )
                    result.success(false)
                }
            }
            .addOnFailureListener { error ->
                Log.e("MainActivity", "Failed to check app update info: ${error.message}", error)
                sendInAppUpdateEvent(
                    "failed",
                    0,
                    null,
                    null,
                    "Не удалось проверить доступность обновления."
                )
                result.success(false)
            }
    }

    private fun completeFlexibleUpdate(result: MethodChannel.Result) {
        appUpdateManager.completeUpdate()
            .addOnSuccessListener {
                sendInAppUpdateEvent(
                    "installing",
                    100,
                    null,
                    null,
                    "Устанавливаем обновление..."
                )
                result.success(true)
            }
            .addOnFailureListener { error ->
                Log.e("MainActivity", "Failed to complete flexible update: ${error.message}", error)
                sendInAppUpdateEvent(
                    "failed",
                    100,
                    null,
                    null,
                    "Не удалось завершить установку обновления."
                )
                result.success(false)
            }
    }

    private fun registerInstallStateListenerIfNeeded() {
        if (updateListenerRegistered) {
            return
        }

        appUpdateManager.registerListener(installStateUpdatedListener)
        updateListenerRegistered = true
    }

    private fun unregisterInstallStateListener() {
        if (!updateListenerRegistered) {
            return
        }

        appUpdateManager.unregisterListener(installStateUpdatedListener)
        updateListenerRegistered = false
    }

    private fun emitDownloadedStateIfNeeded() {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { appUpdateInfo ->
                if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                    sendInAppUpdateEvent(
                        "downloaded",
                        100,
                        null,
                        null,
                        "Обновление загружено и готово к установке."
                    )
                }
            }
            .addOnFailureListener { error ->
                Log.e("MainActivity", "Failed to emit downloaded state: ${error.message}", error)
            }
    }

    private fun sendInAppUpdateEvent(
        status: String,
        progress: Int,
        downloadedBytes: Long?,
        totalBytes: Long?,
        message: String? = null
    ) {
        handler.post {
            val payload = hashMapOf<String, Any>(
                "status" to status,
                "progress" to progress
            )

            downloadedBytes?.let { payload["downloadedBytes"] = it.toInt() }
            totalBytes?.let { payload["totalBytes"] = it.toInt() }
            message?.let { payload["message"] = it }

            inAppUpdateEventSink?.success(payload)
        }
    }

    // ВАШ СУЩЕСТВУЮЩИЙ КОД (виджеты)
    
    private fun handleWidgetIntent(intent: Intent?) {
        intent?.let {
            val screenIdentifier = it.getStringExtra("screen_identifier")
            
            if (!screenIdentifier.isNullOrEmpty()) {
                savePendingNavigation(screenIdentifier)
            }
        }
    }

    private fun savePendingNavigation(screen: String) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PENDING_SCREEN, screen)
            .apply()
    }
    
    private fun getPendingNavigation(): String? {
        return getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_PENDING_SCREEN, null)
    }
    
    private fun clearPendingNavigation() {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_PENDING_SCREEN)
            .apply()
    }
    
    private fun sendScreenToFlutter(screenIdentifier: String) {
        val channel = methodChannel
        if (channel == null) {
            savePendingNavigation(screenIdentifier)
            return
        }

        channel.invokeMethod("navigateFromWidget", mapOf(
            "screen" to screenIdentifier
        ))
        clearPendingNavigation()
    }
    
    private fun updateWidget() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            
            val widgetProviders = listOf(
                ShamCRMWidgetProvider::class.java,
                ReferencesWidgetProvider::class.java,
                AccountingWidgetProvider::class.java
            )
            
            widgetProviders.forEach { provider ->
                val component = ComponentName(this, provider)
                val widgetIds = appWidgetManager.getAppWidgetIds(component)
            
                if (widgetIds.isNotEmpty()) {
                    val intent = Intent(this, provider).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                    }
                    sendBroadcast(intent)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating widget: ${e.message}", e)
        }
    }

    private fun shareExportFile(
        path: String,
        title: String?,
        text: String?,
        mimeType: String,
        result: MethodChannel.Result
    ) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                return
            }

            val authority = "${BuildConfig.APPLICATION_ID}.fileprovider"
            val uri = FileProvider.getUriForFile(this, authority, file)

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                if (!text.isNullOrEmpty()) {
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(shareIntent, title ?: "Share")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            result.success(true)
        } catch (e: Exception) {
            Log.e("MainActivity", "shareExportFile error: ${e.message}", e)
            result.error("SHARE_ERROR", e.message, null)
        }
    }
}
