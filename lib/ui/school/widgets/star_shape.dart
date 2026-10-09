import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Uma estrela no tabuleiro, que cresce ao aparecer. Com [blinking], pisca
/// (está para sumir).
class StarShape extends StatelessWidget {
  const StarShape({
    this.color = const Color(0xfff2b705),
    this.blinking = false,
    super.key,
  });

  final Color color;
  final bool blinking;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.of(context).disabled;
    final star = FittedBox(child: Icon(Icons.star_rounded, color: color));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: AppMotion.of(context).celebrate,
      curve: AppMotion.bounce,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: blinking && !reduced ? _Blink(child: star) : star,
    );
  }
}

class _Blink extends StatefulWidget {
  const _Blink({required this.child});

  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.state,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 1.0, end: 0.15).animate(_controller),
    child: widget.child,
  );
}
