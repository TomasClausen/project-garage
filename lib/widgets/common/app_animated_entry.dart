import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

class AppAnimatedEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AppAnimatedEntry({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AppAnimatedEntry> createState() => _AppAnimatedEntryState();
}

class _AppAnimatedEntryState extends State<AppAnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.emphasis,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.entrance,
    );
    _opacity = curve;
    _offset = Tween(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _offset, child: widget.child),
  );
}
