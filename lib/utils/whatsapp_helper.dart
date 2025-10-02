import 'package:flutter/services.dart';

class WhatsAppHelper {
  static const platform = MethodChannel("com.example.whatsapp/share");

  static Future<void> sendImageToWhatsApp(String filePath, String phone) async {
    try {
      await platform.invokeMethod("sendImageToWhatsApp", {
        "filePath": filePath,
        "phone": phone,
      });
    } catch (e) {
      print("Error sending Image: $e");
    }
  }
}
