import 'package:flutter/material.dart';

import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../view_models/rating_cubit.dart';

/// Os números do progresso em blocos pequenos.
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
        Icons.local_fire_department_outlined,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        // Quatro números em 2 × 2; cinco, em 3 + 2.
        final columns = stats.length == 4 ? 2 : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          key: RatingKeys.stats,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (index, (icon, value, label)) in stats.indexed)
              SizedBox(
                width: width,
                child: _Stat(
                  key: RatingKeys.stat(index),
                  icon: icon,
                  value: value,
                  label: label,
                ),
              ),
          ],
        );
      },
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
