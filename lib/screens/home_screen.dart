import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/components/dashboard_dead_stocks.dart';
import '/components/dashboard_ending_stocks.dart';
import '/components/dashboard_grid.dart';
import '/components/dashboard_monthly_scraps.dart';
import '/components/dashboard_payment_summary.dart';
import '/components/dashboard_slider.dart';
import '/components/dashboard_top_customers.dart';
import '/components/dashboard_top_products.dart';
import '/notifiers/avatar_notifier.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  String? token;
  Map<String, dynamic>? user;

  // Dashboard Screen
  bool _isLoadingDashboardReport = true;
  bool _isChartView = true;
  bool _showScrollToTop = false;
  DateTime _fromDateDashboardReport = DateTime.now();
  DateTime _toDateDashboardReport = DateTime.now();
  final TextEditingController _filterDashboardController =
      TextEditingController();
  final ScrollController _scrollControllerDashboard = ScrollController();
  int grandOrderTotalDashboard = 0;
  double grandRevenueTotalDashboard = 0;
  double grandCreditTotalDashboard = 0;
  double grandDebitTotalDashboard = 0;
  List<dynamic> topCustomers = [];
  List<dynamic> topProducts = [];
  List<dynamic> deadStocks = [];
  List<dynamic> endingStocks = [];
  List<dynamic> monthlyScrap = [];
  List<dynamic> paymentSummary = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollControllerDashboard.addListener(_onDashboardScroll);
    _loadDashboardReport();
    _initAvatar();
  }

  @override
  void dispose() {
    _scrollControllerDashboard.removeListener(_onDashboardScroll);
    super.dispose();
  }

  void _onDashboardScroll() {
    final shouldShow = _scrollControllerDashboard.offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _initAvatar() async {
    final avatarData = await SessionManager.getAvatarAndGender();
    if (avatarData["avatar"] != null) {
      avatarNotifier.updateAvatar(avatarData["avatar"]!);
    }
  }

  Future<void> _loadDashboardReport() async {
    setState(() => _isLoadingDashboardReport = true);
    try {
      final fromDateFormatted = DateFormat(
        'yyyy-MM-dd',
      ).format(_fromDateDashboardReport);
      final toDateFormatted = DateFormat(
        'yyyy-MM-dd',
      ).format(_toDateDashboardReport);
      final response = await ApiService.getDashboardReport(
        fromDate: fromDateFormatted,
        toDate: toDateFormatted,
        fromMonth: fromDateFormatted,
        toMonth: toDateFormatted,
      );

      DateTime fromDate = DateTime.parse(fromDateFormatted);
      DateTime toDate = DateTime.parse(toDateFormatted);

      grandOrderTotalDashboard = 0;
      grandRevenueTotalDashboard = 0;
      grandCreditTotalDashboard = 0;
      grandDebitTotalDashboard = 0;
      for (var item in response.dashboard.DailyOrders) {
        DateTime orderDate = DateTime.parse(item["OrderDate"]);
        if (orderDate.isAfter(fromDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(toDate.add(const Duration(days: 1)))) {
          int totalOrders = item["TotalOrders"] ?? 0;
          grandOrderTotalDashboard += totalOrders;
        }
      }
      for (var item in response.dashboard.DailyRevenue) {
        DateTime orderDate = DateTime.parse(item["OrderDate"]);
        if (orderDate.isAfter(fromDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(toDate.add(const Duration(days: 1)))) {
          double totalRevenue = item["DailyRevenue"] ?? 0;
          grandRevenueTotalDashboard += totalRevenue;
        }
      }
      for (var item in response.dashboard.DailyCreditProfit) {
        DateTime orderDate = DateTime.parse(item["OrderDate"]);
        if (orderDate.isAfter(fromDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(toDate.add(const Duration(days: 1)))) {
          double totalCredit = item["DailyProfit"] ?? 0;
          grandCreditTotalDashboard += totalCredit;
        }
      }
      for (var item in response.dashboard.DailyDebitProfit) {
        DateTime orderDate = DateTime.parse(item["OrderDate"]);
        if (orderDate.isAfter(fromDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(toDate.add(const Duration(days: 1)))) {
          double totalDebit = item["DailyProfit"] ?? 0;
          grandDebitTotalDashboard += totalDebit;
        }
      }
      setState(() {
        topCustomers = response.dashboard.TopCustomer;
        topProducts = response.dashboard.TopProducts;
        deadStocks = response.dashboard.DeadStock;
        endingStocks = response.dashboard.EndingStock;
        monthlyScrap = response.dashboard.MonthlyScap;
        paymentSummary = response.dashboard.PaymentDetails;
      });
    } catch (e) {
      debugPrint("❌ Error fetching dashboard report: $e");
    } finally {
      setState(() => _isLoadingDashboardReport = false);
    }
  }

  Future<void> _selectDateRangeForDahboardReport(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fromDateDashboardReport,
        end: _toDateDashboardReport,
      ),
    );

    if (picked != null) {
      setState(() {
        _fromDateDashboardReport = picked.start;
        _toDateDashboardReport = picked.end;
        _filterDashboardController.text =
            "From: ${DateFormat('yyyy-MM-dd').format(_fromDateDashboardReport)} - "
            "To: ${DateFormat('yyyy-MM-dd').format(_toDateDashboardReport)}";
      });
      await _loadDashboardReport();
    }
  }

  Widget _homePage() {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    _filterDashboardController.text =
        "From: ${DateFormat('yyyy-MM-dd').format(_fromDateDashboardReport)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDateDashboardReport)}";
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollControllerDashboard,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: isDesktop ? 20 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardSlider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _filterDashboardController,
                  readOnly: true,
                  selectAllOnFocus: false,
                  textAlign: TextAlign.start,
                  onTap: () {
                    _selectDateRangeForDahboardReport(context);
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Date Range',
                    hintText: 'Select From Date - To Date',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                      child: Icon(HugeIconsSolid.calendar03),
                    ),
                  ),
                  style: AppInputDecoration.inputTextStyle(context),
                ),
              ),
              SizedBox(height: 16),
              Stack(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 500),
                    scale: _isLoadingDashboardReport ? 0.8 : 1.0,
                    child: AnimatedOpacity(
                      opacity: _isLoadingDashboardReport ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: DashboardGrid(
                        ordersValue: grandOrderTotalDashboard,
                        revenueValue: grandRevenueTotalDashboard,
                        creditSaleValue: grandCreditTotalDashboard,
                        debitSaleValue: grandDebitTotalDashboard,
                      ),
                    ),
                  ),
                  if (_isLoadingDashboardReport)
                    Positioned.fill(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedScale(
                        scale: _isLoadingDashboardReport ? 1.0 : 1.8,
                        duration: const Duration(milliseconds: 500),
                        child: AnimatedOpacity(
                          opacity: _isLoadingDashboardReport ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: AppTheme.inputProgress(context),
                                strokeWidth: 4,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1200
                        ? 3
                        : constraints.maxWidth > 900
                        ? 2
                        : 1;

                    final widgets = [
                      DashboardTopCustomers(
                        customers: topCustomers
                            .map(
                              (e) => TopCustomer.fromJson(
                                e as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                        isChartView: _isChartView,
                        isLoading: _isLoadingDashboardReport,
                        onToggle: (val) => setState(() => _isChartView = val),
                      ),
                      DashboardTopProducts(
                        products: topProducts
                            .map(
                              (e) => TopProduct.fromJson(
                                e as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                        isChartView: _isChartView,
                        isLoading: _isLoadingDashboardReport,
                        onToggle: (val) => setState(() => _isChartView = val),
                      ),
                      DashboardDeadStock(
                        items: deadStocks
                            .map(
                              (e) => DeadStockItem.fromJson(
                                e as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                        isChartView: _isChartView,
                        isLoading: _isLoadingDashboardReport,
                        onToggle: (val) => setState(() => _isChartView = val),
                      ),
                      DashboardEndingStock(
                        items: endingStocks
                            .map(
                              (e) => EndingStockItem.fromJson(
                                e as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                        isChartView: _isChartView,
                        isLoading: _isLoadingDashboardReport,
                        onToggle: (val) => setState(() => _isChartView = val),
                      ),
                      DashboardMonthlyScrap(
                        items: monthlyScrap
                            .map(
                              (e) => MonthlyScrapItem.fromJson(
                                e as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                        isChartView: _isChartView,
                        isLoading: _isLoadingDashboardReport,
                        onToggle: (val) => setState(() => _isChartView = val),
                      ),
                      DashboardPaymentsSummary(
                        items: paymentSummary
                            .map(
                              (e) => PaymentSummary.fromJson(
                                e as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                        isChartView: _isChartView,
                        isLoading: _isLoadingDashboardReport,
                        onToggle: (val) => setState(() => _isChartView = val),
                      ),
                    ];
                    return MasonryGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widgets.length,
                      itemBuilder: (context, index) => widgets[index],
                    );
                  },
                ),
              ),
              // DashboardCharts(),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  "Need Help?",
                  style: AppTheme.textLabel(context).copyWith(
                    fontSize: 14,
                    fontFamily: AppFontFamily.poppinsSemiBold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.5,
                        child: InkWell(
                          child: Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.customListBg(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "FAQs",
                                    style: AppTheme.textLink(context).copyWith(
                                      fontSize: 13,
                                      fontFamily: AppFontFamily.poppinsSemiBold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -40,
                                bottom: -35,
                                child: Image.asset(
                                  "assets/images/dashboard/faqs_image.png",
                                  height: 180,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: 0.5,
                        child: InkWell(
                          child: Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.customListBg(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "Chat Now",
                                    style: AppTheme.textLink(context).copyWith(
                                      fontSize: 13,
                                      fontFamily: AppFontFamily.poppinsSemiBold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -40,
                                bottom: -28,
                                child: Image.asset(
                                  "assets/images/dashboard/chat_image.png",
                                  height: 180,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Column(
              //   children: [
              //     Text("Welcome, ${user?["FullName"] ?? "Guest"}"),
              //     Text("Email: ${user?["Email"] ?? "N/A"}"),
              //     Text("Organization Id: ${user?["OrganizationId"] ?? "Unknown"}"),
              //     Text("Token: ${token ?? "Not available"}"),
              //   ],
              // ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget toggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.customListBg(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppTheme.iconColor(context)
                    : AppTheme.iconColorThree(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _homePage(),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(right: 0),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 3,
              top: 35,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: 1.0,
                child: SizedBox(
                  width: 111,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.sliderHighlightBg(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        toggleBtn('Chart', _isChartView, () {
                          setState(() => _isChartView = true);
                        }),
                        toggleBtn('List', !_isChartView, () {
                          setState(() => _isChartView = false);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showScrollToTop ? 5 : -60,
              right: 3,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showScrollToTop ? 1.0 : 0.0,
                child: FloatingActionButton.small(
                  heroTag: "scrollToTopDashboard",
                  backgroundColor: AppTheme.sliderHighlightBg(context),
                  elevation: 0,
                  focusElevation: 0,
                  hoverElevation: 0,
                  highlightElevation: 0,
                  onPressed: () {
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   _scrollControllerDashboard.jumpTo(0);
                    // });
                    _scrollControllerDashboard.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
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
    );
  }
}
