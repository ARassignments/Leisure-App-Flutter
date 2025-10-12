import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import '/components/dashed_divider.dart';
import '/utils/session_manager.dart';
import '/Models/customer_single_model.dart';
import '/Models/payment_model.dart';
import '/components/appsnackbar.dart';
import '/theme/theme.dart';
import '/components/loading_screen.dart';
import '/utils/whatsapp_helper.dart';

class PaymentReceiptBottomSheet {
  static Future<bool> _requestPermission() async {
    if (await Permission.storage.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  static Future<void> showRecieptPreview(
    BuildContext context,
    PaymentModel payment,
    String apiUrl,
    String fileName,
    CustomerSingleModel? customer,
    bool reciptPreview,
  ) async {
    if (reciptPreview) {
      Map<String, dynamic>? user = await SessionManager.getUser();
      if (kIsWeb) {
        try {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) {
              final date = DateFormat(
                'dd MMM yyyy',
              ).format(payment.PaymentDate);
              final amount = NumberFormat('#,###.00').format(payment.Payment);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Wrap(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /// Main Receipt Box
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              top: 0,
                              left: 0,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SvgPicture.asset(
                                    AppTheme.recieptBgImage(context),
                                    width: constraints.maxWidth,
                                    fit: BoxFit
                                        .fitWidth, // fill width, height auto
                                    alignment: Alignment.topCenter,
                                  );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.screenBg(context).withAlpha(0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  /// Header with logo & date
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              AppTheme.appLogo(context),
                                              width: 60,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Y2K",
                                              style:
                                                  AppTheme.textTitleActiveTwo(
                                                    context,
                                                  ).copyWith(
                                                    fontSize: 20,
                                                    fontFamily: AppFontFamily
                                                        .poppinsBold,
                                                  ),
                                            ),
                                            Text(
                                              "Solutions",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  AppTheme.textTitleActiveTwo(
                                                    context,
                                                  ).copyWith(
                                                    fontSize: 20,
                                                    fontFamily: AppFontFamily
                                                        .poppinsLight,
                                                  ),
                                            ),
                                            Text(
                                              ".",
                                              style: AppTheme.textTitleActive(
                                                context,
                                              ).copyWith(fontSize: 22),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        date,
                                        style:
                                            AppTheme.textSearchInfoLabeled(
                                              context,
                                            ).copyWith(
                                              fontSize: 13,
                                              fontFamily:
                                                  AppFontFamily.poppinsMedium,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "${DateFormat('MMMM').format(payment.PaymentDate)} ${payment.PaymentMode} Bill",
                                    style: AppTheme.textTitle(
                                      context,
                                    ).copyWith(fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(
                                    context,
                                    "Name",
                                    "${payment.UserName}",
                                  ),
                                  _infoRow(
                                    context,
                                    "Phone Number",
                                    "${customer!.PhoneNo}",
                                  ),
                                  _infoRow(
                                    context,
                                    "Address",
                                    "${customer!.Address}, ${customer!.CityName}, ${customer!.StateName}",
                                  ),
                                  _infoRow(context, "From", "01/10/2025"),
                                  _infoRow(context, "To", "11/10/2025"),
                                  _infoRow(
                                    context,
                                    "Payment Type",
                                    payment.PaymentType,
                                  ),
                                  _infoRow(
                                    context,
                                    "Payment Mode",
                                    payment.PaymentMode,
                                  ),
                                  const SizedBox(height: 16),
                                  DashedDivider(
                                    color: AppTheme.dividerBg(context),
                                    height: 2,
                                    dashWidth: 6,
                                    dashSpace: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  _amountRow(
                                    "Total Amount",
                                    "Rs. $amount",
                                    color: Colors.deepPurple,
                                  ),
                                  _amountRow(
                                    "Given Amount",
                                    "Rs. $amount",
                                    color: Colors.deepOrange,
                                  ),
                                ],
                              ),
                            ),

                            /// Watermark “PAID”
                            Opacity(
                              opacity: 0.05,
                              child: Image.asset(
                                payment.PaymentMode.toString().contains("Paid")
                                    ? AppTheme.paidRecieptImage(context)
                                    : AppTheme.receivedRecieptImage(context),
                                width: 220,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Buttons
                        FlatButton(
                          text: "Share Bill",
                          onPressed: () async {
                            final message = Uri.encodeComponent(
                              "📄 *Payment Receipt*\n"
                              "----------------------------------\n"
                              "💼 *Received From:* Abdur Rehman\n"
                              "📞 *Phone:* 03452418563\n"
                              "💳 *Payment Type:* ${payment.PaymentType}\n"
                              "💰 *Amount:* Rs. $amount\n"
                              "📅 *Date:* $date\n"
                              "----------------------------------\n"
                              "Thank you for your payment!",
                            );
                            final url = Uri.parse(
                              "https://wa.me/?text=$message",
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              AppSnackBar.show(
                                context,
                                message: "Unable to open WhatsApp",
                                type: AppSnackBarType.error,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlineErrorButton(
                          text: "Cancel",
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          AppSnackBar.show(
            context,
            message: "Web error: $e",
            type: AppSnackBarType.error,
          );
        }
        return;
      }
    } else {
      if (kIsWeb) {
        try {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Wrap(
                  children: [
                    Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Reciept Generated in PDF",
                          textAlign: TextAlign.center,
                          style: AppTheme.textLabel(context).copyWith(
                            fontSize: 16,
                            fontFamily: AppFontFamily.poppinsBold,
                          ),
                        ),
                        Divider(color: AppTheme.dividerBg(context)),
                        FlatButton(
                          text: "Open Reciept",
                          icon: HugeIconsSolid.linkSquare01,
                          onPressed: () {
                            html.window.open(apiUrl, "_blank");
                          },
                        ),
                        OutlineButton(
                          text: "Download Reciept",
                          icon: HugeIconsSolid.download03,
                          onPressed: () {
                            html.AnchorElement(href: apiUrl)
                              ..setAttribute("download", "$fileName.pdf")
                              ..click();
                          },
                        ),
                        CustomButton(
                          text: "Share to WhatsApp",
                          icon: HugeIconsSolid.whatsapp,
                          color: Colors.green.shade500,
                          onPressed: () {
                            String formatted = customer!.PhoneNo
                                .toString()
                                .replaceAll(" ", "");
                            if (formatted.startsWith("0")) {
                              formatted = formatted.substring(1);
                            }
                            final whatsappUrl =
                                "https://wa.me/92$formatted?text=Here%20is%20your%20payment%20receipt:%20$apiUrl";
                            html.window.open(whatsappUrl, "_blank");
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          AppSnackBar.show(
            context,
            message: "Web error: $e",
            type: AppSnackBarType.error,
          );
        }
        return;
      }
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Container(
            color: AppTheme.screenBg(context),
            child: const Center(child: LoadingLogo()),
          ),
        );

        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode != 200) {
          Navigator.pop(context);
          throw Exception("Failed to load PDF.");
        }

        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/$fileName.pdf";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        Navigator.pop(context);

        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          enableDrag: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Wrap(
                children: [
                  Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Reciept Generated in PDF",
                        textAlign: TextAlign.center,
                        style: AppTheme.textLabel(context).copyWith(
                          fontSize: 16,
                          fontFamily: AppFontFamily.poppinsBold,
                        ),
                      ),
                      Divider(color: AppTheme.dividerBg(context)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SizedBox(
                            height:
                                MediaQuery.of(context).size.height *
                                0.5, // adjust height
                            child: PDFView(
                              filePath: file.path,
                              fitEachPage: true,
                            ),
                          ),
                        ),
                      ),

                      FlatButton(
                        text: "Share Reciept",
                        icon: HugeIconsSolid.share01,
                        onPressed: () async {
                          await Share.shareXFiles([
                            XFile(file.path),
                          ], text: "Here is your PDF file");
                        },
                      ),
                      OutlineButton(
                        text: "Download Receipt",
                        icon: HugeIconsSolid.download03,
                        onPressed: () async {
                          if (await _requestPermission()) {
                            // ✅ Public Downloads directory
                            final downloadsDir =
                                await ExternalPath.getExternalStoragePublicDirectory(
                                  ExternalPath.DIRECTORY_DOWNLOAD,
                                );

                            final newPath = "$downloadsDir/$fileName.pdf";

                            try {
                              final newFile = await file.copy(newPath);

                              AppSnackBar.show(
                                context,
                                message: "PDF saved: ${newFile.path}",
                                type: AppSnackBarType.success,
                              );
                            } catch (e) {
                              AppSnackBar.show(
                                context,
                                message: "Error saving file: $e",
                                type: AppSnackBarType.error,
                              );
                            }
                          } else {
                            AppSnackBar.show(
                              context,
                              message: "Permission denied",
                              type: AppSnackBarType.error,
                            );
                          }
                        },
                      ),
                      Row(
                        spacing: 6,
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Share PDF",
                              icon: HugeIconsSolid.whatsapp,
                              color: Colors.green.shade500,
                              onPressed: () async {
                                String formatted = customer!.PhoneNo
                                    .toString()
                                    .replaceAll(" ", "");
                                if (formatted.startsWith("0")) {
                                  formatted = formatted.substring(1);
                                }
                                final whatsappUrl = Uri.parse(
                                  "https://wa.me/+92$formatted",
                                );

                                if (await canLaunchUrl(whatsappUrl)) {
                                  await WhatsAppHelper.sendPdfToWhatsApp(
                                    file.path,
                                    "92$formatted",
                                  );
                                } else {
                                  AppSnackBar.show(
                                    context,
                                    message: "WhatsApp not available",
                                    type: AppSnackBarType.error,
                                  );
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: CustomButton(
                              text: "Share Image",
                              icon: HugeIconsSolid.whatsapp,
                              color: Colors.green.shade500,
                              onPressed: () async {
                                final pdfDoc = await PdfDocument.openFile(
                                  file.path,
                                );
                                final page = await pdfDoc.getPage(1);

                                const scale = 3.5;
                                final pageImage = await page.render(
                                  width: (page.width * scale).toDouble(),
                                  height: (page.height * scale).toDouble(),
                                  format: PdfPageImageFormat.png,
                                  backgroundColor: '#FFFFFF',
                                );

                                if (pageImage != null) {
                                  final imageFile = File(
                                    "${dir.path}/$fileName.png",
                                  );
                                  await imageFile.writeAsBytes(pageImage.bytes);

                                  String formatted = customer!.PhoneNo
                                      .toString()
                                      .replaceAll(" ", "");
                                  if (formatted.startsWith("0")) {
                                    formatted = formatted.substring(1);
                                  }

                                  await WhatsAppHelper.sendImageToWhatsApp(
                                    imageFile.path,
                                    "92$formatted",
                                  );
                                }

                                await page.close();
                                await pdfDoc.close();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        Navigator.pop(context);
        AppSnackBar.show(
          context,
          message: "Error: $e",
          type: AppSnackBarType.error,
        );
      }
    }
  }

  // @override
  // Widget build(BuildContext context) {
  // final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
  // final amount = payment.Payment.toStringAsFixed(2);

  //   return DraggableScrollableSheet(
  //     expand: false,
  //     initialChildSize: 0.85,
  //     minChildSize: 0.5,
  //     maxChildSize: 0.95,
  //     builder: (_, controller) {
  //       return Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
  //         ),
  //         child: SingleChildScrollView(
  //           controller: controller,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             children: [
  //               Container(
  //                 width: 60,
  //                 height: 5,
  //                 margin: const EdgeInsets.only(bottom: 15),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey.shade300,
  //                   borderRadius: BorderRadius.circular(5),
  //                 ),
  //               ),

  //               /// Header with logo & date
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       const CircleAvatar(
  //                         backgroundColor: Color(0xFFE8EAF6),
  //                         radius: 18,
  //                         child: Icon(Icons.store, color: Colors.deepPurple),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       const Text(
  //                         "Saim Traders",
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.deepPurple,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   Text(
  //                     date,
  //                     style: const TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.black54,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               const Text(
  //                 "October Paid Bill",
  //                 style: TextStyle(
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.w600,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),

  //               /// Main Receipt Box
  //               Stack(
  //                 alignment: Alignment.center,
  //                 children: [
  //                   Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.all(18),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(16),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.grey.shade200,
  //                           spreadRadius: 1,
  //                           blurRadius: 8,
  //                         ),
  //                       ],
  //                     ),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         _infoRow("Name", "Abdur Rehman"),
  //                         _infoRow("Phone Number", "03452418563"),
  //                         _infoRow("From", "01/10/2025"),
  //                         _infoRow("To", "11/10/2025"),
  //                         _infoRow("Payment Type", payment.PaymentType),
  //                         _infoRow("Payment Mode", payment.PaymentMode),
  //                         const SizedBox(height: 8),
  //                         const Divider(),
  //                         _amountRow(
  //                           "Total Amount",
  //                           "Rs. $amount",
  //                           color: Colors.deepPurple,
  //                         ),
  //                         _amountRow(
  //                           "Balanced Amount",
  //                           "Rs. 0.0",
  //                           color: Colors.deepPurple,
  //                         ),
  //                         _amountRow(
  //                           "Given Amount",
  //                           "Rs. $amount",
  //                           color: Colors.deepOrange,
  //                         ),
  //                       ],
  //                     ),
  //                   ),

  //                   /// Watermark “PAID”
  //                   Opacity(
  //                     opacity: 0.1,
  //                     child: Text(
  //                       "PAID",
  //                       style: TextStyle(
  //                         fontSize: 100,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.deepPurple.shade200,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 20),

  //               /// Buttons
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.deepPurple,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   minimumSize: const Size(double.infinity, 50),
  //                 ),
  //                 onPressed: () async {
  //                   final message = Uri.encodeComponent(
  //                     "📄 *Payment Receipt*\n"
  //                     "----------------------------------\n"
  //                     "💼 *Received From:* Abdur Rehman\n"
  //                     "📞 *Phone:* 03452418563\n"
  //                     "💳 *Payment Type:* ${payment.PaymentType}\n"
  //                     "💰 *Amount:* Rs. $amount\n"
  //                     "📅 *Date:* $date\n"
  //                     "----------------------------------\n"
  //                     "Thank you for your payment!",
  //                   );
  //                   final url = Uri.parse("https://wa.me/?text=$message");
  //                   if (await canLaunchUrl(url)) {
  //                     await launchUrl(
  //                       url,
  //                       mode: LaunchMode.externalApplication,
  //                     );
  //                   } else {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                         content: Text("Unable to open WhatsApp"),
  //                       ),
  //                     );
  //                   }
  //                 },
  //                 child: const Text(
  //                   "Share Bill",
  //                   style: TextStyle(color: Colors.white, fontSize: 16),
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               OutlinedButton(
  //                 style: OutlinedButton.styleFrom(
  //                   minimumSize: const Size(double.infinity, 50),
  //                   side: const BorderSide(color: Colors.deepOrange),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text(
  //                   "Cancel",
  //                   style: TextStyle(color: Colors.deepOrange, fontSize: 16),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  static Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textSearchInfoLabeled(
              context,
            ).copyWith(fontSize: 13, fontFamily: AppFontFamily.poppinsMedium),
          ),
          Text(
            value,
            style: AppTheme.textTitle(
              context,
            ).copyWith(fontSize: 13, fontFamily: AppFontFamily.poppinsMedium),
          ),
        ],
      ),
    );
  }

  static Widget _amountRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
