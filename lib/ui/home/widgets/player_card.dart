import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/frentes/d2_routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/valor_que_anima.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/container_navigation.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/home_cubit.dart';

/// O rating no alto da tela inicial, ao lado do nome do app (T83): o número
/// com a variação da última partida e a seta, solto, sem pílula. Antes de ter
/// rating, "Começando". Tocar abre "Seu progresso" (H-CON-03).
class PlayerCard extends StatelessWidget {
  const PlayerCard({required this.state, super.key});

  /// O chevron ao lado do número (canvas `PropV2UxHome`).
  static const chevron = 22.0;

  /// A altura mínima da pílula de "Começando" (canvas: 40).
  static const _pillHeight = 40.0;

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = state.rating;
    final shown = rating != null && state.showsRating;
    return ContainerNavigation(
      // O número fica solto, sem pílula (H-INI-01, PropV2UxHomeTopo B);
      // "Começando" é pílula com contorno (PropV2UxHome), na cor de cartão
      // (sem branco, T85-D0).
      color: shown ? Colors.transparent : AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.full),
        side: shown
            ? BorderSide.none
            : const BorderSide(color: AppColors.cardOutline),
      ),
      // H-CON-03: a pílula abre "Seu progresso" (o Histórico fica lá).
      routeName: D2Paths.progress,
      openBuilder: progressDestination,
      onFallback: () async {
        await context.push<void>(D2Paths.progress);
      },
      closedBuilder: (context, open) => InkWell(
        key: HomeKeys.playerCard,
        onTap: open,
        customBorder: const StadiumBorder(),
        child: Container(
          constraints: BoxConstraints(minHeight: shown ? 0 : _pillHeight),
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
                    child: ValorQueAnima(
                      valor: rating.toDouble(),
                      duracao: LucenaMotion.numeroConta,
                      builder: (context, value) => RatingValue(
                        rating: value.round(),
                        change: state.ratingChange,
                        valueKey: HomeKeys.ratingValue,
                      ),
                    ),
                  ),
                )
              else
                // Quem começa só vê o número depois de algumas partidas.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    context.l10n.homeRatingStarting,
                    key: HomeKeys.ratingPending,
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      height: 21 / 15,
                      fontWeight: AppWeight.strong,
                      color: colors.primary,
                    ),
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
