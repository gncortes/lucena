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
import '../../core/widgets/time_display.dart';
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
            centerTitle: true,
            toolbarHeight: (MediaQuery.textScalerOf(context).scale(44) + 16)
                .clamp(72.0, double.infinity),
            title: piece == null
                ? null
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.starChallengeTitle(piece.name)),
                      if (level != null)
                        Text(
                          '${levelName(l10n, level)} · ${l10n.starChallengeIntroTitle}',
                          key: StarChallengeKeys.levelChip,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              BoardViewport(
                usefulHeight: BoardViewport.usefulHeightOf(context),
                child: SafeArea(
                  child: Builder(
                    builder: (context) => _body(context, state, boardSettings),
                  ),
                ),
              ),
              if (_action(context, state) case final action?)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: action,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget? _action(BuildContext context, StarChallengeState state) {
    if (!state.ready) return null;
    final l10n = context.l10n;
    final cubit = context.read<StarChallengeCubit>();
    return switch (state.phase) {
      ChallengePhase.ready => FilledButton.icon(
        key: StarChallengeKeys.goButton,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.starChallengeGo),
        onPressed: cubit.start,
      ),
      ChallengePhase.finished => FilledButton.icon(
        key: StarChallengeKeys.retryButton,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.starChallengePlayAgain),
        onPressed: cubit.retry,
      ),
      ChallengePhase.running || ChallengePhase.paused => null,
    };
  }

  /// A ação fixa, suas margens e a borda; a área segura fica fora da reserva.
  static const _actionRoom = 52.0 + 8 + 8 + 1;

  /// O espaço mínimo sob o tabuleiro: o placar (duas linhas de texto e as
  /// margens) e, abaixo dele, a ação fixa, que assim nunca cobre o
  /// placar. Em celular comum ele já sobra; em tela baixa ou com fonte
  /// grande, o tabuleiro diminui um pouco.
  static double _reserveBottom(TextScaler scaler, ChallengePhase phase) =>
      24 +
      scaler.scale(44) +
      (phase == ChallengePhase.ready || phase == ChallengePhase.finished
          ? AppSpacing.sm + _actionRoom
          : phase == ChallengePhase.paused
          ? AppSpacing.sm + scaler.scale(20)
          : 0);

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
    final scaler = MediaQuery.textScalerOf(context);
    // Plain numbers occupy 24 dp at the default scale, plus 10/6 padding.
    final timerHeight = 16 + scaler.scale(24).ceilToDouble();
    final lowTime =
        state.phase == ChallengePhase.running &&
        state.timeLeft <= const Duration(seconds: 10);
    // O tabuleiro no centro do espaço útil (T64), entre a barra do app e o
    // fim da área segura. Em cima, o relógio colado na barra do app e, sob
    // ele, o convite ou o resultado; embaixo, o placar das estrelas, sempre
    // no mesmo lugar, e a ação fixa no rodapé.
    return CenteredBoardLayout(
      centerY: BoardViewport.centerYOf(context),
      gutter: 0,
      reserveTop:
          timerHeight +
          switch (state.phase) {
            ChallengePhase.ready => 108,
            ChallengePhase.finished => scaler.scale(140),
            _ => state.level!.announcesSquare ? scaler.scale(44) + 8 : 0,
          },
      minFraction: 0.35,
      // O relógio fica colado na barra do app, como antes, e não no tabuleiro.
      topAlignment: Alignment.topCenter,
      reserveBottom: _reserveBottom(scaler, state.phase),
      bottomAlignment: Alignment.topCenter,
      // O relógio fica; a instrução rola na fonte normal quando falta altura.
      // O centro permanece fixo. Antes de jogar, a regra recebe mais espaço;
      // ao iniciar, o tabuleiro pode crescer em torno do mesmo centro.
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
                TimeDisplay(
                  value: clockText(state.timeLeft),
                  semanticsLabel:
                      '${context.l10n.marathonLeft}: ${clockText(state.timeLeft)}'
                      '${state.phase == ChallengePhase.paused ? ', ${context.l10n.starChallengePaused}' : ''}',
                  type: TimeDisplayType.countdown,
                  size: TimeDisplaySize.inline,
                  presentation: TimeDisplayPresentation.plain,
                  state: lowTime
                      ? TimeDisplayState.low
                      : state.phase == ChallengePhase.running
                      ? TimeDisplayState.active
                      : state.phase == ChallengePhase.paused
                      ? TimeDisplayState.paused
                      : TimeDisplayState.normal,
                  textKey: StarChallengeKeys.timer,
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
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _AboveContent(
                readable: state.phase == ChallengePhase.finished,
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
            settings: (state.level?.announcesSquare ?? false)
                ? boardSettings
                      .copyWith(coordinates: false, highlightLastMove: false)
                      .chessground
                : boardSettings.chessground,
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
            0,
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

  /// Sob o tabuleiro: o placar das estrelas, seguido do aviso quando em pausa.
  Widget _below(BuildContext context, StarChallengeState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        children: [
          // Ouro, prata, bronze e o total, que pulam a cada estrela.
          StarScoreboard(counts: state.byKind, points: state.points),
          if (state.phase == ChallengePhase.paused) ...[
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  l10n.starChallengePaused,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A instrução preserva a fonte e sinaliza a rolagem sem ocupar mais altura.
class _AboveContent extends StatefulWidget {
  const _AboveContent({required this.readable, required this.child});

  final bool readable;
  final Widget child;

  @override
  State<_AboveContent> createState() => _AboveContentState();
}

class _AboveContentState extends State<_AboveContent> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.readable
      ? Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            child: widget.child,
          ),
        )
      : widget.child;
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
      constraints: const BoxConstraints(maxHeight: 108),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? colors.surfaceContainerLowest
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: gold.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
