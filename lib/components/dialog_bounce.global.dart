import 'package:flutter/material.dart';

class BounceDialog extends StatefulWidget {
  final Widget child;
  const BounceDialog({required this.child});

  static Future<T?> showBounceDialog<T>({
    required BuildContext context,
    required Widget child,
    Color barrierColor = Colors.black26,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      builder: (_) => BounceDialog(child: child),
    );
  }

  @override
  State<BounceDialog> createState() => _BounceDialogState();
}

class _BounceDialogState extends State<BounceDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.05,
        end: 0.97,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.97,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
  ]).animate(_ctrl);

  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
