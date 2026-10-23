import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

/// Os três pontinhos de "digitando" (T70): a máquina está respondendo. Ciclo
/// de 1200 ms, defasagem de 150 ms entre os pontos; com "remover animações"
/// ficam parados em 0,6 de opacidade. Fora da semântica (o texto que vem
/// depois entra como `liveRegion`).
class TypingDots extends StatefulWidget {
  const TypingDots({this.color, super.key});

  static const cycle = AppMotion.typingCycle;
  static const stagger = AppMotion.typingStagger;
  static const staticOpacity = 0.6;
  static const dotSize = 6.0;
  static const gap = 4.0;

  final Color? color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: TypingDots.cycle,
  );
  bool _animating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !AppMotion.reduced(context);
    if (animate && !_animating) {
      _controller.repeat();
    } else if (!animate && _animating) {
      _controller.stop();
    }
    _animating = animate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacity(double t, int index) {
    final shifted =
        (t -
            index *
                TypingDots.stagger.inMilliseconds /
                TypingDots.cycle.inMilliseconds) %
        1.0;
    // Sobe e desce uma vez por ciclo: 0,3 a 1.
    return 0.3 + 0.7 * (0.5 - 0.5 * math.cos(shifted * 2 * math.pi));
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: TypingDots.gap),
              Opacity(
                opacity: _animating
                    ? _opacity(_controller.value, i)
                    : TypingDots.staticOpacity,
                child: Container(
                  width: TypingDots.dotSize,
                  height: TypingDots.dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
