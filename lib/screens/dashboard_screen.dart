import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/responses/customer_response.dart';
import '/services/api_service.dart';
import '/Models/customer_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSession();
    _futureCustomers = ApiService.getAllCustomers();
  }

  Future<void> _loadSession() async {
    token = await SessionManager.getUserToken();
    user = await SessionManager.getUser();
    setState(() {});
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
    return [_home(), _allCustomers(), _accounts()];
  }

  Widget _home() {
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

  Widget _accounts() {
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
              showModalBottomSheet(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      left: 30,
                      right: 30,
                    ),
                    child: Wrap(
                      children: [
                        Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Logout",
                              textAlign: TextAlign.center,
                              style: AppTheme.textLabel(context).copyWith(
                                fontSize: 16,
                                fontFamily: AppFontFamily.poppinsBold,
                              ),
                            ),
                            const Divider(),
                            Text(
                              "Are you sure you want to log out?",
                              textAlign: TextAlign.center,
                              style: AppTheme.textLabel(context),
                            ),
                            OutlineErrorButton(
                              text: "Yes, Logout",
                              onPressed: () {
                                Navigator.pop(context);
                                _logout();
                              },
                            ),
                            FlatButton(
                              text: "Cancel",
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _allCustomers() {
    return FutureBuilder<CustomerResponse>(
      future: _futureCustomers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.accounts.isEmpty) {
          return const Center(child: Text("No customers found"));
        }

        final customers = snapshot.data!.accounts;
        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return ListTile(
              title: Text(customer.UserName),
              subtitle: Text(customer.CityName),
              trailing: Text(
                customer.OpeningBalance.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
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
                setState(() {
                  _futureCustomers = ApiService.getAllCustomers();
                });
              },
            ),
          IconButton(
            onPressed: _logout,
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
        selectedLabelStyle: AppTheme.textLabel(context).copyWith(fontSize: 14),
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
