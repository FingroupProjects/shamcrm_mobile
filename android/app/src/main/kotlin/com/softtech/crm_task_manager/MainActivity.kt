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
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    
    private val CHANNEL = "com.softtech.crm_task_manager/widget"
    private val NETWORK_EVENT_CHANNEL = "com.shamcrm/network_status"
    
    private var methodChannel: MethodChannel? = null
    private var networkEventChannel: EventChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private var networkEventSink: EventChannel.EventSink? = null
    private val connectivityManager by lazy {
        getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }
    
    // ✅ Отслеживаем есть ли ХОТЬ ОДНА сеть
    private var hasAnyNetwork = false
    
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
        
        Log.d("MainActivity", "=== onCreate ===")

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
}