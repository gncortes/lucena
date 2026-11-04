import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import '../widgets/animated_progress.dart' show ProgressRole;
import '../widgets/goal_style.dart';
import 'lucena_motion.dart';
import 'valor_que_anima.dart';

/// A barra de progresso que enche (H-ANI-13): 8 dp em pílula, como a do
/// canvas (`CompBarraProgresso`). Na primeira entrada da tela ([EntradaDaTela])
/// enche de 0 em 700 ms; numa mudança real (exercício seguinte), sai do valor
/// anterior; tela já vista ou movimento reduzido, aparece no valor.
///
/// Substitui o `AnimatedProgress` quando cada frente aplica a H-ANI-13. A barra
/// de 4 dp colada na app bar usa [altura].
class BarraQueEnche extends StatelessWidget {
  const BarraQueEnche({
    required this.valor,
    this.papel = ProgressRole.primary,
    this.cor,
    this.corDoTrilho,
    this.altura = 8,
    this.eixo = Axis.horizontal,
    super.key,
  });

  /// De 0 a 1.
  final double valor;
  final ProgressRole papel;
  final Color? cor;

  /// O trilho (padrão do tema); sobre um cartão colorido, a tela passa o seu.
  final Color? corDoTrilho;

  /// A espessura da barra (a altura na horizontal, a largura na vertical).
  final double altura;

  /// Na vertical (barras de gráfico), enche de baixo para cima e ocupa a
  /// altura que o pai der.
  final Axis eixo;

  Color? _cor(BuildContext context) => switch (papel) {
    ProgressRole.primary => null,
    ProgressRole.success => ChangeColors.of(context, up: true),
    ProgressRole.gold => AppColors.of(context).gold,
    ProgressRole.error => Theme.of(context).colorScheme.error,
  };

  @override
  Widget build(BuildContext context) {
    final cor = this.cor ?? _cor(context);
    return ClipRRect(
      key: MotionKeys.barraQueEnche,
      borderRadius: BorderRadius.circular(AppShape.full),
      child: ValorQueAnima(
        valor: valor.clamp(0, 1),
        duracao: LucenaMotion.barraEnche,
        builder: (context, valor) {
          final barra = LinearProgressIndicator(
            value: valor,
            minHeight: altura,
            color: cor,
            backgroundColor: corDoTrilho,
          );
          return eixo == Axis.horizontal
              ? barra
              : SizedBox(
                  width: altura,
                  child: RotatedBox(quarterTurns: 3, child: barra),
                );
        },
      ),
    );
  }
}
