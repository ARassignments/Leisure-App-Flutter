import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/screens/order_detail_screen.dart';
import '/Models/order_model.dart';
import '/components/not_found.dart';
import '/Models/customer_model.dart';
import '/components/dialog_logout.dart';
import '/components/loading_screen.dart';
import '/responses/customer_response.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? token;
  Map<String, dynamic>? user;

  int _currentIndex = 0;
  List<String> menus = ["Home", "Orders", "Customers", "Accounts"];

  //Customers Screen
  late Future<CustomerResponse> _futureCustomers;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  //Orders Screen
  List<Order> _orders = [];
  bool _isLoadingOrders = true;
  bool _isRefreshingOrders = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final TextEditingController _searchOrderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchOrderController.addListener(_onSearchChanged);
    _loadSessionAndCustomers();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchOrderController.removeListener(_onSearchChanged);
    _searchOrderController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((cust) {
        return cust.UserName.toLowerCase().contains(query) ||
            cust.CityName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadSessionAndCustomers() async {
    token = await SessionManager.getUserToken();
    user = await SessionManager.getUser();

    _futureCustomers = ApiService.getAllCustomers();
    try {
      final response = await _futureCustomers;
      setState(() {
        _allCustomers = response.accounts;
        _filteredCustomers = response.accounts;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
    }
  }

  Future<void> _refreshCustomers() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await ApiService.getAllCustomers();
      setState(() {
        _allCustomers = response.accounts;
        _filteredCustomers = response.accounts;
        _searchController.clear();
      });
    } catch (e) {
      debugPrint("Error refreshing customers: $e");
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final response = await ApiService.getAllOrders(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
      );
      debugPrint("Orders fetched: ${response.orders.length}");
      setState(() {
        _orders = response.orders;
      });
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    } finally {
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _refreshOrders() async {
    setState(() => _isRefreshingOrders = true);
    await _loadOrders();
    setState(() => _isRefreshingOrders = false);
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
      await _loadOrders();
    }
  }

  List<Widget> _pages() {
    return [_homePage(), _ordersPage(), _customersPage(), _accountsPage()];
  }

  Widget _homePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Welcome, ${user!["FullName"]}"),
          Text("Email: ${user!["Email"]}"),
          Text("Organization Id: ${user!["OrganizationId"]}"),
          Text("Token: $token"),
        ],
      ),
    );
  }

  Widget _ordersPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextFormField(
                controller: _searchOrderController,
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
                      if (_searchOrderController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _searchOrderController.clear();
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(HugeIconsSolid.calendar01),
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
              if (_searchOrderController.text.isNotEmpty) ...[
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(context),
                        children: [
                          TextSpan(text: 'Result for "'),
                          TextSpan(
                            text: _searchOrderController.text,
                            style: AppTheme.textSearchInfoLabeled(context),
                          ),
                          TextSpan(text: '"'),
                        ],
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: AppTheme.textSearchInfoLabeled(context),
                        children: [
                          TextSpan(text: _filteredCustomers.length.toString()),
                          TextSpan(text: ' found'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              Text(
                "From: ${DateFormat('yyyy-MM-dd').format(_fromDate)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDate)}",
                style: AppTheme.textLabel(context).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingOrders
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: _orders.isEmpty
                      ? NotFoundWidget(
                          title: "No Orders Found",
                          message:
                              "No orders found for the selected date range.",
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final formattedDate = DateFormat(
                              'dd MMM yyyy',
                            ).format(order.OrderDate);
                            final formattedAmount = NumberFormat(
                              '#,###.00',
                            ).format(order.Payable);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              color: AppTheme.customListBg(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        orderId: order.OrderId,
                                      ),
                                    ),
                                  );
                                },
                                leading: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontFamily: AppFontFamily.poppinsMedium,
                                  ),
                                ),
                                title: Text(
                                  order.UserName,
                                  style: AppTheme.textLabel(context).copyWith(
                                    fontFamily: AppFontFamily.poppinsSemiBold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Ref No: ${order.RefNo}"),
                                    Text("Date: $formattedDate"),
                                    Text("Status: ${order.OrderStatus}"),
                                  ],
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
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
                                    Text("Qty: ${order.Quantity}"),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _accountsPage() {
    return ListView(
      shrinkWrap: true,
      children: [
        SizedBox(height: 16),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.customListBg(context),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl:
                    "https://firebasestorage.googleapis.com/v0/b/urban-harmony-8fd99.appspot.com/o/ProfileImages%2Fboy_14.png?alt=media&token=7e4a25da-ffca-4374-b9aa-727b28b7bf0c",
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(HugeIconsSolid.user03, size: 24),
              ),
            ),
          ),
          title: Text(
            "${user!["FullName"]}",
            style: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 17, fontFamily: AppFontFamily.poppinsSemiBold),
          ),
          subtitle: Text(
            "View Profile",
            style: AppTheme.textLink(
              context,
            ).copyWith(fontSize: 12, fontFamily: AppFontFamily.poppinsRegular),
          ),
          onTap: () {
            // Handle profile click
          },
        ),
        Divider(
          thickness: 30,
          height: 30,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColor.neutral_80
              : AppColor.neutral_10,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? HugeIconsStroke.moon02
                : HugeIconsStroke.sun02,
            size: 24,
          ),
          title: Text(
            Theme.of(context).brightness == Brightness.dark
                ? "Dark Mode"
                : "Light Mode",
            style: AppTheme.textLabel(context),
          ),
          trailing: Switch(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              ThemeController.setTheme(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          onTap: () {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            ThemeController.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        Divider(
          height: 1,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColor.neutral_80
              : AppColor.neutral_10,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.chartBreakoutCircle, size: 24),
          title: Text("About App", style: AppTheme.textLabel(context)),
          onTap: () {},
        ),
        Divider(
          height: 1,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColor.neutral_80
              : AppColor.neutral_10,
        ),
        SizedBox(height: 50),
        ListTile(
          title: OutlineErrorButton(
            text: 'Log Out',
            onPressed: () {
              DialogLogout().showDialog(context, _logout);
            },
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _customersPage() {
    double grandTotal = _filteredCustomers.fold(
      0.0,
      (previousValue, customer) => previousValue + customer.OpeningBalance,
    );
    final formattedGrandTotal = NumberFormat('#,###.00').format(grandTotal);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Search Here',
                  hintText: 'Search by name or city',
                  counter: const SizedBox.shrink(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.search01),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(HugeIconsStroke.cancel02),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        )
                      : null,
                ),
                style: AppInputDecoration.inputTextStyle(context),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                    return 'Must contain only letters';
                  }
                  return null;
                },
                maxLength: 20,
              ),
              if (_searchController.text.isNotEmpty) ...[
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(context),
                        children: [
                          TextSpan(text: 'Result for "'),
                          TextSpan(
                            text: _searchController.text,
                            style: AppTheme.textSearchInfoLabeled(context),
                          ),
                          TextSpan(text: '"'),
                        ],
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: AppTheme.textSearchInfoLabeled(context),
                        children: [
                          TextSpan(text: _filteredCustomers.length.toString()),
                          TextSpan(text: ' found'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _isRefreshing
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshCustomers,
                  backgroundColor: Colors.transparent,
                  child: _filteredCustomers.isEmpty
                      ? NotFoundWidget(
                          title: "No Customers Found",
                          message:
                              "Sorry, the keyword you entered cannot be found, please check again or search wit another keyword.",
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final formattedBalance = NumberFormat(
                              '#,###.00',
                            ).format(customer.OpeningBalance);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
                              ),
                              color: AppTheme.customListBg(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () {},
                                leading: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontFamily: AppFontFamily.poppinsMedium,
                                  ),
                                ),
                                title: Text(
                                  customer.UserName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.textLabel(context).copyWith(
                                    fontFamily: AppFontFamily.poppinsSemiBold,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      HugeIconsStroke.mapsLocation02,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      customer.CityName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily:
                                            AppFontFamily.poppinsRegular,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  "Rs $formattedBalance",
                                  style: AppTheme.textSearchInfoLabeled(context)
                                      .copyWith(
                                        fontFamily: AppFontFamily.poppinsBold,
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
        if (_filteredCustomers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
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
                        text: 'Total Balance:',
                      ),
                    ),
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
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                Image.asset(AppTheme.appLogo(context), height: 120, width: 60),
                const SizedBox(width: 10),
                Text(
                  "My",
                  style: AppTheme.textTitle(context).copyWith(
                    fontSize: 20,
                    fontFamily: AppFontFamily.poppinsBold,
                  ),
                ),
                Text(
                  menus[_currentIndex],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.textTitle(context).copyWith(
                    fontSize: 20,
                    fontFamily: AppFontFamily.poppinsLight,
                  ),
                ),
                Text(
                  ".",
                  style: AppTheme.textTitle(context).copyWith(fontSize: 30),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(HugeIconsStroke.refresh, size: 20),
              onPressed: _refreshOrders, // ✅ Correct function
            ),
          if (_currentIndex == 2)
            IconButton(
              icon: const Icon(HugeIconsStroke.refresh, size: 20),
              onPressed: () {
                _refreshCustomers;
              },
            ),
          IconButton(
            onPressed: () {
              DialogLogout().showDialog(context, _logout);
            },
            icon: const Icon(HugeIconsStroke.logout02, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: user == null
          ? const CircularProgressIndicator()
          : pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        elevation: 0,
        iconSize: 24,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedLabelStyle: AppTheme.textLabel(context).copyWith(fontSize: 12),
        unselectedLabelStyle: AppTheme.textLabel(
          context,
        ).copyWith(fontSize: 11),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: AppTheme.onBoardingDotActive(context),
        unselectedItemColor: AppTheme.onBoardingDot(context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(HugeIconsStroke.home11),
            activeIcon: Icon(HugeIconsSolid.home11),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIconsStroke.shoppingBasket01),
            activeIcon: Icon(HugeIconsSolid.shoppingBasket01),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIconsStroke.userMultiple02),
            activeIcon: Icon(HugeIconsSolid.userMultiple02),
            label: "Customers",
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIconsStroke.user03),
            activeIcon: Icon(HugeIconsSolid.user03),
            label: "Accounts",
          ),
        ],
      ),
    );
  }
}
