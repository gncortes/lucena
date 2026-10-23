import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/game_clock.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_board.dart';
import '../../free_board/widgets/game_actions_bar.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/race_cubit.dart';
import 'race_ui.dart';

/// A revisão dos erros, um de cada vez: a posição, a seta no lance certo, o
/// que o jogador jogou e o lance certo.
class RaceReviewView extends StatelessWidget {
  const RaceReviewView({required this.state, super.key});

  final RaceState state;

  // As alturas das duas linhas de cima do tabuleiro.
  static const _headline = 28.0;
  static const _hint = 20.0;

  @override
  Widget build(BuildContext context) {
    final mistakes = state.mistakes;
    if (mistakes.isEmpty) return const SizedBox.shrink();
    final index = state.reviewIndex.clamp(0, mistakes.length - 1);
    final answer = mistakes[index];
    final problem = state.problems
        .where((p) => p.id == answer.problemId)
        .firstOrNull;
    if (problem == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fen = answer.fen ?? problem.fen;
    final position = Chess.fromSetup(Setup.parseFen(fen));
    final bestUci = answer.best.isEmpty ? null : answer.best.first;
    final right = bestUci == null ? null : Move.parse(bestUci);
    final played = Move.parse(answer.move);
    final number =
        (state.outcome?.result.run.answers ?? const <RaceAnswer>[]).indexWhere(
          (a) => a.problemId == answer.problemId && a.move == answer.move,
        ) +
        1;
    final last = index == mistakes.length - 1;
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final scaler = MediaQuery.textScalerOf(context);
    final topRoom = scaler
        .scale(_headline + _hint * (answer.slower ? 3 : 1))
        .ceilToDouble();
    final bottomRoom = PlayersRow.detailedHeight;
    return Stack(
      key: RaceKeys.reviewView,
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: CenteredBoardLayout(
            balanced: true,
            reserveTop: topRoom,
            reserveBottom: bottomRoom,
            footer: const SizedBox(height: GameActionsBar.height),
            top: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: AppSpacing.sm,
                    children: [
                      Icon(
                        Icons.close,
                        size: AppIconSize.standard,
                        color: colors.error,
                      ),
                      Flexible(
                        child: Text(
                          l10n.raceReviewPlayed(
                            _san(l10n, position, played, answer.move),
                          ),
                          key: RaceKeys.reviewPlayed,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    answer.slower
                        ? l10n.raceReviewSlower(
                            _san(l10n, position, right, bestUci ?? ''),
                            answer.mateIn,
                          )
                        : l10n.raceReviewRight(
                            _san(l10n, position, right, bestUci ?? ''),
                          ),
                    key: RaceKeys.reviewRight,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            board: LayoutBuilder(
              builder: (context, box) => PositionBoard(
                fen: fen,
                size: box.maxWidth,
                orientation: problem.side,
                coordinates: true,
                radius: AppShape.none,
                shapes: {
                  if (answer.slower && played is NormalMove)
                    Arrow(
                      color: colors.error.withValues(alpha: 0.85),
                      orig: played.from,
                      dest: played.to,
                    ),
                  if (right is NormalMove)
                    Arrow(
                      color: ChangeColors.of(
                        context,
                        up: true,
                      ).withValues(alpha: 0.85),
                      orig: right.from,
                      dest: right.to,
                    ),
                },
              ),
            ),
            bottom: PlayersRow(
              detailed: true,
              board: settings,
              players: [
                PlayerEntry(
                  side: problem.side,
                  name: l10n.reviewYou,
                  detail: l10n.raceReviewMeta(
                    number,
                    problem.theme.label(context),
                    problem.level,
                  ),
                  detailKey: RaceKeys.reviewMeta,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: ActionsBar(
              children: [
                GameActionButton(
                  buttonKey: RaceKeys.reviewNext,
                  icon: last ? Icons.check : Icons.arrow_forward,
                  label: last ? l10n.raceReviewDone : l10n.raceReviewNext,
                  onPressed: cubit.nextMistake,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // O lance em notação algébrica; se não der, o UCI como veio.
  static String _san(
    AppLocalizations l10n,
    Position position,
    Move? move,
    String fallback,
  ) {
    final san = move == null ? null : GameRules.play(position, move)?.san;
    return san == null ? fallback : localizedSan(l10n, san);
  }
}
