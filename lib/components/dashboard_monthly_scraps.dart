import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '/theme/theme.dart';

class DashboardMonthlyScrap extends StatefulWidget {
  final List<MonthlyScrapItem> items;
  final bool isLoading;
  final bool isChartView;
  final ValueChanged<bool>? onToggle;

  const DashboardMonthlyScrap({
    super.key,
    required this.items,
    this.isLoading = false,
    this.isChartView = true,
    this.onToggle,
  });

  @override
  State<DashboardMonthlyScrap> createState() => _DashboardMonthlyScrapState();
}

class _DashboardMonthlyScrapState extends State<DashboardMonthlyScrap>
    with SingleTickerProviderStateMixin {
  late bool _chart = widget.isChartView;
  int? _sel;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(DashboardMonthlyScrap old) {
    super.didUpdateWidget(old);
    if (old.isChartView != widget.isChartView) {
      setState(() => _chart = widget.isChartView);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _total => widget.items.fold(0.0, (s, i) => s + i.TotalQuantity);
  int get _purchaseCount =>
      widget.items.where((i) => i.OrderType == 'Purchase').length;
  int get _saleCount => widget.items.where((i) => i.OrderType == 'Sale').length;

  void _toggle(bool toChart) {
    setState(() {
      _chart = toChart;
      _sel = null;
    });
    // widget.onToggle?.call(toChart);
    _ctrl.forward(from: 0);
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        'Monthly Scrap',
                        style: AppTheme.textLabel(context).copyWith(
                          fontSize: 14,
                          fontFamily: AppFontFamily.poppinsSemiBold,
                        ),
                      ),
                      const Spacer(),
                      _Toggle(isChart: _chart, onSwitch: _toggle),
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
                    child: _SummaryRow(
                      count: widget.items.length,
                      total: _total,
                      purchaseCount: _purchaseCount,
                      saleCount: _saleCount,
                      fmt: _fmt,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.items.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _chart
                          ? _PieSection(
                              key: const ValueKey('pie'),
                              items: widget.items,
                              anim: _anim,
                              selected: _sel,
                              total: _total,
                              onSelect: (i) => setState(
                                () => _sel = (i < 0 || _sel == i) ? null : i,
                              ),
                              onDeselect: () => setState(() => _sel = null),
                              fmt: _fmt,
                            )
                          : _ListSection(
                              key: const ValueKey('lst'),
                              items: widget.items,
                              anim: _anim,
                              total: _total,
                              fmt: _fmt,
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

// ─── Model (matches your API exactly) ────────────────────────────────────────

class MonthlyScrapItem {
  final String Date;
  final double TotalQuantity;
  final String OrderType;
  final String UserName;

  const MonthlyScrapItem({
    required this.Date,
    required this.TotalQuantity,
    required this.OrderType,
    required this.UserName,
  });

  factory MonthlyScrapItem.fromJson(Map<String, dynamic> json) =>
      MonthlyScrapItem(
        Date: json['Date'] ?? '',
        TotalQuantity: (json['TotalQuantity'] as num?)?.toDouble() ?? 0.0,
        OrderType: json['OrderType'] ?? '',
        UserName: json['UserName'] ?? 'Unknown',
      );
}

// ─── Chart colors ─────────────────────────────────────────────────────────────

const List<Color> kPieColors = [
  Color(0xFF4BC0C0),
  Color(0xFF36A2EB),
  Color(0xFFFF6384),
  Color(0xFF9966FF),
  Color(0xFF4CAF50),
  Color(0xFFFFCD56),
  Color(0xFFFF9F40),
  Color(0xFF8AC926),
  Color(0xFFE24B4A),
  Color(0xFF0F9E91),
];

// ─── Theme ────────────────────────────────────────────────────────────────────

const Color kBg = Color(0xFFF5F6FA);
const Color kCard = Colors.white;
const Color kText = Color(0xFF1A1A2E);
const Color kMuted = Color(0xFF9E9E9E);
const Color kLine = Color(0xFFEEEEEE);

// ─── Summary cards ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int count, purchaseCount, saleCount;
  final double total;
  final String Function(double) fmt;

  const _SummaryRow({
    required this.count,
    required this.total,
    required this.purchaseCount,
    required this.saleCount,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Metric(
        label: 'Entries',
        value: count == 0 ? '0' : count.toString().padLeft(2, '0'),
        color: const Color(0xFF9966FF),
        icon: Icons.receipt_long_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Total Qty',
        value: fmt(total),
        color: const Color(0xFF4BC0C0),
        icon: Icons.scale_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Purchase',
        value: purchaseCount == 0
            ? '0'
            : purchaseCount.toString().padLeft(2, '0'),
        color: const Color(0xFF4CAF50),
        icon: Icons.shopping_bag_outlined,
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
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

// ─── Toggle ───────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool isChart;
  final ValueChanged<bool> onSwitch;
  const _Toggle({required this.isChart, required this.onSwitch});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppTheme.cardDarkBg(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        _TBtn(
          label: 'Chart',
          icon: Icons.pie_chart_rounded,
          active: isChart,
          onTap: () => onSwitch(true),
        ),
        _TBtn(
          label: 'List',
          icon: Icons.format_list_bulleted_rounded,
          active: !isChart,
          onTap: () => onSwitch(false),
        ),
      ],
    ),
  );
}

class _TBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
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
            ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)]
            : [],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: active
                ? const Color(0xFF9966FF)
                : AppTheme.iconColorThree(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
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

// ─── Pie chart section ────────────────────────────────────────────────────────

class _PieSection extends StatelessWidget {
  final List<MonthlyScrapItem> items;
  final Animation<double> anim;
  final int? selected;
  final double total;
  final ValueChanged<int> onSelect;
  final VoidCallback onDeselect;
  final String Function(double) fmt;

  const _PieSection({
    super.key,
    required this.items,
    required this.anim,
    required this.selected,
    required this.total,
    required this.onSelect,
    required this.onDeselect,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pie chart
        SizedBox(
          height: 260,
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, __) => GestureDetector(
              onTapUp: (d) => _handleTap(d.localPosition, context),
              child: CustomPaint(
                size: const Size(double.infinity, 260),
                painter: _PiePainter(
                  items: items,
                  total: total,
                  progress: anim.value,
                  selected: selected,
                  separatorColor: AppTheme.customListBg(context)
                ),
                child: selected != null
                    ? _PieCenter(item: items[selected!], total: total, fmt: fmt)
                    : _PieCenterDefault(
                        total: total,
                        count: items.length,
                        fmt: fmt,
                      ),
              ),
            ),
          ),
        ),

        // Tooltip card (selected)
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _TooltipCard(
              item: items[selected!],
              color: kPieColors[selected! % kPieColors.length],
              fmt: fmt,
            ),
          ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(items.length, (i) {
              final pct = (items[i].TotalQuantity / total * 100)
                  .toStringAsFixed(1);
              final color = kPieColors[i % kPieColors.length];
              final isActive = selected == i;
              return GestureDetector(
                onTap: () => onSelect(i),
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
                        '${items[i].UserName.split(' ').take(2).join(' ')} $pct%',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
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

  void _handleTap(Offset localPos, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cx = size.width / 2;
    final cy = 130.0;
    final dx = localPos.dx - cx;
    final dy = localPos.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    final radius = min(cx, cy) - 16;

    // ✅ Tap outside circle — deselect safely
    if (dist > radius || dist < 10) {
      onDeselect(); // call setState directly, not onSelect
      return;
    }

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    double cumAngle = 0;
    for (int i = 0; i < items.length; i++) {
      final sweep = items[i].TotalQuantity / total * 2 * pi;
      if (angle >= cumAngle && angle < cumAngle + sweep) {
        onSelect(i); // ✅ only valid index passed
        return;
      }
      cumAngle += sweep;
    }

    // ✅ Tapped gap between segments — deselect
    onDeselect();
  }
}

// ─── Center widgets ───────────────────────────────────────────────────────────

class _PieCenter extends StatelessWidget {
  final MonthlyScrapItem item;
  final double total;
  final String Function(double) fmt;
  const _PieCenter({
    required this.item,
    required this.total,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (item.TotalQuantity / total * 100).toStringAsFixed(1);
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // glass effect
              borderRadius: BorderRadius.circular(16),
              // border: Border.all(
              //   color: Colors.white.withOpacity(0.2),
              //   width: 1,
              // ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pct + '%',
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 100,
                  child: Text(
                    item.UserName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 10, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmt(item.TotalQuantity)} Qty',
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PieCenterDefault extends StatelessWidget {
  final double total;
  final int count;
  final String Function(double) fmt;
  const _PieCenterDefault({
    required this.total,
    required this.count,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count == 0 ? '0' : count.toString().padLeft(2, '0'),
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        Text(
          'Total Entries',
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 11, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 4),
        Text(
          '${fmt(total)} Qty',
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

// ─── Pie painter ──────────────────────────────────────────────────────────────

class _PiePainter extends CustomPainter {
  final List<MonthlyScrapItem> items;
  final double total, progress;
  final int? selected;
  final Color separatorColor;

  const _PiePainter({
    required this.items,
    required this.total,
    required this.progress,
    required this.selected,
    required this.separatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = 130.0;
    final baseRadius = min(cx, cy) - 16;
    const gap = 0.012;

    double startAngle = -pi / 2;
    for (int i = 0; i < items.length; i++) {
      final sweep = items[i].TotalQuantity / total * 2 * pi * progress;
      final isSel = selected == i;
      final color = kPieColors[i % kPieColors.length];
      final r = isSel ? baseRadius + 8 : baseRadius;
      final opacity = selected == null ? 1.0 : (isSel ? 1.0 : 0.45);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle + gap,
        sweep - gap * 2,
        true,
        paint,
      );

      // White separator line
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle + gap / 2,
        sweep - gap,
        true,
        Paint()
          ..color = separatorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.progress != progress || old.selected != selected;
}

// ─── Tooltip card ─────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final MonthlyScrapItem item;
  final Color color;
  final String Function(double) fmt;
  const _TooltipCard({
    required this.item,
    required this.color,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.sliderHighlightBg(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.UserName,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${item.UserName}: ${fmt(item.TotalQuantity)}',
              style: AppTheme.textSearchInfoLabeled(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w300),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.OrderType == 'Purchase'
                    ? const Color(0xFF4CAF50).withOpacity(0.25)
                    : const Color(0xFFFF6384).withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.OrderType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item.OrderType == 'Purchase'
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF6384),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── List section ─────────────────────────────────────────────────────────────

class _ListSection extends StatelessWidget {
  final List<MonthlyScrapItem> items;
  final Animation<double> anim;
  final double total;
  final String Function(double) fmt;

  const _ListSection({
    super.key,
    required this.items,
    required this.anim,
    required this.total,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(width: 32),
            Expanded(
              child: Text(
                'Customer',
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                'Type',
                textAlign: TextAlign.center,
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                'Qty',
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
      ...List.generate(
        items.length,
        (i) => AnimatedBuilder(
          animation: anim,
          builder: (_, __) {
            final delay = (i / items.length) * 0.6;
            final t = ((anim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - t)),
                child: _ListRow(
                  rank: i + 1,
                  item: items[i],
                  total: total,
                  fmt: fmt,
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

class _ListRow extends StatefulWidget {
  final int rank;
  final MonthlyScrapItem item;
  final double total;
  final String Function(double) fmt;
  const _ListRow({
    required this.rank,
    required this.item,
    required this.total,
    required this.fmt,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hover = false;

  Color get _color => kPieColors[(widget.rank - 1) % kPieColors.length];
  bool get _isPurchase => widget.item.OrderType == 'Purchase';

  @override
  Widget build(BuildContext context) {
    final pct = widget.item.TotalQuantity / widget.total;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hover ? _color.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            // Rank dot
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  widget.rank.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + bar + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.UserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.Date,
                    style: AppTheme.textSearchInfoLabeled(
                      context,
                    ).copyWith(fontSize: 10, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 3,
                      backgroundColor: AppTheme.sliderHighlightBg(context),
                      valueColor: AlwaysStoppedAnimation(_color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Order type badge
            SizedBox(
              width: 60,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _isPurchase
                        ? const Color(0xFF4CAF50).withOpacity(0.10)
                        : const Color(0xFFFF6384).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.item.OrderType,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _isPurchase
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF6384),
                    ),
                  ),
                ),
              ),
            ),

            // Qty
            SizedBox(
              width: 80,
              child: Text(
                widget.fmt(widget.item.TotalQuantity),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
