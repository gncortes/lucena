package com.gncortes.lucena

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Abre telas do sistema: a de texto para fala (as vozes do aparelho) e
        // a de notificações do Lucena.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lucena/system_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openTextToSpeech" -> result.success(
                        open("com.android.settings.TTS_SETTINGS") ||
                            open(Settings.ACTION_ACCESSIBILITY_SETTINGS) ||
                            open(Settings.ACTION_SETTINGS)
                    )
                    "openAppNotifications" -> result.success(
                        openNotifications() ||
                            open(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    .setData(Uri.fromParts("package", packageName, null))
                            )
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun open(action: String): Boolean = open(Intent(action))

    private fun open(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }

    private fun openNotifications(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            open(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            )
}
