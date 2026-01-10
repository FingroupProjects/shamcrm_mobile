package com.softtech.crm_task_manager

import android.os.Build
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ Новый способ работы с edge-to-edge в Android 15+
        if (Build.VERSION.SDK_INT >= 35) {
            enableEdgeToEdge()
        }
    }
}
