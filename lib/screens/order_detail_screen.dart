import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yetoexplore/components/appsnackbar.dart';
import '/theme/theme.dart';
import '../components/loading_screen.dart';
import '../responses/order_detail_response.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isDownloading = false;

  /// 🔹 Capture current screen as PNG bytes
  Future<Uint8List> _capturePng() async {
    RenderRepaintBoundary boundary =
        _screenshotKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// 🔹 For Mobile (Android/iOS)
  Future<void> _downloadReceiptMobile() async {
    try {
      final pngBytes = await _capturePng();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(pwImage)),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/order_${widget.orderId}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(filePath),
      ], text: "Order #${widget.orderId}");
    } catch (e) {
      AppSnackBar.show(
        context,
        message: "Error saving receipt: $e",
        type: AppSnackBarType.error,
      );
    }
  }

  /// 🔹 For Web
  Future<void> _downloadReceiptWeb() async {
    try {
      final pngBytes = await _capturePng();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(pwImage)),
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: "order_${widget.orderId}.pdf",
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: "Error saving receipt: $e",
        type: AppSnackBarType.error,
      );
    }
  }

  /// 🔹 Button Handler
  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true); // Start loading
    try {
      if (kIsWeb) {
        await _downloadReceiptWeb();
      } else {
        await _downloadReceiptMobile();
      }
    } finally {
      setState(() => _isDownloading = false); // Stop loading
    }
  }

  Future<void> _sharePdfMobile() async {
    try {
      final pngBytes = await _capturePng();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(pwImage)),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/order_${widget.orderId}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // 🔹 Open share dialog (user can select WhatsApp, Email, etc.)
      await Share.shareXFiles([
        XFile(filePath),
      ], text: "Order #${widget.orderId} receipt");
    } catch (e) {
      AppSnackBar.show(
        context,
        message: "Error sharing receipt: $e",
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _sharePdfWeb() async {
    try {
      final pngBytes = await _capturePng();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(pwImage)),
        ),
      );

      // Download first
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: "order_${widget.orderId}.pdf",
      );

      // 🔹 Optionally open WhatsApp Web
      final Uri whatsappUri = Uri.parse("https://wa.me/");
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppSnackBar.show(
        context,
        message: "Error sharing receipt: $e",
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isDownloading = true);
    try {
      if (kIsWeb) {
        await _sharePdfWeb();
      } else {
        await _sharePdfMobile();
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  late Future<OrderDetailResponse> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = ApiService.getOrderDetail(widget.orderId);
  }

  String _formatDate(String dateString) {
    try {
      final inputFormat = DateFormat("dd/MMM/yyyy");
      final dateTime = inputFormat.parse(dateString);
      final outputFormat = DateFormat("MMMM dd, yyyy");
      return outputFormat.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String formatInternationalPhone(String number) {
    if (number.startsWith("3")) {
      return "+92 ${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}";
    }
    return number;
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      AppSnackBar.show(
        context,
        message: "Cannot launch dialer",
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, BuildContext context) async {
    final String formattedNumber = phoneNumber
        .replaceAll("+", "")
        .replaceAll(" ", "");
    final Uri whatsappUri = Uri.parse("https://wa.me/$formattedNumber");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackBar.show(
        context,
        message: "Cannot open WhatsApp",
        type: AppSnackBarType.error,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "paid":
        return Colors.green;
      case "inprogress":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return HugeIconsSolid.clock01;
      case "paid":
        return HugeIconsSolid.checkmarkCircle01;
      case "inprogress":
        return HugeIconsSolid.loading02;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderDetailResponse>(
      future: _futureDetail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: LoadingLogo()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final detail = snapshot.data!;
        final order = detail.orderDetails.first;
        final items = detail.orderItems;
        final numberCheck =
            order.Contact.toString() == "00" || order.Contact.toString() == "0";

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: Text(
              "Order Detail",
              style: AppTheme.textTitle(
                context,
              ).copyWith(fontSize: 20, fontFamily: AppFontFamily.poppinsLight),
            ),
            leading: IconButton(
              icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                onPressed: _isDownloading ? null : _handleShare,
                icon: const Icon(HugeIconsStroke.pdf01, size: 20),
              ),
              if (!numberCheck)
                PopupMenuButton<String>(
                  color: AppTheme.cardDarkBg(context),
                  elevation: 10,
                  shadowColor: Colors.black26,
                  icon: const Icon(
                    HugeIconsStroke.moreVerticalCircle01,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == "call") {
                      _makePhoneCall(order.Contact, context);
                    } else if (value == "whatsapp") {
                      _openWhatsApp(order.Contact, context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: "call",
                      child: Row(
                        children: [
                          Icon(HugeIconsStroke.call02, size: 18),
                          SizedBox(width: 8),
                          Text("Call", style: AppTheme.textLabel(context)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "whatsapp",
                      child: Row(
                        children: [
                          Icon(
                            HugeIconsStroke.whatsapp,
                            size: 18,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Call via WhatsApp",
                            style: AppTheme.textLabel(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _screenshotKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg(context),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        HugeIconsStroke.userAccount,
                                        size: 18,
                                        color: AppTheme.iconColor(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "ID# ${order.RefNo}",
                                        style: AppTheme.textLabel(
                                          context,
                                        ).copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        order.OrderStatus,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(order.OrderStatus),
                                          size: 12,
                                          color: _getStatusColor(
                                            order.OrderStatus,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.OrderStatus,
                                          style: AppTheme.textLink(context)
                                              .copyWith(
                                                fontSize: 10,
                                                color: _getStatusColor(
                                                  order.OrderStatus,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.UserName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.textTitle(
                                  context,
                                ).copyWith(fontSize: 20),
                              ),
                              SizedBox(height: 10),
                              if (!numberCheck)
                                Row(
                                  children: [
                                    Icon(
                                      HugeIconsStroke.call02,
                                      size: 15,
                                      color: AppTheme.iconColorTwo(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatInternationalPhone(order.Contact),
                                      style: AppTheme.textSearchInfoLabeled(
                                        context,
                                      ).copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              if (!order.Address.toString().contains("Null"))
                                Row(
                                  children: [
                                    Icon(
                                      HugeIconsStroke.mapsLocation02,
                                      size: 15,
                                      color: AppTheme.iconColorTwo(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.Address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.textSearchInfoLabeled(
                                          context,
                                        ).copyWith(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // White Card for Amount + Date
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDarkBg(context),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Total Due",
                                          style: AppTheme.textSearchInfo(
                                            context,
                                          ).copyWith(fontSize: 12),
                                        ),
                                        Text(
                                          "Rs ${NumberFormat('#,###.##').format(order.TotalAmount)}",
                                          style: AppTheme.textTitle(context)
                                              .copyWith(
                                                fontSize: 22,
                                                fontFamily:
                                                    AppFontFamily.poppinsMedium,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatDate(order.OrderDate),
                                          style: AppTheme.textSearchInfoLabeled(
                                            context,
                                          ).copyWith(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        // 🔹 Order Items + Charges
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: List.generate(items.length, (index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(
                                    (index + 1).toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontFamily: AppFontFamily.poppinsMedium,
                                    ),
                                  ),
                                  title: Text(
                                    item.ProductName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.textLabel(context).copyWith(
                                      fontFamily: AppFontFamily.poppinsSemiBold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      const Icon(
                                        HugeIconsStroke.package,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Qty: ${item.Quantity.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          fontFamily:
                                              AppFontFamily.poppinsRegular,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        HugeIconsStroke.money01,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Rate: Rs ${NumberFormat('#,###.##').format(item.Price)}",
                                        style: const TextStyle(
                                          fontFamily:
                                              AppFontFamily.poppinsRegular,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    "Rs ${NumberFormat('#,###.##').format(item.TotalPrice)}",
                                    style:
                                        AppTheme.textSearchInfoLabeled(
                                          context,
                                        ).copyWith(
                                          fontSize: 12,
                                          fontFamily: AppFontFamily.poppinsBold,
                                        ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Divider(color: AppTheme.dividerBg(context)),
                              _buildSummaryRow(
                                "Subtotal",
                                order.SubTotal,
                                HugeIconsStroke.nodeAdd,
                              ),
                              _buildSummaryRow(
                                "Sales Tax",
                                order.SalesTax,
                                HugeIconsStroke.saleTag02,
                              ),
                              _buildSummaryRow(
                                "Discount",
                                order.Discount,
                                HugeIconsStroke.discountTag02,
                              ),
                              Divider(color: AppTheme.dividerBg(context)),
                              _buildSummaryRow(
                                "Total Amount",
                                order.TotalAmount,
                                HugeIconsStroke.moneyAdd02,
                                isBold: true,
                              ),
                              _buildSummaryRow(
                                "Paid",
                                order.Paid,
                                HugeIconsStroke.notebook01,
                              ),
                              _buildSummaryRow(
                                "Balance",
                                order.Balance,
                                HugeIconsStroke.invoice03,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔹 Bottom Button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: FlatButton(
                  text: "Download Reciept",
                  icon: HugeIconsSolid.download03,
                  disabled: _isDownloading ? true : false,
                  loading: _isDownloading ? true : false,
                  onPressed: _isDownloading ? null : _handleDownload,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String title,
    double value,
    IconData icon, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.iconColor(context)),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTheme.textLabel(context).copyWith(
                  fontFamily: isBold
                      ? AppFontFamily.poppinsSemiBold
                      : AppFontFamily.poppinsRegular,
                ),
              ),
            ],
          ),
          Text(
            "Rs ${NumberFormat('#,###.##').format(value).toString().padRight(1, '0')}",
            style: AppTheme.textLabel(context).copyWith(
              fontFamily: isBold
                  ? AppFontFamily.poppinsSemiBold
                  : AppFontFamily.poppinsRegular,
            ),
          ),
        ],
      ),
    );
  }
}
