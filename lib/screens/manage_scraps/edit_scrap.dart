import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '/Models/item_location_model.dart';
import '/Models/scrap_single_model.dart';
import '/components/item_location_search_field_global.dart';
import '/responses/item_location_response.dart';
import '/responses/scrap_response_by_id.dart';
import '/Models/customer_model.dart';
import '/components/customer_search_field_global.dart';
import '/responses/customer_response.dart';
import '/services/api_service.dart';
import '/Models/payment_dropdown_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/theme/theme.dart';
import '/components/appsnackbar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class EditScrapBottomSheet extends ConsumerStatefulWidget {
  final int scrapId;
  const EditScrapBottomSheet({super.key, required this.scrapId});

  @override
  ConsumerState<EditScrapBottomSheet> createState() =>
      _EditScrapBottomSheetState();
}

class _EditScrapBottomSheetState extends ConsumerState<EditScrapBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scrapDateController = TextEditingController();
  final _scrapQuantityController = TextEditingController();
  final _scrapWeightController = TextEditingController();
  final _scrapPriceController = TextEditingController();
  final _scrapRemarksController = TextEditingController();
  bool _isLoading = false;

  //Customers Record
  late Future<CustomerResponse> _futureCustomers;
  List<Customer> _allCustomers = [];
  Customer? _selectedCustomerId;

  //Item Location Record
  late Future<ItemLocationResponse> _futureItemLocations;
  List<ItemLocationModel> _allItemLocations = [];
  ItemLocationModel? _selectedItemLocationId;

  //Scrap Record
  late Future<ScrapResponseById> _futureScrap;
  late ScrapSingleModel _singleScrap;
  DateTime? _selectedScrapDate;

  final List<PaymentDropdownModel> scrapType = [
    PaymentDropdownModel(
      true,
      true,
      "",
      name: "Purchase",
      icon: HugeIconsSolid.chartIncrease,
    ),
    PaymentDropdownModel(
      true,
      true,
      "",
      name: "Sale",
      icon: HugeIconsSolid.chartDecrease,
    ),
  ];
  PaymentDropdownModel? selectedScrapType;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadItemLocations();
    _futureScrap = ApiService.getScrapById(id: widget.scrapId);
    _loadScrap();
  }

  Future<void> _loadCustomers() async {
    _futureCustomers = ApiService.getAllCustomers();
    try {
      final response = await _futureCustomers;
      setState(() {
        _allCustomers = response.accounts;
      });
      _setSelectedCustomer();
    } catch (e) {
      debugPrint("Error loading customers: $e");
    }
  }

  Future<void> _loadItemLocations() async {
    _futureItemLocations = ApiService.getAllItemLocations();
    try {
      final response = await _futureItemLocations;
      setState(() {
        _allItemLocations = response.locations
            .where((loc) => loc.Status == 1)
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading item locations: $e");
    }
  }

  void _loadScrap() async {
    try {
      final response = await _futureScrap;
      if (!mounted) return;
      if (response.success) {
        final scrap = response.scrap;

        setState(() {
          _singleScrap = scrap;

          // Text fields
          _scrapQuantityController.text = scrap.Items.toDouble().toString();
          _scrapWeightController.text = scrap.Quantity.toDouble().toString();
          _scrapPriceController.text = scrap.Price.toInt().toString();
          _scrapRemarksController.text = scrap.Remarks;

          // Convert API date string to DateTime
          _selectedScrapDate = DateFormat('dd MMM yyyy').parse(scrap.CreatedAt);

          // Format for TextField
          _scrapDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_selectedScrapDate!);

          // Scrap Type dropdown
          selectedScrapType = scrapType.firstWhere(
            (mode) =>
                mode.name.toLowerCase() == (scrap.OrderType).toLowerCase(),
            orElse: () => scrapType.first,
          );
        });
        _setSelectedCustomer();
        _setSelectedItemLocation();
      }
    } catch (e) {
      debugPrint("Scrap Load Error: $e");
    }
  }

  void _setSelectedCustomer() {
    if (_allCustomers.isEmpty) return;

    final match = _allCustomers.firstWhere(
      (customer) => customer.UserId == _singleScrap.UserAccountId,
      orElse: () => _allCustomers.first,
    );

    setState(() {
      _selectedCustomerId = match;
    });
  }

  void _setSelectedItemLocation() {
    if (_allItemLocations.isEmpty) return;

    final match = _allItemLocations.firstWhere(
      (itemLocation) => itemLocation.LocationName == _singleScrap.LocationId,
      orElse: () => _allItemLocations.first,
    );

    setState(() {
      _selectedItemLocationId = match;
    });
  }

  Future<void> editScrap() async {
    setState(() => _isLoading = true);

    try {
      final int? userId = _selectedCustomerId?.UserId;
      final int? itemLocationId = _selectedItemLocationId?.Id;
      final response = await ApiService.editScrap(
        widget.scrapId,
        userId!,
        int.parse(_scrapQuantityController.text.trim()),
        double.parse(_scrapWeightController.text.trim()),
        int.parse(_scrapPriceController.text.trim()),
        itemLocationId!,
        _scrapDateController.text.trim(),
        selectedScrapType!.name.toString(),
        _scrapRemarksController.text.trim(),
      );

      if (response["Success"] == true) {
        // Navigate to home
        if (mounted) {
          AppSnackBar.show(
            context,
            message: 'Scrap Edit Successfully',
            type: AppSnackBarType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        AppSnackBar.show(
          context,
          message:
              response["ValidationErrors"]?[0]?["Message"] ?? "Scrap failed",
          type: AppSnackBarType.error,
        );
      }
    } catch (e) {
      print("Add scrap error: $e");
      AppSnackBar.show(
        context,
        message: "Failed to edit scrap",
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
    _scrapDateController.dispose();
    _scrapQuantityController.dispose();
    _scrapWeightController.dispose();
    _scrapPriceController.dispose();
    _scrapRemarksController.dispose();
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
                "Edit Scrap",
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),

              CustomerSearchFieldGlobal(
                customers: _allCustomers,
                selectedCustomer: _selectedCustomerId,
                onSelected: (customer) {
                  setState(() => _selectedCustomerId = customer);
                },
              ),

              ItemLocationSearchFieldGlobal(
                itemLocation: _allItemLocations,
                selectedItemLocation: _selectedItemLocationId,
                onSelected: (itemlocationId) {
                  setState(() => _selectedItemLocationId = itemlocationId);
                },
              ),

              TextFormField(
                controller: _scrapDateController,
                readOnly: true,
                selectAllOnFocus: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Scrap Date*",
                  hintText: 'Select Scrap Date',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.calendar03),
                  ),
                  counter: const SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _scrapDateController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _scrapDateController.clear();
                            },
                          ),
                        )
                      : null,
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedScrapDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    setState(() {
                      _selectedScrapDate = pickedDate;
                      _scrapDateController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(pickedDate);
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Scrap Date is required";
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _scrapQuantityController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Scrap Quantity*",
                  hintText: 'Enter Scrap Quantity',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.package02),
                  ),
                  suffixText: " Qty",
                  counter: const SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _scrapQuantityController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _scrapQuantityController
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
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Scrap Quantity is required";
                  }
                  final amount = int.tryParse(value);
                  if (amount == null) {
                    return "Enter valid scrap quantity";
                  }
                  if (amount <= 0) {
                    return "Scrap Quantity must be greater than 0";
                  }
                  return null;
                },
                maxLength: 3,
              ),

              TextFormField(
                controller: _scrapWeightController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Scrap Weight*",
                  hintText: 'Enter Scrap Weight',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.weightScale01),
                  ),
                  suffixText: " Kg",
                  counter: const SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _scrapWeightController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _scrapWeightController
                                  .clear(); // Clear the text field
                            },
                          ),
                        )
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.contains('.')) {
                      final parts = text.split('.');
                      if (parts[1].length > 2) return oldValue;
                    }
                    return newValue;
                  }),
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Scrap Weight is required";
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return "Enter valid scrap weight";
                  }
                  if (amount <= 0) {
                    return "Scrap Weight must be greater than 0";
                  }
                  return null;
                },
                maxLength: 6,
              ),

              TextFormField(
                controller: _scrapPriceController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Scrap Price*",
                  hintText: 'Enter Scrap Price',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.money01),
                  ),
                  prefixText: "Rs ",
                  suffixText: " /-",
                  counter: const SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _scrapPriceController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _scrapPriceController
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
                    return "Scrap Price is required";
                  }
                  final amount = int.tryParse(value);
                  if (amount == null) {
                    return "Enter valid scrap price";
                  }
                  if (amount <= 0) {
                    return "Scrap Price must be greater than 0";
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
                    labelText: "Scrap Type*",
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
                        HugeIconsSolid.moneyExchange03,
                        size: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutral_70
                            : AppColor.neutral_20,
                      ),
                      Text(
                        "Select Scrap Type",
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
                  value: selectedScrapType,
                  validator: (value) {
                    if (value == null) {
                      return "Scrap Type is required";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedScrapType = value;
                    });
                  },
                  items: scrapType.map((mode) {
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

                          if (selectedScrapType == mode)
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
                controller: _scrapRemarksController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Scrap Remarks (Optional)",
                  hintText: 'Enter Scrap Remarks',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.documentValidation),
                  ),
                  counter: SizedBox.shrink(),
                  suffixIcon: _isLoading
                      ? null
                      : _scrapRemarksController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _scrapRemarksController
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
                    return 'Scrap Remarks must be at least 10 characters long';
                  } else if (!RegExp(r'^[a-zA-Z ,.()]+$').hasMatch(value)) {
                    return 'Scrap Remark must contain only letters';
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
                        if (_formKey.currentState!.validate()) editScrap();
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
                    : Text("Edit Scrap"),
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
