import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/review_destinations.dart';
import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/container_navigation.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/home_cubit.dart';

/// O rating no alto da tela inicial, ao lado do nome do app (T83): o número
/// com a variação da última partida e a seta. Antes de ter rating, a pílula
/// "Começando". Tocar abre os detalhes do rating (o gráfico e o histórico).
class PlayerCard extends StatelessWidget {
  const PlayerCard({required this.state, super.key});

  /// O chevron ao lado do número (canvas `PropV2UxHome`).
  static const chevron = 22.0;

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = state.rating;
    final shown = rating != null && state.showsRating;
    return ContainerNavigation(
      color: shown ? colors.surface : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      routeName: Routes.rating,
      openBuilder: ratingDestination,
      onFallback: () async {
        await context.push<void>(Routes.rating);
      },
      closedBuilder: (context, open) => InkWell(
        key: HomeKeys.playerCard,
        onTap: open,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shown)
                Semantics(
                  container: true,
                  label: ratingSemantics(
                    context,
                    rating,
                    state.ratingChange ?? 0,
                  ),
                  excludeSemantics: true,
                  child: KeyedSubtree(
                    key: HomeKeys.rating,
                    // Ao voltar de uma partida, o número conta até o rating
                    // novo.
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: rating.toDouble()),
                      duration: AppMotion.of(context).celebrate,
                      curve: AppMotion.enter,
                      builder: (context, value, _) => RatingValue(
                        rating: value.round(),
                        change: state.ratingChange,
                        valueKey: HomeKeys.ratingValue,
                      ),
                    ),
                  ),
                )
              else
                // Quem começa só vê o número depois de algumas partidas.
                Text(
                  context.l10n.homeRatingStarting,
                  key: HomeKeys.ratingPending,
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: AppWeight.strong,
                  ),
                ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                size: chevron,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
