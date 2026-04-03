import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:y2ksolutions/components/dialog_payment_reciept.dart';
import 'package:y2ksolutions/components/loading_screen.dart';
import '/components/appsnackbar.dart';
import '/components/dialog_bounce.global.dart';
import '/screens/manage_payments/edit_payment.dart';
import '/Models/payment_dropdown_model.dart';
import '/components/not_found.dart';
import '/providers/payment_type_provider.dart';
import '/screens/manage_payments/add_payment.dart';
import '/theme/theme.dart';
import '/Models/customer_single_model.dart';
import '/Models/payment_model.dart';
import '/services/api_service.dart';
import '/utils/session_manager.dart';

class PaymentsTableScreen extends ConsumerStatefulWidget {
  const PaymentsTableScreen({super.key});

  @override
  ConsumerState<PaymentsTableScreen> createState() =>
      _PaymentsTableScreenState();
}

class _PaymentsTableScreenState extends ConsumerState<PaymentsTableScreen>
    with AutomaticKeepAliveClientMixin {
  String? token;
  Map<String, dynamic>? user;
  CustomerSingleModel? _customer;

  final TextEditingController _searchController = TextEditingController();
  late List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoadingPayments = true;
  bool _isRefreshingPayments = false;
  String _sortCol = 'id';
  bool _sortAsc = false;
  int? _hoveredRow;
  int _selectedRows = 0;
  final Set<int> _checkedIds = {};
  String? _filterPaymentType;
  String? _filterPaymentMode;

  // Date filter
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  // Pagination
  int _page = 0;
  int? _rowsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

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
        // _applyFilter();
      });
    } catch (e) {
      debugPrint("❌ Error fetching payments: $e");
    } finally {
      setState(() => _isLoadingPayments = false);
    }
  }

  Future<void> _refreshPayments() async {
    setState(() {
      _isRefreshingPayments = true;
      _resetFilters(); // ✅ reset filters & search before reload
    });
    await _loadPayments();
    setState(() => _isRefreshingPayments = false);
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      final newFiltered = _allPayments.where((p) {
        final matchSearch =
            q.isEmpty ||
            p.UserName.toLowerCase().contains(q) ||
            p.Id.toString().contains(q);
        final matchDate =
            !p.PaymentDate.isBefore(_fromDate) &&
            !p.PaymentDate.isAfter(_toDate);
        final matchType =
            _filterPaymentType == null || p.PaymentType == _filterPaymentType;
        final matchMode =
            _filterPaymentMode == null || p.PaymentMode == _filterPaymentMode;
        return matchSearch && matchDate && matchType && matchMode;
      }).toList();

      setState(() {
        _filteredPayments = newFiltered;
        if (_filterPaymentType != null &&
            !_filteredPayments.any(
              (p) => p.PaymentType == _filterPaymentType,
            )) {
          _filterPaymentType = null;
        }
        if (_filterPaymentMode != null &&
            !_filteredPayments.any(
              (p) => p.PaymentMode == _filterPaymentMode,
            )) {
          _filterPaymentMode = null;
        }
        _sortData();
        final maxPage = _totalPages > 0 ? _totalPages - 1 : 0;
        if (_page > maxPage) {
          _page = maxPage;
        }
      });
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _filterPaymentType = null;
    _filterPaymentMode = null;
    _page = 0;
    _checkedIds.clear();
    _sortCol = 'id';
    _sortAsc = false;
    _filteredPayments = List.from(_allPayments);
  }

  void _sortData() {
    _filteredPayments.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 'id':
          cmp = a.Id.compareTo(b.Id);
          break;
        case 'name':
          cmp = a.UserName.compareTo(b.UserName);
          break;
        case 'date':
          cmp = a.PaymentDate.compareTo(b.PaymentDate);
          break;
        case 'amount':
          cmp = a.Payment.compareTo(b.Payment);
          break;
        case 'mode':
          cmp = a.PaymentMode.compareTo(b.PaymentMode);
          break;
        case 'type':
          cmp = a.PaymentType.compareTo(b.PaymentType);
          break;
        case 'remarks':
          cmp = a.Remarks.compareTo(b.Remarks);
          break;
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });
  }

  void _onSort(String col) {
    setState(() {
      if (_sortCol == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col;
        _sortAsc = true;
      }
      _sortData();
    });
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  Widget _confirmDeleteModal(BuildContext context, String name) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width >= 500 ? 400 : double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.screenBg(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Confirm Delete",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(context).copyWith(
                      fontSize: 16,
                      fontFamily: AppFontFamily.poppinsBold,
                    ),
                  ),
                  const Divider(),
                  Text(
                    "Are you sure you want to delete '$name' payment?",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.accent_50,
                    ),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true) // ✅
                            .pop(true),
                    child: const Text(
                      "Yes, Remove",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true) // ✅
                            .pop(false),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> fetchReciptPreview(PaymentModel payment, bool reciptPreview) async {
    showDialog(
      context: context,
      useRootNavigator: true,
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

      Navigator.of(context, rootNavigator: true).pop();
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

  String _fmtAmount(double v) => NumberFormat('#,##0.00').format(v);
  String _fmtDate(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  double get totalPaid => _filteredPayments
      .where((p) => !p.PaymentMode.toString().toLowerCase().contains("recived"))
      .fold(0.0, (sum, p) => sum + p.Payment);

  double get totalReceived => _filteredPayments
      .where((p) => p.PaymentMode.toString().toLowerCase().contains("recived"))
      .fold(0.0, (sum, p) => sum + p.Payment);

  List<PaymentModel> get _pageData {
    // ✅ null = show all entries
    if (_filteredPayments.isEmpty) return [];
    if (_rowsPerPage == null) return _filteredPayments;
    final start = (_page * _rowsPerPage!).clamp(
      0,
      _filteredPayments.length - 1,
    );
    final end = (start + _rowsPerPage!).clamp(0, _filteredPayments.length);
    return _filteredPayments.sublist(start, end);
  }

  int get _totalPages {
    if (_filteredPayments.isEmpty) return 1;
    if (_rowsPerPage == null) return 1;
    return (_filteredPayments.length / _rowsPerPage!).ceil();
  }

  List<String> get _paymentTypes =>
      _filteredPayments.map((p) => p.PaymentType).toSet().toList()..sort();

  List<String> get _paymentModes =>
      _filteredPayments.map((p) => p.PaymentMode).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Content ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Search + filter row
                  _buildSearchRow(),
                  const SizedBox(height: 12),
                  // Summary cards
                  _buildSummaryRow(),
                  const SizedBox(height: 16),
                  // Table
                  Expanded(child: _buildTable()),
                  const SizedBox(height: 12),
                  // Pagination + totals footer
                  _buildFooter(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search + Filter Row ───────────────────────────────────────────────────

  Widget _buildSearchRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Search
      Expanded(
        child: Column(
          children: [
            TextFormField(
              controller: _searchController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Search Here',
                hintText: 'Search by name or id no',
                counter: const SizedBox.shrink(),
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.screenBg(context)
                    : Colors.white,
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
                          _applyFilter();
                        },
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
            // ✅ Add below search row when filter is active
            if (_filterPaymentType != null || _filterPaymentMode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      'Filters: ',
                      style: AppTheme.textSearchInfoLabeled(context).copyWith(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    if (_filterPaymentType != null)
                      _FilterChip(
                        label: _filterPaymentType!,
                        onClear: () {
                          setState(() => _filterPaymentType = null);
                          _applyFilter();
                        },
                      ),
                    if (_filterPaymentMode != null) ...[
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: _filterPaymentMode!,
                        color: _filterPaymentMode == 'Recived'
                            ? kReceived
                            : kPaid,
                        onClear: () {
                          setState(() => _filterPaymentMode = null);
                          _applyFilter();
                        },
                      ),
                    ],
                    const SizedBox(width: 8),
                    // ✅ Clear all filters
                    if (_filterPaymentType != null ||
                        _filterPaymentMode != null)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _filterPaymentType = null;
                            _filterPaymentMode = null;
                          });
                          _applyFilter();
                        },
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.iconColorTwo(context)
                                : kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 10),

      // Date range pill
      InkWell(
        onTap: _pickDateRange,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.screenBg(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                HugeIconsSolid.calendar03,
                size: 16,
                color: AppTheme.iconColorThree(context),
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd/MM/yyyy').format(_fromDate)}  –  ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.iconColorTwo(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppTheme.iconColorThree(context),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),

      // Add Payment
      InkWell(
        onTap: () async {
          final result = await BounceDialog.showBounceDialog<bool>(
            context: context,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width >= 500
                    ? 400
                    : double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.screenBg(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const AddPaymentBottomSheet(),
              ),
            ),
          );

          if (result == true) {
            _searchController.clear();
            _loadPayments(isResetAll: true);
          }
        },
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColor.primary_50.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(HugeIconsStroke.add01, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Add Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),
      InkWell(
        onTap: _refreshPayments,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.screenBg(context),
          ),
          child: Icon(
            Icons.refresh_rounded,
            size: 16,
            color: AppTheme.iconColorThree(context),
          ),
        ),
      ),
    ],
  );

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
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

  // ── Summary Cards ─────────────────────────────────────────────────────────

  Widget _buildSummaryRow() => Row(
    spacing: 10,
    children: [
      _SummaryCard(
        label: 'Total Entries',
        value: _filteredPayments.length.toString() == '0'
            ? '0'
            : _filteredPayments.length.toString().padLeft(2, '0'),
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFD13838),
      ),
      _SummaryCard(
        label: 'Total Received',
        value: 'Rs ${_fmtAmount(totalReceived)}',
        icon: Icons.south_west_rounded,
        color: kReceived,
      ),
      _SummaryCard(
        label: 'Total Paid',
        value: 'Rs ${_fmtAmount(totalPaid)}',
        icon: Icons.north_east_rounded,
        color: kPaid,
      ),
      _SummaryCard(
        label: 'Net Balance',
        value: 'Rs ${_fmtAmount(totalReceived - totalPaid)}',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF9966FF),
      ),
    ],
  );

  // ── Table ─────────────────────────────────────────────────────────────────

  Widget _buildTable() => Container(
    decoration: BoxDecoration(
      color: AppTheme.screenBg(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : kBorder,
        width: 0.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header
        _buildTableHeader(),
        // Rows
        Expanded(
          child: _pageData.isEmpty
              ? NotFoundWidget(
                  title: "No Payments Found",
                  message: "No payments found for the selected date range.",
                )
              : ListView.builder(
                  itemCount: _pageData.length,
                  itemBuilder: (ctx, i) => _buildTableRow(_pageData[i], i),
                ),
        ),
      ],
    ),
  );

  Widget _buildTableHeader() => Container(
    height: 44,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.sliderHighlightBg(context).withOpacity(0.30)
          : Color(0xFFF8F9FC),
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : kBorder,
          width: 0.5,
        ),
      ),
    ),
    child: Row(
      children: [
        // Checkbox
        SizedBox(
          width: 48,
          child: Checkbox(
            value:
                _checkedIds.length == _filteredPayments.length &&
                _filteredPayments.isNotEmpty,
            onChanged: (v) => setState(() {
              if (v == true) {
                _checkedIds.addAll(_filteredPayments.map((p) => p.Id));
              } else {
                _checkedIds.clear();
              }
            }),
            activeColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.iconColorThree(context)
                : kPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        _HeaderCell(
          label: '#',
          width: 44,
          col: 'id',
          sortCol: _sortCol,
          sortAsc: _sortAsc,
          onSort: _onSort,
        ),
        _HeaderCell(
          label: 'Customer Name',
          flex: 2,
          col: 'name',
          sortCol: _sortCol,
          sortAsc: _sortAsc,
          onSort: _onSort,
        ),
        _HeaderCell(
          label: 'Payment Date',
          flex: 2,
          col: 'date',
          sortCol: _sortCol,
          sortAsc: _sortAsc,
          onSort: _onSort,
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _SortFilterHeader(
              label: 'Payment Type',
              col: 'type',
              sortCol: _sortCol,
              sortAsc: _sortAsc,
              onSort: _onSort,
              selected:
                  _allPayments
                      .map((p) => p.PaymentType)
                      .contains(_filterPaymentType)
                  ? _filterPaymentType
                  : null,
              items: _allPayments.map((p) => p.PaymentType).toSet().toList()
                ..sort(),
              allItems: _allPayments.map((p) => p.PaymentType).toList(),
              onFilterChanged: (val) {
                setState(() => _filterPaymentType = val);
                _applyFilter();
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _SortFilterHeader(
              label: 'Payment Mode',
              col: 'mode',
              sortCol: _sortCol,
              sortAsc: _sortAsc,
              onSort: _onSort,
              selected:
                  _allPayments
                      .map((p) => p.PaymentMode)
                      .contains(_filterPaymentMode)
                  ? _filterPaymentMode
                  : null,
              items: _allPayments.map((p) => p.PaymentMode).toSet().toList()
                ..sort(),
              allItems: _allPayments.map((p) => p.PaymentMode).toList(),
              onFilterChanged: (val) {
                setState(() => _filterPaymentMode = val);
                _applyFilter();
              },
            ),
          ),
        ),
        _HeaderCell(
          label: 'Remarks',
          flex: 2,
          col: 'remarks',
          sortCol: _sortCol,
          sortAsc: _sortAsc,
          onSort: _onSort,
          align: TextAlign.center,
        ),
        _HeaderCell(
          label: 'Amount',
          flex: 2,
          col: 'amount',
          sortCol: _sortCol,
          sortAsc: _sortAsc,
          onSort: _onSort,
          align: TextAlign.right,
        ),
        const SizedBox(width: 120), // actions
      ],
    ),
  );

  Widget _buildTableRow(PaymentModel p, int i) {
    final isChecked = _checkedIds.contains(p.Id);
    final isHovered = _hoveredRow == p.Id;
    final isReceived = p.PaymentMode == 'Recived';
    final index = (_page * (_rowsPerPage ?? _filteredPayments.length)) + i + 1;
    ;
    final paymentTypes = ref.read(paymentTypeProvider).toList();
    PaymentDropdownModel? selectedPaymentType;
    selectedPaymentType = paymentTypes.firstWhere(
      (type) => type.name.toLowerCase() == p.PaymentType.toLowerCase(),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRow = p.Id),
      onExit: (_) => setState(() => _hoveredRow = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: isChecked
              ? Theme.of(context).brightness == Brightness.dark
                    ? AppColor.neutral_70.withOpacity(0.50)
                    : kPrimary.withOpacity(0.04)
              : isHovered
              ? Theme.of(context).brightness == Brightness.dark
                    ? AppColor.neutral_70.withOpacity(0.20)
                    : const Color(0xFFF8F9FC)
              : Theme.of(context).brightness == Brightness.dark
              ? AppTheme.screenBg(context)
              : kCard,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColor.neutral_70
                  : kBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 48,
              child: Checkbox(
                value: isChecked,
                onChanged: (v) => setState(() {
                  if (v == true)
                    _checkedIds.add(p.Id);
                  else
                    _checkedIds.remove(p.Id);
                }),
                activeColor: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.iconColorThree(context)
                    : kPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            // Index
            SizedBox(
              width: 44,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: AppTheme.textSearchInfoLabeled(context).copyWith(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Customer
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Id# ${p.Id}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.iconColorTwo(context)
                          : kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    p.UserName,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.iconColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Date
            Expanded(
              flex: 2,
              child: Text(
                _fmtDate(p.PaymentDate),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.iconColor(context),
                ),
              ),
            ),

            // Payment Type
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.customListBg(context)
                          : Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        (selectedPaymentType.isIcon)
                            ? Icon(
                                selectedPaymentType.icon,
                                size: 20,
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
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColor.neutral_20
                                      : AppColor.white,
                                  child: Image.asset(
                                    selectedPaymentType.imageUrl,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                        Text(
                          p.PaymentType,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.iconColorThree(context)
                                : AppTheme.iconColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Payment Mode badge
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isReceived
                          ? kReceived.withOpacity(0.10)
                          : kPaid.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReceived
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          size: 10,
                          color: isReceived ? kReceived : kPaid,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.PaymentMode,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isReceived ? kReceived : kPaid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Remark
            Expanded(
              flex: 2,
              child: Text(
                p.Remarks.isEmpty ? '-' : p.Remarks,
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: Text(
                'Rs ${_fmtAmount(p.Payment)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isReceived ? kReceived : kPaid,
                ),
              ),
            ),

            // Actions
            SizedBox(
              width: 120,
              child: isHovered
                  ? Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionBtn(
                          icon: HugeIconsSolid.edit01,
                          color: Colors.blue,
                          onTap: () async {
                            final result =
                                await BounceDialog.showBounceDialog<bool>(
                                  context: context,
                                  child: Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: Container(
                                      padding: EdgeInsets.only(top: 20),
                                      width:
                                          MediaQuery.of(context).size.width >=
                                              500
                                          ? 400
                                          : double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.screenBg(context),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: EditPaymentBottomSheet(
                                        paymentId: p.Id,
                                      ),
                                    ),
                                  ),
                                );

                            if (result == true) {
                              _refreshPayments();
                            }
                          },
                        ),
                        _ActionBtn(
                          icon: HugeIconsSolid.delete01,
                          color: const Color(0xFFE53935),
                          onTap: () async {
                            final bool? confirmDelete =
                                await BounceDialog.showBounceDialog<bool>(
                                  context: context,
                                  child: _confirmDeleteModal(
                                    context,
                                    "Id#${p.Id} ${p.UserName} (${p.PaymentMode})",
                                  ),
                                );
                            if (confirmDelete == true) {
                              deletePaymentById(p.Id);
                            }
                          },
                        ),
                        _ActionBtn(
                          icon: HugeIconsSolid.pdf01,
                          color: AppTheme.iconColorThree(context),
                          onTap: () async {
                            await fetchReciptPreview(p,true);
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.screenBg(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : kBorder,
        width: 0.5,
      ),
    ),
    child: Row(
      children: [
        // Totals
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.south_west_rounded,
                  size: 13,
                  color: kReceived,
                ),
                const SizedBox(width: 4),
                Text(
                  'Total Received:  ',
                  style: AppTheme.textSearchInfoLabeled(context).copyWith(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rs ${_fmtAmount(totalReceived)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kReceived,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.north_east_rounded, size: 13, color: kPaid),
                const SizedBox(width: 4),
                Text(
                  'Total Paid:  ',
                  style: AppTheme.textSearchInfoLabeled(context).copyWith(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rs ${_fmtAmount(totalPaid)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kPaid,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 20),
        // ✅ Show entries dropdown
        Text(
          'Show',
          style: AppTheme.textSearchInfoLabeled(context).copyWith(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColor.neutral_90
                : Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : kBorder,
              width: 0.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<int?>(
              value: _rowsPerPage,
              isDense: true,
              iconStyleData: IconStyleData(
                icon: Icon(
                  HugeIconsStroke.arrowDown01,
                  size: 16,
                  color: AppTheme.iconColorTwo(context),
                ),
              ),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.iconColorTwo(context),
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              dropdownStyleData: DropdownStyleData(
                padding: EdgeInsets.all(0),
                width: 60,
                elevation: 0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColor.neutral_90
                      : AppColor.neutral_5,
                ),
              ),
              items: [
                // ✅ Numbered options
                ...[10, 20, 30, 40, 50].map(
                  (v) => DropdownMenuItem<int?>(value: v, child: Text('$v')),
                ),
                // ✅ All option
                const DropdownMenuItem<int?>(value: null, child: Text('All')),
              ],
              onChanged: (v) {
                setState(() {
                  _rowsPerPage = v; // ✅ null = All
                  _page = 0; // ✅ reset to first page
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'entries',
          style: AppTheme.textSearchInfoLabeled(context).copyWith(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        const Spacer(),

        // Page buttons
        // ✅ Only show pagination when not showing all
        if (_rowsPerPage != null) ...[
          Text(
            '${_page * _rowsPerPage! + 1}–${(_page * _rowsPerPage! + _pageData.length)} of ${_filteredPayments.length}',
            style: AppTheme.textSearchInfoLabeled(context).copyWith(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: _page > 0,
            onTap: () => setState(() => _page--),
          ),
          const SizedBox(width: 4),
          ..._buildPageNumbers(),
          const SizedBox(width: 4),
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: _page < _totalPages - 1,
            onTap: () => setState(() => _page++),
          ),
        ] else
          Text(
            'All ${_filteredPayments.length} entries',
            style: AppTheme.textSearchInfoLabeled(context).copyWith(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
  );

  // ── Smart page numbers ────────────────────────────────────────────────────────

  List<Widget> _buildPageNumbers() {
    const int maxVisible = 2;
    final List<Widget> pages = [];

    if (_totalPages <= maxVisible + 2) {
      // ✅ Few pages — show all
      for (int i = 0; i < _totalPages; i++) {
        pages.add(_pageNumBtn(i));
      }
    } else {
      // ✅ Always first page
      pages.add(_pageNumBtn(0));

      final int start = (_page - 1).clamp(1, _totalPages - maxVisible);
      final int end = (start + maxVisible - 1).clamp(1, _totalPages - 2);

      // Left ellipsis
      if (start > 1) pages.add(_ellipsis());

      // Middle window
      for (int i = start; i <= end; i++) {
        pages.add(_pageNumBtn(i));
      }

      // Right ellipsis
      if (end < _totalPages - 2) pages.add(_ellipsis());

      // ✅ Always last page
      pages.add(_pageNumBtn(_totalPages - 1));
    }

    return pages;
  }

  Widget _pageNumBtn(int i) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: InkWell(
      onTap: () => setState(() => _page = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _page == i
              ? Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.iconColor(context)
                    : kPrimary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _page == i
                ? Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.iconColor(context)
                      : kPrimary
                : Theme.of(context).brightness == Brightness.dark
                ? AppTheme.iconColorThree(context)
                : kBorder,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            '${i + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _page == i
                  ? Theme.of(context).brightness == Brightness.dark
                        ? AppColor.neutral_90
                        : Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.iconColorThree(context)
                  : kMuted,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _ellipsis() => Padding(
    padding: EdgeInsets.only(right: 4),
    child: SizedBox(
      width: 30,
      height: 30,
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.iconColorThree(context)
                : kMuted,
          ),
        ),
      ),
    ),
  );
}

// ─── Theme helpers ────────────────────────────────────────────────────────────

const Color kPrimary = AppColor.primary_50;
const Color kBg = Color(0xFFF5F6FA);
const Color kCard = Colors.white;
const Color kText = Color(0xFF1A1A2E);
const Color kMuted = Color(0xFF9E9E9E);
const Color kReceived = Color(0xFF1D9E75);
const Color kPaid = Color(0xFF378ADD);
const Color kBorder = Color(0xFFEEEEEE);

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.screenBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : kBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.textSearchInfoLabeled(context).copyWith(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.iconColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeaderCell extends StatelessWidget {
  final String label, col, sortCol;
  final bool sortAsc;
  final ValueChanged<String> onSort;
  final double? width;
  final int? flex;
  final TextAlign align;

  const _HeaderCell({
    required this.label,
    required this.col,
    required this.sortCol,
    required this.sortAsc,
    required this.onSort,
    this.width,
    this.flex,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortCol == col;
    final cell = InkWell(
      onTap: () => onSort(col),
      child: Row(
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.iconColor(context)
                        : kPrimary
                  : AppTheme.iconColorTwo(context),
              letterSpacing: 0.3,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              sortAsc
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.iconColor(context)
                  : kPrimary,
            ),
          ],
        ],
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    ),
  );
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enabled
              ? Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.iconColorThree(context)
                    : kBorder
              : Theme.of(context).brightness == Brightness.dark
              ? AppColor.neutral_60
              : kBorder,
          width: 0.5,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: enabled
            ? Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.iconColorThree(context)
                  : AppTheme.iconColorTwo(context)
            : Theme.of(context).brightness == Brightness.dark
            ? AppColor.neutral_60
            : kMuted.withOpacity(0.4),
      ),
    ),
  );
}

class _SortFilterHeader extends StatelessWidget {
  final String label;
  final String col;
  final String sortCol;
  final bool sortAsc;
  final ValueChanged<String> onSort;
  final String? selected;
  final List<String> items;
  final List<String> allItems;
  final ValueChanged<String?> onFilterChanged;

  const _SortFilterHeader({
    required this.label,
    required this.col,
    required this.sortCol,
    required this.sortAsc,
    required this.onSort,
    required this.selected,
    required this.items,
    required this.allItems,
    required this.onFilterChanged,
  });

  bool get _isSortActive => sortCol == col;
  // bool get _isFilterActive => selected != null;

  @override
  Widget build(BuildContext context) {
    final safeSelected = (selected != null && items.contains(selected))
        ? selected
        : null;
    final isActive = safeSelected != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ Sort button
        InkWell(
          onTap: () => onSort(col),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isSortActive
                      ? Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.iconColor(context)
                            : kPrimary
                      : AppTheme.iconColorTwo(context),
                  letterSpacing: 0.3,
                ),
              ),
              if (_isSortActive) ...[
                const SizedBox(width: 4),
                Icon(
                  sortAsc
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.iconColor(context)
                      : kPrimary,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 4),

        // ✅ Filter dropdown
        if (items.length > 1)
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<String?>(
                value: safeSelected,
                isDense: true,
                selectedItemBuilder: (_) => [
                  // null selected — show default label (hidden, icon only)
                  const SizedBox.shrink(),
                  // each item selected
                  ...items.map((_) => const SizedBox.shrink()),
                ],
                iconStyleData: IconStyleData(
                  icon: Icon(
                    isActive
                        ? Icons.filter_alt_rounded
                        : HugeIconsStroke.arrowDown01,
                    color: isActive
                        ? Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.iconColorThree(context)
                              : kPrimary
                        : Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.iconColorThree(context)
                        : AppColor.neutral_40,
                  ),
                  iconSize: 14,
                  openMenuIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.iconColor(context).withOpacity(0.10)
                                : kPrimary.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.filter_alt_rounded
                          : HugeIconsStroke.arrowDown01,
                      size: 14,
                      color: isActive
                          ? Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.iconColorThree(context)
                                : kPrimary
                          : kMuted,
                    ),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  padding: EdgeInsets.all(0),
                  width: 200,
                  elevation: 0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColor.neutral_90
                        : AppColor.neutral_5,
                  ),
                ),
                items: [
                  // ✅ All option
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.clear_all_rounded, size: 14, color: kMuted),
                        const SizedBox(width: 8),
                        const Text(
                          'All',
                          style: TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Each item
                  ...items.map((t) {
                    final isSelected = safeSelected == t;
                    final count = allItems.where((x) => x == t).length;
                    return DropdownMenuItem<String?>(
                      value: t,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (t == 'Recived' ? kReceived : kPaid)
                                  : kMuted.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? (t == 'Recived' ? kReceived : kPaid)
                                  : AppTheme.iconColorThree(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (t == 'Recived' ? kReceived : kPaid)
                                        .withOpacity(0.10)
                                  : kMuted.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? (t == 'Recived' ? kReceived : kPaid)
                                    : kMuted,
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: t == 'Recived' ? kReceived : kPaid,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  onFilterChanged(val == safeSelected ? null : val);
                },
              ),
            ),
          )
        else
          // ✅ Single unique value — show plain icon, no dropdown
          Icon(
            HugeIconsStroke.arrowDown01,
            size: 14,
            color: AppTheme.iconColorTwo(context).withOpacity(0.3),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onClear;

  const _FilterChip({
    required this.label,
    this.color = kPrimary,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.sliderHighlightBg(context).withOpacity(0.50)
          : color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColor.neutral_70
            : color.withOpacity(0.3),
        width: 0.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.iconColorThree(context)
                : color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onClear,
          child: Icon(
            Icons.close_rounded,
            size: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.iconColorThree(context)
                : color,
          ),
        ),
      ],
    ),
  );
}
