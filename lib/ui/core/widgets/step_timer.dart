import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/use_cases/step_clock.dart';
import '../l10n/l10n.dart';

/// O cronômetro de um exercício ou passo (T60): o tempo decorrido desde que o passo abriu,
/// contando para cima, no canto inferior de fim (à direita; à esquerda em
/// árabe). Sem limite e sem barra.
class StepTimer extends StatelessWidget {
  const StepTimer({required this.elapsed, super.key});

  /// O tempo decorrido, atualizado pela tela a cada instante.
  final ValueListenable<Duration> elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<Duration>(
      valueListenable: elapsed,
      builder: (context, value, _) {
        final label = StepClock.format(value);
        return Semantics(
          label: context.l10n.lessonStepTimer(label),
          liveRegion: false,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
