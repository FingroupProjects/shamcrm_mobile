package com.softtech.crm_task_manager

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    
    private val CHANNEL = "com.softtech.crm_task_manager/widget"
    private var methodChannel: MethodChannel? = null
    
    // Store pending navigation for when Flutter isn't ready yet
    private var pendingScreenIdentifier: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ Edge-to-edge для Android 15+
        if (Build.VERSION.SDK_INT >= 35) {
            enableEdgeToEdge()
        }
        
        // Обработка интента от виджета
        handleWidgetIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Создаём MethodChannel для связи с Flutter
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        // Handle method calls from Flutter
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    updateWidget()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        Log.d("MainActivity", "MethodChannel configured")
        
        // Send pending navigation if any
        pendingScreenIdentifier?.let { screen ->
            sendScreenToFlutter(screen)
            pendingScreenIdentifier = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent?) {
        intent?.let {
            val screenIdentifier = it.getStringExtra("screen_identifier")
            
            Log.d("MainActivity", "Widget intent received: screen=$screenIdentifier")
            
            if (!screenIdentifier.isNullOrEmpty()) {
                if (methodChannel != null) {
                    // Flutter is ready, send immediately
                    sendScreenToFlutter(screenIdentifier)
                } else {
                    // Flutter not ready yet, store for later
                    pendingScreenIdentifier = screenIdentifier
                    Log.d("MainActivity", "Stored pending navigation: $screenIdentifier")
                }
            }
        }
    }
    
    private fun sendScreenToFlutter(screenIdentifier: String) {
        methodChannel?.invokeMethod("navigateFromWidget", mapOf(
            "screen" to screenIdentifier
        ))
        
        Log.d("MainActivity", "Sent to Flutter: screen=$screenIdentifier")
    }
    
    private fun updateWidget() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val widgetComponent = ComponentName(this, ShamCRMWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)
            
            if (widgetIds.isNotEmpty()) {
                // Send broadcast to update all widget instances
                val intent = Intent(this, ShamCRMWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                }
                sendBroadcast(intent)
                
                Log.d("MainActivity", "Widget update triggered for ${widgetIds.size} widgets")
            } else {
                Log.d("MainActivity", "No widgets to update")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating widget: ${e.message}", e)
        }
    }
}