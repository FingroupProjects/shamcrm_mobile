package com.softtech.crm_task_manager

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    
    private val CHANNEL = "com.softtech.crm_task_manager/widget"
    private var methodChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    
    companion object {
        private const val PREFS_NAME = "WidgetNavigation"
        private const val KEY_PENDING_SCREEN = "pending_screen"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "=== onCreate ===")
        Log.d("MainActivity", "Intent: $intent")
        Log.d("MainActivity", "Intent extras: ${intent?.extras}")
        Log.d("MainActivity", "Intent action: ${intent?.action}")
        Log.d("MainActivity", "screen_identifier extra: ${intent?.getStringExtra("screen_identifier")}")

        // ✅ Edge-to-edge для Android 15+
        if (Build.VERSION.SDK_INT >= 35) {
            enableEdgeToEdge()
        }
        
        // Store widget navigation in SharedPreferences for Flutter to read
        handleWidgetIntent(intent)
        
        // If app is cold-started from widget, send navigation to Flutter after engine is ready
        val screenIdentifier = intent?.getStringExtra("screen_identifier")
        if (!screenIdentifier.isNullOrEmpty()) {
            Log.d("MainActivity", "onCreate: Scheduling sendScreenToFlutter for: $screenIdentifier")
            // Delay to ensure Flutter engine is ready
            handler.postDelayed({
                Log.d("MainActivity", "onCreate: Executing delayed sendScreenToFlutter for: $screenIdentifier")
                sendScreenToFlutter(screenIdentifier)
            }, 500) // Longer delay for cold start
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("MainActivity", "=== configureFlutterEngine ===")
        
        // Создаём MethodChannel для связи с Flutter
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        // Handle method calls from Flutter
        methodChannel?.setMethodCallHandler { call, result ->
            Log.d("MainActivity", "MethodChannel call: ${call.method}")
            when (call.method) {
                "updateWidget" -> {
                    updateWidget()
                    result.success(true)
                }
                "getPendingNavigation" -> {
                    val pending = getPendingNavigation()
                    Log.d("MainActivity", "getPendingNavigation called, returning: $pending")
                    clearPendingNavigation()
                    result.success(pending)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        Log.d("MainActivity", "MethodChannel configured")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        Log.d("MainActivity", "=== onNewIntent ===")
        Log.d("MainActivity", "Intent: $intent")
        Log.d("MainActivity", "Intent extras: ${intent.extras}")
        Log.d("MainActivity", "screen_identifier extra: ${intent.getStringExtra("screen_identifier")}")
        
        setIntent(intent)
        handleWidgetIntent(intent)
        
        // When app is already running, send navigation immediately with small delay
        val screenIdentifier = intent.getStringExtra("screen_identifier")
        if (!screenIdentifier.isNullOrEmpty()) {
            Log.d("MainActivity", "Scheduling sendScreenToFlutter for: $screenIdentifier")
            handler.postDelayed({
                Log.d("MainActivity", "Executing delayed sendScreenToFlutter for: $screenIdentifier")
                sendScreenToFlutter(screenIdentifier)
            }, 100)
        }
    }

    private fun handleWidgetIntent(intent: Intent?) {
        Log.d("MainActivity", "=== handleWidgetIntent ===")
        Log.d("MainActivity", "Intent is null: ${intent == null}")
        
        intent?.let {
            val screenIdentifier = it.getStringExtra("screen_identifier")
            
            Log.d("MainActivity", "Extracted screen_identifier: $screenIdentifier")
            Log.d("MainActivity", "All extras keys: ${it.extras?.keySet()?.toList()}")
            
            if (!screenIdentifier.isNullOrEmpty()) {
                // Store in SharedPreferences for Flutter to read on cold start
                savePendingNavigation(screenIdentifier)
                Log.d("MainActivity", "Saved pending navigation to SharedPrefs: $screenIdentifier")
                
                // Verify it was saved
                val verified = getPendingNavigation()
                Log.d("MainActivity", "Verified saved value: $verified")
            } else {
                Log.d("MainActivity", "screen_identifier is null or empty, not saving")
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
        Log.d("MainActivity", "Sent to Flutter: screen=$screenIdentifier")
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
                    
                    Log.d("MainActivity", "Widget update triggered for ${provider.simpleName} (${widgetIds.size} instances)")
                } else {
                    Log.d("MainActivity", "No widgets to update for ${provider.simpleName}")
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating widget: ${e.message}", e)
        }
    }
}