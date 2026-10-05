import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/rating_value.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/home_cubit.dart';

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
    final nickname = state.nickname.isEmpty
        ? l10n.profileNicknameDefault
        : state.nickname;
    final rating = state.rating;
    return Card(
      key: HomeKeys.playerCard,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.rating),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Row(
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.reportRatingLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      // Ao voltar de uma partida, o número conta até o
                      // rating novo.
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: rating.toDouble()),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => RatingValue(
                          rating: value.round(),
                          change: state.ratingChange,
                          valueKey: HomeKeys.ratingValue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
