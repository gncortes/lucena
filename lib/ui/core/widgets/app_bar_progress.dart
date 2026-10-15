import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A barra de progresso de 4 dp colada na base da barra do app (`bottom` do
/// `LucenaAppBar`): do teste de nível e do tour. [value] vai de 0 a 1 e
/// anda com a transição de componente.
class AppBarProgress extends StatelessWidget implements PreferredSizeWidget {
  const AppBarProgress({required this.value, super.key});

  final double value;

  static const height = 4.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: AppMotion.of(context).component,
    curve: AppMotion.enter,
    builder: (context, value, _) =>
        LinearProgressIndicator(value: value, minHeight: height),
  );
}
