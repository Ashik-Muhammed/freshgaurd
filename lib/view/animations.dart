import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeIn({super.key, required this.child, required this.duration});

  @override
  _FadeInState createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class SlideIn extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration duration;

  const SlideIn({super.key, required this.child, required this.direction, required this.duration});

  @override
  _SlideInState createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: widget.direction == Axis.horizontal
          ? const Offset(-1, 0)
          : const Offset(0, -1),
      end: Offset.zero,
    ).animate(_controller);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

class ScaleTransition extends StatefulWidget {
  final Widget child;
  final double scale;

  ScaleTransition({required this.child, required this.scale});

  @override
  _ScaleTransitionState createState() => _ScaleTransitionState();
}

class _ScaleTransitionState extends State<ScaleTransition> {
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: widget.scale,
      child: widget.child,
    );
  }
}


class LottieAnimation extends StatefulWidget {
  const LottieAnimation({super.key});

  @override
  _LottieAnimationState createState() => _LottieAnimationState();
}

class _LottieAnimationState extends State<LottieAnimation> {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset('lib/assets/loading_anim.json');
  }
}