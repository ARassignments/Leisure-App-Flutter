import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:yetoexplore/Models/customer_model.dart';
import 'package:yetoexplore/Models/payment_model.dart';
import 'package:yetoexplore/components/loading_screen.dart';
import 'package:yetoexplore/components/not_found.dart';
import 'package:yetoexplore/responses/customer_response.dart';
import 'package:yetoexplore/responses/payment_response.dart';
import 'package:yetoexplore/screens/customer_detail_screen.dart';
import 'package:yetoexplore/services/api_service.dart';
import 'package:yetoexplore/theme/theme.dart';
import 'package:yetoexplore/utils/session_manager.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String? token;
  Map<String, dynamic>? user;

  //Customers Screen
  late List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoadingPayments = true;
  bool _isRefreshingPayments = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSession();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    token = await SessionManager.getUserToken();
    user = await SessionManager.getUser();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoadingPayments = true);
    try {
      final response = await ApiService.getAllPayments(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
      );
      debugPrint("Payments fetched: ${response.payments.length}");
      setState(() {
        _allPayments = response.payments;
        _filteredPayments = List.from(_allPayments); // show all initially
      });
    } catch (e) {
      debugPrint("Error fetching payments: $e");
    } finally {
      setState(() => _isLoadingPayments = false);
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
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      await _loadPayments();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayments = _allPayments.where((payment) {
        final searchMatch =
            _searchController.text.trim().isEmpty ||
            payment.UserName.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        return searchMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _filteredPayments = List.from(_allPayments);
  }

  Widget _paymentPage() {
    double grandTotal = _filteredPayments.fold(
      0.0,
      (previousValue, payment) => previousValue + payment.Payment,
    );
    final formattedGrandTotal = NumberFormat(
      '#,###.00',
    ).format(grandTotal);
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
                  hintText: 'Search by name or ref no',
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
                children: [
                  Icon(
                    HugeIconsSolid.calendar02,
                    size: 18,
                    color: AppTheme.iconColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "From: ${DateFormat('yyyy-MM-dd').format(_fromDate)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDate)}",
                    style: AppTheme.textLabel(context).copyWith(fontSize: 12),
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
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _filteredPayments[index];
                            final formattedDate = DateFormat(
                              'MMMM dd, yyyy',
                            ).format(payment.PaymentDate);
                            final formattedAmount = NumberFormat(
                              '#,###.00',
                            ).format(payment.Payment);

                            return Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: index == 0 ? 0 : 2,
                                bottom: index == _filteredPayments.length - 1
                                    ? 0
                                    : 8,
                              ),
                              color: AppTheme.customListBg(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () {
                                },
                                leading: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontFamily: AppFontFamily.poppinsMedium,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Id# ",
                                                style:
                                                    AppTheme.textLabel(
                                                      context,
                                                    ).copyWith(
                                                      fontFamily: AppFontFamily
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
                                                      fontFamily: AppFontFamily
                                                          .poppinsSemiBold,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                            ],
                                          ),

                                          Row(
                                            children: [
                                              Icon(
                                                HugeIconsStroke.userAccount,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                payment.UserName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,

                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: AppFontFamily
                                                      .poppinsMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                HugeIconsStroke.calendar03,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                formattedDate,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: AppFontFamily
                                                      .poppinsMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    HugeIconsStroke.package,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Payment Type: ${payment.PaymentType}",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                ],
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                payment.PaymentMode.toString()
                                                    .contains("Recived")
                                                ? Colors.green.withOpacity(0.15)
                                                : Colors.blue.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                HugeIconsStroke.chartIncrease,
                                                size: 10,
                                                color:
                                                    payment.PaymentMode.toString()
                                                    .contains("Recived")
                                                    ? Colors.green
                                                    : Colors.blue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                payment.PaymentMode,
                                                style:
                                                    AppTheme.textLink(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 8,
                                                      color:
                                                          payment.PaymentMode.toString()
                                                    .contains("Recived")
                                                          ? Colors.green
                                                          : Colors.blue,
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
                                                    AppFontFamily.poppinsBold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
        if (_filteredPayments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        text: 'Total Payment:',
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
                            text: "Rs $formattedGrandTotal",
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
      body: user == null
          ? const Center(child: LoadingLogo())
          : _paymentPage(),
    );
  }
}
