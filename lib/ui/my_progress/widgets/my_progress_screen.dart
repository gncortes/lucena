import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/achievement.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../account/widgets/account_invite_card.dart';
import '../../achievements/widgets/achievement_ui.dart';
import '../../core/keys/my_progress_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/skeleton.dart';
import '../view_models/my_progress_cubit.dart';

/// O `momento` do `conta_convite` aberto por "Seu progresso".
const accountInviteFromProgress = 'progresso';

/// "Seu progresso" (PropV2UxProgresso, H-CON-03): a pílula do Início abre
/// aqui. Rating grande com o histórico, o convite da conta para quem não tem
/// (X suspende por 7 dias) e as conquistas. Tudo local: funciona sem rede.
class MyProgressScreen extends StatelessWidget {
  const MyProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<MyProgressCubit>().state;
    return Scaffold(
      key: MyProgressKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.conProgressTitle)),
      // H-ANI-07: a primeira leitura brilha e o conteúdo surge no lugar.
      body: ShimmerConteudo(
        carregando: !state.loaded,
        esqueleto: const SkeletonList(key: MyProgressKeys.loading),
        child: !state.loaded
            ? const SizedBox.shrink()
            : ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.screen,
                  right: AppSpacing.screen,
                ),
                children: [
                  // H-ANI-17: os blocos entram em ordem.
                  ListaEmOrdem(
                    itens: [
                      _Rating(state: state),
                      if (state.invite)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.betweenCards,
                          ),
                          child: AccountInviteCard(
                            title: l10n.conCartaoTitleProgress,
                            from: D2Paths.progress,
                            moment: accountInviteFromProgress,
                            cardKey: MyProgressKeys.accountCard,
                            closeKey: MyProgressKeys.accountClose,
                            onClose: () => unawaited(
                              context.read<MyProgressCubit>().closeInvite(),
                            ),
                          ),
                        ),
                      SectionTitle(
                        l10n.conProgressAchievements,
                        inset: 0,
                        action: SectionAction(
                          key: MyProgressKeys.achievementsAll,
                          label: l10n.conProgressSeeAll,
                          onPressed: () =>
                              unawaited(context.push(Routes.achievements)),
                        ),
                      ),
                      _Medals(state: state),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.state});

  final MyProgressState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return KeyedSubtree(
      key: MyProgressKeys.rating,
      child: LucenaCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.conProgressRating, style: muted),
                  Semantics(
                    label: ratingSemantics(
                      context,
                      state.rating,
                      state.change ?? 0,
                    ),
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: RatingValue(
                        rating: state.rating,
                        change: state.change,
                        large: true,
                        animateOnce: true,
                        valueKey: MyProgressKeys.ratingValue,
                      ),
                    ),
                  ),
                  Text(
                    l10n.conProgressGames(state.games),
                    key: MyProgressKeys.games,
                    style: muted,
                  ),
                ],
              ),
            ),
            TextButton(
              key: MyProgressKeys.history,
              onPressed: () => unawaited(context.push(Routes.rating)),
              child: Text(l10n.conProgressHistory),
            ),
          ],
        ),
      ),
    );
  }
}

/// A grade de quatro colunas: obtidas em dourado, as que faltam com o
/// cadeado.
class _Medals extends StatelessWidget {
  const _Medals({required this.state});

  final MyProgressState state;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4,
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (final medal in state.medals)
        _Medal(
          achievement: medal,
          unlocked: state.unlocked.contains(medal.id),
          state: state,
        ),
    ],
  );
}

class _Medal extends StatelessWidget {
  const _Medal({
    required this.achievement,
    required this.unlocked,
    required this.state,
  });

  final Achievement achievement;
  final bool unlocked;
  final MyProgressState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = unlocked ? colors.onTertiaryContainer : colors.outline;
    final title = achievement.title(context.l10n, state.characters);
    return Semantics(
      label: title,
      excludeSemantics: true,
      child: DecoratedBox(
        key: MyProgressKeys.medal(achievement.id),
        decoration: BoxDecoration(
          color: unlocked
              ? colors.tertiaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                unlocked ? achievement.iconData : Icons.lock,
                size: AppIconSize.large,
                color: ink,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: ink, fontWeight: AppWeight.strong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
