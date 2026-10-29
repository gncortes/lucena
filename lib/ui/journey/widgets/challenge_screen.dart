import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/journey.dart';
import '../../free_board/widgets/saved_game_sheet.dart';
import 'journey_resume.dart';
import '../../../domain/models/pace.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/keys/training_keys.dart';
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
  const ChallengeScreen({
    required this.rungId,
    this.trainingGoalDone,
    this.onNextGoal,
    this.homeHero = false,
    super.key,
  });
  final Future<bool> Function()? trainingGoalDone;
  final VoidCallback? onNextGoal;
  final bool homeHero;

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
  String? _savedChallenge;
  Future<SavedGame?>? _saved;
  SavedGame? _preview;

  Future<SavedGame?> _savedFor(Challenge challenge) {
    if (_savedChallenge != challenge.id || _saved == null) {
      _savedChallenge = challenge.id;
      _preview = null;
      _saved = savedJourneyGame(context, challenge).then((game) {
        if (mounted && _savedChallenge == challenge.id) {
          setState(() => _preview = game);
        }
        return game;
      });
    }
    return _saved!;
  }

  Future<void> _play(Challenge challenge, {bool restart = false}) async {
    final played = await playChallenge(
      context,
      challenge,
      restart: restart,
      onLaunch: () => setState(() => _launching = true),
    );
    if (!mounted) return;
    setState(() {
      _launching = false;
      _saved = null;
      _preview = null;
    });
    if (!played) return;
    final uri = GoRouterState.of(context).pathParameters;
    await context.read<JourneyCubit>().load(
      rungId: uri['rung'],
      positionId: uri['position'],
    );
  }

  String get rungId => widget.rungId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<JourneyCubit>().state;
    final savedTime = context.watch<SettingsCubit>().state?.clock.journeyTime;
    final challenge = state.challenge?.copyWith(time: savedTime);
    final shownTime = _preview == null
        ? challenge?.time
        : _preview!.snapshot.clock?.config.of(
            _preview!.snapshot.playerSide ?? Side.white,
          );
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
          : FutureBuilder<bool>(
              future: widget.trainingGoalDone?.call(),
              builder: (context, training) => training.data == true
                  ? ActionsFooter(
                      children: [
                        FilledButton(
                          key: TrainingKeys.nextGoal,
                          onPressed: widget.onNextGoal,
                          child: Text(l10n.trainingNextGoal),
                        ),
                      ],
                    )
                  : FutureBuilder<SavedGame?>(
                      future: _savedFor(challenge),
                      builder: (context, saved) => ActionsFooter(
                        stacked: true,
                        children: [
                          FilledButton.icon(
                            key: saved.data == null
                                ? JourneyKeys.play
                                : JourneyKeys.resume,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              saved.data == null
                                  ? l10n.journeyPlay
                                  : l10n.journeyResume,
                            ),
                            onPressed:
                                saved.connectionState == ConnectionState.done
                                ? () => _play(challenge)
                                : null,
                          ),
                          if (saved.data != null)
                            TextButton(
                              key: JourneyKeys.restart,
                              onPressed: () => _play(challenge, restart: true),
                              child: Text(l10n.journeyRestart),
                            ),
                        ],
                      ),
                    ),
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
                        homeHero: widget.homeHero,
                        challenge: challenge,
                        launching: _launching,
                        saved: _preview,
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
                              icon: switch (shownTime) {
                                final time? => paceIcon(PaceCategory.of(time)),
                                null => Icons.timer_off_outlined,
                              },
                              label: switch (shownTime) {
                                final time? => l10n.speedrunTimeControl(
                                  time.initial.inMinutes,
                                  time.increment.inSeconds,
                                ),
                                null => l10n.challengeNoClock,
                              },
                            ),
                            if (_preview == null)
                              TextButton(
                                key: JourneyKeys.changePace,
                                onPressed: () async {
                                  final settings = context
                                      .read<SettingsCubit>();
                                  final clock = settings.state?.clock;
                                  if (clock == null) return;
                                  final choice = await showPaceSheet(
                                    context,
                                    current: clock.journeyTime,
                                    allowNoClock: true,
                                  );
                                  if (choice != null && context.mounted) {
                                    await settings.setClock(
                                      clock.copyWith(journeyTime: choice.time),
                                    );
                                  }
                                },
                                child: Text(l10n.journeyChangePace),
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
  const _BigBoard({
    required this.challenge,
    required this.launching,
    this.saved,
    this.homeHero = false,
  });
  final SavedGame? saved;
  final bool homeHero;

  final Challenge challenge;

  /// A partida está abrindo: o tabuleiro voa até o centro dela.
  final bool launching;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation =
            saved?.snapshot.orientation ??
            (challenge.position.fen.split(' ')[1] == 'b'
                ? Side.black
                : Side.white);
        final arriving = homeHero && !launching;
        final board = PositionBoard(
          boardKey: JourneyKeys.challengeBoard,
          fen: saved?.position.fen ?? challenge.position.fen,
          orientation:
              saved?.snapshot.orientation ??
              (challenge.position.fen.split(' ')[1] == 'b'
                  ? Side.black
                  : Side.white),
          size: constraints.maxWidth,
          coordinates: true,
          radius: AppShape.none,
          // A partida é vista pelo lado que joga, como este tabuleiro.
          heroTag: arriving
              ? null
              : launching
              ? gameBoardTag(
                  challenge.position.fen.split(' ')[1] == 'b'
                      ? Side.black
                      : Side.white,
                )
              : challengeBoardTag(challenge.id),
        );
        return arriving
            ? GameBoardHero(orientation: orientation, child: board)
            : board;
      },
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
