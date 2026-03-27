import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class DashboardEndingStock extends StatefulWidget {
  final List<EndingStockItem> items;
  final bool isLoading;
  final bool isChartView;
  final ValueChanged<bool>? onToggle;

  const DashboardEndingStock({
    super.key,
    required this.items,
    this.isLoading = false,
    this.isChartView = true,
    this.onToggle,
  });

  @override
  State<DashboardEndingStock> createState() => _DashboardEndingStockState();
}

class _DashboardEndingStockState extends State<DashboardEndingStock>
    with SingleTickerProviderStateMixin {
  late bool _chart = widget.isChartView;
  int? _sel;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
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
  void didUpdateWidget(DashboardEndingStock old) {
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

  double get _totalStock =>
      widget.items.fold(0.0, (s, i) => s + i.AvailableStock);
  double get _maxStock => widget.items.isEmpty
      ? 1
      : widget.items.map((i) => i.AvailableStock).reduce(max);
  double get _avgStock =>
      widget.items.isEmpty ? 0 : _totalStock / widget.items.length;

  void _toggle(bool toChart) {
    setState(() {
      _chart = toChart;
      _sel = null;
    });
    // widget.onToggle?.call(toChart);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 16),
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
                        'Ending Stock',
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
                      totalStock: _totalStock,
                      avgStock: _avgStock,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.items.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _chart
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _AreaChartSection(
                                key: const ValueKey('area'),
                                items: widget.items,
                                anim: _anim,
                                selected: _sel,
                                onSelect: (i) =>
                                    setState(() => _sel = _sel == i ? null : i),
                              ),
                            )
                          : _ListSection(
                              key: const ValueKey('lst'),
                              items: widget.items,
                              anim: _anim,
                              maxStock: _maxStock,
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

class EndingStockItem {
  final int ProductId;
  final String ProductName;
  final String CompanyName;
  final double AvailableStock;

  const EndingStockItem({
    required this.ProductId,
    required this.ProductName,
    required this.CompanyName,
    required this.AvailableStock,
  });

  factory EndingStockItem.fromJson(Map<String, dynamic> json) =>
      EndingStockItem(
        ProductId: json['ProductId'] ?? 0,
        ProductName: json['ProductName'] ?? 'Unknown',
        CompanyName: json['CompanyName'] ?? '',
        AvailableStock: (json['AvailableStock'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─── Theme ────────────────────────────────────────────────────────────────────

const Color kPurple = Color(0xFF9966FF);
const Color kPurpleLight = Color(0xFFEDE8FF);
const Color kPurpleDark = Color(0xFF6A3FCB);
const Color kBg = Color(0xFFF5F6FA);
const Color kCard = Colors.white;
const Color kText = Color(0xFF1A1A2E);
const Color kMuted = Color(0xFF9E9E9E);
const Color kLine = AppColor.neutral_80;

// ─── Summary cards ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int count;
  final double totalStock, avgStock;
  const _SummaryRow({
    required this.count,
    required this.totalStock,
    required this.avgStock,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Metric(
        label: 'Products',
        value: count == 0 ? '0' : count.toString().padLeft(2, '0'),
        color: kPurple,
        icon: Icons.inventory_2_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Total Stock',
        value: totalStock == 0
            ? '0'
            : totalStock.toInt().toString().padLeft(2, '0'),
        color: const Color(0xFF378ADD),
        icon: Icons.warehouse_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Avg Stock',
        value: avgStock.toStringAsFixed(1),
        color: const Color(0xFF1D9E75),
        icon: Icons.bar_chart_rounded,
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
          icon: HugeIconsSolid.chartLineData02,
          active: isChart,
          onTap: () => onSwitch(true),
        ),
        _TBtn(
          label: 'List',
          icon: HugeIconsSolid.file01,
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
            color: active ? kPurple : AppTheme.iconColorThree(context),
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

// ─── Area chart section ───────────────────────────────────────────────────────

class _AreaChartSection extends StatelessWidget {
  final List<EndingStockItem> items;
  final Animation<double> anim;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _AreaChartSection({
    super.key,
    required this.items,
    required this.anim,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart with Y-axis
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: _AreaChartWithYAxis(
            items: items,
            anim: anim,
            selected: selected,
            onSelect: onSelect,
          ),
        ),

        // Tooltip
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _Tooltip(item: items[selected!]),
          ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: kPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Available',
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Area painter ─────────────────────────────────────────────────────────────

class _AreaPainter extends CustomPainter {
  final List<EndingStockItem> items;
  final double maxStock, progress;
  final int? selected;
  final Color separatorColor;

  const _AreaPainter({
    required this.items,
    required this.maxStock,
    required this.progress,
    required this.selected,
    required this.separatorColor,
  });

  void _txt(Canvas c, String t, Offset o, double sz, Color col, FontWeight w) {
    (TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: sz,
          color: col,
          fontWeight: w,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padB = 24.0; // x-axis area
    final chartH = size.height - padB;
    final chartW = size.width;
    final n = items.length;
    final slotW = chartW / n;

    // Y-axis labels on left side (drawn outside, but we paint them via padding)
    // Grid lines
    final gridPaint = Paint()
      ..color = separatorColor
      ..strokeWidth = 0.5;
    final yMax = (maxStock * 1.15).ceilToDouble();
    final steps = _niceSteps(yMax);
    for (final s in steps) {
      final y = chartH - (chartH * s / yMax);
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
      // Y label (drawn to the LEFT — handled by left padding in parent)
    }

    if (n < 2) return;

    // Compute data points
    List<Offset> pts = [];
    for (int i = 0; i < n; i++) {
      final cx = i * slotW + slotW / 2;
      final cy = chartH - (chartH * items[i].AvailableStock / yMax) * progress;
      pts.add(Offset(cx, cy));
    }

    // Filled area path
    final areaPath = Path()..moveTo(pts[0].dx, chartH);
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) {
        areaPath.lineTo(pts[0].dx, pts[0].dy);
      } else {
        // Smooth cubic bezier
        final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
        final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
        areaPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
      }
    }
    areaPath.lineTo(pts.last.dx, chartH);
    areaPath.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [kPurple.withOpacity(0.35), kPurple.withOpacity(0.05)],
      ).createShader(Rect.fromLTWH(0, 0, chartW, chartH));
    canvas.drawPath(areaPath, fillPaint);

    // Line path
    final linePath = Path();
    linePath.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = kPurple
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (int i = 0; i < pts.length; i++) {
      final isSel = selected == i;

      // Outer ring for selected
      if (isSel) {
        canvas.drawCircle(
          pts[i],
          7,
          Paint()..color = kPurple.withOpacity(0.25),
        );
      }

      // White fill dot
      canvas.drawCircle(pts[i], isSel ? 5 : 3.5, Paint()..color = kCard);
      // Colored border dot
      canvas.drawCircle(
        pts[i],
        isSel ? 5 : 3.5,
        Paint()
          ..color = isSel ? kPurpleDark : kPurple
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 2 : 1.5,
      );
    }

    // Vertical line for selected
    if (selected != null) {
      drawDashedLine(
        canvas,
        Offset(pts[selected!].dx, 0),
        Offset(pts[selected!].dx, chartH),
        Paint()
          ..color = kPurple.withOpacity(0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  List<double> _niceSteps(double max) {
    final step = max <= 5
        ? 0.5
        : max <= 10
        ? 1.0
        : max <= 20
        ? 2.0
        : 5.0;
    final steps = <double>[];
    for (double s = 0; s <= max; s += step) {
      steps.add(s);
    }
    return steps;
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.progress != progress || old.selected != selected;

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4;
    const dashSpace = 4;

    double distance = (end - start).distance;
    final dx = (end.dx - start.dx) / distance;
    final dy = (end.dy - start.dy) / distance;

    double current = 0;

    while (current < distance) {
      final x1 = start.dx + dx * current;
      final y1 = start.dy + dy * current;

      current += dashWidth;

      final x2 = start.dx + dx * current;
      final y2 = start.dy + dy * current;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

      current += dashSpace;
    }
  }
}

// ─── Y-axis wrapper ───────────────────────────────────────────────────────────

class _AreaChartWithYAxis extends StatelessWidget {
  final List<EndingStockItem> items;
  final Animation<double> anim;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _AreaChartWithYAxis({
    required this.items,
    required this.anim,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxStock = items.map((i) => i.AvailableStock).reduce(max);
    final yMax = (maxStock * 1.15).ceilToDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-axis labels
        SizedBox(
          width: 32,
          height: 240,
          child: CustomPaint(painter: _YAxisPainter(yMax: yMax)),
        ),
        // Chart
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, box) {
              return AnimatedBuilder(
                animation: anim,
                builder: (_, __) => GestureDetector(
                  onTapUp: (d) {
                    final slotW = box.maxWidth / items.length;
                    final idx = (d.localPosition.dx / slotW).floor().clamp(
                      0,
                      items.length - 1,
                    );
                    onSelect(idx);
                  },
                  child: CustomPaint(
                    size: Size(box.maxWidth, 240),
                    painter: _AreaPainter(
                      items: items,
                      maxStock: maxStock,
                      progress: anim.value,
                      selected: selected,
                      separatorColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_80
                          : AppColor.neutral_20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YAxisPainter extends CustomPainter {
  final double yMax;
  const _YAxisPainter({required this.yMax});

  @override
  void paint(Canvas canvas, Size size) {
    const padB = 24.0;
    final chartH = size.height - padB;
    final step = yMax <= 5
        ? 0.5
        : yMax <= 10
        ? 1.0
        : yMax <= 20
        ? 2.0
        : 5.0;

    for (double s = 0; s <= yMax; s += step) {
      final y = chartH - (chartH * s / yMax);
      final label = s == s.truncateToDouble()
          ? s.toInt().toString()
          : s.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 9,
            color: kMuted,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_YAxisPainter old) => old.yMax != yMax;
}

// ─── Tooltip card ─────────────────────────────────────────────────────────────

class _Tooltip extends StatelessWidget {
  final EndingStockItem item;
  const _Tooltip({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.sliderHighlightBg(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.ProductName,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.CompanyName,
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: kPurple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Available: ${item.AvailableStock.toInt() == 0 ? 0 : item.AvailableStock.toInt().toString().padLeft(2, '0')}',
              style: AppTheme.textLabel(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── List section ─────────────────────────────────────────────────────────────

class _ListSection extends StatelessWidget {
  final List<EndingStockItem> items;
  final Animation<double> anim;
  final double maxStock;

  const _ListSection({
    super.key,
    required this.items,
    required this.anim,
    required this.maxStock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(width: 32),
              Expanded(
                child: Text(
                  'Product',
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'Company',
                  textAlign: TextAlign.center,
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Stock',
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
        SizedBox(
          height: 300,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: List.generate(
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
                          maxStock: maxStock,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ListRow extends StatefulWidget {
  final int rank;
  final EndingStockItem item;
  final double maxStock;
  const _ListRow({
    required this.rank,
    required this.item,
    required this.maxStock,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hover = false;

  Color get _stockColor {
    final s = widget.item.AvailableStock;
    if (s <= 2) return const Color(0xFFE24B4A);
    if (s <= 4) return const Color(0xFFFF9F40);
    return const Color(0xFF1D9E75);
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.item.AvailableStock / widget.maxStock;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hover ? kPurple.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            // Rank
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: widget.rank <= 3
                    ? kPurple.withOpacity(0.15)
                    : AppTheme.sliderHighlightBg(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  widget.rank.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.rank <= 3
                        ? kPurpleDark
                        : AppTheme.iconColorThree(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.ProductName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 3,
                      backgroundColor: AppTheme.sliderHighlightBg(context),
                      valueColor: const AlwaysStoppedAnimation(kPurple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Company pill
            SizedBox(
              width: 70,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sliderHighlightBg(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.item.CompanyName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textSearchInfoLabeled(
                      context,
                    ).copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            // Stock badge
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _stockColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.item.AvailableStock.toInt().toString().padLeft(2, '0')} St.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _stockColor,
                    ),
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
