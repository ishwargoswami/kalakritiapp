package com.example.kalakritiapp

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kalakritiapp/ar"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This line explicitly allows screenshots by removing FLAG_SECURE
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAr" -> {
                    try {
                        MultiObjectArActivity.launch(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AR_ERROR", "Failed to launch AR: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
