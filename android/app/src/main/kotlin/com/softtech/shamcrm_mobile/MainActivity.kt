    package com.softtech.shamcrm_mobile

    import android.os.Build
    import android.os.Bundle
    import androidx.activity.enableEdgeToEdge
    import io.flutter.embedding.android.FlutterFragmentActivity

    class MainActivity : FlutterFragmentActivity() {
        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)

            // ✅ Новый API Android 15+
            if (Build.VERSION.SDK_INT >= 35) {
                enableEdgeToEdge()
            }
        }
    }
