import 'package:flutter/material.dart';

import '../../../domain/use_cases/clock_format.dart';
import '../theme/app_shape.dart';

/// Um tempo de speedrun como nos cronômetros de speedrun: minutos e segundos
/// (`3:25`) e os décimos menores (`.0`), sempre com ponto, como nos relógios
/// de xadrez. [large] é o total: na caixa clara do relógio da partida. Sem
/// [large], só o ícone e os números, para caber ao lado de cada etapa.
class RunClock extends StatelessWidget {
  const RunClock(this.time, {this.large = false, this.textKey, super.key});

  final Duration time;
  final bool large;

  /// A chave do texto com o tempo, para os testes lerem.
  final Key? textKey;

  static const _light = Color(0xFFFFFFFF);
  static const _dark = Color(0xFF262421);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = RunTimeFormat.clock(time);
    final dot = text.lastIndexOf('.');
    final main = dot < 0 ? text : text.substring(0, dot);
    final fraction = dot < 0 ? '' : text.substring(dot);
    final color = large ? _dark : colors.onSurface;
    final style =
        (large ? theme.textTheme.headlineMedium : theme.textTheme.titleMedium)
            ?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final numbers = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: main),
          // Os décimos, menores e mais apagados: o olho lê minutos e
          // segundos primeiro.
          TextSpan(
            text: fraction,
            style: TextStyle(
              fontSize: (style?.fontSize ?? 16) * 0.7,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      key: textKey,
      maxLines: 1,
      style: style,
    );
    // Os números do relógio são sempre da esquerda para a direita.
    final row = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: large ? 26 : 18,
            color: large ? _dark : colors.primary,
          ),
          SizedBox(width: large ? 8 : 4),
          numbers,
        ],
      ),
    );
    if (!large) return row;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _light,
        borderRadius: BorderRadius.circular(AppShape.medium),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: row,
    );
  }
}
