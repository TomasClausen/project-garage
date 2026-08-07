import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.emphasis,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppRadius.medium),
      ),
    );
    if (AppMotion.reduceMotion(context)) {
      _controller.stop();
      return block;
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.42, end: 0.9).animate(_controller),
      child: block,
    );
  }
}

class AppScreenSkeleton extends StatelessWidget {
  const AppScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: const [
        AppSkeleton(width: 190, height: 28),
        SizedBox(height: AppSpacing.xxl),
        AppSkeleton(height: 190),
        SizedBox(height: AppSpacing.lg),
        AppSkeleton(height: 92),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(height: 92),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(height: 92),
      ],
    );
  }
}

class AppLoadingGate extends StatefulWidget {
  final Future<dynamic> future;
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppLoadingGate({
    super.key,
    required this.future,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<AppLoadingGate> createState() => _AppLoadingGateState();
}

class _AppLoadingGateState extends State<AppLoadingGate> {
  late final Future<dynamic> _initialLoad = widget.future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialLoad,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: snapshot.connectionState != ConnectionState.done
              ? const AppScreenSkeleton(key: ValueKey('skeleton'))
              : RefreshIndicator(
                  key: const ValueKey('content'),
                  color: AppColors.primary,
                  onRefresh: widget.onRefresh,
                  child: widget.child,
                ),
        );
      },
    );
  }
}
