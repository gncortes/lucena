import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';
import 'goal_style.dart';

/// Para que serve a barra: dá a cor do preenchimento (E1.08, D23).
enum ProgressRole {
  /// O avanço comum (cor principal).
  primary,

  /// O que está dando certo: o verde do app (catálogo, degrau concluído).
  success,

  /// Realce de conquista (dourado).
  gold,

  /// Pouco tempo (a contagem regressiva do desafio).
  error,
}

/// A barra de progresso do app (E1.08, D23; canvas `CompBarraProgresso`): 8 dp
/// de altura em pílula, sempre. Enche aos poucos quando o valor muda (ao
/// voltar de uma vitória, por exemplo); na primeira vez já aparece no valor, e
/// com "remover animações", sempre. [value] nulo é a barra que corre sem fim
/// (carregando). A barra de 4 dp colada na AppBar é o `AppBarProgress`.
class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    required this.value,
    this.role = ProgressRole.primary,
    this.backgroundColor,
    super.key,
  });

  /// A altura única da barra.
  static const height = 8.0;

  final double? value;
  final ProgressRole role;

  /// O trilho (padrão do tema); sobre um cartão colorido, a tela passa o seu.
  final Color? backgroundColor;

  Color? _color(BuildContext context) => switch (role) {
    ProgressRole.primary => null,
    ProgressRole.success => ChangeColors.of(context, up: true),
    ProgressRole.gold => AppColors.of(context).gold,
    ProgressRole.error => Theme.of(context).colorScheme.error,
  };

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final color = _color(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShape.full),
      child: value == null
          ? LinearProgressIndicator(
              minHeight: height,
              color: color,
              backgroundColor: backgroundColor,
            )
          : TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: AppMotion.of(context).screen,
              curve: AppMotion.enter,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: height,
                color: color,
                backgroundColor: backgroundColor,
              ),
            ),
    );
  }
}
