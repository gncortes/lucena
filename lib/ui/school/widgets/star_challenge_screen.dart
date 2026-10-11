import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../endgames/widgets/stars_row.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/star_challenge_cubit.dart';
import 'star_challenge_ui.dart';
import 'star_scoreboard.dart';
import 'star_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

/// Um desafio das estrelas: o relógio, o tabuleiro com a estrela e, no fim,
/// a marca e a nota.
class StarChallengeScreen extends StatefulWidget {
  const StarChallengeScreen({super.key});

  @override
  State<StarChallengeScreen> createState() => _StarChallengeScreenState();
}

class _StarChallengeScreenState extends State<StarChallengeScreen>
    with WidgetsBindingObserver {
  ChessboardController? _board;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _board?.dispose();
    super.dispose();
  }

  // Em segundo plano o relógio para; de volta, continua.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<StarChallengeCubit>();
    switch (state) {
      case AppLifecycleState.resumed:
        cubit.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        cubit.pause();
    }
  }

  GameData _gameData(StarChallengeState state) {
    final fen = state.fen!;
    final board = LessonRules.starsBoard(fen);
    return GameData(
      fen: fen,
      playerSide: state.interactive ? PlayerSide.white : PlayerSide.none,
      sideToMove: Side.white,
      validMoves: StarChallengeRules.validMoves(board),
      lastMove: state.lastMove,
    );
  }

  StarChallengeState _previous = const StarChallengeState();

  void _onState(BuildContext context, StarChallengeState state) {
    final previous = _previous;
    _previous = state;
    if (state.fen == null) return;
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
      return;
    }
    board.updatePosition(
      _gameData(state),
      animate: previous.fen != state.fen && previous.phase == state.phase,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return BlocConsumer<StarChallengeCubit, StarChallengeState>(
      listener: _onState,
      builder: (context, state) {
        if (state.fen != null && _board == null) {
          _board = ChessboardController(game: _gameData(state));
        }
        final piece = state.piece;
        final level = state.level;
        return Scaffold(
          key: StarChallengeKeys.screen,
          appBar: AppBar(
            title: piece == null
                ? null
                : Text(l10n.starChallengeTitle(piece.name)),
            actions: [
              if (level != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
                  child: _LevelChip(level: level),
                ),
            ],
          ),
          body: SafeArea(child: _body(context, state, boardSettings)),
          // O botão do momento no canto de baixo: "Vai!" no convite e "Jogar
          // de novo" no fim. Jogando, some (o Scaffold anima a saída).
          floatingActionButton: _fab(context, state),
        );
      },
    );
  }

  Widget? _fab(BuildContext context, StarChallengeState state) {
    if (!state.ready) return null;
    final l10n = context.l10n;
    final cubit = context.read<StarChallengeCubit>();
    return switch (state.phase) {
      ChallengePhase.ready => FloatingActionButton.extended(
        key: StarChallengeKeys.goButton,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.starChallengeGo),
        onPressed: cubit.start,
      ),
      ChallengePhase.finished => FloatingActionButton.extended(
        key: StarChallengeKeys.retryButton,
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.starChallengePlayAgain),
        onPressed: cubit.retry,
      ),
      ChallengePhase.running || ChallengePhase.paused => null,
    };
  }

  /// A altura que o botão flutuante ocupa no pé da tela, com a margem dele.
  static const _fabRoom = 56.0 + AppSpacing.lg + AppSpacing.xs;

  /// O espaço mínimo sob o tabuleiro: o placar (duas linhas de texto e as
  /// margens) e, abaixo dele, o botão flutuante, que assim nunca cobre o
  /// placar. Em celular comum ele já sobra; em tela baixa ou com fonte
  /// grande, o tabuleiro diminui um pouco.
  static double _reserveBottom(TextScaler scaler) =>
      3 * AppSpacing.sm + scaler.scale(36) + AppSpacing.sm + _fabRoom;

  Widget _body(
    BuildContext context,
    StarChallengeState state,
    BoardSettings boardSettings,
  ) {
    final board = _board;
    if (!state.ready || board == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final star = state.star;
    final lowTime =
        state.phase == ChallengePhase.running &&
        state.timeLeft <= const Duration(seconds: 10);
    // O tabuleiro no centro do espaço útil (T64), entre a barra do app e o
    // fim da área segura. Em cima, o relógio colado na barra do app e, sob
    // ele, o convite ou o resultado; embaixo, o placar das estrelas, sempre
    // no mesmo lugar, e o botão flutuante no canto.
    return CenteredBoardLayout(
      gutter: AppSpacing.sm,
      reserveTop: 40,
      // O relógio fica colado na barra do app, como antes, e não no tabuleiro.
      topAlignment: Alignment.topCenter,
      reserveBottom: _reserveBottom(MediaQuery.textScalerOf(context)),
      bottomAlignment: Alignment.topCenter,
      // Cada lado cuida de caber: em cima, o relógio fica e o convite ou o
      // resultado diminuem; embaixo, o placar fica e o texto rola.
      shrinkSides: false,
      top: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // O relógio e a barra do tempo.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: lowTime ? colors.error : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  clockText(state.timeLeft),
                  key: StarChallengeKeys.timer,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: lowTime ? colors.error : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppShape.small),
                    child: LinearProgressIndicator(
                      value: 1 - state.elapsedFraction,
                      minHeight: 8,
                      color: lowTime ? colors.error : colors.primary,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ShrinkToFit(
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context).component,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: KeyedSubtree(
                  key: ValueKey(
                    state.phase == ChallengePhase.paused
                        ? ChallengePhase.running
                        : state.phase,
                  ),
                  child: _above(context, state),
                ),
              ),
            ),
          ),
        ],
      ),
      board: LayoutBuilder(
        builder: (context, box) => Directionality(
          textDirection: TextDirection.ltr,
          child: Chessboard(
            key: StarChallengeKeys.board,
            size: box.maxWidth,
            controller: board,
            settings: boardSettings.chessground,
            orientation: Side.white,
            shapes: {
              if (star != null && !(state.level?.announcesSquare ?? false))
                CustomShape(
                  orig: star,
                  scale: 0.75,
                  child: StarShape(
                    key: StarChallengeKeys.star(star.name),
                    color: starColor(state.starKind),
                    blinking: state.starBlinking,
                  ),
                ),
            },
            onMove: (move, {viaDragAndDrop}) =>
                context.read<StarChallengeCubit>().play(move),
          ),
        ),
      ),
      bottom: _below(context, state),
    );
  }

  /// Sob o relógio: o convite antes de começar; jogando às cegas, a casa da
  /// estrela pelo nome; no fim, a nota e a melhor marca.
  Widget _above(BuildContext context, StarChallengeState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final level = state.level!;
    switch (state.phase) {
      case ChallengePhase.ready:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            0,
          ),
          child: _IntroCard(level: level),
        );
      case ChallengePhase.running:
      case ChallengePhase.paused:
        // Às cegas: a casa da estrela pelo nome, grande, no lugar do desenho.
        if (!level.announcesSquare) return const SizedBox(width: 1);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AnimatedSwitcher(
            duration: AppMotion.state,
            child: Text(
              state.star?.name ?? ' ',
              key: StarChallengeKeys.starName,
              style: theme.textTheme.displaySmall?.copyWith(
                color: starColor(state.starKind),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      case ChallengePhase.finished:
        return Padding(
          key: StarChallengeKeys.result,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.starChallengeTimeUp,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                label: l10n.endgameEarnedStars(state.earned, level.stars),
                excludeSemantics: true,
                child: StarsRow(
                  key: StarChallengeKeys.earned,
                  total: level.stars,
                  earned: state.earned,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.newBest
                    ? l10n.starChallengeNewBest
                    : l10n.starChallengeBest(state.best ?? 0),
                key: StarChallengeKeys.best,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: state.newBest
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: state.newBest ? FontWeight.w700 : null,
                ),
              ),
              TextButton(
                key: StarChallengeKeys.backButton,
                onPressed: () => context.pop(),
                child: Text(l10n.starChallengesTitle),
              ),
            ],
          ),
        );
    }
  }

  /// Sob o tabuleiro: o placar das estrelas, sempre no mesmo lugar e do mesmo
  /// tamanho (no convite, jogando e no fim), e embaixo dele, jogando, "sua
  /// vez" ou "em pausa".
  Widget _below(BuildContext context, StarChallengeState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final playing =
        state.phase == ChallengePhase.running ||
        state.phase == ChallengePhase.paused;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        children: [
          // Ouro, prata, bronze e o total, que pulam a cada estrela.
          StarScoreboard(counts: state.byKind, points: state.points),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: AnimatedOpacity(
                opacity: playing ? 1 : 0,
                duration: AppMotion.of(context).state,
                child: Text(
                  state.phase == ChallengePhase.paused
                      ? l10n.starChallengePaused
                      : l10n.exerciseYourMove,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O convite: o nome do jogo e a regra, num cartão com a estrela de ouro.
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.level});

  final ChallengeLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gold = starColor(StarKind.gold);
    return Container(
      key: StarChallengeKeys.intro,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star_rounded, color: gold, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.starChallengeIntroTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.starChallengeIntroBody(level.seconds),
            style: theme.textTheme.bodyMedium,
          ),
          // Com peões no tabuleiro: eles só atrapalham, não se capturam.
          if (level.obstacles > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.starChallengeObstacles,
              key: StarChallengeKeys.obstacles,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O selo do nível, na cor dele.
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final ChallengeLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: StarChallengeKeys.levelChip,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: levelColor(level),
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Text(
        levelName(context.l10n, level),
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
