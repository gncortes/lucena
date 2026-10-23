import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/models/game_setup.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/opponent_card.dart';
import '../view_models/challenge_link_cubit.dart';

/// O desafio fechado, aberto por link (canvas `PropV1LinkDesafio`): a posição,
/// o objetivo e a vez, o adversário e o relógio e o modo travados. Quem abre só
/// joga.
class ChallengeLinkScreen extends StatelessWidget {
  const ChallengeLinkScreen({super.key});

  /// A fração da altura que o tabuleiro ocupa, no máximo.
  static const _maxBoardShare = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ChallengeLinkCubit>().state;
    final link = state.link;
    final theme = Theme.of(context);
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
          : LayoutBuilder(
              builder: (context, box) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Column(
                      spacing: AppSpacing.md,
                      children: [
                        // Colado no topo, como no quadro; encolhe se a tela
                        // for baixa, para sobrar espaço aos cartões.
                        SizedBox.square(
                          dimension: math.min(
                            box.maxWidth - 2 * AppSpacing.lg,
                            box.maxHeight * _maxBoardShare,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) => PositionBoard(
                              boardKey: ChallengeKeys.board,
                              fen: link.fen,
                              size: constraints.maxWidth,
                              orientation: link.userSide,
                              coordinates: true,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            InfoChip(
                              icon: goal.icon,
                              label: goalLabel(l10n, link.goal),
                            ),
                            InfoChip(
                              label: link.userSide.name == 'white'
                                  ? l10n.freeBoardWhiteToMove
                                  : l10n.freeBoardBlackToMove,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      children: [
                        OpponentCard(
                          key: ChallengeKeys.opponentCard,
                          label: l10n.challengeOpponent,
                          image: portraitImageOrNull(state.opponent),
                          name: link.opponent == OpponentKind.stockfish
                              ? l10n.setupOpponentStockfish
                              : [
                                  state.opponent?.name ??
                                      l10n.setupOpponentMaia,
                                  '${state.level}',
                                ].join(' · '),
                          tagline:
                              state.opponent?.taglineIn(
                                Localizations.localeOf(context).languageCode,
                              ) ??
                              '',
                        ),
                        Card(
                          margin: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Column(
                            children: [
                              _LockedRow(
                                key: ChallengeKeys.clockRow,
                                icon: Icons.av_timer_outlined,
                                label: l10n.freeBoardClock,
                                value: link.clock == null
                                    ? l10n.challengeNoClock
                                    : paceShort(l10n, link.clock!),
                              ),
                              _LockedRow(
                                key: ChallengeKeys.modeRow,
                                icon: Icons.grid_on,
                                label: l10n.setupMode,
                                value: l10n.setupModeNormal,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          key: ChallengeKeys.lockedNote,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.md,
                            children: [
                              Icon(
                                Icons.lock,
                                size: AppIconSize.button,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              Expanded(
                                child: Text(
                                  l10n.challengeLockedNote,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Uma linha do cartão: o que é, o valor e o cadeado.
class _LockedRow extends StatelessWidget {
  const _LockedRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          Text(value, style: theme.textTheme.titleMedium),
          Icon(
            Icons.lock,
            size: AppIconSize.button,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
