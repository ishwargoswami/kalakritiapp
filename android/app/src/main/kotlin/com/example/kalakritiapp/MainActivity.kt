package com.example.kalakritiapp

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This line explicitly allows screenshots (removes FLAG_SECURE if present)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
