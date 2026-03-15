import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class DashboardGrid extends StatelessWidget {
  final int ordersValue;
  final double revenueValue;
  final double creditSaleValue;
  final double debitSaleValue;
  const DashboardGrid({
    super.key,
    required this.ordersValue,
    required this.revenueValue,
    required this.creditSaleValue,
    required this.debitSaleValue,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Orders',
        'value':
            '${ordersValue == 0 ? 0 : ordersValue.toString().padLeft(2, '0')}',
        'valueInt': ordersValue.toDouble(),
        'color1': Colors.tealAccent.shade400,
        'color2': Colors.teal,
        'icon': HugeIconsStroke.shoppingBasket02,
        'prefix': "",
        'suffix': " Qty",
      },
      {
        'title': 'Revenue',
        'value':
            'Rs ${revenueValue == 0 ? 0 : revenueValue.toString().padLeft(2, '0')}',
        'valueInt': revenueValue.toDouble(),
        'color1': Colors.orangeAccent,
        'color2': Colors.deepOrange,
        'icon': HugeIconsStroke.wallet02,
        'prefix': "Rs ",
        'suffix': "",
      },
      {
        'title': 'Credit Sale',
        'value':
            'Rs ${creditSaleValue == 0 ? 0 : creditSaleValue.toString().padLeft(2, '0')}',
        'valueInt': creditSaleValue.toDouble(),
        'color1': Colors.lightBlueAccent,
        'color2': Colors.blue,
        'icon': HugeIconsStroke.moneySend01,
        'prefix': "Rs ",
        'suffix': "",
      },
      {
        'title': 'Debit Sale',
        'value':
            'Rs ${debitSaleValue == 0 ? 0 : debitSaleValue.toString().padLeft(2, '0')}',
        'valueInt': debitSaleValue.toDouble(),
        'color1': Colors.purpleAccent,
        'color2': Colors.deepPurple,
        'icon': HugeIconsStroke.moneyReceive01,
        'prefix': "Rs ",
        'suffix': "",
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600
            ? 2 // small screen → 2 cards per row
            : 4; // large screen → 4 cards per row

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];
            return _buildStatCard(
              context,
              item['title'] as String,
              item['value'] as String,
              item['valueInt'] as double,
              item['color1'] as Color,
              item['color2'] as Color,
              item['icon'] as IconData,
              item['prefix'] as String,
              item['suffix'] as String,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    double valueInt,
    Color color1,
    Color color2,
    IconData icon,
    String prefix,
    String suffix,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTheme.textTitle(
                    context,
                  ).copyWith(color: Colors.white, fontSize: 18),
                ),
                AnimatedDigitWidget(
                  prefix: prefix,
                  suffix: suffix,
                  value: valueInt,
                  duration: Duration(milliseconds: 1000),
                  separateSymbol: ',',
                  fractionDigits: 2,
                  enableSeparator: true,
                  textStyle: AppTheme.textLabel(context).copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: AppFontFamily.poppinsMedium,
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
