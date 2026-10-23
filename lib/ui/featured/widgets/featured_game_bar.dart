import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/crowd/crowd_repository.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/share/share_button.dart';
import '../view_models/featured_crowd_cubit.dart';
import '../view_models/featured_endgame_cubit.dart';
import 'featured_crowd_card.dart';
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

/// O rodapé da partida terminada: "Jogar de novo" e "Continuar" (que abre os
/// próximos passos).
class FeaturedEndBar extends StatelessWidget {
  const FeaturedEndBar({required this.onAgain, super.key});

  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocProvider(
          create: (context) => FeaturedCrowdCubit(
            id: context.read<FeaturedEndgameCubit>().id,
            crowd: context.read<CrowdRepository>(),
          )..load(),
          child: const FeaturedCrowdCard(),
        ),
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
              onPressed: () {
                final state = context.read<FeaturedEndgameCubit>().state;
                final endgame = state.endgame;
                if (endgame == null) return;
                showFeaturedNext(
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
