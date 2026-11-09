import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';
import '../../../routing/routes.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/motion/tabuleiro_hero.dart';
import '../../core/widgets/load_error.dart';
import '../../journey/widgets/challenge_load_error.dart';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/clock.dart';
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
  Future<bool>? _trainingGoal;

  Future<bool>? _trainingGoalFor() {
    final query = widget.trainingGoalDone;
    if (query == null) return null;
    return _trainingGoal ??= Future<bool>.sync(query)
        .onError<Object>((error, stack) {
          reportHandledError(error, stack);
          return false;
        });
  }

  @override
  void didUpdateWidget(covariant ChallengeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trainingGoalDone != widget.trainingGoalDone) {
      _trainingGoal = null;
    }
  }

  Future<SavedGame?> _readSaved(Challenge challenge) async {
    try {
      return await savedJourneyGame(context, challenge);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      rethrow;
    }
  }

  Future<void> _retrySaved(Challenge challenge) async {
    _saved = null;
    try {
      await _savedFor(challenge);
    } on Object {
      // The existing full-screen error stays visible; another retry is safe.
    }
  }

  Future<SavedGame?> _savedFor(Challenge challenge) {
    if (_savedChallenge != challenge.id || _saved == null) {
      _savedChallenge = challenge.id;
      _preview = null;
      _saved = _readSaved(challenge).then((game) {
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
      _trainingGoal = null;
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
    final failure = state.failure;
    if (failure != null) {
      return challengeLoadError(
        context,
        failure,
        context.read<JourneyCubit>().retry,
      );
    }
    final savedTime = context.watch<SettingsCubit>().state?.clock.journeyTime;
    final challenge = state.challenge?.copyWith(time: savedTime);
    final shownTime = _preview == null
        ? challenge?.time
        : _preview!.snapshot.clock?.config.of(
            _preview!.snapshot.playerSide ?? Side.white,
          );
    return FutureBuilder<bool>(
      future: _trainingGoalFor(),
      builder: (context, training) => FutureBuilder<SavedGame?>(
        future: challenge == null || training.data == true
            ? null
            : _savedFor(challenge),
        builder: (context, saved) {
          if (saved.hasError) {
            return LoadErrorScreen(
              kind: LoadErrorKind.fromFailure(LoadFailure.of(saved.error!)),
              onAction: () async => _retrySaved(challenge!),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            );
          }
          final appBar = LucenaAppBar(
            title: Text(
              challenge == null
                  ? l10n.journeyChallengeTitle
                  : endgameName(l10n, challenge.position.subcategory),
            ),
          );
          // A8: o centro da tela inteira (com as barras do sistema) nas
          // coordenadas do corpo, que começa no fim da barra do app.
          final centerY =
              MediaQuery.sizeOf(context).height / 2 -
              MediaQuery.viewPaddingOf(context).top -
              appBar.preferredSize.height;
          return Scaffold(
            key: JourneyKeys.challengeScreen,
            appBar: appBar,
            bottomNavigationBar: challenge == null
                ? null
                : training.data == true
                ? _NextGoalFooter(onNextGoal: widget.onNextGoal)
                : _PlayFooter(
                    saved: saved.data,
                    ready: saved.connectionState == ConnectionState.done,
                    onPlay: () => _play(challenge),
                    onRestart: () => _play(challenge, restart: true),
                  ),
            // O tabuleiro e os selos no centro do espaço entre a barra do app
            // e o painel do adversário e das partidas (T64), que rola; o botão
            // de jogar fica fixo embaixo.
            body: ShimmerConteudo(
              carregando: challenge == null,
              esqueleto: const SkeletonList(),
              child: challenge == null
                  ? const SizedBox.shrink()
                  : _ChallengeBody(
                      challenge: challenge,
                      state: state,
                      shownTime: shownTime,
                      centerY: centerY,
                      homeHero: widget.homeHero,
                      launching: _launching,
                      preview: _preview,
                      rungId: rungId,
                    ),
            ),
          );
        },
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
          heroTag: launching && !arriving
              ? gameBoardTag(
                  challenge.position.fen.split(' ')[1] == 'b'
                      ? Side.black
                      : Side.white,
                )
              : null,
        );
        if (arriving) {
          return GameBoardHero(orientation: orientation, child: board);
        }
        // H-ANI-02: chega do cartão (Início ou degrau) com o id = FEN.
        return launching
            ? board
            : TabuleiroHero(id: challenge.position.fen, child: board);
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

/// O tabuleiro e os selos no centro do espaço entre a barra do app e o painel
/// do adversário e das partidas (T64), que rola.
class _ChallengeBody extends StatelessWidget {
  const _ChallengeBody({
    required this.challenge,
    required this.state,
    required this.shownTime,
    required this.centerY,
    required this.homeHero,
    required this.launching,
    required this.preview,
    required this.rungId,
  });

  final Challenge challenge;
  final JourneyState state;
  final TimeControl? shownTime;
  final double centerY;
  final bool homeHero;
  final bool launching;
  final SavedGame? preview;
  final String rungId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        // A8: o tabuleiro no centro útil, o painel com o
        // espaço de baixo (rola). Se o painel não cabe nem
        // com uma linha, volta ao centro acima dele (T64).
        final centered = BoardOptionsPanel.centeredAreaFor(
          box.maxHeight,
          centerY: centerY,
          below:
              box.maxWidth / 2 +
              2 * AppSpacing.md +
              _ChallengeScreenState._chipsHeight,
          minPanel: kMinInteractiveDimension,
          // Sem subir: o painel de uma linha não deixa ver o
          // histórico; em tela baixa vale o centro do espaço.
          minTop: centerY,
        );
        return Column(
          children: [
            SizedBox(
              height:
                  centered?.area ??
                  BoardOptionsPanel.boardAreaFor(
                    box.maxHeight,
                    boardRoom:
                        box.maxWidth +
                        2 *
                            (_ChallengeScreenState._chipsHeight +
                                AppSpacing.md) +
                        AppSpacing.md,
                    minPanel: 0.3,
                  ),
              child: CenteredBoardLayout(
                gap: AppSpacing.md,
                reserveBottom: _ChallengeScreenState._chipsHeight,
                centerY: centered?.centerY,
                board: _BigBoard(
                  homeHero: homeHero,
                  challenge: challenge,
                  launching: launching,
                  saved: preview,
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
                      if (preview == null)
                        TextButton(
                          key: JourneyKeys.changePace,
                          onPressed: () async {
                            final settings = context.read<SettingsCubit>();
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
        );
      },
    );
  }
}

/// O botão do fim do desafio de uma meta de treino.
class _NextGoalFooter extends StatelessWidget {
  const _NextGoalFooter({required this.onNextGoal});

  final VoidCallback? onNextGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ActionsFooter(
      children: [
        FilledButton(
          key: TrainingKeys.nextGoal,
          onPressed: onNextGoal,
          child: Text(l10n.trainingNextGoal),
        ),
      ],
    );
  }
}

/// Jogar, ou continuar a partida salva (com a opção de recomeçar).
class _PlayFooter extends StatelessWidget {
  const _PlayFooter({
    required this.saved,
    required this.ready,
    required this.onPlay,
    required this.onRestart,
  });

  final SavedGame? saved;
  final bool ready;
  final VoidCallback onPlay;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ActionsFooter(
      stacked: true,
      children: [
        FilledButton.icon(
          key: saved == null ? JourneyKeys.play : JourneyKeys.resume,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(saved == null ? l10n.journeyPlay : l10n.journeyResume),
          onPressed: ready ? onPlay : null,
        ),
        if (saved != null)
          TextButton(
            key: JourneyKeys.restart,
            onPressed: onRestart,
            child: Text(l10n.journeyRestart),
          ),
      ],
    );
  }
}
