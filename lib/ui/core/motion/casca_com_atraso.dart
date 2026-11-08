import 'package:flutter/material.dart';

import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A casca (esqueleto) de uma tela cujo dado costuma chegar na hora: nos
/// primeiros [LucenaMotion.atrasoDaCasca] ela fica invisível e só então
/// aparece, em [LucenaMotion.fadeDaCasca]. Se o conteúdo chega antes, ela
/// nunca é vista. Com movimento reduzido, aparece depois do atraso, sem fade.
class CascaComAtraso extends StatelessWidget {
  const CascaComAtraso({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = LucenaMotion.atrasoDaCasca + LucenaMotion.fadeDaCasca;
    final de = LucenaMotion.atrasoDaCasca.inMicroseconds / total.inMicroseconds;
    final curva = MovimentoReduzido.of(context)
        ? Threshold(de)
        : Interval(de, 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: curva,
      builder: (context, t, filho) => Opacity(opacity: t, child: filho),
      child: child,
    );
  }
}
