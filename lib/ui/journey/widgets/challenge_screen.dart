import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/journey.dart';
import '../../../domain/models/pace.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/attempt_history.dart';
import '../../core/widgets/game_board_hero.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/position_board.dart';
import '../view_models/journey_cubit.dart';
import '../../core/widgets/opponent_card.dart';
import 'journey_ui.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_title.dart';

/// Um desafio: o tabuleiro grande, o objetivo e o ritmo em selos, o
/// adversário, as partidas já jogadas e o botão de jogar fixo embaixo.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({required this.rungId, super.key});

  /// O adversário (degrau) do desafio: o retrato dele chega voando da tela
  /// de antes.
  final String rungId;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  /// O espaço da linha dos selos (objetivo e ritmo).
  static const _chipsHeight = 40.0;

  // A partida está abrindo: o tabuleiro grande voa até o centro dela. Na
  // volta, ele retoma a marca de antes (o voo de volta para o degrau).
  bool _launching = false;

  String get rungId => widget.rungId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<JourneyCubit>().state;
    final challenge = state.challenge;
    return Scaffold(
      key: JourneyKeys.challengeScreen,
      appBar: LucenaAppBar(
        title: Text(
          challenge == null
              ? l10n.journeyChallengeTitle
              : endgameName(l10n, challenge.position.subcategory),
        ),
      ),
      bottomNavigationBar: challenge == null
          ? null
          : ActionsFooter(
              children: [
                FilledButton.icon(
                  key: JourneyKeys.play,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.journeyPlay),
                  onPressed: () async {
                    final played = await playChallenge(
                      context,
                      challenge,
                      onLaunch: () => setState(() => _launching = true),
                    );
                    if (mounted && _launching) {
                      setState(() => _launching = false);
                    }
                    if (!played) return;
                    if (!context.mounted) return;
                    final uri = GoRouterState.of(context).pathParameters;
                    await context.read<JourneyCubit>().load(
                      rungId: uri['rung'],
                      positionId: uri['position'],
                    );
                  },
                ),
              ],
            ),
      body: challenge == null
          ? const SkeletonList()
          // O tabuleiro e os selos no centro do espaço entre a barra do app
          // e o painel do adversário e das partidas (T64), que rola; o botão
          // de jogar fica fixo embaixo.
          : LayoutBuilder(
              builder: (context, box) => Column(
                children: [
                  SizedBox(
                    height: BoardOptionsPanel.boardAreaFor(
                      box.maxHeight,
                      boardRoom:
                          box.maxWidth +
                          2 * (_chipsHeight + AppSpacing.md) +
                          AppSpacing.md,
                      minPanel: 0.3,
                    ),
                    child: CenteredBoardLayout(
                      gap: AppSpacing.md,
                      reserveBottom: _chipsHeight,
                      board: _BigBoard(
                        challenge: challenge,
                        launching: _launching,
                      ),
                      bottom: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            _GoalChip(challenge: challenge),
                            InfoChip(
                              icon: switch (challenge.time) {
                                final time? => paceIcon(PaceCategory.of(time)),
                                null => Icons.timer_off_outlined,
                              },
                              label: switch (challenge.time) {
                                final time? => l10n.speedrunTimeControl(
                                  time.initial.inMinutes,
                                  time.increment.inSeconds,
                                ),
                                null => l10n.challengeNoClock,
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: BoardOptionsPanel(
                      key: JourneyKeys.challengePanel,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        children: [
                          _journeyOpponent(context, challenge.opponent, rungId),
                          SectionTitle(l10n.setupHistory),
                          if (state.attempts.isEmpty)
                            EmptyState(
                              style: EmptyStateStyle.filters,
                              icon: Icons.sports_esports_outlined,
                              message: l10n.challengeHistoryInvite,
                              messageKey: JourneyKeys.emptyHistory,
                            )
                          else
                            AttemptHistory(
                              attempts: state.attempts,
                              monthKey: JourneyKeys.month,
                              attemptKey: JourneyKeys.attempt,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// A posição na largura da tela, vista pelo lado que joga. Ela chega voando
/// do tabuleiro pequeno da tela de antes (a do adversário ou a inicial).
class _BigBoard extends StatelessWidget {
  const _BigBoard({required this.challenge, required this.launching});

  final Challenge challenge;

  /// A partida está abrindo: o tabuleiro voa até o centro dela.
  final bool launching;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => PositionBoard(
        boardKey: JourneyKeys.challengeBoard,
        fen: challenge.position.fen,
        size: constraints.maxWidth,
        coordinates: true,
        radius: AppShape.none,
        // A partida é vista pelo lado que joga, como este tabuleiro.
        heroTag: launching
            ? gameBoardTag(
                challenge.position.fen.split(' ')[1] == 'b'
                    ? Side.black
                    : Side.white,
              )
            : challengeBoardTag(challenge.id),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final style = GoalStyle.of(context, challenge.goal);
    return InfoChip(
      icon: style.icon,
      label: goalLabel(context.l10n, challenge.goal),
      background: style.container,
      foreground: style.onContainer,
    );
  }
}

/// Contra quem: o retrato (que chega voando), o nome, o nível e a frase.
Widget _journeyOpponent(
  BuildContext context,
  OpponentRef opponent,
  String rungId,
) {
  final l10n = context.l10n;
  final characters = context.select(
    (JourneyCubit cubit) => cubit.state.characters,
  );
  final character = opponentCharacter(characters, opponent);
  final language = Localizations.localeOf(context).languageCode;
  return OpponentCard(
    key: JourneyKeys.opponentCard,
    character: character,
    heroTag: opponentHeroTag(rungId),
    name: [
      opponentName(l10n, characters, opponent),
      if (opponent.level case final level?) '$level',
    ].join(' · '),
    tagline: character?.taglineIn(language) ?? '',
  );
}
