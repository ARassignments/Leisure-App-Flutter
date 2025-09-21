import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
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
  List<String> menus = ["Home", "Customers", "Accounts"];
  late Future<CustomerResponse> _futureCustomers;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSessionAndCustomers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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

  List<Widget> _pages() {
    return [_homePage(), _customersPage(), _accountsPage()];
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
            radius: 48,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.asset(
                AppTheme.appLogo(context), // replace with your image
                width: 86,
                height: 100,
                fit: BoxFit.cover,
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
                  child: _filteredCustomers.isEmpty
                      ? Center(
                          child: Text(
                            "No Customers Found",
                            style: AppTheme.textTitle(
                              context,
                            ).copyWith(fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final formattedBalance = NumberFormat(
                              '#,###.00',
                            ).format(customer.OpeningBalance);
                            return ListTile(
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
                                      fontFamily: AppFontFamily.poppinsRegular,
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
