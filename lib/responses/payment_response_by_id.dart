import '/Models/payment_single_model.dart';

class PaymentResponseById {
  final PaymentSingleModel payment;
  final bool success;

  PaymentResponseById({required this.payment, required this.success});

  factory PaymentResponseById.fromJson(Map<String, dynamic> json) {
    return PaymentResponseById(
      payment: PaymentSingleModel.fromJson(json),
      success: json['Success'],
    );
  }
}
