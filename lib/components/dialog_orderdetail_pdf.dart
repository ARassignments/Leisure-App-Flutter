import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import '/utils/whatsapp_helper.dart'; // ✅ for PDF to Image conversion

class PdfBottomSheet {
  static Future<void> showPdfPreview(
    BuildContext context,
    String apiUrl,
    String fileName,
    String contactNumber, // for WhatsApp
  ) async {
    try {
      // 🔽 Show loading dialog while fetching
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 🔽 Fetch PDF from API
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode != 200) {
        Navigator.pop(context); // close loader
        throw Exception("Failed to load PDF.");
      }

      // 📂 Save PDF to temporary storage
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$fileName.pdf";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      Navigator.pop(context); // close loader

      // 🔽 Show bottom sheet with PDF preview
      // ignore: use_build_context_synchronously
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // 📑 PDF Preview
                Expanded(child: PDFView(filePath: file.path)),

                // 🔘 Action Buttons
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Share PDF Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Share.shareXFiles([
                              XFile(file.path),
                            ], text: "Here is your PDF file");
                          },
                          icon: const Icon(Icons.share),
                          label: const Text("Share PDF"),
                        ),
                        const SizedBox(width: 10),

                        // Download Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final downloads = await getDownloadsDirectory();
                            if (downloads != null) {
                              final newPath = "${downloads.path}/$fileName.pdf";
                              await file.copy(newPath);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "PDF saved to Downloads folder",
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Download"),
                        ),
                        const SizedBox(width: 10),

                        // Share to WhatsApp (PDF)
                        ElevatedButton.icon(
                          onPressed: () async {
                            String formatted = contactNumber.replaceAll(
                              " ",
                              "",
                            );
                            if (formatted.startsWith("0")) {
                              formatted = formatted.substring(1);
                            }
                            final whatsappUrl = Uri.parse(
                              "https://wa.me/+92$formatted",
                            );

                            if (await canLaunchUrl(whatsappUrl)) {
                              await Share.shareXFiles([
                                XFile(file.path),
                              ], text: "Order Receipt");
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("WhatsApp not available"),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            HugeIconsSolid.whatsapp,
                            color: Colors.green,
                          ),
                          label: const Text("WhatsApp PDF"),
                        ),
                        const SizedBox(width: 10),

                        // 🚀 NEW: Share PDF as Image
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pdfDoc = await PdfDocument.openFile(
                              file.path,
                            );
                            final page = await pdfDoc.getPage(1);
                            final pageImage = await page.render(
                              width: page.width,
                              height: page.height,
                              format: PdfPageImageFormat.png,
                            );

                            if (pageImage != null) {
                              final imageFile = File(
                                "${dir.path}/$fileName.png",
                              );
                              await imageFile.writeAsBytes(pageImage.bytes);

                              String formatted = contactNumber.replaceAll(
                                " ",
                                "",
                              );
                              if (formatted.startsWith("0")) {
                                formatted = formatted.substring(1);
                              }

                              // 🔽 Call native Android method
                              await WhatsAppHelper.sendImageToWhatsApp(
                                imageFile.path,
                                "92$formatted",
                              );
                            }

                            await page.close();
                            await pdfDoc.close();
                          },
                          icon: const Icon(Icons.image, color: Colors.blue),
                          label: const Text("WhatsApp Image"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // close loader if error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
