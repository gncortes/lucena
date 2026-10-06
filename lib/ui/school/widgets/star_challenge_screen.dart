import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../endgames/widgets/stars_row.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/star_challenge_cubit.dart';
import 'star_challenge_ui.dart';
import 'star_shape.dart';

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
            title: piece == null || level == null
                ? null
                : Text(
                    l10n.starChallengeTitle(
                      pieceName(l10n, piece),
                      levelName(l10n, level),
                    ),
                  ),
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
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          // O relógio e a conta das estrelas.
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
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1 - state.elapsedFraction,
                      minHeight: 8,
                      color: lowTime ? colors.error : colors.primary,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, color: StarsRow.color, size: 22),
                const SizedBox(width: 2),
                Text(
                  '${state.points}',
                  key: StarChallengeKeys.collected,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // O tabuleiro na largura da tela, até uns 60% da altura.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Chessboard(
              key: StarChallengeKeys.board,
              size: max(
                min(constraints.maxWidth - 16, constraints.maxHeight * 0.6),
                120,
              ),
              controller: board,
              settings: boardSettings.chessground,
              orientation: Side.white,
              shapes: {
                if (star != null)
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
          Expanded(child: _below(context, state)),
        ],
      ),
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
            mainAxisAlignment: MainAxisAlignment.center,
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
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A conta grande, que pula a cada estrela.
              // O "+N" da última estrela sobe e some.
              SizedBox(
                height: 24,
                child: state.collected == 0
                    ? null
                    : TweenAnimationBuilder<double>(
                        key: ValueKey(state.collected),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, t, child) => Opacity(
                          opacity: 1 - t,
                          child: Transform.translate(
                            offset: Offset(0, -12 * t),
                            child: child,
                          ),
                        ),
                        child: Text(
                          '+${state.lastPoints}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ),
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey(state.collected),
                tween: Tween(begin: state.collected == 0 ? 1 : 1.5, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: StarsRow.color,
                      size: 44,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.points}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
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
            mainAxisAlignment: MainAxisAlignment.center,
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
