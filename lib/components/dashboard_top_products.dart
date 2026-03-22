import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class DashboardTopProducts extends StatefulWidget {
  final List<TopProduct> products;
  final bool isLoading;
  final bool isChartView;
  final ValueChanged<bool>? onToggle;

  const DashboardTopProducts({
    super.key,
    required this.products,
    this.isLoading = false,
    this.isChartView = true,
    this.onToggle,
  });

  @override
  State<DashboardTopProducts> createState() => _DashboardTopProductsState();
}

class _DashboardTopProductsState extends State<DashboardTopProducts>
    with SingleTickerProviderStateMixin {
  late bool _chart = widget.isChartView;
  int? _sel;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
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
  void didUpdateWidget(DashboardTopProducts old) {
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

  int get _total => widget.products.fold(0, (s, p) => s + p.TotalQuantitySold);

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
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card
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
                        'Top Products',
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
                      count: widget.products.length,
                      total: _total,
                      loading: widget.isLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.products.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _chart
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _BarSection(
                                key: const ValueKey('bar'),
                                products: widget.products,
                                anim: _anim,
                                selected: _sel,
                                onSelect: (i) =>
                                    setState(() => _sel = _sel == i ? null : i),
                              ),
                            )
                          : _ListSection(
                              key: const ValueKey('lst'),
                              products: widget.products,
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

// ─── Model ───────────────────────────────────────────────────────────────────
class TopProduct {
  final int ProductId;
  final String ProductName;
  final int TotalQuantitySold;

  const TopProduct({
    required this.ProductId,
    required this.ProductName,
    required this.TotalQuantitySold,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
    ProductId: json['ProductId'] ?? 0,
    ProductName: json['ProductName'] ?? 'Unknown',
    TotalQuantitySold: (json['TotalQuantitySold'] as num?)?.toInt() ?? 0,
  );
}

// ─── Theme ────────────────────────────────────────────────────────────────────

const Color kTeal = Color(0xFF3BBFB2);
const Color kTealLight = Color(0xFFE0F7F5);
const Color kTealDark = Color(0xFF0F9E91);
const Color kBg = Color(0xFFF5F6FA);
const Color kCard = Colors.white;
const Color kText = Color(0xFF1A1A2E);
const Color kMuted = Color(0xFF9E9E9E);
const Color kLine = AppColor.neutral_80;

// ─── Summary ──────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int count, total;
  final bool loading;
  const _SummaryRow({
    required this.count,
    required this.total,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Metric(
        label: 'Products',
        value: loading
            ? '—'
            : count == 0
            ? '0'
            : count.toString().padLeft(2, '0'),
        color: kTeal,
        icon: Icons.inventory_2_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Units Sold',
        value: loading
            ? '—'
            : total == 0
            ? '0'
            : total.toString().padLeft(2, '0'),
        color: const Color(0xFF378ADD),
        icon: Icons.shopping_cart_outlined,
      ),
      const SizedBox(width: 10),
      _Metric(
        label: 'Rank #1',
        value: loading ? '—' : 'Top',
        color: const Color(0xFFD85A30),
        icon: Icons.emoji_events_outlined,
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
          icon: HugeIconsSolid.chart01,
          active: isChart,
          onTap: () => onSwitch(true),
        ),
        _TBtn(
          label: 'List',
          icon: HugeIconsSolid.packageMoving01,
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
            color: active ? kTeal : AppTheme.iconColorThree(context),
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

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _BarSection extends StatelessWidget {
  final List<TopProduct> products;
  final Animation<double> anim;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _BarSection({
    super.key,
    required this.products,
    required this.anim,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxQ = products
        .map((p) => p.TotalQuantitySold)
        .reduce(max)
        .toDouble();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 38, right: 16),
          child: SizedBox(
            height: 230,
            child: LayoutBuilder(
              builder: (ctx, box) {
                final slotW = box.maxWidth / products.length;
                return AnimatedBuilder(
                  animation: anim,
                  builder: (_, __) => GestureDetector(
                    onTapUp: (d) {
                      final idx = (d.localPosition.dx / slotW).floor().clamp(
                        0,
                        products.length - 1,
                      );
                      onSelect(idx);
                    },
                    child: CustomPaint(
                      size: Size(box.maxWidth, 230),
                      painter: _BarPainter(
                        products: products,
                        maxQ: maxQ,
                        progress: anim.value,
                        selected: selected,
                        slotW: slotW,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Tooltip
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _Tooltip(product: products[selected!]),
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
                  color: kTeal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Quantity Sold',
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

class _BarPainter extends CustomPainter {
  final List<TopProduct> products;
  final double maxQ, progress, slotW;
  final int? selected;

  const _BarPainter({
    required this.products,
    required this.maxQ,
    required this.progress,
    required this.selected,
    required this.slotW,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 28.0;
    final chartH = size.height - labelH;
    final barW = slotW * 0.62;

    // Grid
    final gp = Paint()
      ..color = kLine
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
      _txt(
        canvas,
        (maxQ * i / 4).round().toString().padLeft(2, '0'),
        Offset(-20, y - 13),
        9,
        kMuted,
        FontWeight.w400,
      );
    }

    // Bars
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final isSel = selected == i;
      final frac = p.TotalQuantitySold / maxQ;
      final barH = chartH * frac * progress;
      final cx = i * slotW + slotW / 2;
      final left = cx - barW / 2;
      final top = chartH - barH;

      final color = isSel
          ? kTealDark
          : (selected == null ? kTeal : kTeal.withOpacity(0.38));

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barW, barH),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        Paint()..color = color,
      );

      if (isSel && progress > 0.75) {
        _txt(
          canvas,
          '${p.TotalQuantitySold.toString().padLeft(2, '0')} Qty',
          Offset(cx - 14, top - 16),
          10,
          kTealDark,
          FontWeight.w700,
        );
      }

      _txt(
        canvas,
        (i + 1).toString().padLeft(2, '0'),
        Offset(cx - 4, chartH + 8),
        10,
        isSel ? kTealDark : kMuted,
        isSel ? FontWeight.w700 : FontWeight.w400,
      );
    }
  }

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
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.selected != selected;
}

// ─── Tooltip ─────────────────────────────────────────────────────────────────

class _Tooltip extends StatelessWidget {
  final TopProduct product;
  const _Tooltip({required this.product});

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
          product.ProductName,
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
                color: kTeal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Quantity Sold: ${product.TotalQuantitySold.toString().padLeft(2, '0')} QTY',
              style: AppTheme.textSearchInfoLabeled(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _ListSection extends StatelessWidget {
  final List<TopProduct> products;
  final Animation<double> anim;
  const _ListSection({super.key, required this.products, required this.anim});

  @override
  Widget build(BuildContext context) {
    final maxQ = products
        .map((p) => p.TotalQuantitySold)
        .reduce(max)
        .toDouble();
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
                width: 80,
                child: Text(
                  'Qty Sold',
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
          products.length,
          (i) => AnimatedBuilder(
            animation: anim,
            builder: (_, __) {
              final delay = (i / products.length) * 0.6;
              final t = ((anim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: _ListRow(
                    rank: i + 1,
                    product: products[i],
                    maxQ: maxQ,
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
  final TopProduct product;
  final double maxQ;
  const _ListRow({
    required this.rank,
    required this.product,
    required this.maxQ,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final pct = widget.product.TotalQuantitySold / widget.maxQ;
    final isTop = widget.rank <= 3;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hover ? kTeal.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isTop
                    ? kTeal.withOpacity(0.15)
                    : AppTheme.sliderHighlightBg(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  widget.rank.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isTop ? kTealDark : AppTheme.iconColorThree(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.ProductName,
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
                      minHeight: 4,
                      backgroundColor: AppTheme.sliderHighlightBg(context),
                      valueColor: const AlwaysStoppedAnimation(kTeal),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Qty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.sliderHighlightBg(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.product.TotalQuantitySold.toString().padLeft(2, '0')} Qty',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kTealDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
