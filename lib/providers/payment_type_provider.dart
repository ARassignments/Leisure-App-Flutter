import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Models/payment_dropdown_model.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class PaymentTypeNotifier extends StateNotifier<List<PaymentDropdownModel>> {
  PaymentTypeNotifier() : super(_defaultPaymentTypes());

  static List<PaymentDropdownModel> _defaultPaymentTypes() {
    return [
      PaymentDropdownModel(true, true, "", name: "Cash", icon: HugeIconsSolid.wallet01),
      PaymentDropdownModel(false, true, "", name: "Bank", icon: HugeIconsSolid.bank),
      PaymentDropdownModel(true, false, "assets/images/payment_type/jazzcash.png",
          name: "JazzCash", icon: HugeIconsSolid.sendToMobile),
      PaymentDropdownModel(true, false, "assets/images/payment_type/ubl-bank.png",
          name: "UBL Bank", icon: HugeIconsSolid.bank),
      PaymentDropdownModel(true, false, "assets/images/payment_type/meezan-bank.png",
          name: "Meezan Bank", icon: HugeIconsSolid.bank),
      PaymentDropdownModel(false, false, "assets/images/payment_type/easypaisa.png",
          name: "EasyPaisa", icon: HugeIconsSolid.bank),
      PaymentDropdownModel(false, false, "assets/images/payment_type/upaisa.png",
          name: "Upaisa", icon: HugeIconsSolid.bank),
      PaymentDropdownModel(false, false, "assets/images/payment_type/nayapay.png",
          name: "Nayapay", icon: HugeIconsSolid.bank),
      PaymentDropdownModel(false, false, "assets/images/payment_type/sadapay.png",
          name: "Sadapay", icon: HugeIconsSolid.bank),
    ];
  }

  void togglePaymentType(String name) {
    state = state.map((type) {
      if (type.name == name) {
        return PaymentDropdownModel(
          !type.isVisible,
          type.isIcon,
          type.imageUrl,
          name: type.name,
          icon: type.icon,
        );
      }
      return type;
    }).toList();
  }
}

final paymentTypeProvider =
    StateNotifierProvider<PaymentTypeNotifier, List<PaymentDropdownModel>>(
        (ref) => PaymentTypeNotifier());