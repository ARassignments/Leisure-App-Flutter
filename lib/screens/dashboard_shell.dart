import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html show document, Element;
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/appsnackbar.dart';
import '/services/api_service.dart';
import '/components/dialog_bounce.global.dart';
import '/screens/payments_screen.dart';
import '/screens/desktop/payments_screen.dart';
import '/screens/account_screen.dart';
import '/screens/login_screen.dart';
import '/utils/session_manager.dart';
import '/screens/customers_screen.dart';
import '/screens/scraps_screen.dart';
import '/screens/home_screen.dart';
import '/theme/theme.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell>
    with SingleTickerProviderStateMixin {
  String? token;
  Map<String, dynamic>? user;
  bool _isLoadingUser = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _globalFocusNode = FocusNode();
  bool _isFullscreen = false;
  late final List<NavItem> _navItems;
  final HomeScreen homeScreen = const HomeScreen();
  final PaymentsTableScreen paymentScreen = const PaymentsTableScreen();
  // final PaymentsScreen paymentScreen = const PaymentsScreen();
  final ScrapsScreen scrapScreen = const ScrapsScreen();
  final CustomersScreen customerScreen = const CustomersScreen();
  bool _sidebarOpen = true;
  bool _profileMenuOpen = false;
  bool _dropdownHovered = false;
  int _activeIndex = 0;
  int _previousIndex = 0;
  String _activeLabel = 'Dashboard';
  late final List<Widget> _pages;
  late final List<String> _pageLabels;

  static const double _sidebarExpanded = 220;
  static const double _sidebarCollapsed = 80;

  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final AnimationController _sidebarCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1.0,
  );
  late final Animation<double> _sidebarAnim = CurvedAnimation(
    parent: _sidebarCtrl,
    curve: Curves.easeInOutCubic,
  );

  Future<void> _loadSession() async {
    token = await SessionManager.getUserToken();
    final userData = await SessionManager.getUser();
    setState(() {
      user = userData;
      _isLoadingUser = false;
    });
  }

  void _toggleSidebar() {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      setState(() => _sidebarOpen = !_sidebarOpen);
      _sidebarOpen ? _sidebarCtrl.forward() : _sidebarCtrl.reverse();
    } else {
      final scaffold = _scaffoldKey.currentState;
      if (scaffold == null) return;
      scaffold.isDrawerOpen ? scaffold.closeDrawer() : scaffold.openDrawer();
    }
  }

  void _toggleFullscreen() {
    if (!kIsWeb) return;
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      html.document.documentElement?.requestFullscreen();
    } else {
      html.document.exitFullscreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
    _navItems = [
      NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/',
        page: homeScreen,
      ),
      NavItem(
        label: 'Orders',
        icon: Icons.shopping_cart_outlined,
        route: '/orders',
      ),
      NavItem(
        label: 'Payments',
        icon: Icons.credit_card_outlined,
        route: '/payment',
        page: paymentScreen,
      ),
      NavItem(
        label: 'Scraps',
        icon: Icons.recycling_outlined,
        route: '/scrap',
        page: scrapScreen,
      ),
      NavItem(
        label: 'Claim/Exchange',
        icon: Icons.swap_horiz_rounded,
        route: '/claim',
      ),
      NavItem(
        label: 'Customers',
        icon: Icons.people_outline,
        route: '/users',
        page: customerScreen,
      ),
      NavItem(
        label: 'Product',
        icon: Icons.inventory_2_outlined,
        children: [
          NavItem(
            label: 'All Products',
            icon: Icons.list_alt_outlined,
            route: '/products',
          ),
          NavItem(
            label: 'Add Product',
            icon: Icons.add_box_outlined,
            route: '/products/add',
          ),
          NavItem(
            label: 'Categories',
            icon: Icons.category_outlined,
            route: '/products/categories',
          ),
        ],
      ),
      NavItem(
        label: 'Log Book',
        icon: Icons.menu_book_outlined,
        children: [
          NavItem(
            label: 'Daily Log',
            icon: Icons.today_outlined,
            route: '/logbook/daily',
          ),
          NavItem(
            label: 'Reports',
            icon: Icons.bar_chart_outlined,
            route: '/logbook/reports',
          ),
        ],
      ),
      NavItem(
        label: 'Configuration',
        icon: Icons.settings_outlined,
        children: [
          NavItem(
            label: 'City',
            icon: Icons.location_city_outlined,
            route: '/config/city',
          ),
          NavItem(
            label: 'State',
            icon: Icons.map_outlined,
            route: '/config/state',
          ),
          NavItem(
            label: 'Bank',
            icon: Icons.account_balance_outlined,
            route: '/config/bank',
          ),
          NavItem(
            label: 'Tax',
            icon: Icons.percent_outlined,
            route: '/config/tax',
          ),
          NavItem(
            label: 'Investors',
            icon: Icons.monetization_on_outlined,
            route: '/config/investors',
          ),
        ],
      ),
    ];
    _pages = [];
    _pageLabels = [];

    void collectPages(List<NavItem> items) {
      for (final item in items) {
        if (item.page != null) {
          item.pageIndex = _pages.length; // assign index to item
          _pages.add(item.page!);
          _pageLabels.add(item.label);
        }
        if (item.children.isNotEmpty) {
          collectPages(item.children);
        }
      }
    }

    collectPages(_navItems);
    _activeIndex = 0;
    _activeLabel = _pageLabels.isNotEmpty ? _pageLabels[0] : '';

    _navigatorKeys = List.generate(
      _pages.length,
      (_) => GlobalKey<NavigatorState>(),
    );

    if (kIsWeb) {
      // ✅ Browser fullscreen change (Esc, F11, etc.)
      html.document.onFullscreenChange.listen((_) {
        final isNow = html.document.fullscreenElement != null;
        if (mounted) setState(() => _isFullscreen = isNow);
      });
    }
  }

  @override
  void dispose() {
    _sidebarCtrl.dispose();
    _globalFocusNode.dispose();
    super.dispose();
  }

  void _onNavSelect(NavItem item) {
    if (item.pageIndex >= 0) {
      // ✅ Reset current (old) page stack
      _navigatorKeys[_activeIndex].currentState?.popUntil(
        (route) => route.isFirst,
      );

      setState(() {
        _previousIndex = _activeIndex;
        _activeIndex = item.pageIndex;
        _activeLabel = item.label;
        _profileMenuOpen = false;
        _dropdownHovered = false;
      });

      // ✅ Also reset new page stack (in case it was left mid-navigation)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKeys[_activeIndex].currentState?.popUntil(
          (route) => route.isFirst,
        );
      });
    }
  }

  void _closeProfileIfNotHovered() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_dropdownHovered && mounted) {
        setState(() => _profileMenuOpen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return KeyboardListener(
      focusNode: _globalFocusNode,
      autofocus: true, // ✅ always listening
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;

        // ✅ Escape — exit fullscreen
        if (event.logicalKey == LogicalKeyboardKey.escape && _isFullscreen) {
          if (!kIsWeb) {
            setState(() => _isFullscreen = false);
          }
        }

        // ✅ F11 — toggle fullscreen
        if (event.logicalKey == LogicalKeyboardKey.f11) {
          if (!kIsWeb) {
            setState(() => _isFullscreen = true);
          }
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.customListBg(context),
          // Mobile: use drawer
          drawer: isDesktop
              ? null
              : _SidebarDrawer(
                  navItems: _navItems,
                  activeIndex: _activeIndex,
                  onItemSelect: _onNavSelect,
                  userName: _isLoadingUser
                      ? ''
                      : user?["FullName"] ?? 'Unknown User',
                ),
          body: Row(
            children: [
              // ── Desktop Sidebar ──
              if (isDesktop)
                AnimatedBuilder(
                  animation: _sidebarAnim,
                  builder: (_, __) {
                    final w =
                        _sidebarCollapsed +
                        (_sidebarExpanded - _sidebarCollapsed) *
                            _sidebarAnim.value;
                    return SizedBox(
                      width: w,
                      child: _Sidebar(
                        navItems: _navItems,
                        activeIndex: _activeIndex,
                        collapsed: !_sidebarOpen,
                        animValue: _sidebarAnim.value,
                        onItemSelect: _onNavSelect,
                        onToggleItem: (item) {
                          setState(() {
                            for (final nav in _navItems) {
                              nav.expanded = nav == item
                                  ? !nav.expanded
                                  : false;
                            }
                          });
                        },
                        userName: _isLoadingUser
                            ? ''
                            : user?["FullName"] ?? 'Unknown User',
                      ),
                    );
                  },
                ),

              // ── Main content ──
              Expanded(
                child: Column(
                  children: [
                    // Topbar
                    _Topbar(
                      title: _activeLabel,
                      isDesktop: isDesktop,
                      isFullscreen: _isFullscreen,
                      onToggleFullscreen: _toggleFullscreen,
                      onMenuTap: _toggleSidebar,
                      profileOpen: _profileMenuOpen,
                      onProfileTap: () =>
                          setState(() => _profileMenuOpen = !_profileMenuOpen),
                      onProfileClose: _closeProfileIfNotHovered,
                      userName: _isLoadingUser
                          ? ''
                          : user?["FullName"] ?? 'Unknown User',
                      userImage: _isLoadingUser
                          ? ''
                          : user!["UserImage"] != 'N/A'
                          ? '${ApiService.getImagebaseUrl}${user!["UserImage"]}'
                          : '',
                    ),

                    // Page content
                    Expanded(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 60),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // ✅ Determine slide direction based on index
                                  final isForward =
                                      _activeIndex >= _previousIndex;

                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      // ✅ Slide from right if going forward, left if going back
                                      final begin = Offset(
                                        isForward ? 1.0 : -1.0,
                                        0.0,
                                      );
                                      final tween =
                                          Tween<Offset>(
                                            begin: begin,
                                            end: Offset.zero,
                                          ).chain(
                                            CurveTween(
                                              curve: Curves.easeOutCubic,
                                            ),
                                          );

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: IndexedStack(
                                      key: ValueKey(
                                        _activeIndex,
                                      ), // ✅ triggers AnimatedSwitcher
                                      index: _activeIndex,
                                      children: List.generate(_pages.length, (
                                        i,
                                      ) {
                                        final navigator = Navigator(
                                          key: _navigatorKeys[i],
                                          onGenerateRoute: (_) => PageRouteBuilder(
                                            opaque: true,
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) => _pages[i],
                                            transitionsBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  // ✅ Slide up animation for push inside navigator
                                                  const begin = Offset(
                                                    0.0,
                                                    0.04,
                                                  );
                                                  const end = Offset.zero;
                                                  final tween =
                                                      Tween(
                                                        begin: begin,
                                                        end: end,
                                                      ).chain(
                                                        CurveTween(
                                                          curve: Curves
                                                              .easeOutCubic,
                                                        ),
                                                      );

                                                  return SlideTransition(
                                                    position: animation.drive(
                                                      tween,
                                                    ),
                                                    child: FadeTransition(
                                                      opacity: CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.easeOut,
                                                      ),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                          ),
                                        );

                                        return SizedBox(
                                          key: ValueKey(i),
                                          width: constraints.maxWidth,
                                          height: constraints.maxHeight,
                                          child: navigator,
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Wrap(
                                direction: Axis.horizontal,
                                spacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runAlignment: WrapAlignment.center,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: AppTheme.textLabel(
                                        context,
                                      ).copyWith(fontSize: 14),
                                      children: [
                                        TextSpan(text: '2026 © '),
                                        TextSpan(
                                          text: 'Y2k Solutions',
                                          style: AppTheme.textLink(
                                            context,
                                          ).copyWith(fontSize: 14),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () async {
                                              final Uri url = Uri.parse(
                                                'https://www.y2ksolutions.com/',
                                              );
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                  mode: LaunchMode
                                                      .externalApplication, // opens in browser
                                                );
                                              } else {
                                                AppSnackBar.show(
                                                  context,
                                                  message:
                                                      "Could not open the website.",
                                                  type: AppSnackBarType.error,
                                                );
                                              }
                                              debugPrint(
                                                "Y2k Solutions clicked",
                                              );
                                            },
                                        ),
                                        TextSpan(text: '. All Right Reserved'),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      style: AppTheme.textLabel(
                                        context,
                                      ).copyWith(fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: 'Designed & Developed by ',
                                        ),
                                        TextSpan(
                                          text: 'AR Assignments',
                                          style: AppTheme.textLink(
                                            context,
                                          ).copyWith(fontSize: 14),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () async {
                                              final Uri url = Uri.parse(
                                                'https://myfolio-web.netlify.app/',
                                              );
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                  mode: LaunchMode
                                                      .externalApplication, // opens in browser
                                                );
                                              } else {
                                                AppSnackBar.show(
                                                  context,
                                                  message:
                                                      "Could not open the website.",
                                                  type: AppSnackBarType.error,
                                                );
                                              }
                                              debugPrint(
                                                "AR Assignments clicked",
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Profile dropdown
                          // if (_profileMenuOpen)
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.bounceInOut,
                            top: _profileMenuOpen ? 0 : 50,
                            right: 20,
                            child: AnimatedOpacity(
                              duration: Duration(microseconds: 300),
                              opacity: _profileMenuOpen ? 1.0 : 0.0,
                              child: _profileMenuOpen
                                  ? MouseRegion(
                                      onEnter: (_) => setState(
                                        () => _dropdownHovered = true,
                                      ),
                                      onExit: (_) {
                                        setState(
                                          () => _dropdownHovered = false,
                                        );
                                        _closeProfileIfNotHovered();
                                      },
                                      child: _ProfileDropdown(
                                        onClose: () => setState(() {
                                          _profileMenuOpen = false;
                                          _dropdownHovered = false;
                                        }),
                                        activeNavigatorKey:
                                            _navigatorKeys[_activeIndex],
                                        userName: _isLoadingUser
                                            ? ''
                                            : user?["FullName"] ??
                                                  'Unknown User',
                                        userImage: _isLoadingUser
                                            ? ''
                                            : user!["UserImage"] != 'N/A'
                                            ? '${ApiService.getImagebaseUrl}${user!["UserImage"]}'
                                            : '',
                                        userType: _isLoadingUser
                                            ? ''
                                            : user?["UserType"] ??
                                                  'Unknown User',
                                        userEmail: _isLoadingUser
                                            ? ''
                                            : user?["Email"] ??
                                                  'info@y2ksolutions.com',
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class NavItem {
  final String label;
  final IconData icon;
  final String? route;
  final Widget? page;
  final List<NavItem> children;
  bool expanded;
  int pageIndex;

  NavItem({
    required this.label,
    required this.icon,
    this.route,
    this.page,
    this.children = const [],
    this.expanded = false,
    this.pageIndex = -1,
  });
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<NavItem> navItems;
  final int activeIndex;
  final bool collapsed;
  final double animValue;
  final ValueChanged<NavItem> onItemSelect;
  final ValueChanged<NavItem> onToggleItem;
  final String userName;

  const _Sidebar({
    required this.navItems,
    required this.activeIndex,
    required this.collapsed,
    required this.animValue,
    required this.onItemSelect,
    required this.onToggleItem,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userName.trim().isNotEmpty
        ? userName.trim().split(' ').length >= 2
              ? '${userName.trim().split(' ').first[0]}${userName.trim().split(' ').last[0]}'
              : userName.trim()[0]
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.customListBg(context).withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  AppTheme.appLogoLauncher(context),
                  height: 45,
                  width: 45,
                ),
                if (animValue > 0.4) ...[
                  const SizedBox(width: 10),
                  Opacity(
                    opacity: ((animValue - 0.4) / 0.6).clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Y2K SOLUTIONS',
                          style: AppTheme.textLabel(
                            context,
                          ).copyWith(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Business Suite',
                          style: AppTheme.textSearchInfoLabeled(
                            context,
                          ).copyWith(fontSize: 9, fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Section label
          if (animValue > 0.5)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Opacity(
                opacity: ((animValue - 0.5) / 0.5).clamp(0.0, 1.0),
                child: Text(
                  'MAIN',
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              children: navItems
                  .map(
                    (item) => _NavItemTile(
                      item: item,
                      activeIndex: activeIndex,
                      collapsed: collapsed,
                      animValue: animValue,
                      onSelect: onItemSelect,
                      onToggle: () => onToggleItem(item),
                    ),
                  )
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Opacity(
              opacity: ((animValue - 0.5) / 0.5).clamp(0.0, 1.0),
              child: Text(
                'SETTINGS',
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Bottom user hint
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: animValue > 0.4
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.sliderHighlightBg(
                    context,
                  ).withOpacity(0.95),
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.iconColor(context),
                    ),
                  ),
                ),
                if (animValue > 0.4) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Opacity(
                      opacity: ((animValue - 0.4) / 0.6).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.iconColor(context),
                            ),
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      BounceDialog.showBounceDialog<bool>(
                        context: context,
                        child: const _LogoutDialog(),
                      );
                    },
                    icon: Icon(
                      HugeIconsSolid.shutDown,
                      color: AppTheme.iconColor(context),
                      size: 15,
                    ),
                    tooltip: "Logout",
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Tile ────────────────────────────────────────────────────────────

class _NavItemTile extends StatefulWidget {
  final NavItem item;
  final int activeIndex;
  final bool collapsed;
  final double animValue;
  final ValueChanged<NavItem> onSelect;
  final VoidCallback onToggle;

  const _NavItemTile({
    required this.item,
    required this.activeIndex,
    required this.collapsed,
    required this.animValue,
    required this.onSelect,
    required this.onToggle,
  });

  bool get _isActive =>
      item.pageIndex == activeIndex ||
      item.children.any((c) => c.pageIndex == activeIndex);

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.item.children.isNotEmpty;
    final isActive = widget._isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main tile ──
        Tooltip(
          message: widget.collapsed ? widget.item.label : '',
          preferBelow: false,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: hasChildren
                  ? widget.onToggle
                  : () => widget.onSelect(widget.item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColor.primary_50.withOpacity(0.80)
                      : _hovered
                      ? AppColor.primary_50.withOpacity(0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _hovered && !isActive ? 1.10 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.item.icon,
                        size: 18,
                        color: isActive
                            ? AppColor.white
                            : _hovered
                            ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppColor.primary_50
                            : AppTheme.iconColorTwo(context),
                      ),
                    ),
                    if (widget.animValue > 0.3) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Opacity(
                          opacity: ((widget.animValue - 0.3) / 0.7).clamp(
                            0.0,
                            1.0,
                          ),
                          child: Text(
                            widget.item.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? AppColor.white
                                  : _hovered
                                  ? Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : AppColor.primary_50
                                  : AppTheme.iconColorTwo(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (hasChildren)
                        AnimatedRotation(
                          turns: widget.item.expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Opacity(
                            opacity: ((widget.animValue - 0.3) / 0.7).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Icon(
                              HugeIconsStroke.arrowDown01,
                              size: 16,
                              color: _hovered
                                  ? Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : AppColor.primary_50
                                  : AppTheme.iconColorTwo(context),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Sub-items (accordion animated) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: hasChildren && widget.item.expanded && widget.animValue > 0.3
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Column(
                    children: widget.item.children.map((child) {
                      return _SubItemTile(
                        child: child,
                        isActive: child.pageIndex == widget.activeIndex,
                        onSelect: widget.onSelect,
                        context: context,
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Sub Item Tile ────────────────────────────────────────────────────────────

class _SubItemTile extends StatefulWidget {
  final NavItem child;
  final bool isActive;
  final ValueChanged<NavItem> onSelect;
  final BuildContext context;

  const _SubItemTile({
    required this.child,
    required this.isActive,
    required this.onSelect,
    required this.context,
  });

  @override
  State<_SubItemTile> createState() => _SubItemTileState();
}

class _SubItemTileState extends State<_SubItemTile> {
  bool _hovered = false;

  Color get _activeColor =>
      Theme.of(widget.context).brightness == Brightness.dark
      ? Colors.white
      : AppColor.primary_50;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onSelect(widget.child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColor.primary_50.withOpacity(0.20)
                : _hovered
                ? AppColor.primary_50.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Dot indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.isActive || _hovered ? 6 : 4,
                height: widget.isActive || _hovered ? 6 : 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive
                      ? _activeColor
                      : _hovered
                      ? Theme.of(widget.context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColor.primary_50.withOpacity(0.6)
                      : AppTheme.iconColorTwo(context),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                widget.child.icon,
                size: 14,
                color: widget.isActive
                    ? _activeColor
                    : _hovered
                    ? Theme.of(widget.context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColor.primary_50
                    : AppTheme.iconColorTwo(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.child.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isActive || _hovered
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.isActive
                        ? _activeColor
                        : _hovered
                        ? Theme.of(widget.context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColor.primary_50
                        : AppTheme.iconColorTwo(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile Drawer ────────────────────────────────────────────────────────────

class _SidebarDrawer extends StatefulWidget {
  final List<NavItem> navItems;
  final int activeIndex;
  final ValueChanged<NavItem> onItemSelect;
  final String userName;

  const _SidebarDrawer({
    required this.navItems,
    required this.activeIndex,
    required this.onItemSelect,
    required this.userName,
  });

  @override
  State<_SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<_SidebarDrawer> {
  @override
  Widget build(BuildContext context) => Drawer(
    child: _Sidebar(
      navItems: widget.navItems,
      activeIndex: widget.activeIndex,
      collapsed: false,
      animValue: 1.0,
      onItemSelect: (item) {
        widget.onItemSelect(item); // ✅ notify parent
        Navigator.of(context).pop(); // ✅ close drawer on select
      },
      onToggleItem: (tappedItem) {
        setState(() {
          for (final nav in widget.navItems) {
            nav.expanded = nav == tappedItem ? !nav.expanded : false;
          }
        });
      },
      userName: widget.userName,
    ),
  );
}

// ─── Topbar ───────────────────────────────────────────────────────────────────

class _Topbar extends StatefulWidget {
  final String title;
  final bool isDesktop;
  final VoidCallback onMenuTap;
  final bool profileOpen;
  final VoidCallback onProfileTap;
  final VoidCallback onProfileClose;
  final String userName;
  final String userImage;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  const _Topbar({
    required this.title,
    required this.isDesktop,
    required this.onMenuTap,
    required this.profileOpen,
    required this.onProfileTap,
    required this.onProfileClose,
    required this.userName,
    required this.userImage,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  @override
  State<_Topbar> createState() => _TopbarState();
}

class _TopbarState extends State<_Topbar> {
  bool _avatarHovered = false;
  Widget _defaultAvatar(BuildContext context) => CircleAvatar(
    foregroundImage: AssetImage("assets/images/avatars/boy_14.png"),
  );

  @override
  Widget build(BuildContext context) {
    final initials = widget.userName.trim().isNotEmpty
        ? widget.userName.trim().split(' ').length >= 2
              ? '${widget.userName.trim().split(' ').first[0]}${widget.userName.trim().split(' ').last[0]}'
              : widget.userName.trim()[0]
        : '?';
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.customListBg(context).withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Menu toggle
          IconButton(
            icon: Icon(
              HugeIconsStroke.menu02,
              size: 22,
              color: AppTheme.iconColor(context),
            ),
            onPressed: widget.onMenuTap,
            tooltip: 'Toggle Sidebar',
          ),
          const SizedBox(width: 5),

          // Title
          Row(
            children: [
              Text(
                "My",
                style: AppTheme.textTitle(
                  context,
                ).copyWith(fontSize: 20, fontFamily: AppFontFamily.poppinsBold),
              ),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.textTitle(context).copyWith(
                  fontSize: 20,
                  fontFamily: AppFontFamily.poppinsLight,
                ),
              ),
              Text(
                ".",
                style: AppTheme.textTitleActive(
                  context,
                ).copyWith(fontFamily: 'Poppins', fontSize: 18),
              ),
            ],
          ),

          const Spacer(),

          // Action icons
          _TopbarIcon(
            icon: Icons.calculate_outlined,
            tooltip: 'Calculator',
            onTap: () => _showCalculator(context),
          ),
          _TopbarIcon(
            icon: widget.isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            tooltip: widget.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
            onTap: widget.onToggleFullscreen,
          ),
          _TopbarIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            badge: '3',
          ),
          const SizedBox(width: 6),

          // Avatar
          MouseRegion(
            onEnter: (_) {
              setState(() => _avatarHovered = true);
              widget.onProfileTap();
            },
            onExit: (_) {
              setState(() => _avatarHovered = false);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!_avatarHovered && mounted) {
                  widget.onProfileClose();
                }
              });
            },
            child: InkWell(
              onTap: widget.onProfileTap,
              child: widget.userImage.isEmpty
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColor.primary_40, AppColor.primary_50],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: CircleAvatar(
                        backgroundColor: AppTheme.sliderHighlightBg(context),
                        child: Image.network(
                          widget.userImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _defaultAvatar(context);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _defaultAvatar(context);
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculator(BuildContext context) {
    BounceDialog.showBounceDialog<bool>(
      context: context,
      barrierDismissible: true,
      child: const _CalculatorDialog(),
    );
  }
}

class _TopbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String badge;
  final VoidCallback? onTap;

  const _TopbarIcon({
    required this.icon,
    required this.tooltip,
    this.badge = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      IconButton(
        icon: Icon(icon, size: 20, color: AppTheme.iconColorTwo(context)),
        onPressed: onTap,
        tooltip: tooltip,
      ),
      if (badge.isNotEmpty)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.sliderHighlightBg(context)
                  : AppTheme.iconColorThree(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

// ─── Profile Dropdown ─────────────────────────────────────────────────────────

class _ProfileDropdown extends StatelessWidget {
  final VoidCallback onClose;
  final String userName;
  final String userImage;
  final String userType;
  final String userEmail;
  final GlobalKey<NavigatorState> activeNavigatorKey;
  const _ProfileDropdown({
    required this.onClose,
    required this.userName,
    required this.userImage,
    required this.userType,
    required this.userEmail,
    required this.activeNavigatorKey,
  });

  // void _navigateTo(Widget page) {
  //   activeNavigatorKey.currentState?.push(
  //     MaterialPageRoute(builder: (_) => page),
  //   );
  // }

  void _navigateTo(Widget page) {
    final nav = activeNavigatorKey.currentState;
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
    nav.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  Widget _defaultAvatar(BuildContext context) => CircleAvatar(
    foregroundImage: AssetImage("assets/images/avatars/boy_14.png"),
  );

  @override
  Widget build(BuildContext context) {
    final initials = userName.trim().isNotEmpty
        ? userName.trim().split(' ').length >= 2
              ? '${userName.trim().split(' ').first[0]}${userName.trim().split(' ').last[0]}'
              : userName.trim()[0]
        : '?';
    return InkWell(
      onTap: () {}, // prevent close on tap inside
      mouseCursor: MouseCursor.defer,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black26,
        child: Container(
          width: MediaQuery.of(context).size.width >= 500
              ? 300
              : MediaQuery.of(context).size.width - 40,
          padding: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardDarkBg(context), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColor.primary_50.withOpacity(0.06),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      userImage.isEmpty
                          ? Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColor.primary_40,
                                    AppColor.primary_50,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initials.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              clipBehavior: Clip.antiAlias,
                              child: CircleAvatar(
                                backgroundColor: AppTheme.sliderHighlightBg(
                                  context,
                                ),
                                child: Image.network(
                                  userImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _defaultAvatar(context);
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return _defaultAvatar(context);
                                      },
                                ),
                              ),
                            ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'HI! ${userName.toUpperCase()}',
                              style: AppTheme.textLabel(context).copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                              maxLines: 2,
                            ),
                            Row(
                              spacing: 4,
                              children: [
                                Icon(
                                  HugeIconsStroke.userStory,
                                  size: 15,
                                  color: AppTheme.iconColorThree(context),
                                ),
                                Text(
                                  userType,
                                  style: AppTheme.textSearchInfoLabeled(context)
                                      .copyWith(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                      ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            Row(
                              spacing: 4,
                              children: [
                                Icon(
                                  HugeIconsStroke.mail02,
                                  size: 15,
                                  color: AppTheme.iconColorThree(context),
                                ),
                                Text(
                                  userEmail,
                                  style: AppTheme.textSearchInfoLabeled(context)
                                      .copyWith(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                      ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Menu items
              _DropdownItem(
                icon: HugeIconsStroke.user03,
                label: 'My Profile',
                color: AppTheme.iconColorTwo(context),
                onTap: () {
                  onClose();
                  _navigateTo(
                    const AccountScreen(),
                  ); // ✅ push to active navigator
                },
              ),
              _DropdownItem(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                color: AppTheme.iconColorTwo(context),
                onTap: onClose,
              ),
              Divider(color: AppTheme.dividerBg(context)),
              _DropdownItem(
                icon: HugeIconsStroke.logout01,
                label: 'Logout',
                color: AppColor.accent_50,
                onTap: () {
                  onClose();
                  BounceDialog.showBounceDialog<bool>(
                    context: context,
                    child: const _LogoutDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF444444),
    required this.onTap,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _hover ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── Calculator Dialog ─────────────────────────────────────────────────────────

class _CalculatorDialog extends StatefulWidget {
  const _CalculatorDialog();

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  String _display = '0';
  String _expression = '';
  double _firstOperand = 0;
  String _operator = '';
  bool _shouldResetDisplay = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // ✅ Auto-focus so keyboard works immediately on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _onButton('0');
    } else if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      _onButton('1');
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      _onButton('2');
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      _onButton('3');
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      _onButton('4');
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      _onButton('5');
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      _onButton('6');
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      _onButton('7');
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      _onButton('8');
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      _onButton('9');
    } else if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      _onButton('+');
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _onButton('-');
    } else if (key == LogicalKeyboardKey.asterisk ||
        key == LogicalKeyboardKey.numpadMultiply) {
      _onButton('×');
    } else if (key == LogicalKeyboardKey.slash ||
        key == LogicalKeyboardKey.numpadDivide) {
      _onButton('÷');
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadEqual ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _onButton('=');
    } else if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      _onButton('.');
    } else if (key == LogicalKeyboardKey.backspace) {
      _onButton('⌫');
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(); // ✅ Esc closes dialog
    } else if (key == LogicalKeyboardKey.delete) {
      _onButton('C'); // ✅ Delete clears
    } else if (key == LogicalKeyboardKey.percent) {
      _onButton('%');
    }
  }

  void _onButton(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _expression = '';
        _firstOperand = 0;
        _operator = '';
        _shouldResetDisplay = false;
      } else if (value == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (['+', '-', '×', '÷'].contains(value)) {
        _firstOperand = double.tryParse(_display) ?? 0;
        _operator = value;
        _expression = '$_display $value';
        _shouldResetDisplay = true;
      } else if (value == '=') {
        if (_operator.isEmpty) return;
        final second = double.tryParse(_display) ?? 0;
        double result = 0;
        switch (_operator) {
          case '+':
            result = _firstOperand + second;
            break;
          case '-':
            result = _firstOperand - second;
            break;
          case '×':
            result = _firstOperand * second;
            break;
          case '÷':
            result = second != 0 ? _firstOperand / second : 0;
            break;
        }
        _expression = '$_expression $_display =';
        _display = result == result.truncateToDouble()
            ? result.toInt().toString()
            : result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '');
        _operator = '';
        _shouldResetDisplay = true;
      } else if (value == '%') {
        final current = double.tryParse(_display) ?? 0;
        _display = (current / 100).toString();
        _shouldResetDisplay = false;
      } else if (value == '+/-') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else if (_display != '0') {
          _display = '-$_display';
        }
      } else if (value == '.') {
        if (_shouldResetDisplay) {
          _display = '0.';
          _shouldResetDisplay = false;
        } else if (!_display.contains('.')) {
          _display += '.';
        }
      } else {
        // Number
        if (_shouldResetDisplay || _display == '0') {
          _display = value;
          _shouldResetDisplay = false;
        } else {
          if (_display.length < 12) _display += value;
        }
      }
    });
  }

  Color _btnColor(String label) {
    if (label == 'C' || label == '+/-' || label == '%') {
      return AppTheme.iconColorTwo(context).withOpacity(0.2);
    }
    if (['+', '-', '×', '÷', '='].contains(label)) {
      return AppColor.primary_50;
    }
    return AppTheme.iconColorThree(context).withOpacity(0.1);
  }

  Color _btnTextColor(String label) {
    if (['+', '-', '×', '÷', '='].contains(label)) return Colors.white;
    if (label == 'C' || label == '+/-' || label == '%') {
      return AppTheme.iconColorTwo(context);
    }
    return AppTheme.iconColorThree(context);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['C', '+/-', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['⌫', '0', '.', '='],
    ];

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: MediaQuery.of(context).size.width >= 500
              ? 300
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 18,
                      color: AppTheme.iconColorTwo(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calculator',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.iconColorTwo(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppTheme.iconColorTwo(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Expression
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.iconColorThree(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Main display
                    Text(
                      _display,
                      style: TextStyle(
                        fontSize: _display.length > 10 ? 22 : 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.iconColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.5),

              // Buttons
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: 4,
                ),
                child: Column(
                  children: buttons.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row.asMap().entries.map((e) {
                          final label = e.value;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: e.key < row.length - 1 ? 8 : 0,
                              ),
                              child: _CalcButton(
                                label: label,
                                color: _btnColor(label),
                                textColor: _btnTextColor(label),
                                onTap: () => _onButton(label),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Calc Button ──────────────────────────────────────────────────────────────

class _CalcButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _CalcButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 52,
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withOpacity(0.75) : widget.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logout Dialog ─────────────────────────────────────────────────────────

class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog();

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
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

  @override
  Widget build(BuildContext context) {
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
                    "Logout",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(context).copyWith(
                      fontSize: 16,
                      fontFamily: AppFontFamily.poppinsBold,
                    ),
                  ),
                  const Divider(),
                  Text(
                    "Are you sure you want to logout?",
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
            ),
          ],
        ),
      ),
    );
  }
}
