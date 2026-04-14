package com.softtech.crm_task_manager

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
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
    
    private var methodChannel: MethodChannel? = null
    private var networkEventChannel: EventChannel? = null
    private var inAppUpdateMethodChannel: MethodChannel? = null
    private var inAppUpdateEventChannel: EventChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private var networkEventSink: EventChannel.EventSink? = null
    private var inAppUpdateEventSink: EventChannel.EventSink? = null
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

        if (Build.VERSION.SDK_INT >= 35) {
            enableEdgeToEdge()
        }
        
        handleWidgetIntent(intent)
        
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
        
        Log.d("MainActivity", "✅ Channels configured")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        setIntent(intent)
        handleWidgetIntent(intent)
        
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
        methodChannel?.invokeMethod("navigateFromWidget", mapOf(
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
