import 'package:flutter/material.dart';

import '../../../domain/use_cases/clock_format.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/rating_sparkline.dart';
import '../../core/widgets/rating_value.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/home_cubit.dart';

/// O jogador no alto da tela inicial: o apelido e a faixa, o rating em
/// destaque com a variação da última partida e a curva.
class PlayerCard extends StatelessWidget {
  const PlayerCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final nickname = state.nickname.isEmpty
        ? l10n.profileNicknameDefault
        : state.nickname;
    final rating = state.rating;
    return Card(
      key: HomeKeys.playerCard,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeHello(nickname),
                        key: HomeKeys.hello,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (state.level case final level?)
                        Text(
                          level.name(l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (rating != null)
                  Semantics(
                    container: true,
                    label: ratingSemantics(
                      context,
                      rating,
                      state.ratingChange ?? 0,
                    ),
                    excludeSemantics: true,
                    child: Column(
                      key: HomeKeys.rating,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.reportRatingLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        RatingValue(
                          rating: rating,
                          change: state.ratingChange,
                          valueKey: HomeKeys.ratingValue,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (state.ratingCurve.length > 1) ...[
              const SizedBox(height: 8),
              RatingSparkline(ratings: state.ratingCurve, height: 44),
            ],
          ],
        ),
      ),
    );
  }
}

/// Os números do progresso em blocos pequenos.
class StatsRow extends StatelessWidget {
  const StatsRow({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final best = state.bestSpeedrun;
    final stats = [
      (
        Icons.sports_esports_outlined,
        '${state.stats.games}',
        l10n.homeStatGames,
      ),
      (Icons.emoji_events_outlined, '${state.stats.wins}', l10n.homeStatWins),
      (
        Icons.local_fire_department_outlined,
        '${state.stats.streakDays}',
        l10n.homeStatStreak,
      ),
      (
        Icons.military_tech_outlined,
        l10n.homeStatAchievements(
          state.achievementsUnlocked,
          state.achievementsTotal,
        ),
        l10n.homeAchievements,
      ),
      if (best != null)
        (
          Icons.timer_outlined,
          RunTimeFormat.format(best),
          l10n.homeStatBestRun,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        // Quatro números em 2 × 2; cinco, em 3 + 2.
        final columns = stats.length == 4 ? 2 : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          key: HomeKeys.stats,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (index, (icon, value, label)) in stats.indexed)
              SizedBox(
                width: width,
                child: _Stat(
                  key: HomeKeys.stat(index),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
