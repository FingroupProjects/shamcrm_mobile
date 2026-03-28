package com.softtech.crm_task_manager

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
        
        Log.d("MainActivity", "MethodChannel configured")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent?) {
        intent?.let {
            val group = it.getIntExtra("group_index", -1)
            val screenIndex = it.getIntExtra("screen_index", -1)
            
            Log.d("MainActivity", "Widget intent received: group=$group, screen=$screenIndex")
            
            if (group != -1 && screenIndex != -1) {
                // Отправляем данные в Flutter
                sendToFlutter(group, screenIndex)
            }
        }
    }
    
    private fun sendToFlutter(group: Int, screenIndex: Int) {
        methodChannel?.invokeMethod("navigateFromWidget", mapOf(
            "group" to group,
            "screenIndex" to screenIndex
        ))
        
        Log.d("MainActivity", "Sent to Flutter: group=$group, screen=$screenIndex")
    }
}