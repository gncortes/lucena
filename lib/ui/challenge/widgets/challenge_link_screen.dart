import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/core/theme/goal_tone_ui.dart';
import 'package:lucena/ui/core/widgets/character_portrait.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/models/game_setup.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../view_models/challenge_link_cubit.dart';

/// O desafio fechado, aberto por link (canvas `PropV1LinkDesafio`): a posição,
/// o objetivo e a vez, o adversário e o relógio e o modo travados. Quem abre só
/// joga.
class ChallengeLinkScreen extends StatelessWidget {
  const ChallengeLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ChallengeLinkCubit>().state;
    final link = state.link;
    final goal = GoalStyle.of(context, link.goal.tone);
    return Scaffold(
      key: ChallengeKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.journeyChallengeTitle)),
      bottomNavigationBar: ActionsFooter(
        children: [
          FilledButton.icon(
            key: ChallengeKeys.play,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.journeyPlay),
            // A partida substitui esta tela: voltar dela cai de onde veio.
            onPressed: state.ready
                ? () => context.pushReplacement(state.gameRoute)
                : null,
          ),
        ],
      ),
      body: !state.ready
          ? const SkeletonList()
          : ChallengePreview(
              boardKey: ChallengeKeys.board,
              fen: link.fen,
              orientation: link.userSide,
              chips: [
                ChallengeChip(
                  icon: goal.icon,
                  label: goalLabel(l10n, link.goal),
                ),
                ChallengeChip(
                  label: link.userSide.name == 'white'
                      ? l10n.freeBoardWhiteToMove
                      : l10n.freeBoardBlackToMove,
                ),
              ],
              opponent: OpponentCard(
                key: ChallengeKeys.opponentCard,
                label: l10n.challengeOpponent,
                image: portraitImageOrNull(state.opponent),
                name: link.opponent == OpponentKind.stockfish
                    ? l10n.setupOpponentStockfish
                    : [
                        state.opponent?.name ?? l10n.setupOpponentMaia,
                        '${state.level}',
                      ].join(' · '),
                tagline:
                    state.opponent?.taglineIn(
                      Localizations.localeOf(context).languageCode,
                    ) ??
                    '',
              ),
              rows: [
                ChallengeLockedRow(
                  rowKey: ChallengeKeys.clockRow,
                  icon: Icons.av_timer_outlined,
                  label: l10n.freeBoardClock,
                  value: link.clock == null
                      ? l10n.challengeNoClock
                      : paceShort(l10n, link.clock!),
                ),
                ChallengeLockedRow(
                  rowKey: ChallengeKeys.modeRow,
                  icon: Icons.grid_on,
                  label: l10n.setupMode,
                  value: l10n.setupModeNormal,
                ),
              ],
              lockedNote: l10n.challengeLockedNote,
              noteKey: ChallengeKeys.lockedNote,
            ),
    );
  }
}
