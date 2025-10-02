package com.example.yetoexplore

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.whatsapp/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "sendPdfToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                val contact = call.argument<String>("contact")
                if (filePath != null && contact != null) {
                    sendPdfToWhatsApp(filePath, contact)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing file path or contact", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendPdfToWhatsApp(filePath: String, contact: String) {
        val file = File(filePath)
        val uri: Uri = FileProvider.getUriForFile(
            this,
            applicationContext.packageName + ".fileprovider",
            file
        )

        val intent = Intent(Intent.ACTION_SEND)
        intent.setType("application/pdf")
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.setPackage("com.whatsapp")

        // Optional: add specific contact if available
        // val jid = "92${contact}@s.whatsapp.net"
        // intent.putExtra("jid", jid) // requires permission by WhatsApp Business API

        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        startActivity(intent)
    }
}