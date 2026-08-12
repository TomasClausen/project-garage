import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_radius.dart';

class AppSwipeAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const AppSwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}

class AppSwipeActions extends StatefulWidget {
  final Widget child;
  final List<AppSwipeAction> actions;
  final BorderRadius borderRadius;

  const AppSwipeActions({
    super.key,
    required this.child,
    required this.actions,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppRadius.large),
    ),
  });

  @override
  State<AppSwipeActions> createState() => _AppSwipeActionsState();
}

class _AppSwipeActionsState extends State<AppSwipeActions> {
  double _offset = 0;

  double get _maxOffset => widget.actions.length * 64.0;

  void _dragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset - details.delta.dx).clamp(0, _maxOffset);
    });
  }

  void _dragEnd(DragEndDetails details) {
    final open = _offset > _maxOffset * 0.28;
    setState(() => _offset = open ? _maxOffset : 0);
    if (open) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.actions
                    .map(
                      (action) => SizedBox(
                        width: 64,
                        height: double.infinity,
                        child: Material(
                          color: action.color.withValues(alpha: 0.18),
                          child: InkWell(
                            onTap: () {
                              setState(() => _offset = 0);
                              HapticFeedback.mediumImpact();
                              action.onPressed();
                            },
                            child: Semantics(
                              button: true,
                              label: action.label,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(action.icon, color: action.color),
                                  const SizedBox(height: 4),
                                  Text(
                                    action.label,
                                    style: TextStyle(
                                      color: action.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(-_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: _dragEnd,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
