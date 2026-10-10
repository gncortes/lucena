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
        );
      },
    );
  }

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
    // fim da área segura; o relógio em cima e o resto embaixo, centrado no
    // espaço que sobra, diminuindo se não couber.
    return CenteredBoardLayout(
      gutter: AppSpacing.sm,
      reserveTop: 40,
      bottomAlignment: Alignment.center,
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
          // Às cegas: a casa da estrela pelo nome, grande, no lugar do desenho.
          if (state.level?.announcesSquare ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedSwitcher(
                duration: AppMotion.state,
                child: Text(
                  star?.name ?? ' ',
                  key: StarChallengeKeys.starName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: starColor(state.starKind),
                    fontWeight: FontWeight.w800,
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

  /// Sob o tabuleiro: o convite e o "vai"; depois, só "sua vez"; no fim, a
  /// marca, a nota e os botões.
  Widget _below(BuildContext context, StarChallengeState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<StarChallengeCubit>();
    final level = state.level!;
    switch (state.phase) {
      case ChallengePhase.ready:
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.starChallengeRule(level.seconds),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              // A legenda: ouro 3, prata 2, bronze 1.
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final kind in StarKind.values.reversed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: starColor(kind),
                          size: 22,
                        ),
                        Text(
                          '${kind.points}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.starChallengeLegend,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              // Com peões no tabuleiro: eles só atrapalham, não se capturam.
              if (level.obstacles > 0) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.starChallengeObstacles,
                  key: StarChallengeKeys.obstacles,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                key: StarChallengeKeys.goButton,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 52),
                  textStyle: theme.textTheme.titleMedium,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.starChallengeGo),
                onPressed: cubit.start,
              ),
            ],
          ),
        );
      case ChallengePhase.running:
      case ChallengePhase.paused:
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bronze, prata, ouro e o total, que pulam a cada estrela.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: StarScoreboard(
                  counts: state.byKind,
                  points: state.points,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.phase == ChallengePhase.paused
                    ? l10n.starChallengePaused
                    : l10n.exerciseYourMove,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case ChallengePhase.finished:
        return Padding(
          key: StarChallengeKeys.result,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.starChallengeTimeUp,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
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
              const SizedBox(height: 4),
              Text(
                '${l10n.starChallengePoints(state.points)} · '
                '${l10n.endgameStars(state.collected)}',
                style: theme.textTheme.bodyLarge,
              ),
              Text(
                state.newBest
                    ? l10n.starChallengeNewBest
                    : l10n.starChallengeBest(state.best ?? 0),
                key: StarChallengeKeys.best,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: state.newBest
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: state.newBest ? FontWeight.w700 : null,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    key: StarChallengeKeys.retryButton,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l10n.starChallengePlayAgain),
                    onPressed: cubit.retry,
                  ),
                  OutlinedButton(
                    key: StarChallengeKeys.backButton,
                    onPressed: () => context.pop(),
                    child: Text(l10n.starChallengesTitle),
                  ),
                ],
              ),
            ],
          ),
        );
    }
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
