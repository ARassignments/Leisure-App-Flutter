import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;
  int? _selectedPlan = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _plans.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _fadeAnims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slideAnims = _controllers
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    // Staggered entry
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          "Subscriptions",
          style: AppTheme.textTitle(
            context,
          ).copyWith(fontSize: 20, fontFamily: AppFontFamily.poppinsLight),
        ),
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth < 500
                  ? 1 // small screen → 1 cards per row
                  : 3; // large screen → 3 cards per row
              return Column(
                children: [
                  // Title
                  _buildHeader(),
                  const SizedBox(height: 36),

                  // Cards
                  // GridView.builder(
                  //   shrinkWrap: true,
                  //   physics: const NeverScrollableScrollPhysics(),
                  //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  //     crossAxisCount: crossAxisCount,
                  //     crossAxisSpacing: 20,
                  //     mainAxisSpacing: 20,
                  //     childAspectRatio: constraints.maxWidth < 500 ? 0.96 : 1.22,
                  //   ),
                  //   itemCount: _plans.length,
                  //   itemBuilder: (context, index) {
                  //     // final item = _plans[index];
                  //     return FadeTransition(
                  //       opacity: _fadeAnims[index],
                  //       child: SlideTransition(
                  //         position: _slideAnims[index],
                  //         child: _PricingCard(
                  //           plan: _plans[index],
                  //           isSelected: _selectedPlan == index,
                  //           onTap: () => setState(
                  //             () => _selectedPlan = _selectedPlan == index
                  //                 ? null
                  //                 : index,
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                  ...List.generate(
                    _plans.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: FadeTransition(
                        opacity: _fadeAnims[i],
                        child: SlideTransition(
                          position: _slideAnims[i],
                          child: _PricingCard(
                            plan: _plans[i],
                            isSelected: _selectedPlan == i,
                            onTap: () => setState(
                              () => _selectedPlan = _selectedPlan == i ? null : i,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Decorative line
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dividerline(),
            const SizedBox(width: 12),
            Text(
              'PRICING PLANS',
              style: TextStyle(
                color: AppTheme.iconColor(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 12),
            _Dividerline(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Choose the plan that grows with your business',
          style: TextStyle(
            color: AppTheme.iconColor(context).withOpacity(0.45),
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _PlanFeature {
  final String text;
  final _FeatureType type;
  const _PlanFeature(this.text, this.type);
}

enum _FeatureType { check, info, warning, success }

class _Plan {
  final String name;
  final String price;
  final String period;
  final List<_PlanFeature> features;
  final List<Color> gradient;
  final Color accentColor;
  final bool isPopular;
  final String badge;

  const _Plan({
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.gradient,
    required this.accentColor,
    this.isPopular = false,
    this.badge = '',
  });
}

final List<_Plan> _plans = [
  _Plan(
    name: 'Silver',
    price: 'Rs 3,500',
    period: 'Per Month',
    accentColor: const Color(0xFFB39DDB),
    gradient: const [Color(0xFFCE93D8), Color(0xFF9FA8DA), Color(0xFF80DEEA)],
    features: [
      const _PlanFeature('All Features', _FeatureType.check),
      const _PlanFeature('Live Support Included', _FeatureType.check),
      const _PlanFeature(
        '+ Rs 10,000 (One-time Server Charges)',
        _FeatureType.info,
      ),
      const _PlanFeature(
        'Updates & New Modules = Extra Cost',
        _FeatureType.warning,
      ),
    ],
  ),
  _Plan(
    name: 'Golden',
    price: 'Rs 85,000',
    period: 'One-Time',
    accentColor: const Color(0xFFF48FB1),
    gradient: const [Color(0xFFF48FB1), Color(0xFFCE93D8), Color(0xFF90CAF9)],
    isPopular: true,
    badge: 'MOST POPULAR',
    features: [
      const _PlanFeature('All Features', _FeatureType.check),
      const _PlanFeature('Live Support Included', _FeatureType.check),
      const _PlanFeature('Rs 10,000/Year (Server Charges)', _FeatureType.info),
      const _PlanFeature(
        'Updates & New Modules = Extra Cost',
        _FeatureType.warning,
      ),
    ],
  ),
  _Plan(
    name: 'Platinum',
    price: 'Rs 185,000',
    period: 'One-Time',
    accentColor: const Color(0xFF80CBC4),
    gradient: const [Color(0xFF80DEEA), Color(0xFF80CBC4), Color(0xFFA5D6A7)],
    badge: 'BEST VALUE',
    features: [
      const _PlanFeature('All Features', _FeatureType.check),
      const _PlanFeature('Live Support Included', _FeatureType.check),
      const _PlanFeature('No Extra Server Charges', _FeatureType.success),
      const _PlanFeature(
        'Updates & New Modules = Extra Cost',
        _FeatureType.warning,
      ),
    ],
  ),
];

class _Dividerline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 1.5,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.iconColor(context).withOpacity(0.4),
        ],
      ),
    ),
  );
}

// ─── Pricing Card ─────────────────────────────────────────────────────────────

class _PricingCard extends StatefulWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scaleAnim = Tween<double>(
    begin: 1.0,
    end: 1.02,
  ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Gradient background
                  Positioned.fill(
                    child: widget.isSelected
                        ? _GradientBackground(colors: plan.gradient)
                        : Container(color: AppTheme.customListBg(context)),
                  ),

                  // Glass overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Decorative circle
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.07)
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.07)
                            : AppColor.primary_50.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.05)
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : AppColor.primary_50.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + name row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                color: widget.isSelected
                                    ? Colors.white
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? Colors.white
                                    : AppTheme.iconColor(context),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (plan.badge.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? Colors.white.withOpacity(0.25)
                                      : Theme.of(context).brightness ==
                                            Brightness.dark
                                      ? Colors.white.withOpacity(0.25)
                                      : AppTheme.iconColor(
                                          context,
                                        ).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.isSelected
                                        ? Colors.white.withOpacity(0.4)
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white.withOpacity(0.4)
                                        : AppTheme.iconColorThree(
                                            context,
                                          ).withOpacity(0.4),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  plan.badge,
                                  style: TextStyle(
                                    color: widget.isSelected
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white
                                        : AppTheme.iconColor(context),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price
                        Text(
                          plan.price,
                          style: TextStyle(
                            color: widget.isSelected
                                ? Colors.white
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? Colors.white
                                : AppTheme.iconColor(context),
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.period,
                          style: TextStyle(
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.6)
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? Colors.white.withOpacity(0.6)
                                : AppTheme.iconColor(context).withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? Colors.white.withOpacity(0.3)
                                    : AppTheme.iconColor(
                                        context,
                                      ).withOpacity(0.02),
                                widget.isSelected
                                    ? Colors.transparent
                                    : Theme.of(context).brightness ==
                                          Brightness.dark
                                    ? Colors.transparent
                                    : AppTheme.customListBg(context),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Features
                        ...plan.features.map(
                          (f) => _FeatureRow(
                            feature: f,
                            isSelected: widget.isSelected,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CTA Button
                        _CTAButton(
                          isSelected: widget.isSelected,
                          onTap: widget.onTap,
                          planName: plan.name,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gradient background with shimmer ────────────────────────────────────────

class _GradientBackground extends StatefulWidget {
  final List<Color> colors;
  const _GradientBackground({required this.colors});

  @override
  State<_GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<_GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(_ctrl.value * 2 - 1, -1),
          end: Alignment(1 - _ctrl.value * 2, 1),
          colors: widget.colors,
        ),
      ),
    ),
  );
}

// ─── Feature row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final _PlanFeature feature;
  final bool isSelected;
  const _FeatureRow({required this.feature, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final icon = _icon();
    final iconColor = _iconColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isSelected
                  ? iconColor.withOpacity(0.20)
                  : Theme.of(context).brightness == Brightness.dark
                  ? iconColor.withOpacity(0.20)
                  : AppColor.primary_50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 12,
              color: isSelected
                  ? iconColor
                  : Theme.of(context).brightness == Brightness.dark
                  ? iconColor
                  : AppColor.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature.text,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.90)
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.90)
                    : AppTheme.iconColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (feature.type) {
      case _FeatureType.check:
        return HugeIconsStroke.tick01;
      case _FeatureType.info:
        return HugeIconsStroke.alert01;
      case _FeatureType.warning:
        return HugeIconsStroke.alert02;
      case _FeatureType.success:
        return HugeIconsSolid.checkmarkCircle02;
    }
  }

  Color _iconColor() {
    switch (feature.type) {
      case _FeatureType.check:
        return Colors.white;
      case _FeatureType.info:
        return Colors.white;
      case _FeatureType.warning:
        return Colors.white;
      case _FeatureType.success:
        return Colors.white;
    }
  }
}

// ─── CTA Button ──────────────────────────────────────────────────────────────

class _CTAButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String planName;
  const _CTAButton({
    required this.isSelected,
    required this.onTap,
    required this.planName,
  });

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
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
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.white
              : Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.20)
              : AppColor.primary_50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(widget.isSelected ? 0 : 0.35),
            width: Theme.of(context).brightness == Brightness.dark ? 1 : 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            if (widget.isSelected)
              Icon(HugeIconsStroke.tick01, size: 16, color: AppColor.black),
            Text(
              widget.isSelected ? 'Subscribed' : 'Get ${widget.planName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: widget.isSelected
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
