import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class DashboardTopCustomers extends StatefulWidget {
  final List<TopCustomer> customers;
  final bool isChartView;
  final bool isLoading;
  final ValueChanged<bool>? onToggle;
  const DashboardTopCustomers({
    super.key,
    required this.customers,
    this.isChartView = true,
    this.isLoading = false,
    this.onToggle,
  });

  @override
  State<DashboardTopCustomers> createState() => _DashboardTopCustomersState();
}

class _DashboardTopCustomersState extends State<DashboardTopCustomers>
    with SingleTickerProviderStateMixin {
  late bool _isChartView = widget.isChartView;
  int? _hoveredIndex;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardTopCustomers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChartView != widget.isChartView) {
      setState(() => _isChartView = widget.isChartView);
      _animController.forward(from: 0);
    }
  }

  double get _totalAmount =>
      widget.customers.fold(0, (s, c) => s + c.TotalAmount);
  int get _totalOrders => widget.customers.fold(0, (s, c) => s + c.TotalOrders);

  String _formatAmount(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  String _formatFull(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Rs $intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main card ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.customListBg(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Customers',
                        style: AppTheme.textLabel(context).copyWith(
                          fontSize: 14,
                          fontFamily: AppFontFamily.poppinsSemiBold,
                        ),
                      ),
                      const Spacer(),
                      // Toggle
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDarkBg(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _ToggleBtn(
                              label: 'Chart',
                              icon: HugeIconsSolid.pieChart08,
                              active: _isChartView,
                              onTap: () {
                                setState(() => _isChartView = true);
                                // widget.onToggle?.call(true);
                                _animController.forward(from: 0);
                              },
                            ),
                            _ToggleBtn(
                              label: 'List',
                              icon: HugeIconsSolid.userList,
                              active: !_isChartView,
                              onTap: () {
                                setState(() => _isChartView = false);
                                // widget.onToggle?.call(false);
                                _animController.forward(from: 0);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.isLoading) ...[
                  _buildShimmerLoader(context),
                  const SizedBox(height: 25),
                ],
                if (!widget.isLoading) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SummaryCards(
                      count: widget.customers.length,
                      totalOrders: _totalOrders,
                      totalAmount: _formatAmount(_totalAmount),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  if (widget.customers.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _isChartView
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _ChartView(
                                key: const ValueKey('chart'),
                                customers: widget.customers,
                                animation: _animation,
                                hoveredIndex: _hoveredIndex,
                                onHover: (i) =>
                                    setState(() => _hoveredIndex = i),
                                formatFull: _formatFull,
                              ),
                            )
                          : _ListView(
                              key: const ValueKey('list'),
                              customers: widget.customers,
                              animation: _animation,
                              formatFull: _formatFull,
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

  /// ✨ Shimmer Loader
  Widget _buildShimmerLoader(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            strokeWidth: 4,
            color: AppTheme.inputProgress(context),
          ),
          const SizedBox(height: 16),
          Text("Loading chart data...", style: AppTheme.textLabel(context)),
        ],
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  final int count;
  final int totalOrders;
  final String totalAmount;

  const SummaryCards({
    required this.count,
    required this.totalOrders,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricCard(
          label: 'Customers',
          value: count==0?'0':count.toString().padLeft(2, '0'),
          color: const Color(0xFF378ADD),
        ),
        const SizedBox(width: 10),
        _MetricCard(
          label: 'Total Orders',
          value: totalOrders==0?'0':totalOrders.toString().padLeft(2, '0'),
          color: const Color(0xFF1D9E75),
        ),
        const SizedBox(width: 10),
        _MetricCard(
          label: 'Total Amount',
          value: totalAmount,
          color: const Color(0xFFD85A30),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.sliderHighlightBg(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.textLabel(
                context,
              ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.textSearchInfoLabeled(
                context,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.sliderHighlightBg(context)
              : Colors.transparent,
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
            Icon(
              icon,
              size: 14,
              color: active
                  ? const Color(0xFF378ADD)
                  : AppTheme.iconColorThree(context),
            ),
            const SizedBox(width: 4),
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
}

class _ChartView extends StatelessWidget {
  final List<TopCustomer> customers;
  final Animation<double> animation;
  final int? hoveredIndex;
  final ValueChanged<int?> onHover;
  final String Function(double) formatFull;

  const _ChartView({
    super.key,
    required this.customers,
    required this.animation,
    required this.hoveredIndex,
    required this.onHover,
    required this.formatFull,
  });

  @override
  Widget build(BuildContext context) {
    final total = customers.fold(0.0, (s, c) => s + c.TotalAmount);

    return Column(
      children: [
        // Donut chart
        SizedBox(
          height: 240,
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => GestureDetector(
              onTapDown: (d) {
                // tap outside = deselect
                onHover(null);
              },
              child: CustomPaint(
                painter: _DonutPainter(
                  customers: customers,
                  total: total,
                  progress: animation.value,
                  hoveredIndex: hoveredIndex,
                ),
                child: Center(
                  child: hoveredIndex != null
                      ? _DonutCenter(
                          customer: customers[hoveredIndex!],
                          formatFull: formatFull,
                          color:
                              kChartColors[hoveredIndex! % kChartColors.length],
                        )
                      : _DonutCenterDefault(
                          count: customers.length,
                          total: total,
                        ),
                ),
              ),
            ),
          ),
        ),

        // Tap targets over each segment (using GestureDetector on the painter area)
        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(customers.length, (i) {
              final pct = (customers[i].TotalAmount / total * 100)
                  .toStringAsFixed(1);
              final color = kChartColors[i % kChartColors.length];
              final isActive = hoveredIndex == i;
              return GestureDetector(
                onTap: () => onHover(isActive ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? color.withOpacity(0.4)
                          : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${customers[i].UserName.split(' ').take(2).join(' ')} $pct%',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.iconColor(context)
                              : AppTheme.iconColorThree(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class TopCustomer {
  final int UserId;
  final String UserName;
  final double TotalAmount;
  final int TotalOrders;
  final String OrderMonth;

  const TopCustomer({
    required this.UserId,
    required this.UserName,
    required this.TotalAmount,
    required this.TotalOrders,
    required this.OrderMonth,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) => TopCustomer(
    UserId: json['UserId'] ?? 0,
    UserName: json['UserName'] ?? 'Unknown',
    TotalAmount: (json['TotalAmount'] as num?)?.toDouble() ?? 0.0,
    TotalOrders: json['TotalOrders'] ?? 0,
    OrderMonth: json['OrderMonth'] ?? '',
  );
}

// ─── Colors ──────────────────────────────────────────────────────────────────

const List<Color> kChartColors = [
  Color(0xFF378ADD),
  Color(0xFF1D9E75),
  Color(0xFFD85A30),
  Color(0xFFD4537E),
  Color(0xFF7F77DD),
  Color(0xFFBA7517),
  Color(0xFF639922),
  Color(0xFFE24B4A),
  Color(0xFF888780),
  Color(0xFF0F6E56),
];

class _DonutCenter extends StatelessWidget {
  final TopCustomer customer;
  final String Function(double) formatFull;
  final Color color;

  const _DonutCenter({
    required this.customer,
    required this.formatFull,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(HugeIconsSolid.user03, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: Text(
            customer.UserName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${customer.TotalOrders.toString().padLeft(2, '0')} orders',
          style: AppTheme.textSearchInfoLabeled(
            context,
          ).copyWith(fontSize: 11, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 2),
        Text(
          formatFull(customer.TotalAmount),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DonutCenterDefault extends StatelessWidget {
  final int count;
  final double total;

  const _DonutCenterDefault({required this.count, required this.total});

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString().padLeft(2, '0'),
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        Text(
          'customers',
          style: AppTheme.textSearchInfoLabeled(
            context,
          ).copyWith(fontSize: 11, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 4),
        Text(
          _fmt(total),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF378ADD),
          ),
        ),
      ],
    );
  }
}

// ─── Donut Painter ────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<TopCustomer> customers;
  final double total;
  final double progress;
  final int? hoveredIndex;

  _DonutPainter({
    required this.customers,
    required this.total,
    required this.progress,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - 16;
    const strokeWidth = 44.0;
    const gap = 0.018; // radians gap between segments

    double startAngle = -pi / 2;

    for (int i = 0; i < customers.length; i++) {
      final sweep = (customers[i].TotalAmount / total) * 2 * pi * progress;
      final isHovered = hoveredIndex == i;
      final color = kChartColors[i % kChartColors.length];
      final r = isHovered ? radius + 6 : radius;
      final sw = isHovered ? strokeWidth + 8 : strokeWidth;

      final paint = Paint()
        ..color = isHovered
            ? color
            : color.withOpacity(hoveredIndex == null ? 1.0 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle + gap / 2,
        sweep - gap,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.hoveredIndex != hoveredIndex;
}

// ─── List View ────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<TopCustomer> customers;
  final Animation<double> animation;
  final String Function(double) formatFull;

  const _ListView({
    super.key,
    required this.customers,
    required this.animation,
    required this.formatFull,
  });

  @override
  Widget build(BuildContext context) {
    final total = customers.fold(0.0, (s, c) => s + c.TotalAmount);

    return Column(
      children: [
        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              SizedBox(width: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '#  Customer',
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Orders',
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Divider(height: 1, color: AppTheme.dividerBg(context)),

        // Rows
        ...List.generate(customers.length, (i) {
          final c = customers[i];
          final color = kChartColors[i % kChartColors.length];
          final pct = c.TotalAmount / total;

          return AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              final delay = (i / customers.length) * 0.6;
              final t = ((animation.value - delay) / (1 - delay)).clamp(
                0.0,
                1.0,
              );
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - t)),
                  child: _CustomerRow(
                    rank: i + 1,
                    customer: c,
                    color: color,
                    pct: pct,
                    formatFull: formatFull,
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CustomerRow extends StatefulWidget {
  final int rank;
  final TopCustomer customer;
  final Color color;
  final double pct;
  final String Function(double) formatFull;

  const _CustomerRow({
    required this.rank,
    required this.customer,
    required this.color,
    required this.pct,
    required this.formatFull,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? widget.color.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Rank
            SizedBox(
              width: 20,
              child: Text(
                widget.rank.toString().padLeft(2, '0'),
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            // Name + bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customer.UserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: widget.pct,
                      minHeight: 3,
                      backgroundColor: AppTheme.sliderHighlightBg(context),
                      valueColor: AlwaysStoppedAnimation(widget.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Orders badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.customer.TotalOrders.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            SizedBox(
              width: 110,
              child: Text(
                widget.formatFull(widget.customer.TotalAmount),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
