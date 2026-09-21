import 'package:flutter/material.dart';

import 'toukh_motion.dart';

/// Fade + slide up on mount (iOS-style entrance).
class ToukhFadeSlide extends StatefulWidget {
  const ToukhFadeSlide({
    required this.child,
    this.delay = Duration.zero,
    this.offset = ToukhMotion.fadeUpOffset,
    this.duration = ToukhMotion.entrance,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<ToukhFadeSlide> createState() => _ToukhFadeSlideState();
}

class _ToukhFadeSlideState extends State<ToukhFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: ToukhMotion.standard);
    _slide = Tween<double>(begin: widget.offset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: ToukhMotion.standard),
    );
    _play();
  }

  Future<void> _play() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    if (ToukhMotion.reducesMotion(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    await _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ToukhMotion.reducesMotion(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
