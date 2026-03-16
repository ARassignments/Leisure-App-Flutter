import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:y2ksolutions/Models/customer_model.dart';
import 'package:y2ksolutions/components/customer_search_field_global.dart';
import 'package:y2ksolutions/responses/customer_response.dart';
import 'package:y2ksolutions/services/api_service.dart';
import '/Models/payment_dropdown_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/theme/theme.dart';
import '/components/appsnackbar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class AddPaymentBottomSheet extends StatefulWidget {
  const AddPaymentBottomSheet({super.key});

  @override
  State<AddPaymentBottomSheet> createState() => _AddPaymentBottomSheetState();
}

class _AddPaymentBottomSheetState extends State<AddPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _paymentAmountController = TextEditingController();
  final _paymentRemarksController = TextEditingController();
  bool _isLoading = false;

  //Customers Record
  late Future<CustomerResponse> _futureCustomers;
  List<Customer> _allCustomers = [];
  Customer? _selectedCustomerId;

  final List<PaymentDropdownModel> paymentModes = [
    PaymentDropdownModel(
      true,
      "",
      name: "Recived",
      icon: HugeIconsSolid.chartIncrease,
    ),
    PaymentDropdownModel(
      true,
      "",
      name: "Paid",
      icon: HugeIconsSolid.chartDecrease,
    ),
  ];
  PaymentDropdownModel? selectedPaymentMode;
  final List<PaymentDropdownModel> paymentTypes = [
    PaymentDropdownModel(true, "", name: "Cash", icon: HugeIconsSolid.wallet01),
    PaymentDropdownModel(true, "", name: "Bank", icon: HugeIconsSolid.bank),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/jazzcash.png",
      name: "JazzCash",
      icon: HugeIconsSolid.sendToMobile,
    ),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/ubl-bank.png",
      name: "UBL Bank",
      icon: HugeIconsSolid.bank,
    ),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/meezan-bank.png",
      name: "Meezan Bank",
      icon: HugeIconsSolid.bank,
    ),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/easypaisa.png",
      name: "EasyPaisa",
      icon: HugeIconsSolid.bank,
    ),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/upaisa.png",
      name: "Upaisa",
      icon: HugeIconsSolid.bank,
    ),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/nayapay.png",
      name: "Nayapay",
      icon: HugeIconsSolid.bank,
    ),
    PaymentDropdownModel(
      false,
      "assets/images/payment_type/sadapay.png",
      name: "Sadapay",
      icon: HugeIconsSolid.bank,
    ),
  ];
  PaymentDropdownModel? selectedPaymentType;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    _futureCustomers = ApiService.getAllCustomers();
    try {
      final response = await _futureCustomers;
      setState(() {
        _allCustomers = response.accounts;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
    }
  }

  Future<void> addPayment() async {
    setState(() => _isLoading = true);

    try {
      final int? userId = _selectedCustomerId?.UserId;
      final response = await ApiService.addPayment(
        userId!,
        selectedPaymentType!.name.toString(),
        selectedPaymentMode!.name.toString(),
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        int.parse(_paymentAmountController.text.trim()),
        _paymentRemarksController.text.trim(),
      );

      if (response["Success"] == true) {
        // Navigate to home
        if (mounted) {
          AppSnackBar.show(
            context,
            message: 'Payment Added Successfully',
            type: AppSnackBarType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        AppSnackBar.show(
            context,
            message:
                response["ValidationErrors"]?[0]?["Message"] ?? "Payment failed",
            type: AppSnackBarType.error,
          );
      }
    } catch (e) {
      print("Add payment error: $e");
      AppSnackBar.show(
        context,
        message: "Failed to add payment",
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentRemarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Payment",
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),

              CustomerSearchFieldGlobal(
                customers: _allCustomers,
                onSelected: (customer) {
                  setState(() => _selectedCustomerId = customer);
                },
              ),

              TextFormField(
                controller: _paymentAmountController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Payment Amount*",
                  hintText: 'Enter Payment Amount',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.money01),
                  ),
                  prefixText: "Rs ",
                  suffixText: " /-",
                  counter: const SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _paymentAmountController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _paymentAmountController
                                  .clear(); // Clear the text field
                            },
                          ),
                        )
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),

                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Payment Amount is required";
                  }
                  final amount = int.tryParse(value);
                  if (amount == null) {
                    return "Enter valid payment amount";
                  }
                  if (amount <= 0) {
                    return "Payment Amount must be greater than 0";
                  }
                  return null;
                },
                maxLength: 6,
              ),

              DropdownButtonHideUnderline(
                child: DropdownButtonFormField2<PaymentDropdownModel>(
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,

                  decoration: InputDecoration(
                    labelText: "Payment Mode*",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  hint: Row(
                    spacing: 12,
                    children: [
                      Icon(
                        HugeIconsSolid.money02,
                        size: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutral_70
                            : AppColor.neutral_20,
                      ),
                      Text(
                        "Select Payment Mode",
                        style: Theme.of(context).brightness == Brightness.dark
                            ? TextStyle(
                                fontSize: 14,
                                color: AppColor.neutral_60,
                              )
                            : TextStyle(
                                fontSize: 14,
                                color: AppColor.neutral_40,
                              ),
                      ),
                    ],
                  ),
                  value: selectedPaymentMode,
                  validator: (value) {
                    if (value == null) {
                      return "Payment Mode is required";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMode = value;
                    });
                  },
                  items: paymentModes.map((mode) {
                    return DropdownMenuItem<PaymentDropdownModel>(
                      value: mode,
                      child: Row(
                        spacing: 12,
                        children: [
                          (mode.isIcon)
                              ? Icon(
                                  mode.icon,
                                  size: 24,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColor.neutral_70
                                      : AppColor.neutral_20,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: EdgeInsets.all(3),
                                    color: AppColor.white,
                                    child: Image.asset(
                                      mode.imageUrl,
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                          Expanded(
                            child: Text(
                              mode.name,
                              style:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? TextStyle(
                                      fontSize: 14,
                                      color: AppColor.neutral_60,
                                    )
                                  : TextStyle(
                                      fontSize: 14,
                                      color: AppColor.neutral_40,
                                    ),
                            ),
                          ),

                          if (selectedPaymentMode == mode)
                            Icon(
                              HugeIconsSolid.checkmarkCircle01,
                              size: 20,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColor.neutral_70
                                  : AppColor.primary_50,
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  // buttonStyleData: ButtonStyleData(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 5,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(10),
                  //     color: Theme.of(context).brightness == Brightness.dark
                  //         ? AppColor.neutral_90
                  //         : AppColor.neutral_5,
                  //   ),
                  //   elevation: 0,
                  // ),
                  iconStyleData: IconStyleData(
                    icon: Icon(
                      HugeIconsSolid.arrowDown01,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_60
                          : AppColor.neutral_40,
                    ),
                    iconSize: 22,
                  ),

                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 205,
                    elevation: 0,
                    width: MediaQuery.of(context).size.width - 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_80
                          : AppColor.neutral_5,
                    ),
                    offset: const Offset(0, -5),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(40),
                      thickness: MaterialStateProperty.all(5),
                    ),
                  ),

                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              DropdownButtonHideUnderline(
                child: DropdownButtonFormField2<PaymentDropdownModel>(
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,

                  decoration: InputDecoration(
                    labelText: "Payment Mode*",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  hint: Row(
                    spacing: 12,
                    children: [
                      Icon(
                        HugeIconsSolid.wallet01,
                        size: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutral_70
                            : AppColor.neutral_20,
                      ),
                      Text(
                        "Select Payment Type",
                        style: Theme.of(context).brightness == Brightness.dark
                            ? TextStyle(
                                fontSize: 14,
                                color: AppColor.neutral_60,
                              )
                            : TextStyle(
                                fontSize: 14,
                                color: AppColor.neutral_40,
                              ),
                      ),
                    ],
                  ),
                  value: selectedPaymentType,
                  validator: (value) {
                    if (value == null) {
                      return "Payment Type is required";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentType = value;
                    });
                  },
                  items: paymentTypes.map((type) {
                    return DropdownMenuItem<PaymentDropdownModel>(
                      value: type,
                      child: Row(
                        spacing: 12,
                        children: [
                          (type.isIcon)
                              ? Icon(
                                  type.icon,
                                  size: 24,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColor.neutral_70
                                      : AppColor.neutral_20,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: EdgeInsets.all(3),
                                    color: AppColor.white,
                                    child: Image.asset(
                                      type.imageUrl,
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                          Expanded(
                            child: Text(
                              type.name,
                              style:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? TextStyle(
                                      fontSize: 14,
                                      color: AppColor.neutral_60,
                                    )
                                  : TextStyle(
                                      fontSize: 14,
                                      color: AppColor.neutral_40,
                                    ),
                            ),
                          ),

                          if (selectedPaymentType == type)
                            Icon(
                              HugeIconsSolid.checkmarkCircle01,
                              size: 20,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColor.neutral_70
                                  : AppColor.primary_50,
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  // buttonStyleData: ButtonStyleData(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 5,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(10),
                  //     color: Theme.of(context).brightness == Brightness.dark
                  //         ? AppColor.neutral_90
                  //         : AppColor.neutral_5,
                  //   ),
                  //   elevation: 0,
                  // ),
                  iconStyleData: IconStyleData(
                    icon: Icon(
                      HugeIconsSolid.arrowDown01,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_60
                          : AppColor.neutral_40,
                    ),
                    iconSize: 22,
                  ),

                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 205,
                    elevation: 0,
                    width: MediaQuery.of(context).size.width - 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_80
                          : AppColor.neutral_5,
                    ),
                    offset: const Offset(0, -5),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(40),
                      thickness: MaterialStateProperty.all(5),
                    ),
                  ),

                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              TextFormField(
                controller: _paymentRemarksController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Payment Remarks*",
                  hintText: 'Enter Payment Remarks',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.documentValidation),
                  ),
                  counter: SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _paymentRemarksController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _paymentRemarksController
                                  .clear(); // Clear the text field
                            },
                          ),
                        )
                      : null,
                ),
                maxLines: 4,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  } else if (value.length < 10) {
                    return 'Payment Remarks must be at least 10 characters long';
                  } else if (!RegExp(r'^[a-zA-Z ,.()]+$').hasMatch(value)) {
                    return 'Payment Remark must contain only letters';
                  }
                  return null;
                },
                maxLength: 100,
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),

              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) addPayment();
                      },
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          color: Colors.white,
                        ),
                      )
                    : Text("Add Payment"),
              ),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
