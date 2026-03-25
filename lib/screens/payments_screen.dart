import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '/screens/manage_payments/edit_payment.dart';
import '/screens/manage_payments/add_payment.dart';
import '/components/dialog_payment_reciept.dart';
import '/Models/customer_single_model.dart';
import '/components/appsnackbar.dart';
import '/Models/payment_model.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with AutomaticKeepAliveClientMixin {
  String? token;
  Map<String, dynamic>? user;
  CustomerSingleModel? _customer;

  //Payment Screen
  late List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoadingPayments = true;
  bool _isSortAscendingPayments = true;
  bool _isRefreshingPayments = false;
  bool _showScrollToTop = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollControllerPayment = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSession();
    _loadPayments();
    _scrollControllerPayment.addListener(_onPaymentScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollControllerPayment.removeListener(_onPaymentScroll);
    super.dispose();
  }

  Future<void> _loadSession() async {
    token = await SessionManager.getUserToken();
    user = await SessionManager.getUser();
  }

  Future<void> _loadPayments({bool isResetAll = false}) async {
    setState(() => _isLoadingPayments = true);
    try {
      if (isResetAll) {
        setState(() {
          _fromDate = DateTime.now();
          _toDate = DateTime.now();
        });
      }
      final fromDateFormatted = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toDateFormatted = DateFormat('yyyy-MM-dd').format(_toDate);
      final response = await ApiService.getAllPayments(
        fromDate: fromDateFormatted,
        toDate: toDateFormatted,
      );

      setState(() {
        _allPayments = response.payments;
        _filteredPayments = List.from(_allPayments);
      });
    } catch (e) {
      debugPrint("❌ Error fetching payments: $e");
    } finally {
      setState(() => _isLoadingPayments = false);
    }
  }

  Future<void> deletePaymentById(int paymentId) async {
    try {
      final response = await ApiService.deletePaymentById(paymentId);

      if (response["Success"] == true) {
        // Navigate to home
        if (mounted) {
          AppSnackBar.show(
            context,
            message: 'Payment Deleted Successfully',
            type: AppSnackBarType.success,
          );
          _refreshPayments();
        }
      } else {
        AppSnackBar.show(
          context,
          message: response["msg"] ?? "Payment failed",
          type: AppSnackBarType.error,
        );
      }
    } catch (e) {
      print("Delete payment error: $e");
      AppSnackBar.show(
        context,
        message: "Failed to delete payment",
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> fetchCustomer(PaymentModel payment, bool reciptPreview) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Container(
        color: AppTheme.screenBg(context),
        child: const Center(child: LoadingLogo()),
      ),
    );
    try {
      final id = payment.UserId;
      final customer = await ApiService.getSingleCustomer(id);
      if (!mounted) return;

      Navigator.pop(context);
      setState(() {
        _customer = customer;
        PaymentReceiptBottomSheet.showRecieptPreview(
          context,
          payment,
          "https://www.y2ksolutions.com/Payment/PaymentPrint/${payment.Id}",
          "${payment.UserName}-${user!["FullName"]}-Payment_Reciept-${DateFormat('dd-MMM-yyyy').format(payment.PaymentDate)}_#${payment.Id}",
          customer,
          reciptPreview,
        );
      });
    } catch (e) {
      debugPrint("❌ Error fetching customer: $e");
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _refreshPayments() async {
    setState(() {
      _isRefreshingPayments = true;
      _resetFilters(); // ✅ reset filters & search before reload
    });
    await _loadPayments();
    setState(() => _isRefreshingPayments = false);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });

      await _loadPayments();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayments =
          _allPayments.where((payment) {
            final searchMatch =
                _searchController.text.trim().isEmpty ||
                payment.UserName.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                payment.Id.toString().contains(
                  _searchController.text.toLowerCase(),
                );

            return searchMatch;
          }).toList()..sort((a, b) {
            final dateCompare = _isSortAscendingPayments
                ? a.PaymentDate.compareTo(b.PaymentDate)
                : b.PaymentDate.compareTo(a.PaymentDate);

            // ✅ if dates are same, sort by Id
            if (dateCompare == 0) {
              return _isSortAscendingPayments
                  ? a.Id.compareTo(b.Id)
                  : b.Id.compareTo(a.Id);
            }

            return dateCompare;
          });
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _filteredPayments = List.from(_allPayments);
    setState(() {
      _isSortAscendingPayments = true;
    });
  }

  Widget _confirmDeleteSheet(BuildContext context, String name) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Confirm Delete",
            textAlign: TextAlign.center,
            style: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Divider(color: AppTheme.dividerBg(context)),
          Text(
            "Are you sure you want to delete '$name' payment?",
            textAlign: TextAlign.center,
            style: AppTheme.textLabel(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.accent_50,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Remove",
              style: TextStyle(color: Colors.white),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _onPaymentScroll() {
    final shouldShow = _scrollControllerPayment.offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Widget _paymentPage() {
    double paidTotal = _filteredPayments
        .where(
          (p) => p.PaymentMode.toString().toLowerCase().contains("recived"),
        )
        .fold(0.0, (sum, p) => sum + p.Payment);

    double unpaidTotal = _filteredPayments
        .where(
          (p) => !p.PaymentMode.toString().toLowerCase().contains("recived"),
        )
        .fold(0.0, (sum, p) => sum + p.Payment);
    final formattedPaidTotal = NumberFormat('#,###.00').format(paidTotal);
    final formattedUnPaidTotal = NumberFormat('#,###.00').format(unpaidTotal);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _searchController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Search Here',
                  hintText: 'Search by name or id no',
                  counter: const SizedBox.shrink(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.search01),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(HugeIconsSolid.calendar03),
                          onPressed: () => _selectDateRange(context),
                        ),
                      ),
                    ],
                  ),
                ),
                style: AppInputDecoration.inputTextStyle(context),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  } else if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                    return 'Must contain only letters or digits';
                  }
                  return null;
                },
                maxLength: 20,
              ),

              if (_searchController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(context),
                        children: [
                          const TextSpan(text: 'Result for "'),
                          TextSpan(
                            text: _searchController.text,
                            style: AppTheme.textSearchInfoLabeled(context),
                          ),
                          const TextSpan(text: '"'),
                        ],
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: AppTheme.textSearchInfoLabeled(context),
                        children: [
                          TextSpan(text: _filteredPayments.length.toString()),
                          const TextSpan(text: ' found'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        HugeIconsSolid.calendar02,
                        size: 18,
                        color: AppTheme.iconColor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "From: ${DateFormat('yyyy-MM-dd').format(_fromDate)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDate)}",
                        style: AppTheme.textLabel(
                          context,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  if (_filteredPayments.isNotEmpty)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSortAscendingPayments = !_isSortAscendingPayments;
                          _filteredPayments.sort((a, b) {
                            final dateCompare = _isSortAscendingPayments
                                ? a.PaymentDate.compareTo(b.PaymentDate)
                                : b.PaymentDate.compareTo(a.PaymentDate);

                            // ✅ if dates are same, sort by OrderId
                            if (dateCompare == 0) {
                              return _isSortAscendingPayments
                                  ? a.Id.compareTo(b.Id)
                                  : b.Id.compareTo(a.Id);
                            }

                            return dateCompare;
                          });
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollControllerPayment.jumpTo(0);
                        });
                      },
                      child: Icon(
                        _isSortAscendingPayments
                            ? HugeIconsSolid.sortByUp01
                            : HugeIconsSolid.sortByDown01,
                        size: 18,
                        color: AppTheme.iconColor(context),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingPayments
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshPayments,
                  child: _filteredPayments.isEmpty
                      ? NotFoundWidget(
                          title: "No Payments Found",
                          message:
                              "No payments found for the selected date range.",
                        )
                      : SlidableAutoCloseBehavior(
                          child: Stack(
                            children: [
                              ListView.builder(
                                controller: _scrollControllerPayment,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredPayments.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _filteredPayments.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10,
                                        bottom: 75,
                                      ),
                                      child: Shimmer(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.sliderHighlightBg(context),
                                            AppTheme.iconColorThree(context),
                                            AppTheme.sliderHighlightBg(context),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        direction: ShimmerDirection.rtl,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 12,
                                          children: [
                                            const Icon(
                                              HugeIconsStroke.confused,
                                            ),
                                            Text(
                                              "No more record at the moment",
                                              style: AppTheme.textLink(context)
                                                  .copyWith(
                                                    fontFamily: AppFontFamily
                                                        .poppinsMedium,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final payment = _filteredPayments[index];
                                  final formattedDate = DateFormat(
                                    'MMMM dd, yyyy',
                                  ).format(payment.PaymentDate);
                                  final formattedAmount = NumberFormat(
                                    '#,###.00',
                                  ).format(payment.Payment);

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: index == 0 ? 0 : 2,
                                      bottom: 2,
                                    ),
                                    child: Slidable(
                                      key: ValueKey(payment.Id),
                                      startActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.4,
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final result =
                                                    await showModalBottomSheet(
                                                      context: context,
                                                      isDismissible: false,
                                                      enableDrag: false,
                                                      showDragHandle: true,
                                                      isScrollControlled: true,
                                                      backgroundColor: Theme.of(
                                                        context,
                                                      ).scaffoldBackgroundColor,
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    30,
                                                                  ),
                                                            ),
                                                      ),
                                                      builder: (context) =>
                                                          EditPaymentBottomSheet(
                                                            paymentId:
                                                                payment.Id,
                                                          ),
                                                    );

                                                if (result == true) {
                                                  Slidable.of(context)?.close();
                                                  _refreshPayments();
                                                }
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.customListBg(
                                                    context,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                height: double.infinity,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      HugeIconsSolid.edit01,
                                                      color: Colors.blue,
                                                      size: 24,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final bool? confirmDelete =
                                                    await showModalBottomSheet<
                                                      bool
                                                    >(
                                                      context: context,
                                                      isDismissible: false,
                                                      enableDrag: false,
                                                      showDragHandle: true,
                                                      isScrollControlled: true,
                                                      backgroundColor: Theme.of(
                                                        context,
                                                      ).scaffoldBackgroundColor,
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    30,
                                                                  ),
                                                            ),
                                                      ),
                                                      builder: (context) {
                                                        return _confirmDeleteSheet(
                                                          context,
                                                          "Id#${payment.Id} ${payment.UserName} (${payment.PaymentMode})",
                                                        );
                                                      },
                                                    );
                                                if (confirmDelete == true) {
                                                  Slidable.of(context)?.close();
                                                  deletePaymentById(payment.Id);
                                                }
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.customListBg(
                                                    context,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                height: double.infinity,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      HugeIconsSolid.delete01,
                                                      color: Color(0xFFC41F1F),
                                                      size: 24,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.4,
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                Slidable.of(context)?.close();
                                                fetchCustomer(payment, false);
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.customListBg(
                                                    context,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                height: double.infinity,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      HugeIconsSolid.pdf02,
                                                      color: Color(0xFFC41F1F),
                                                      size: 24,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                Slidable.of(context)?.close();
                                                fetchCustomer(payment, true);
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.customListBg(
                                                    context,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                height: double.infinity,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      HugeIconsSolid.invoice02,
                                                      color:
                                                          AppTheme.iconColorThree(
                                                            context,
                                                          ),
                                                      size: 24,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Card(
                                        color: AppTheme.customListBg(context),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Text(
                                            (index + 1).toString().padLeft(
                                              2,
                                              '0',
                                            ),
                                            style: const TextStyle(
                                              fontFamily:
                                                  AppFontFamily.poppinsMedium,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          "Id# ",
                                                          style:
                                                              AppTheme.textLabel(
                                                                context,
                                                              ).copyWith(
                                                                fontFamily:
                                                                    AppFontFamily
                                                                        .poppinsSemiBold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        Text(
                                                          payment.Id.toString(),
                                                          style:
                                                              AppTheme.textLabel(
                                                                context,
                                                              ).copyWith(
                                                                fontFamily:
                                                                    AppFontFamily
                                                                        .poppinsSemiBold,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          HugeIconsStroke
                                                              .userAccount,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          payment.UserName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .poppinsMedium,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          HugeIconsStroke
                                                              .calendar03,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          formattedDate,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .poppinsMedium,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          HugeIconsStroke
                                                              .package,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          "Payment Type: ${payment.PaymentType}",
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .poppinsMedium,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          payment
                                                              .PaymentMode.contains(
                                                            "Recived",
                                                          )
                                                          ? Colors.green
                                                                .withOpacity(
                                                                  0.15,
                                                                )
                                                          : Colors.blue
                                                                .withOpacity(
                                                                  0.15,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          payment.PaymentMode.contains(
                                                                "Recived",
                                                              )
                                                              ? HugeIconsStroke
                                                                    .chartIncrease
                                                              : HugeIconsStroke
                                                                    .chartDecrease,
                                                          size: 10,
                                                          color:
                                                              payment
                                                                  .PaymentMode.contains(
                                                                "Recived",
                                                              )
                                                              ? Colors.green
                                                              : Colors.blue,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          payment.PaymentMode,
                                                          style:
                                                              AppTheme.textLink(
                                                                context,
                                                              ).copyWith(
                                                                fontSize: 8,
                                                                color:
                                                                    payment
                                                                        .PaymentMode.contains(
                                                                      "Recived",
                                                                    )
                                                                    ? Colors
                                                                          .green
                                                                    : Colors
                                                                          .blue,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "Rs $formattedAmount",
                                                    style:
                                                        AppTheme.textSearchInfoLabeled(
                                                          context,
                                                        ).copyWith(
                                                          fontFamily:
                                                              AppFontFamily
                                                                  .poppinsBold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Scroll to top button
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                bottom: _filteredPayments.length > 10
                                    ? _showScrollToTop
                                          ? 8
                                          : -60
                                    : -60,
                                left: 24,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: _filteredPayments.length > 10
                                      ? _showScrollToTop
                                            ? 1.0
                                            : 0.0
                                      : 0.0,
                                  child: FloatingActionButton.small(
                                    heroTag: "scrollToTopPayment",
                                    backgroundColor: AppTheme.sliderHighlightBg(
                                      context,
                                    ),
                                    elevation: 0,
                                    focusElevation: 0,
                                    hoverElevation: 0,
                                    highlightElevation: 0,
                                    onPressed: () {
                                      _scrollControllerPayment.animateTo(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Icon(
                                      HugeIconsStroke.arrowUp01,
                                      color: AppTheme.iconColor(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
        ),
        if (_filteredPayments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: 10,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(
                          context,
                        ).copyWith(fontSize: 14),
                        text: 'Total Paid:',
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          HugeIconsStroke.moneySend01,
                          size: 14,
                          color: AppTheme.iconColor(context),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            style: AppTheme.textSearchInfoLabeled(
                              context,
                            ).copyWith(fontSize: 14),
                            text: "Rs $formattedUnPaidTotal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(
                          context,
                        ).copyWith(fontSize: 14),
                        text: 'Total Recieved:',
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          HugeIconsStroke.moneyReceive01,
                          size: 14,
                          color: AppTheme.iconColor(context),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            style: AppTheme.textSearchInfoLabeled(
                              context,
                            ).copyWith(fontSize: 14),
                            text: "Rs $formattedPaidTotal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          "Payments",
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
            icon: const Icon(HugeIconsStroke.refresh, size: 20),
            onPressed: () {
              _refreshPayments();
            },
          ),
        ],
      ),
      body: user == null ? const Center(child: LoadingLogo()) : _paymentPage(),
      floatingActionButton: AnimatedPadding(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          bottom: _filteredPayments.isEmpty ? 0 : 75,
          right: 8,
        ),
        child: FloatingActionButton.extended(
          isExtended: true,
          foregroundColor: AppTheme.iconColor(context),
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          onPressed: () async {
            final result = await showModalBottomSheet(
              context: context,
              isDismissible: false,
              enableDrag: false,
              showDragHandle: true,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              builder: (context) => const AddPaymentBottomSheet(),
            );

            if (result == true) {
              _searchController.clear();
              _loadPayments(isResetAll: true);
            }
          },
          backgroundColor: AppTheme.sliderHighlightBg(context),
          label: Row(
            spacing: 8,
            children: [
              Icon(
                HugeIconsStroke.add01,
                color: AppTheme.iconColor(context),
                size: 20,
              ),
              Text("Add Payment", style: AppTheme.textLabel(context)),
            ],
          ),
        ),
      ),
    );
  }
}
