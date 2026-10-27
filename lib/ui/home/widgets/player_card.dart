import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../routing/review_destinations.dart';
import '../../../domain/use_cases/beginner_home.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/container_navigation.dart';
import '../../core/theme/app_shape.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/home_cubit.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// O jogador no alto da tela inicial: o apelido e a faixa, e o rating em
/// destaque com a variação da última partida. Tocar abre os detalhes do
/// rating (o gráfico e o histórico).
class PlayerCard extends StatelessWidget {
  const PlayerCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final rating = state.rating;
    final showsRating = state.showsRating;
    return ContainerNavigation(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      routeName: Routes.rating,
      openBuilder: ratingDestination,
      onFallback: () async {
        await context.push<void>(Routes.rating);
      },
      closedBuilder: (context, open) => Card(
        key: HomeKeys.playerCard,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeYourRating,
                        key: HomeKeys.ratingLabel,
                        style: context.cardTitle,
                      ),
                      // Quem começa só vê o número depois de algumas partidas.
                      if (!showsRating) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.homeRatingAfterGames(
                            BeginnerHome.gamesForRating,
                          ),
                          key: HomeKeys.ratingPending,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (rating != null && showsRating)
                  Semantics(
                    container: true,
                    label: ratingSemantics(
                      context,
                      rating,
                      state.ratingChange ?? 0,
                    ),
                    excludeSemantics: true,
                    // Só o número e a seta: o card inteiro já abre o rating.
                    child: Row(
                      key: HomeKeys.rating,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ao voltar de uma partida, o número conta até o
                        // rating novo.
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: rating.toDouble()),
                          duration: AppMotion.of(context).celebrate,
                          curve: AppMotion.enter,
                          builder: (context, value, _) => RatingValue(
                            rating: value.round(),
                            change: state.ratingChange,
                            valueKey: HomeKeys.ratingValue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
