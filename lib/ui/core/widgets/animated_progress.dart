import 'package:flutter/material.dart';

/// Uma barra de progresso que enche aos poucos quando o valor muda (ao
/// voltar de uma vitória, por exemplo). Na primeira vez, já aparece no
/// valor; com "remover animações", sempre.
class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    required this.value,
    this.minHeight,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final double value;
  final double? minHeight;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => LinearProgressIndicator(
        value: value,
        minHeight: minHeight,
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
