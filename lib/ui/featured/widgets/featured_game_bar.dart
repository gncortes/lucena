import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../alerts/view_models/alerts_cubit.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/share/share_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_card.dart';
import '../../region/widgets/region_sheet.dart';
import '../view_models/featured_alert_cubit.dart';
import '../view_models/featured_endgame_cubit.dart';
import 'featured_book_sheet.dart';
import 'featured_labels.dart';
import 'featured_next_sheet.dart';

/// Os botões da barra de cima da partida de um final em destaque: o livrinho
/// e, com a partida terminada, compartilhar. [boundary] é o que a imagem
/// compartilhada captura.
class FeaturedGameActions extends StatelessWidget {
  const FeaturedGameActions({
    required this.boundary,
    required this.ended,
    super.key,
  });

  final GlobalKey boundary;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<FeaturedEndgameCubit, FeaturedEndgameState>(
      builder: (context, state) {
        final endgame = state.endgame;
        if (endgame == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: FeaturedKeys.bookButton,
              tooltip: l10n.featuredBookTitle,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => showFeaturedBook(
                context,
                endgame: endgame,
                tournament: state.tournament,
              ),
            ),
            if (ended)
              ShareIconButton(
                key: FeaturedKeys.shareButton,
                boundary: boundary,
                tooltip: l10n.featuredShare,
                fileName: 'lucena-${endgame.id}.png',
                text: l10n.featuredShareText(
                  FeaturedLabels.players(l10n, endgame),
                  endgame.challenge(state.choice).uri.toString(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// O cartão do aviso aparece agora? (para a partida reservar a altura dele)
bool featuredAlertShown(BuildContext context) =>
    context.watch<FeaturedEndgameCubit>().state.tournament != null &&
    context.watch<FeaturedAlertCubit>().state.visible;

/// O rodapé da partida terminada: "Jogar de novo" e "Continuar" (que abre os
/// próximos passos).
class FeaturedEndBar extends StatelessWidget {
  const FeaturedEndBar({required this.onAgain, super.key});

  final VoidCallback onAgain;

  /// A altura que o cartão do aviso ocupa sobre os botões (com a margem de
  /// cima), para a partida reservar o espaço dele.
  static const alertHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AlertCard(),
        ActionsFooter(
          children: [
            OutlinedButton.icon(
              key: FeaturedKeys.playAgain,
              onPressed: onAgain,
              icon: const Icon(Icons.replay),
              label: Text(l10n.featuredPlayAgain),
            ),
            FilledButton.icon(
              key: FeaturedKeys.continueButton,
              onPressed: () async {
                final state = context.read<FeaturedEndgameCubit>().state;
                final endgame = state.endgame;
                if (endgame == null) return;
                await askRegionOnce(context);
                if (!context.mounted) return;
                await showFeaturedNext(
                  context,
                  endgame: endgame,
                  tournament: state.tournament,
                  tournamentFinals: state.siblings.length + 1,
                  onAgain: onAgain,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.featuredContinue),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Quer saber quando sair outro final assim?" (H-INI-07): só em final de
/// torneio e uma vez por final.
class _AlertCard extends StatelessWidget {
  const _AlertCard();

  @override
  Widget build(BuildContext context) {
    if (!featuredAlertShown(context)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final alert = context.read<FeaturedAlertCubit>();
    return Padding(
      key: FeaturedKeys.alertCard,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: LucenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  size: AppIconSize.button,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.featuredAlertTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.featuredAlertBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: FeaturedKeys.alertAccept,
              onPressed: () async {
                final alerts = context.read<AlertsCubit>();
                if (await alert.accept()) {
                  await alerts.change(
                    alerts.state.settings.copyWith(tournaments: true),
                  );
                }
              },
              icon: const Icon(Icons.notifications),
              label: Text(l10n.featuredAlertAccept),
            ),
            TextButton(
              key: FeaturedKeys.alertDecline,
              onPressed: alert.decline,
              child: Text(l10n.featuredAlertDecline),
            ),
          ],
        ),
      ),
    );
  }
}
