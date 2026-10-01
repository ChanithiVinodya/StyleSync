import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// SmoothMouseScroll provides effortless, accelerated, and silky-smooth mouse wheel
/// and trackpad scrolling so users never need to click or drag the scrollbar.
class SmoothMouseScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double scrollSpeedMultiplier;

  const SmoothMouseScroll({
    super.key,
    required this.child,
    required this.controller,
    this.scrollSpeedMultiplier = 2.8,
  });

  @override
  State<SmoothMouseScroll> createState() => _SmoothMouseScrollState();
}

class _SmoothMouseScrollState extends State<SmoothMouseScroll> {
  double? _targetOffset;

  void _onPointerSignal(PointerSignalEvent pointerSignal) {
    if (pointerSignal is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (event) {
        final scrollEvent = event as PointerScrollEvent;
        if (!widget.controller.hasClients) return;

        final position = widget.controller.position;
        final dy = scrollEvent.scrollDelta.dy;
        if (dy.abs() < 0.1) return;

        // Multiply scroll delta for effortless, responsive gliding
        final delta = dy * widget.scrollSpeedMultiplier;

        final double currentBase = _targetOffset ?? widget.controller.offset;
        final double newTarget = (currentBase + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );

        _targetOffset = newTarget;

        widget.controller
            .animateTo(
              newTarget,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (mounted && _targetOffset == newTarget) {
                _targetOffset = null;
              }
            });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _onPointerSignal,
      child: widget.child,
    );
  }
}
