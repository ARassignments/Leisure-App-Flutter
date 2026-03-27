import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:y2ksolutions/screens/customers_screen.dart';
import 'package:y2ksolutions/screens/payments_screen.dart';
import 'package:y2ksolutions/screens/scraps_screen.dart';
import '/screens/home_screen.dart';
import '/theme/theme.dart';

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

// ─── Dashboard Shell ──────────────────────────────────────────────────────────

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell>
    with SingleTickerProviderStateMixin {
  late final List<NavItem> _navItems;
  final HomeScreen homeScreen = const HomeScreen();
  final PaymentsScreen paymentScreen = const PaymentsScreen();
  final ScrapsScreen scrapScreen = const ScrapsScreen();
  final CustomersScreen customerScreen = const CustomersScreen();
  bool _sidebarOpen = true;
  bool _profileMenuOpen = false;
  // final List<NavItem> _navItems = buildNavItems();

  int _activeIndex = 0;
  String _activeLabel = 'Dashboard';
  late final List<Widget> _pages; // flat list of all pages
  late final List<String> _pageLabels;

  static const double _sidebarExpanded = 220;
  static const double _sidebarCollapsed = 80;

  late final AnimationController _sidebarCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1.0,
  );
  late final Animation<double> _sidebarAnim = CurvedAnimation(
    parent: _sidebarCtrl,
    curve: Curves.easeInOutCubic,
  );
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    _sidebarOpen ? _sidebarCtrl.forward() : _sidebarCtrl.reverse();
  }

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _sidebarCtrl.dispose();
    super.dispose();
  }

  void _onNavSelect(NavItem item) {
    if (item.pageIndex >= 0) {
      setState(() {
        _activeIndex = item.pageIndex;
        _activeLabel = item.label;
        _profileMenuOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.customListBg(context),
      // Mobile: use drawer
      drawer: isDesktop
          ? null
          : _SidebarDrawer(
              navItems: _navItems,
              activeIndex: _activeIndex,
              onItemSelect: _onNavSelect,
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
                    (_sidebarExpanded - _sidebarCollapsed) * _sidebarAnim.value;
                return SizedBox(
                  width: w,
                  child: _Sidebar(
                    navItems: _navItems,
                    activeIndex: _activeIndex,
                    collapsed: !_sidebarOpen,
                    animValue: _sidebarAnim.value,
                    onItemSelect: _onNavSelect,
                    onToggleItem: (item) {
                      // ✅ receives NavItem
                      setState(() {
                        for (final nav in _navItems) {
                          nav.expanded = nav == item ? !nav.expanded : false;
                        }
                      });
                    },
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
                  onMenuTap: isDesktop
                      ? _toggleSidebar
                      : () => Scaffold.of(context).openDrawer(),
                  profileOpen: _profileMenuOpen,
                  onProfileTap: () =>
                      setState(() => _profileMenuOpen = !_profileMenuOpen),
                  onProfileClose: () =>
                      setState(() => _profileMenuOpen = false),
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
                              return IndexedStack(
                                index: _activeIndex,
                                children: List.generate(_pages.length, (i) {
                                  final navigator = Navigator(
                                    key: _navigatorKeys[i],
                                    onGenerateRoute: (_) => MaterialPageRoute(
                                      builder: (_) => _pages[i],
                                    ),
                                  );

                                  return SizedBox(
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    child:
                                        navigator, // ✅ full width scoped navigator
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Text(
                            "Y2k Solutions © 2026 all right reserved.",
                            style: AppTheme.textLink(
                              context,
                            ).copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      // Profile dropdown
                      if (_profileMenuOpen)
                        Positioned(
                          top: 0,
                          right: 20,
                          child: _ProfileDropdown(
                            onClose: () =>
                                setState(() => _profileMenuOpen = false),
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
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<NavItem> navItems;
  final int activeIndex;
  final bool collapsed;
  final double animValue;
  final ValueChanged<NavItem> onItemSelect;
  final ValueChanged<NavItem> onToggleItem;

  const _Sidebar({
    required this.navItems,
    required this.activeIndex,
    required this.collapsed,
    required this.animValue,
    required this.onItemSelect,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
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
                    'ST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.iconColor(context),
                    ),
                  ),
                ),
                if (animValue > 0.4) ...[
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: ((animValue - 0.4) / 0.6).clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SAIM TRADERS',
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

  const _SidebarDrawer({
    required this.navItems,
    required this.activeIndex,
    required this.onItemSelect,
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
    ),
  );
}

// ─── Topbar ───────────────────────────────────────────────────────────────────

class _Topbar extends StatelessWidget {
  final String title;
  final bool isDesktop;
  final VoidCallback onMenuTap;
  final bool profileOpen;
  final VoidCallback onProfileTap;
  final VoidCallback onProfileClose;

  const _Topbar({
    required this.title,
    required this.isDesktop,
    required this.onMenuTap,
    required this.profileOpen,
    required this.onProfileTap,
    required this.onProfileClose,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: onMenuTap,
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
                title,
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
          _TopbarIcon(icon: Icons.save_outlined, tooltip: 'Save'),
          _TopbarIcon(
            icon: Icons.bookmark_border_rounded,
            tooltip: 'Bookmarks',
          ),
          _TopbarIcon(icon: Icons.fullscreen_rounded, tooltip: 'Fullscreen'),
          _TopbarIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            badge: '3',
          ),
          const SizedBox(width: 6),

          // Avatar
          InkWell(
            onTap: onProfileTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColor.primary_40, AppColor.primary_50],
                ),
              ),
              child: const Center(
                child: Text(
                  'ST',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String badge;

  const _TopbarIcon({
    required this.icon,
    required this.tooltip,
    this.badge = '',
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      IconButton(
        icon: Icon(icon, size: 20, color: AppTheme.iconColorTwo(context)),
        onPressed: () {},
        tooltip: tooltip,
      ),
      if (badge.isNotEmpty)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
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
  const _ProfileDropdown({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, // prevent close on tap inside
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black26,
        child: Container(
          width: 200,
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.primary_50.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColor.primary_40, AppColor.primary_50],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'ST',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HI! SAIM TRADERS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.iconColor(context),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),

              // Menu items
              _DropdownItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                color: AppTheme.iconColorTwo(context),
                onTap: onClose,
              ),
              _DropdownItem(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                color: AppTheme.iconColorTwo(context),
                onTap: onClose,
              ),
              _DropdownItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: AppColor.accent_50,
                onTap: onClose,
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
