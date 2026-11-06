import 'package:flutter/material.dart';

import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../streak/view_models/streak_cubit.dart' show StreakState;
import '../../streak/widgets/streak_screen.dart' show StreakWeek;

/// A sequência de dias no cartão de Hoje das Metas (canvas `SugAchadoP8`,
/// coluna A): dias seguidos, o que aconteceu ontem, o recorde e a faixa da
/// semana, a mesma da tela Sequência ([StreakWeek]).
///
/// O dia conta como na tela Sequência: partida, lição ou final no dia.
class TrainingStreakSummary extends StatelessWidget {
  const TrainingStreakSummary({required this.state, super.key});

  final StreakState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final streak = state.streak;
    final never = streak.record == 0 && !streak.activeToday;
    final title = never
        ? t.trainingStreakFirst
        : t.trainingStreakDays(streak.current);
    final note = never
        ? t.trainingStreakFirstHint
        : streak.activeToday
        ? t.trainingStreakToday
        : streak.current > 0
        ? t.trainingStreakYesterday(streak.current + 1)
        : t.trainingStreakLost;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Column(
      key: TrainingKeys.streakCard,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(
              Icons.event_repeat,
              size: AppIconSize.standard,
              color: colors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: TrainingKeys.streakTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    note,
                    key: TrainingKeys.streakNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (streak.record > 0)
              Text(
                t.trainingStreakRecord(streak.record),
                key: TrainingKeys.streakRecord,
                style: muted,
              ),
          ],
        ),
        StreakWeek(state: state),
      ],
    );
  }
}
