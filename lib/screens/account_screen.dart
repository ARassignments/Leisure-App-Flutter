import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/appsnackbar.dart';
import '/notifiers/avatar_notifier.dart';
import '/screens/customers_screen.dart';
import '/screens/payments_screen.dart';
import '/screens/profile_screen.dart';
import '/screens/scraps_screen.dart';
import '/screens/settings/payment_type_settings.dart';
import '/screens/subscription_screen.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with AutomaticKeepAliveClientMixin {
  String? token;
  Map<String, dynamic>? user;
  bool _isLoadingUser = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _initAvatar();
  }

  Future<void> _loadSession() async {
    token = await SessionManager.getUserToken();
    final userData = await SessionManager.getUser();
    setState(() {
      user = userData;
      _isLoadingUser = false;
    });
  }

  Future<void> _initAvatar() async {
    final avatarData = await SessionManager.getAvatarAndGender();
    if (avatarData["avatar"] != null) {
      avatarNotifier.updateAvatar(avatarData["avatar"]!);
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(icon, size: 24),
      title: Text(label, style: AppTheme.textLabel(context)),
      subtitle: Text(
        value.isNotEmpty ? value : "Not provided",
        style: AppTheme.textSearchInfoLabeled(context).copyWith(fontSize: 12),
      ),
    );
  }

  String formatInternationalPhone(String number) {
    if (number.startsWith("0")) {
      return "+92 ${number.substring(1, 4)} ${number.substring(4, 7)} ${number.substring(7)}";
    }
    return number;
  }

  Widget _accountsPage() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: avatarNotifier,
              builder: (context, avatar, _) {
                return Column(
                  children: [
                    Hero(
                      tag: 'profile-avatar',
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.customListBg(context),
                          foregroundImage: avatar != null
                              ? AssetImage(avatar)
                              : const AssetImage(
                                  "assets/images/avatars/boy_14.png",
                                ),
                          child: avatar != null
                              ? Icon(
                                  HugeIconsSolid.user03,
                                  size: 60,
                                  color: AppTheme.iconColorThree(context),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Profile Details",
                      style: AppTheme.textTitle(context).copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              HugeIconsStroke.user03,
                              "Name",
                              user!["FullName"],
                            ),
                            Divider(
                              height: 1,
                              color: AppTheme.dividerBg(context),
                            ),
                            _buildInfoTile(
                              HugeIconsStroke.mail01,
                              "Email",
                              user!["Email"],
                            ),
                            Divider(
                              height: 1,
                              color: AppTheme.dividerBg(context),
                            ),
                            _buildInfoTile(
                              HugeIconsStroke.call02,
                              "Contact",
                              formatInternationalPhone(
                                "${user!["PhoneNumber"]}",
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: AppTheme.dividerBg(context),
                            ),
                            _buildInfoTile(
                              HugeIconsStroke.mapsLocation01,
                              "Address",
                              user!["Address"],
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: FlatButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => ProfileScreen(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            const begin = Offset(0.0, 1.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;
                                            final tween = Tween(
                                              begin: begin,
                                              end: end,
                                            ).chain(CurveTween(curve: curve));
                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                icon: HugeIconsSolid.edit01,
                                radiusCustom: true,
                                radius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                text: "Edit Profile",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.userGroup, size: 24),
                      title: Text(
                        "Customers",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    CustomersScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        HugeIconsStroke.moneyReceiveFlow01,
                        size: 24,
                      ),
                      title: Text(
                        "Payments",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PaymentsScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.recycle02, size: 24),
                      title: Text("Scraps", style: AppTheme.textLabel(context)),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    ScrapsScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.userGroup03, size: 24),
                      title: Text(
                        "Manage Users",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {},
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        HugeIconsStroke.messageMultiple02,
                        size: 24,
                      ),
                      title: Text(
                        "Messages",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // ListTile(
                    //   contentPadding: const EdgeInsets.symmetric(
                    //     horizontal: 16,
                    //     vertical: 8,
                    //   ),
                    //   leading: Icon(HugeIconsStroke.shoppingBag01, size: 24),
                    //   title: Text(
                    //     "View Orders",
                    //     style: AppTheme.textLabel(context),
                    //   ),
                    //   trailing: _filteredOrders.length > 0
                    //       ? AnimatedContainer(
                    //           duration: const Duration(milliseconds: 250),
                    //           padding: const EdgeInsets.all(10),
                    //           decoration: BoxDecoration(
                    //             color: AppTheme.cardDarkBg(context),
                    //             shape: BoxShape.circle,
                    //           ),
                    //           child: Text(
                    //             _filteredOrders.length.toString().padLeft(
                    //               2,
                    //               '0',
                    //             ),
                    //             style: AppTheme.textSearchInfoLabeled(
                    //               context,
                    //             ).copyWith(fontSize: 10),
                    //           ),
                    //         )
                    //       : null,
                    //   onTap: () {
                    //     setState(() => _currentIndex = 1);
                    //   },
                    // ),
                    // Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.payment01, size: 24),
                      title: Text(
                        "Payment Types",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PaymentTypeSettingsScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
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
                        value: Theme.of(context).brightness == Brightness.dark,
                        activeColor: AppTheme.iconColor(context),
                        onChanged: (value) {
                          ThemeController.setTheme(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                      onTap: () {
                        final isDark =
                            ThemeController.themeNotifier.value ==
                            ThemeMode.dark;
                        ThemeController.setTheme(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.crown03, size: 24),
                      title: Text(
                        "Subscription",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SubscriptionScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.note, size: 24),
                      title: Text(
                        "Privacy Policy",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {},
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.headset, size: 24),
                      title: Text(
                        "Help Center",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () {},
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        HugeIconsStroke.chartBreakoutCircle,
                        size: 24,
                      ),
                      title: Text(
                        "About Y2K Solutions",
                        style: AppTheme.textLabel(context),
                      ),
                      onTap: () async {
                        final Uri url = Uri.parse('https://y2ksolutions.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode
                                .externalApplication, // opens in browser
                          );
                        } else {
                          AppSnackBar.show(
                            context,
                            message: "Could not open the website.",
                            type: AppSnackBarType.error,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlineErrorButton(
                  text: 'Log Out',
                  onPressed: () {
                    // DialogLogout().showDialog(context, _logout);
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
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
      body: _accountsPage(),
    );
  }
}
