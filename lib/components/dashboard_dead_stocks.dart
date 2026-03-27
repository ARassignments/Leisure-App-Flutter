import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '/theme/theme.dart';

class DashboardDeadStock extends StatefulWidget {
  final List<DeadStockItem> items;
  final bool isLoading;
  final bool isChartView;
  final ValueChanged<bool>? onToggle;

  const DashboardDeadStock({
    super.key,
    required this.items,
    this.isLoading = false,
    this.isChartView = true,
    this.onToggle,
  });

  @override
  State<DashboardDeadStock> createState() => _DashboardDeadStockState();
}

class _DashboardDeadStockState extends State<DashboardDeadStock>
    with SingleTickerProviderStateMixin {
  late bool _chart = widget.isChartView;
  int? _sel;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
  void didUpdateWidget(DashboardDeadStock old) {
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
                        'Dead Stock',
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
                      items: widget.items,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.items.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _chart
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _HBarSection(
                                key: const ValueKey('bar'),
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

class DeadStockItem {
  final int ProductId;
  final String ProductName;
  final String CompanyName;
  final double AvailableStock;
  final DateTime LastSaleDate;

  const DeadStockItem({
    required this.ProductId,
    required this.ProductName,
    required this.CompanyName,
    required this.AvailableStock,
    required this.LastSaleDate,
  });

  factory DeadStockItem.fromJson(Map<String, dynamic> json) => DeadStockItem(
    ProductId: json['ProductId'] ?? 0,
    ProductName: json['ProductName'] ?? 'Unknown',
    CompanyName: json['CompanyName'] ?? '',
    AvailableStock: (json['AvailableStock'] as num?)?.toDouble() ?? 0.0,
    LastSaleDate:
        DateTime.tryParse(json['LastSaleDate'] ?? '') ?? DateTime.now(),
  );
}

// ─── Theme ────────────────────────────────────────────────────────────────────

const Color kPink = Color(0xFFFF6384);
const Color kPinkLight = Color(0xFFFFE8ED);
const Color kPinkDark = Color(0xFFD63060);
const Color kBg = Color(0xFFF5F6FA);
const Color kCard = Colors.white;
const Color kText = Color(0xFF1A1A2E);
const Color kMuted = Color(0xFF9E9E9E);
const Color kLine = AppColor.neutral_80;

// ─── Summary cards ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int count;
  final double totalStock;
  final List<DeadStockItem> items;

  const _SummaryRow({
    required this.count,
    required this.totalStock,
    required this.items,
  });

  String _oldestDate() {
    if (items.isEmpty) return '—';
    final oldest = items
        .map((i) => i.LastSaleDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateFormat('MMM dd, yyyy').format(oldest);
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Metric(
        label: 'Dead Products',
        value: count == 0 ? '0' : count.toString().padLeft(2, '0'),
        color: kPink,
        icon: Icons.inventory_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Total Units',
        value: totalStock == 0
            ? '0'
            : totalStock.toInt().toString().padLeft(2, '0'),
        color: const Color(0xFFFF9F40),
        icon: Icons.warehouse_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Oldest Sale',
        value: _oldestDate(),
        color: const Color(0xFF9966FF),
        icon: Icons.event_outlined,
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
          icon: HugeIconsSolid.barChartHorizontal,
          active: isChart,
          onTap: () => onSwitch(true),
        ),
        _TBtn(
          label: 'List',
          icon: HugeIconsSolid.packageMoving,
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
            color: active ? kPink : AppTheme.iconColorThree(context),
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

// ─── Horizontal bar chart ─────────────────────────────────────────────────────

class _HBarSection extends StatelessWidget {
  final List<DeadStockItem> items;
  final Animation<double> anim;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _HBarSection({
    super.key,
    required this.items,
    required this.anim,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxStock = items.map((i) => i.AvailableStock).reduce(max);

    return Column(
      children: [
        // Chart canvas
        Padding(
          padding: const EdgeInsets.only(left: 26, right: 38),
          child: LayoutBuilder(
            builder: (ctx, box) {
              // row height * items + x-axis area
              const rowH = 26.0;
              const xAxis = 36.0;
              final chartH = rowH * items.length + xAxis;

              return AnimatedBuilder(
                animation: anim,
                builder: (_, __) => GestureDetector(
                  onTapUp: (d) {
                    final idx = (d.localPosition.dy / rowH).floor().clamp(
                      0,
                      items.length - 1,
                    );
                    onSelect(idx);
                  },
                  child: CustomPaint(
                    size: Size(box.maxWidth, chartH),
                    painter: _HBarPainter(
                      items: items,
                      maxStock: maxStock,
                      progress: anim.value,
                      selected: selected,
                      rowH: rowH,
                      xAxis: xAxis,
                      canvasW: box.maxWidth,
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
                  color: kPink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Dead Stock',
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

class _HBarPainter extends CustomPainter {
  final List<DeadStockItem> items;
  final double maxStock, progress, rowH, xAxis, canvasW;
  final int? selected;
  final Color separatorColor;

  const _HBarPainter({
    required this.items,
    required this.maxStock,
    required this.progress,
    required this.selected,
    required this.rowH,
    required this.xAxis,
    required this.canvasW,
    required this.separatorColor,
  });

  void _txt(Canvas c, String t, Offset o, double sz, Color col, FontWeight w) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: sz,
          color: col,
          fontWeight: w,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: ui.TextDirection.ltr, // ✅ FIX
    );

    textPainter.layout();
    textPainter.paint(c, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const labelW = 0.0; // no left labels — product names shown in tooltip
    final chartW = canvasW - labelW;
    final chartH = size.height - xAxis;

    // Vertical grid lines + X-axis labels
    const steps = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    final gp = Paint()
      ..color = separatorColor
      ..strokeWidth = 0.5;
    for (final s in steps) {
      if (s > maxStock + 5) continue;
      // final x = labelW + chartW * s / (maxStock + 5) * progress;
      // Only draw fixed grid — not scaled by progress
      final xFixed = labelW + chartW * s / (maxStock + 5);
      canvas.drawLine(Offset(xFixed, 0), Offset(xFixed, chartH), gp);
      _txt(
        canvas,
        s == 0 ? '0' : s.toString().padLeft(2, '0'),
        Offset(xFixed - 6, chartH + 8),
        9,
        kMuted,
        FontWeight.w400,
      );
    }

    // Bars
    const barPad = 4.0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isSel = selected == i;
      final barW = chartW * (item.AvailableStock / (maxStock + 5)) * progress;
      final top = i * rowH + barPad;
      final barH = rowH - barPad * 2;

      final color = isSel
          ? kPinkDark
          : (selected == null ? kPink : kPink.withOpacity(0.38));

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(labelW, top, barW, barH),
          topRight: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
        Paint()..color = color,
      );

      // Stock value at end of selected bar
      if (isSel && progress > 0.7) {
        final xVal = labelW + barW + 4;
        _txt(
          canvas,
          '${item.AvailableStock.toInt().toString().padLeft(2, '0')} Qty',
          Offset(xVal, top + barH / 2 - 6),
          10,
          kPinkDark,
          FontWeight.w700,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HBarPainter old) =>
      old.progress != progress || old.selected != selected;
}

// ─── Tooltip ─────────────────────────────────────────────────────────────────

class _Tooltip extends StatelessWidget {
  final DeadStockItem item;
  const _Tooltip({required this.item});

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
          item.ProductName,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: kPink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Dead Stock:  ${item.AvailableStock.toInt().toString().padLeft(2, '0')}',
              style: AppTheme.textSearchInfoLabeled(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w300),
            ),
            const SizedBox(width: 16),
            Icon(
              HugeIconsSolid.dateTime,
              color: AppTheme.iconColorThree(context),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Last Sale: ${DateFormat('MMM dd, yyyy').format(item.LastSaleDate)}',
              style: AppTheme.textSearchInfoLabeled(
                context,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── List view ────────────────────────────────────────────────────────────────

class _ListSection extends StatelessWidget {
  final List<DeadStockItem> items;
  final Animation<double> anim;

  const _ListSection({super.key, required this.items, required this.anim});

  @override
  Widget build(BuildContext context) {
    final maxStock = items.map((i) => i.AvailableStock).reduce(max);

    return Column(
      children: [
        // Header
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
                  'Stock',
                  textAlign: TextAlign.center,
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Last Sale',
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
  final DeadStockItem item;
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

  // Days since last sale
  int get _daysSince =>
      DateTime.now().difference(widget.item.LastSaleDate).inDays;

  Color get _ageColor {
    if (_daysSince > 180) return const Color(0xFFE24B4A);
    if (_daysSince > 90) return const Color(0xFFFF9F40);
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
        color: _hover ? kPink.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            // Rank
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: widget.rank <= 3
                    ? kPink.withOpacity(0.15)
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
                        ? kPinkDark
                        : AppTheme.iconColorThree(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + bar + company
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
                  const SizedBox(height: 2),
                  Text(
                    widget.item.CompanyName,
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
                      valueColor: const AlwaysStoppedAnimation(kPink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Stock badge
            SizedBox(
              width: 70,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sliderHighlightBg(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.item.AvailableStock.toInt().toString().padLeft(
                      2,
                      '0',
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kPinkDark,
                    ),
                  ),
                ),
              ),
            ),

            // Last sale date + age indicator
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM dd').format(widget.item.LastSaleDate),
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _ageColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _timeSinceLastSale,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _ageColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _timeSinceLastSale {
    final now = DateTime.now();
    final last = widget.item.LastSaleDate;

    int years = now.year - last.year;
    int months = now.month - last.month;
    int days = now.day - last.day;

    // Adjust negative days
    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }

    // Adjust negative months
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    // Build string
    String result = '';
    if (years > 0) result += '${years}y ';
    if (months > 0) result += '${months}m ';
    if (days > 0) result += '${days}d';

    return result.trim().isEmpty ? 'Today' : '${result.trim()} ago';
  }
}
