import 'package:flutter/material.dart';

import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../view_models/rating_cubit.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/one_line.dart';

/// Os números do progresso numa grade de duas colunas, sem buracos e com os
/// cartões da mesma altura (T51, A5).
class StatsRow extends StatelessWidget {
  const StatsRow({required this.numbers, super.key});

  final PlayerNumbers numbers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final best = numbers.bestSpeedrun;
    final stats = [
      (
        Icons.sports_esports_outlined,
        '${numbers.stats.games}',
        l10n.homeStatGames,
      ),
      (Icons.emoji_events_outlined, '${numbers.stats.wins}', l10n.homeStatWins),
      (
        Icons.event_repeat_outlined,
        '${numbers.stats.streakDays}',
        l10n.homeStatStreak,
      ),
      (
        Icons.military_tech_outlined,
        l10n.homeStatAchievements(
          numbers.achievementsUnlocked,
          numbers.achievementsTotal,
        ),
        l10n.homeAchievements,
      ),
      if (best != null)
        (Icons.timer_outlined, runTime(context, best), l10n.homeStatBestRun),
    ];
    // Grade de duas colunas, sem buracos: com número ímpar de itens, o
    // último ocupa a linha inteira. Cada linha estica os cartões à altura do
    // mais alto, e os rótulos nunca quebram (a letra diminui), então todos
    // ficam da mesma altura.
    final rows = [
      for (var start = 0; start < stats.length; start += 2)
        [
          for (
            var index = start;
            index < start + 2 && index < stats.length;
            index++
          )
            index,
        ],
    ];
    return Column(
      key: RatingKeys.stats,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (rowIndex, row) in rows.indexed) ...[
          if (rowIndex > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (position, index) in row.indexed) ...[
                  if (position > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Stat(
                      key: RatingKeys.stat(index),
                      icon: stats[index].$1,
                      value: stats[index].$2,
                      label: stats[index].$3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Um número: o ícone num círculo, o número grande e o rótulo, cada um numa
/// linha só.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OneLine(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                OneLine(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
