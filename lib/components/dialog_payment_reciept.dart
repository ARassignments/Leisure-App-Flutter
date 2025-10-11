import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/Models/payment_model.dart';

class PaymentReceiptSheet extends StatelessWidget {
  final PaymentModel payment;
  const PaymentReceiptSheet({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final amount = payment.Payment.toStringAsFixed(2);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                /// Header with logo & date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE8EAF6),
                          radius: 18,
                          child: Icon(Icons.store, color: Colors.deepPurple),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Saim Traders",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "October Paid Bill",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                /// Main Receipt Box
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            spreadRadius: 1,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Name", "Abdur Rehman"),
                          _infoRow("Phone Number", "03452418563"),
                          _infoRow("From", "01/10/2025"),
                          _infoRow("To", "11/10/2025"),
                          _infoRow("Payment Type", payment.PaymentType),
                          _infoRow("Payment Mode", payment.PaymentMode),
                          const SizedBox(height: 8),
                          const Divider(),
                          _amountRow(
                            "Total Amount",
                            "Rs. $amount",
                            color: Colors.deepPurple,
                          ),
                          _amountRow(
                            "Balanced Amount",
                            "Rs. 0.0",
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
                      opacity: 0.1,
                      child: Text(
                        "PAID",
                        style: TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// Buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
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
                    final url = Uri.parse("https://wa.me/?text=$message");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Unable to open WhatsApp"),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Share Bill",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.deepOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.deepOrange, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, {Color? color}) {
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
