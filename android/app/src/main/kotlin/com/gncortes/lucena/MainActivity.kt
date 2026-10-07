package com.gncortes.lucena

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Abre telas do sistema: a de texto para fala (as vozes do aparelho).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lucena/system_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openTextToSpeech" -> result.success(
                        open("com.android.settings.TTS_SETTINGS") ||
                            open(Settings.ACTION_ACCESSIBILITY_SETTINGS) ||
                            open(Settings.ACTION_SETTINGS)
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun open(action: String): Boolean = try {
        startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }
}
