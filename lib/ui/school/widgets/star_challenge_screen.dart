import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
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
import '../../core/widgets/actions_footer.dart';

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
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final cubit = context.read<StarChallengeCubit>();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<StarChallengeCubit, StarChallengeState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
          }
          final piece = state.piece;
          final level = state.level;
          return Scaffold(
            key: StarChallengeKeys.screen,
            appBar: LucenaAppBar(
              toolbarHeight: (MediaQuery.textScalerOf(context).scale(44) + 16)
                  .clamp(72.0, double.infinity),
              title: piece == null ? null : _title(context, piece, level),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  child: Builder(
                    builder: (context) => _body(context, state, boardSettings),
                  ),
                ),
                if (_action(context, state) case final action?)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ActionsFooter(children: [action]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Pergunta 2 do contrato (T65), opção A: o nível e o modo no subtítulo
  /// ("Fácil · Caça às estrelas"). Para a opção B (o nível no título, sem
  /// subtítulo), troque para `false`.
  static const _levelInSubtitle = true;

  /// O título centralizado (`CompTopBar back centralizado subtitulo`).
  Widget _title(
    BuildContext context,
    ChallengePiece piece,
    ChallengeLevel? level,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final title = l10n.starChallengeTitle(piece.name);
    final levelText = level == null ? null : levelName(l10n, level);
    if (!_levelInSubtitle || levelText == null) {
      return Text(
        levelText == null ? title : '$title · $levelText',
        key: levelText == null ? null : StarChallengeKeys.levelChip,
        textAlign: TextAlign.center,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: TextAlign.center),
        Text(
          '$levelText · ${l10n.starChallengeIntroTitle}',
          key: StarChallengeKeys.levelChip,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget? _action(BuildContext context, StarChallengeState state) {
    if (!state.ready) return null;
    final l10n = context.l10n;
    final cubit = context.read<StarChallengeCubit>();
    // Uma linha só: em fonte grande o rótulo diminui em vez de quebrar.
    Widget label(String text) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
    if (state.saving) {
      return const Center(
        child: CircularProgressIndicator(key: StarChallengeKeys.saveProgress),
      );
    }
    if (state.saveError) {
      return FilledButton.icon(
        key: StarChallengeKeys.retrySave,
        icon: const Icon(Icons.refresh),
        label: label(l10n.lessonRetry),
        onPressed: cubit.retryFinish,
      );
    }
    return switch (state.phase) {
      ChallengePhase.ready => FilledButton.icon(
        key: StarChallengeKeys.goButton,
        icon: const Icon(Icons.play_arrow_rounded),
        label: label(l10n.starChallengeGo),
        onPressed: cubit.start,
      ),
      ChallengePhase.finished => FilledButton.icon(
        key: StarChallengeKeys.retryButton,
        icon: const Icon(Icons.replay_rounded),
        label: label(l10n.starChallengePlayAgain),
        onPressed: cubit.retry,
      ),
      ChallengePhase.running || ChallengePhase.paused => null,
    };
  }

  /// A ação fixa e suas margens; a área segura fica fora da reserva.
  static const _actionRoom = kButtonHeight + 8 + 8;

  /// O placar sob o tabuleiro (duas linhas de texto e as margens). Na pausa
  /// o aviso vai na sobra de baixo, sem mexer no bloco.
  /// Cada linha arredonda para cima, como o texto pintado.
  static double _reserveBottom(TextScaler scaler) =>
      24 + scaler.scale(28).ceilToDouble() + scaler.scale(16).ceilToDouble();

  Widget _body(
    BuildContext context,
    StarChallengeState state,
    BoardSettings boardSettings,
  ) {
    final board = _board;
    if (!state.ready || board == null) return const SizedBox.shrink();
    final scaler = MediaQuery.textScalerOf(context);
    // Plain numbers occupy 24 dp at the default scale, plus 10/6 padding.
    final timerHeight = 16 + scaler.scale(24).ceilToDouble();
    final lowTime =
        state.phase == ChallengePhase.running &&
        state.timeLeft <= StarChallengeCubit.lowTime;
    // O bloco (relógio, convite ou resultado, tabuleiro e placar) centrado
    // entre a barra do app e o rodapé, a sobra meio a meio (T65, "Centralizar
    // igual"). Ao tocar em Vai!, o convite e o botão somem e o bloco é
    // recentrado.
    return LayoutBuilder(
      builder: (context, box) {
        final wanted =
            timerHeight +
            (state.saveError
                ? scaler.scale(88)
                : switch (state.phase) {
                    // O convite na altura do conteúdo dele (fonte, idioma, nota dos
                    // obstáculos), medida na largura de verdade.
                    ChallengePhase.ready => _IntroCard.heightFor(
                      context,
                      state.level!,
                      width: box.maxWidth - 2 * AppSpacing.screen,
                    ),
                    ChallengePhase.finished => scaler.scale(140),
                    _ =>
                      state.level!.announcesSquare ? scaler.scale(44) + 8 : 0,
                  });
        // Fonte grande em tela baixa: o tabuleiro não passa de metade da
        // largura para baixo; o que vem em cima ganha só a altura que sobra e
        // rola.
        final footer = _hasAction(state) ? _actionRoom : 0.0;
        final room =
            box.maxHeight -
            footer -
            _reserveBottom(scaler) -
            2 * AppSpacing.sm -
            box.maxWidth / 2;
        return _layout(
          context,
          state,
          boardSettings,
          board: board,
          reserveTop: max(timerHeight, min(wanted, room)),
          lowTime: lowTime,
        );
      },
    );
  }

  static bool _hasAction(StarChallengeState state) =>
      state.saving ||
      state.saveError ||
      state.phase == ChallengePhase.ready ||
      state.phase == ChallengePhase.finished;

  Widget _layout(
    BuildContext context,
    StarChallengeState state,
    BoardSettings boardSettings, {
    required ChessboardController board,
    required double reserveTop,
    required bool lowTime,
  }) {
    final colors = Theme.of(context).colorScheme;
    final star = state.star;
    final scaler = MediaQuery.textScalerOf(context);
    final withAction = _hasAction(state);
    return CenteredBoardLayout(
      balanced: true,
      reserveTop: reserveTop,
      // O topo do bloco tem a altura da reserva, colado no tabuleiro.
      topAlignment: Alignment.bottomCenter,
      reserveBottom: _reserveBottom(scaler),
      bottomAlignment: Alignment.topCenter,
      // O lugar da ação fixa (o "Vai!" ou o "Jogar de novo", desenhados por
      // cima, fora da área segura): o bloco centra acima dela.
      footer: withAction ? SizedBox(height: _actionRoom) : null,
      // O relógio fica; o convite e o resultado rolam na fonte normal quando
      // falta altura (fonte grande em tela baixa), sem cortar o cartão.
      shrinkSides: false,
      top: ConstrainedBox(
        key: StarChallengeKeys.blockTop,
        constraints: BoxConstraints(maxHeight: reserveTop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // O relógio e a barra do tempo.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: AppIconSize.button,
                    color: lowTime ? colors.error : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AnimatedProgress(
                      value: 1 - state.elapsedFraction,
                      role: lowTime ? ProgressRole.error : ProgressRole.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _AboveContent(
                  readable:
                      state.phase == ChallengePhase.ready ||
                      state.phase == ChallengePhase.finished,
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
    if (state.saveError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Text(
          l10n.trainingExerciseSaveError,
          key: StarChallengeKeys.saveError,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.error),
        ),
      );
    }
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
        if (!level.announcesSquare) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AnimatedSwitcher(
            duration: AppMotion.state,
            child: Text(
              state.star?.name ?? ' ',
              key: StarChallengeKeys.starName,
              // A casa é notação: "e4" também em árabe.
              textDirection: TextDirection.ltr,
              style: theme.textTheme.displaySmall?.copyWith(
                color: starColor(state.starKind),
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
                style: context.cardTitle,
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

/// O convite (`CompInfoCard estilo=estrela`): o nome do jogo e a regra,
/// num cartão com a estrela de ouro. A altura é a do conteúdo, sem rolagem
/// interna; [heightFor] faz a mesma conta para a tela reservar o espaço.
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.level});

  final ChallengeLevel level;

  static const _padding = AppSpacing.insideCard;
  static const _border = 1.0;

  /// O círculo da estrela: o ícone e 4 de cada lado (CompInfoCard).
  static const _badge = AppIconSize.standard + 2 * AppSpacing.xs;

  static TextStyle? _titleStyle(ThemeData theme) => theme.cardTitle;

  static TextStyle? _bodyStyle(ThemeData theme) => theme.textTheme.bodyMedium;

  static TextStyle? _noteStyle(ThemeData theme) => theme.textTheme.bodySmall
      ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

  /// A altura do cartão com a largura [width] (sem as margens da tela),
  /// medindo os textos como o [Text] mede: estilo padrão, escala da fonte,
  /// negrito do sistema, direção e idioma.
  static double heightFor(
    BuildContext context,
    ChallengeLevel level, {
    required double width,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final base = DefaultTextStyle.of(context).style;
    final bold = MediaQuery.boldTextOf(context);
    final inner = max(0.0, width - 2 * (_padding + _border));
    double measure(String text, TextStyle? style, double maxWidth) {
      final merged = bold
          ? base
                .merge(style)
                .merge(const TextStyle(fontWeight: FontWeight.bold))
          : base.merge(style);
      final painter = TextPainter(
        text: TextSpan(text: text, style: merged),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
      )..layout(maxWidth: max(0.0, maxWidth));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final title = measure(
      l10n.starChallengeIntroTitle,
      _titleStyle(theme),
      inner - _badge - AppSpacing.sm,
    );
    var height =
        2 * (_padding + _border) +
        max(_badge, title) +
        AppSpacing.sm +
        measure(
          l10n.starChallengeIntroBody(level.seconds),
          _bodyStyle(theme),
          inner,
        );
    if (level.obstacles > 0) {
      height +=
          AppSpacing.xs +
          measure(l10n.starChallengeObstacles, _noteStyle(theme), inner);
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gold = starColor(StarKind.gold);
    return Card(
      key: StarChallengeKeys.intro,
      color: starCardColor(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
        side: BorderSide(color: gold.withValues(alpha: 0.5), width: _border),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(_padding + _border),
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
                    child: Icon(
                      Icons.star_rounded,
                      color: gold,
                      size: AppIconSize.standard,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.starChallengeIntroTitle,
                      style: _titleStyle(theme),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.starChallengeIntroBody(level.seconds),
                style: _bodyStyle(theme),
              ),
              // Com peões no tabuleiro: eles só atrapalham, não se capturam.
              if (level.obstacles > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.starChallengeObstacles,
                  key: StarChallengeKeys.obstacles,
                  style: _noteStyle(theme),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
