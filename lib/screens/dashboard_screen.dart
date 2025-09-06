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
    return [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${user!["FullName"]}"),
            Text("Email: ${user!["Email"]}"),
            Text("Organization Id: ${user!["OrganizationId"]}"),
            Text("Token: $token"),
          ],
        ),
      ),
      _allCustomers(),
      // const Center(child: Text("💰 Accounts Screen")),
      const Center(child: Text("💰 Accounts Screen")),
    ];
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
        title: const Text("Dashboard"),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _futureCustomers = ApiService.getAllCustomers();
                });
              },
            ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: user == null
          ? const CircularProgressIndicator()
          : Center(
              child: SingleChildScrollView(
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [pages[_currentIndex]],
                  ),
                ),
              ),
            ),
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
            label: "Users",
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
