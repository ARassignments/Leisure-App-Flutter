package com.example.yetoexplore

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.whatsapp/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendPdfToWhatsApp" -> {
                        val filePath = call.argument<String>("filePath")
                        val contact = call.argument<String>("contact")
                        if (filePath != null && contact != null) {
                            sendPdfToWhatsApp(filePath, contact)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENTS", "Missing file path or contact", null)
                        }
                    }

                    "sendImageToWhatsApp" -> {
                        val filePath = call.argument<String>("filePath")
                        val phone = call.argument<String>("phone")
                        if (filePath != null && phone != null) {
                            sendImageToWhatsApp(filePath, phone)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGS", "File path or phone missing", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun sendPdfToWhatsApp(filePath: String, contact: String) {
        val file = File(filePath)
        val uri: Uri = FileProvider.getUriForFile(
            this,
            applicationContext.packageName + ".provider",
            file
        )

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            setPackage("com.whatsapp")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        startActivity(intent)
    }

    private fun sendImageToWhatsApp(filePath: String, phone: String) {
        val file = File(filePath)
        val uri: Uri = FileProvider.getUriForFile(
            this,
            applicationContext.packageName + ".fileprovider",
            file
        )

        val jid = "${phone.replace("+", "").replace(" ", "")}@s.whatsapp.net"

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/*"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra("jid", jid) // 👈 direct target
            setPackage("com.whatsapp")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivity(shareIntent)
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

}
