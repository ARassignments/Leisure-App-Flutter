import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class DashboardPaymentsSummary extends StatefulWidget {
  final List<PaymentSummary> items;
  final bool isLoading;
  final bool isChartView;
  final ValueChanged<bool>? onToggle;

  const DashboardPaymentsSummary({
    super.key,
    required this.items,
    this.isLoading = false,
    this.isChartView = true,
    this.onToggle,
  });

  @override
  State<DashboardPaymentsSummary> createState() =>
      _DashboardPaymentsSummaryState();
}

class _DashboardPaymentsSummaryState extends State<DashboardPaymentsSummary>
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
  void didUpdateWidget(DashboardPaymentsSummary old) {
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

  // Group by userName — sum payments
  List<_GroupedPayment> get _grouped {
    final Map<String, _GroupedPayment> map = {};
    for (final item in widget.items) {
      if (map.containsKey(item.UserName)) {
        map[item.UserName]!.Payments.add(item);
        map[item.UserName]!.Total += item.Payment;
      } else {
        map[item.UserName] = _GroupedPayment(
          UserName: item.UserName,
          Payments: [item],
          Total: item.Payment,
          PaymentMode: item.PaymentMode,
        );
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.Total.compareTo(a.Total));
    return list;
  }

  double get _totalReceived => widget.items
      .where((i) => i.PaymentMode == 'Recived')
      .fold(0.0, (s, i) => s + i.Payment);

  double get _totalPaid => widget.items
      .where((i) => i.PaymentMode == 'Paid')
      .fold(0.0, (s, i) => s + i.Payment);

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtFull(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

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
    final grouped = _grouped;

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments Summary',
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
                      count: grouped.length,
                      totalReceived: _totalReceived,
                      totalPaid: _totalPaid,
                      fmt: _fmt,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.items.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _chart
                          ? _PolarSection(
                              key: const ValueKey('polar'),
                              grouped: grouped,
                              anim: _anim,
                              selected: _sel,
                              onSelect: (i) =>
                                  setState(() => _sel = _sel == i ? null : i),
                              onDeselect: () => setState(() => _sel = null),
                              fmtFull: _fmtFull,
                            )
                          : _ListSection(
                              key: const ValueKey('lst'),
                              grouped: grouped,
                              anim: _anim,
                              fmtFull: _fmtFull,
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

class PaymentSummary {
  final String UserName;
  final double Payment;
  final String PaymentDate;
  final String PaymentMode;

  const PaymentSummary({
    required this.UserName,
    required this.Payment,
    required this.PaymentDate,
    required this.PaymentMode,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
    UserName: json['UserName'] ?? 'Unknown',
    Payment: (json['Payment'] as num?)?.toDouble() ?? 0.0,
    PaymentDate: json['PaymentDate'] ?? '',
    PaymentMode: json['PaymentMode'] ?? '',
  );
}

// ─── Colors ───────────────────────────────────────────────────────────────────

const List<Color> kChartColors = [
  Color(0xFF36A2EB),
  Color(0xFF4BC0C0),
  Color(0xFF9966FF),
  Color(0xFFFF9F40),
  Color(0xFFFF6384),
  Color(0xFF4CAF50),
  Color(0xFF36A2EB),
  Color(0xFF4BC0C0),
  Color(0xFF9966FF),
  Color(0xFFFF9F40),
  Color(0xFFFF6384),
  Color(0xFF4CAF50),
];

// ─── Theme ────────────────────────────────────────────────────────────────────

const Color kBg = Color(0xFFF5F6FA);
const Color kCard = Colors.white;
const Color kText = Color(0xFF1A1A2E);
const Color kMuted = Color(0xFF9E9E9E);

// ─── Grouped payment model ────────────────────────────────────────────────────

class _GroupedPayment {
  final String UserName;
  final List<PaymentSummary> Payments;
  double Total;
  final String PaymentMode;

  _GroupedPayment({
    required this.UserName,
    required this.Payments,
    required this.Total,
    required this.PaymentMode,
  });
}

// ─── Summary cards ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int count;
  final double totalReceived, totalPaid;
  final String Function(double) fmt;

  const _SummaryRow({
    required this.count,
    required this.totalReceived,
    required this.totalPaid,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Metric(
        label: 'Customers',
        value: count == 0 ? '0' : count.toString().padLeft(2, '0'),
        color: const Color(0xFF36A2EB),
        icon: Icons.people_outline,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Received',
        value: 'Rs ${fmt(totalReceived)}',
        color: const Color(0xFF4CAF50),
        icon: Icons.south_west_rounded,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Paid',
        value: 'Rs ${fmt(totalPaid)}',
        color: const Color(0xFFFF6384),
        icon: Icons.north_east_rounded,
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
          icon: Icons.radar_rounded,
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
                ? const Color(0xFF36A2EB)
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

// ─── Polar area chart section ─────────────────────────────────────────────────

class _PolarSection extends StatelessWidget {
  final List<_GroupedPayment> grouped;
  final Animation<double> anim;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onDeselect;
  final String Function(double) fmtFull;

  const _PolarSection({
    super.key,
    required this.grouped,
    required this.anim,
    required this.selected,
    required this.onSelect,
    required this.onDeselect,
    required this.fmtFull,
  });

  @override
  Widget build(BuildContext context) {
    final maxTotal = grouped.map((g) => g.Total).reduce(max);

    return Column(
      children: [
        // Chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) => GestureDetector(
                onTapUp: (d) => _handleTap(d.localPosition, context, maxTotal),
                child: CustomPaint(
                  size: const Size(double.infinity, 300),
                  painter: _PolarPainter(
                    grouped: grouped,
                    maxTotal: maxTotal,
                    progress: anim.value,
                    selected: selected,
                    separatorColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColor.neutral_80
                        : AppColor.neutral_20,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Tooltip
        if (selected != null && selected! < grouped.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _TooltipCard(
              group: grouped[selected!],
              color: kChartColors[selected! % kChartColors.length],
              fmtFull: fmtFull,
            ),
          ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(grouped.length, (i) {
              final color = kChartColors[i % kChartColors.length];
              final isActive = selected == i;
              return GestureDetector(
                onTap: () => isActive ? onDeselect() : onSelect(i),
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
                          ? color.withOpacity(0.5)
                          : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        grouped[i].UserName.split(' ').take(3).join(' '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive ? AppTheme.iconColor(context) : AppTheme.iconColorThree(context),
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

  void _handleTap(Offset localPos, BuildContext context, double maxTotal) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = localPos.dx - cx;
    final dy = localPos.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    final maxRadius = min(cx, cy) - 20;

    if (dist > maxRadius || dist < 8) {
      onDeselect();
      return;
    }

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    final n = grouped.length;
    final sliceAngle = 2 * pi / n;

    for (int i = 0; i < n; i++) {
      // final start = i * sliceAngle - pi / 2 + pi / 2; // offset already added
      // Recalculate with same offset as painter
      final startA = i * sliceAngle;
      final endA = startA + sliceAngle;

      double tapAngle = atan2(dy, dx) + pi / 2;
      if (tapAngle < 0) tapAngle += 2 * pi;

      if (tapAngle >= startA && tapAngle < endA) {
        final radius = maxRadius * (grouped[i].Total / maxTotal);
        if (dist <= radius) {
          onSelect(i);
          return;
        }
        onDeselect();
        return;
      }
    }
    onDeselect();
  }
}

// ─── Polar painter ────────────────────────────────────────────────────────────

class _PolarPainter extends CustomPainter {
  final List<_GroupedPayment> grouped;
  final double maxTotal, progress;
  final int? selected;
  final Color separatorColor;

  const _PolarPainter({
    required this.grouped,
    required this.maxTotal,
    required this.progress,
    required this.selected,
    required this.separatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = min(cx, cy) - 20;
    final n = grouped.length;
    final sliceAngle = 2 * pi / n;
    const gap = 0.03;

    // Grid circles
    final gridPaint = Paint()
      ..color = separatorColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(Offset(cx, cy), maxRadius * r / 4, gridPaint);
    }

    // Radial grid lines
    for (int i = 0; i < n; i++) {
      final angle = i * sliceAngle - pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxRadius * cos(angle), cy + maxRadius * sin(angle)),
        gridPaint,
      );
    }

    // Polar segments
    for (int i = 0; i < n; i++) {
      final isSel = selected == i;
      final color = kChartColors[i % kChartColors.length];
      final radius = maxRadius * (grouped[i].Total / maxTotal) * progress;
      final startAngle = i * sliceAngle - pi / 2 + gap;
      final sweep = sliceAngle - gap * 2;

      final fillOpacity = selected == null ? 0.75 : (isSel ? 0.95 : 0.30);
      final extraR = isSel ? 10.0 : 0.0;

      // Fill
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius + extraR),
        startAngle,
        sweep,
        true,
        Paint()..color = color.withOpacity(fillOpacity),
      );

      // Border
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius + extraR),
        startAngle,
        sweep,
        true,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 2 : 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(_PolarPainter old) =>
      old.progress != progress || old.selected != selected;
}

// ─── Tooltip card ─────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final _GroupedPayment group;
  final Color color;
  final String Function(double) fmtFull;

  const _TooltipCard({
    required this.group,
    required this.color,
    required this.fmtFull,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.sliderHighlightBg(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${group.UserName}: ${fmtFull(group.Total)}',
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Individual payments
        ...group.Payments.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.PaymentMode == 'Recived'
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6384),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${p.PaymentMode}: ${fmtFull(p.Payment)}',
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w300),
                ),
                const Spacer(),
                Text(
                  p.PaymentDate,
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── List section ─────────────────────────────────────────────────────────────

class _ListSection extends StatefulWidget {
  final List<_GroupedPayment> grouped;
  final Animation<double> anim;
  final String Function(double) fmtFull;

  const _ListSection({
    super.key,
    required this.grouped,
    required this.anim,
    required this.fmtFull,
  });

  @override
  State<_ListSection> createState() => _ListSectionState();
}

class _ListSectionState extends State<_ListSection> {
  int? _expandedIndex;
  @override
  Widget build(BuildContext context) {
    final maxTotal = widget.grouped.map((g) => g.Total).reduce(max);
    return Column(
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
                width: 55,
                child: Text(
                  'Mode',
                  textAlign: TextAlign.center,
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 80,
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

        ...List.generate(
          widget.grouped.length,
          (i) => AnimatedBuilder(
            animation: widget.anim,
            builder: (_, __) {
              final delay = (i / widget.grouped.length) * 0.6;
              final t = ((widget.anim.value - delay) / (1 - delay)).clamp(
                0.0,
                1.0,
              );
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: _ListRow(
                    rank: i + 1,
                    group: widget.grouped[i],
                    maxTotal: maxTotal,
                    fmtFull: widget.fmtFull,
                    isExpanded: _expandedIndex == i, // ✅ control here
                    onToggle: () {
                      setState(() {
                        _expandedIndex = _expandedIndex == i
                            ? null
                            : i; // toggle
                      });
                    },
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
}

class _ListRow extends StatefulWidget {
  final int rank;
  final _GroupedPayment group;
  final double maxTotal;
  final String Function(double) fmtFull;
  final bool isExpanded;
  final VoidCallback onToggle;
  const _ListRow({
    required this.rank,
    required this.group,
    required this.maxTotal,
    required this.fmtFull,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> with TickerProviderStateMixin {
  bool _hover = false;

  Color get _color => kChartColors[(widget.rank - 1) % kChartColors.length];
  bool get _isReceived => widget.group.PaymentMode == 'Recived';

  @override
  Widget build(BuildContext context) {
    final pct = widget.group.Total / widget.maxTotal;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hover ? _color.withOpacity(0.05) : Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    // Rank
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

                    // Name + bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.UserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.textLabel(context).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.group.Payments.length.toString().padLeft(2, '0')} payment${widget.group.Payments.length > 1 ? 's' : ''}',
                            style: AppTheme.textSearchInfoLabeled(context)
                                .copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 3,
                              backgroundColor: AppTheme.sliderHighlightBg(
                                context,
                              ),
                              valueColor: AlwaysStoppedAnimation(_color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Mode badge
                    SizedBox(
                      width: 55,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _isReceived
                                ? const Color(0xFF4CAF50).withOpacity(0.10)
                                : const Color(0xFFFF6384).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.group.PaymentMode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: _isReceived
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6384),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Amount + expand icon
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'Rs ${widget.fmtFull(widget.group.Total)}',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.textLabel(context).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: widget.isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              HugeIconsStroke.arrowDown01,
                              size: 14,
                              color: AppTheme.iconColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded sub-payments
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: widget.isExpanded
                    ? Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.sliderHighlightBg(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: widget.group.Payments.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final p = entry.value;

                            final isRec = p.PaymentMode == 'Recived';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBg(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (index + 1).toString().padLeft(2, '0'),
                                        style:
                                            AppTheme.textSearchInfoLabeled(
                                              context,
                                            ).copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    isRec
                                        ? Icons.south_west_rounded
                                        : Icons.north_east_rounded,
                                    size: 14,
                                    color: isRec
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFF6384),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.PaymentMode,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isRec
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFFF6384),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    p.PaymentDate,
                                    style:
                                        AppTheme.textSearchInfoLabeled(
                                          context,
                                        ).copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w300,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Rs ${widget.fmtFull(p.Payment)}',
                                    style: AppTheme.textLabel(context).copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
