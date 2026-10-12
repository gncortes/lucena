import '../../../domain/models/explanation.dart';

import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/game_export.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/speech_links.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/exercise_layout.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/board/speech_flash.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/external_page_sheet.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/step_timer.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/viktor_sheet.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/exercise_cubit.dart';
import 'endgame_ui.dart';
import 'stars_row.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

/// Um exercício: o Viktor dá o enunciado, o aluno acha os lances no
/// tabuleiro; no fim, a solução, as estrelas ganhas e o próximo exercício.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    this.lessonId,
    this.exerciseId,
    this.previewFen,
    super.key,
  });

  /// A aula e o exercício (da rota), para o voo da miniatura da lista até o
  /// tabuleiro: [previewFen] é a posição, mostrada parada enquanto o
  /// exercício carrega, porque o voo precisa do destino já no primeiro quadro.
  final String? lessonId;
  final String? exerciseId;
  final String? previewFen;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  ChessboardController? _board;
  VariationCursor? _variation;

  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );

  /// O lance errado fica um instante no tabuleiro, em vermelho.
  // A casa ou o lance tocado na fala, por um instante no tabuleiro.
  final _flash = SpeechFlash();

  late final _wrongFlash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // O layout: 0 resolvendo (tabuleiro no centro), 1 resolvido (no alto,
  // com o resultado e a fala embaixo). Uma animação só leva de um ao outro.
  late final _mode = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );
  double? _target;

  // O cronômetro: anda enquanto o aluno resolve; resolvido, fica parado no
  // tempo final.
  final _elapsed = ValueNotifier(Duration.zero);
  Timer? _ticker;

  bool _background = false;
  final _sheetExpanded = ValueNotifier(false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _background) {
      return;
    }
    _background = background;
    final cubit = context.read<ExerciseCubit>();
    final speech = TeacherSpeech.speechOf(context);
    if (background) {
      unawaited(cubit.pauseForBackground());
      unawaited(speech?.pauseForBackground());
    } else {
      unawaited(cubit.resumeFromBackground());
      unawaited(speech?.resumeFromBackground());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _background) {
        return;
      }
      final cubit = context.read<ExerciseCubit>();
      if (cubit.state.layout == ExerciseLayoutMode.solving) {
        _elapsed.value = cubit.elapsed;
      }
    });
  }

  /// Leva o tabuleiro ao layout do estado: animado, ou direto na abertura e
  /// com "reduzir movimento".
  void _setMode(
    BuildContext context,
    ExerciseState state, {
    required bool animate,
  }) {
    final target = state.layout == ExerciseLayoutMode.solving ? 0.0 : 1.0;
    if (target == _target) {
      return;
    }
    _target = target;
    if (!animate || AppMotion.of(context).disabled) {
      _mode.value = target;
      return;
    }
    _mode.animateTo(
      target,
      duration: AppMotion.of(context).component,
      curve: AppMotion.enter,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _mode.dispose();
    _elapsed.dispose();
    _sheetExpanded.dispose();
    _board?.dispose();
    _shake.dispose();
    _wrongFlash.dispose();
    _flash.dispose();
    super.dispose();
  }

  GameData _gameData(ExerciseState state) {
    final fen = state.fen!;
    final side = state.side;
    final position = GameRules.fromFen(fen);
    return GameData(
      fen: fen,
      playerSide: position == null || !state.interactive
          ? PlayerSide.none
          : (side == Side.white ? PlayerSide.white : PlayerSide.black),
      sideToMove: position?.turn ?? side,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  ExerciseState _previous = const ExerciseState();

  void _onState(BuildContext context, ExerciseState state) {
    final previous = _previous;
    if (state.fen != previous.fen ||
        state.speech != previous.speech ||
        state.phase != previous.phase ||
        state.exercise?.id != previous.exercise?.id) {
      _variation = null;
    }
    _previous = state;
    if (state.speech == null || state.viktor == null) {
      _sheetExpanded.value = false;
    }
    _setMode(context, state, animate: previous.ready);
    // Resolvendo: o cronômetro já com o tempo do exercício (ao reabrir o
    // app, o tabuleiro nasce aqui, antes do primeiro tique).
    if (state.layout == ExerciseLayoutMode.solving) {
      _elapsed.value = context.read<ExerciseCubit>().elapsed;
    }
    if (state.mistakes > previous.mistakes) {
      _shake.forward(from: 0);
      _wrongFlash.forward(from: 0);
    }
    if (state.fen == null) {
      return;
    }
    if (_variation != null) {
      return;
    }
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
      return;
    }
    board.updatePosition(
      _gameData(state),
      animate: previous.fen != state.fen,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ExerciseCubit>();
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<ExerciseCubit, ExerciseState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
            _setMode(context, state, animate: false);
            _elapsed.value = cubit.elapsed;
          }
          final lesson = state.lesson;
          return Scaffold(
            key: ExerciseKeys.screen,
            // Só o número: o título da aula, longo, ficou na tela dela.
            appBar: AppBar(
              title: lesson == null
                  ? null
                  : Text(
                      l10n.exerciseTitle(state.number, state.count),
                      key: ExerciseKeys.counter,
                    ),
              // O que o exercício vale agora: dourada (3), prata (2) ou
              // bronze (1); cada erro ou dica desce um degrau.
              actions: [
                if (state.exercise case final exercise?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Semantics(
                      // Resolvido: o que ganhou de quanto valia (a estrela
                      // grande some quando o Viktor explica).
                      label: state.phase == ExercisePhase.done
                          ? l10n.exerciseEarned(
                              state.earned ?? 0,
                              exercise.stars,
                            )
                          : l10n.exercisePoints(_worth(state, exercise)),
                      excludeSemantics: true,
                      child: ValueStar(
                        key: ExerciseKeys.stars,
                        points: _worth(state, exercise),
                      ),
                    ),
                  ),
              ],
            ),
            body: BoardViewport(
              usefulHeight: BoardViewport.usefulHeightOf(context),
              child: SafeArea(child: _body(context, state, boardSettings)),
            ),
          );
        },
      ),
    );
  }

  /// O que o exercício vale agora: as estrelas dele menos erros e dicas, ou
  /// o ganho, depois de resolvido.
  static int _worth(ExerciseState state, Exercise exercise) =>
      state.phase == ExercisePhase.done
      ? (state.earned ?? 0)
      : max(0, exercise.stars - state.mistakes - state.hints);

  /// O tabuleiro fica com chave: o voo da miniatura só continua se o widget
  /// for o mesmo entre o carregamento e o exercício aberto.
  static const _boardAreaKey = ValueKey('exercise.boardArea');

  Widget _body(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    if (!state.ready) return _loading(context, state, boardSettings);
    final exercise = state.exercise;
    if (state.missing || exercise == null) {
      return Center(
        child: Text(l10n.exerciseMissing, key: ExerciseKeys.missing),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        SizedBox.shrink(key: ExerciseKeys.open(state.lesson!.id, exercise.id)),
        Positioned.fill(child: _area(context, state, boardSettings)),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: ValueListenableBuilder(
            valueListenable: _sheetExpanded,
            builder: (context, expanded, _) => IgnorePointer(
              ignoring: expanded,
              child: ExcludeSemantics(
                excluding: expanded,
                child: AnimatedSlide(
                  duration: AppMotion.of(context).component,
                  offset: expanded ? const Offset(0, 1) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: AppMotion.of(context).component,
                    opacity: expanded ? 0 : 1,
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context).component,
                      child: KeyedSubtree(
                        key: ValueKey(state.phase == ExercisePhase.done),
                        child: state.phase == ExercisePhase.done
                            ? _actions(context, state)
                            : _solvingFooter(context, state),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// O mesmo tabuleiro em todos os estados; dica e explicação apenas
  /// sobrepõem uma folha expansível abaixo dele.
  Widget _area(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) => LayoutBuilder(
    builder: (context, box) {
      final rect = ExerciseLayout.solvingRect(
        Size(box.maxWidth, box.maxHeight),
        footer: ViktorSheet.peekHeight,
        centerY: BoardViewport.centerYOf(context),
      );
      final hasSpeech = state.viktor != null && state.speech != null;
      return Stack(
        children: [
          Positioned.fromRect(
            rect: rect,
            child: KeyedSubtree(
              key: _boardAreaKey,
              child: _boardArea(
                context,
                state,
                boardSettings,
                size: rect.width,
              ),
            ),
          ),
          if (!hasSpeech && state.phase == ExercisePhase.active && state.ready)
            PositionedDirectional(
              start: 16,
              end: 16,
              top: rect.bottom + ExerciseLayout.gutter,
              child: Text(
                context.l10n.exerciseGoal(
                  state.side == Side.white ? 'white' : 'black',
                  state.exercise!.goal.name,
                ),
                key: ExerciseKeys.goal,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          // Resolvido sem fala (acerto limpo): o selo "Correto!" logo abaixo
          // do tabuleiro, sem cobri-lo.
          if (!hasSpeech && state.phase == ExercisePhase.done)
            PositionedDirectional(
              start: 16,
              end: 16,
              top: rect.bottom + ExerciseLayout.gutter,
              child: Center(child: _correctBadge(context)),
            ),
          if (hasSpeech)
            Positioned.fill(
              child: ViktorSheet(
                key: ExerciseKeys.viktorSheet,
                top: rect.bottom + ExerciseLayout.gutter,
                scrollKey: ExerciseKeys.scroll,
                closeKey: ExerciseKeys.closeSheet,
                onExpanded: (value) => _sheetExpanded.value = value,
                children: [
                  state.phase == ExercisePhase.done
                      ? _result(context, state, boardSettings)
                      : _prompt(context, state),
                ],
              ),
            ),
        ],
      );
    },
  );

  /// O selo de acerto: entra com fade e um leve rebote (parado com
  /// "remover animações").
  Widget _correctBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final motion = AppMotion.of(context);
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        key: ExerciseKeys.correct,
        tween: Tween(begin: 0, end: 1),
        duration: motion.component,
        curve: AppMotion.enter,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppShape.full),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 16, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    context.l10n.exerciseCorrect,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVariation(VariationCursor? cursor) {
    _flash.clear();
    setState(() => _variation = cursor);
    final state = context.read<ExerciseCubit>().state;
    if (cursor == null) {
      _board?.updatePosition(
        _gameData(state),
        animate: true,
        resetPremove: true,
      );
    } else {
      final position = GameRules.fromFen(cursor.fen);
      _board?.updatePosition(
        GameData(
          fen: cursor.fen,
          playerSide: PlayerSide.none,
          sideToMove: position?.turn ?? Side.white,
          validMoves: const {},
          lastMove: cursor.lastMove,
          kingSquareInCheck: position == null
              ? null
              : GameRules.checkedKing(position),
        ),
        animate: true,
        resetPremove: true,
      );
    }
  }

  /// A fala solicitada pelo estado fica na folha abaixo do tabuleiro.
  void _onExplanationLink(
    BuildContext context,
    ExerciseState state,
    SpeechLink link,
  ) {
    final cursor = link.isMove
        ? state.explanationPayload?.cursorForNotation(
            link.text,
            preferred: _variation?.variation,
          )
        : null;
    if (cursor != null) {
      _showVariation(cursor);
    } else {
      _flash.toggle(
        link,
        fen: _variation?.fen ?? state.fen,
        color: Theme.of(context).colorScheme.primary,
      );
    }
  }

  Widget _prompt(BuildContext context, ExerciseState state) {
    final viktor = state.viktor;
    if (viktor == null || state.speech == null) return const SizedBox.shrink();
    final speech = state.speech;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TeacherSpeech(
        speechContext: SpeechContext.game,
        teacher: viktor,
        text: speech,
        explanation:
            state.explanationPayload ?? ExplanationPayload.context([?speech]),
        emotion: state.emotion,
        avatarSize: 40,
        compactInSheet: false,
        bubbleKey: ExerciseKeys.speech,
        onLink: (link) => _flash.toggle(
          link,
          fen: state.fen,
          color: Theme.of(context).colorScheme.primary,
        ),
        onSpoken: (link) => _flash.show(
          link,
          fen: state.fen,
          color: Theme.of(context).colorScheme.primary,
        ),
        speaks: true,
      ),
    );
  }

  /// Resolvido: as estrelas, a solução e a fala do Viktor (correção ou
  /// explicação), rolando sob o tabuleiro.
  Widget _result(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final viktor = state.viktor;
    return Column(
      children: [
        if (viktor != null && state.speech != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TeacherSpeech(
              speechContext: SpeechContext.teaching,
              teacher: viktor,
              text: state.speech,
              explanation:
                  state.explanationPayload ??
                  ExplanationPayload.context([?state.speech]),
              onVariation: _showVariation,
              activeVariation: _variation,
              emotion: state.emotion,
              avatarSize: 56,
              compactInSheet: false,
              bubbleKey: ExerciseKeys.speech,
              onLink: (link) => _onExplanationLink(context, state, link),
              onSpoken: (link) => _flash.show(
                link,
                fen: _variation?.fen ?? state.fen,
                color: Theme.of(context).colorScheme.primary,
              ),
              speaks: true,
            ),
          ),
        _belowBoard(context, state, boardSettings),
      ],
    );
  }

  /// Enquanto o exercício carrega: o tabuleiro parado no centro (se a rota
  /// trouxe a posição), para a miniatura pousar nele.
  Widget _loading(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    if (widget.previewFen == null) return const SizedBox.shrink();
    return _area(context, state, boardSettings);
  }

  /// Resolvendo: a dica (com o que ela custa) à esquerda e o cronômetro à
  /// direita (os lados trocam em árabe).
  Widget _solvingFooter(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final cubit = context.read<ExerciseCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // As ações tomam o espaço que sobra, alinhadas ao início; o texto
              // fica numa linha só e encolhe se faltar largura.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.interactive)
                        Flexible(
                          child: OutlinedButton.icon(
                            key: ExerciseKeys.hintButton,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surface,
                            ),
                            onPressed: cubit.askHint,
                            icon: const Icon(Icons.lightbulb_outline),
                            // O texto diz o que a dica custa agora: um ponto, o
                            // último (o exercício deixa de pontuar) ou nada.
                            label: OneLine(switch (_worth(
                              state,
                              state.exercise!,
                            )) {
                              0 => l10n.exerciseHintFree,
                              1 => l10n.exerciseHintLast,
                              _ => l10n.exerciseHint,
                            }),
                          ),
                        ),
                      // Com a nota fechada, a posição vai para a análise do
                      // Lichess.
                      if (state.locked && state.interactive) ...[
                        const SizedBox(width: 8),
                        Flexible(child: _lichessButton(context, state)),
                      ],
                      if (state.phase == ExercisePhase.waiting)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.lessonThinking),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppShape.small),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: StepTimer(key: ExerciseKeys.timer, elapsed: _elapsed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boardArea(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings, {
    required double size,
  }) {
    final board = _board;
    final previewFen = widget.previewFen;
    if (board == null && previewFen == null) return const SizedBox.shrink();
    final lessonId = state.lesson?.id ?? widget.lessonId ?? '';
    final exerciseId = state.exercise?.id ?? widget.exerciseId ?? '';
    final hint = state.hint;
    final wrong = state.wrongMove;
    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _wrongFlash]),
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 4) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      // A miniatura da lista voa até aqui e vira o tabuleiro.
      child: Hero(
        tag: exerciseHeroTag(lessonId, exerciseId),
        child: board == null
            ? PositionBoard(
                fen: previewFen!,
                size: size,
                radius: 0,
                coordinates: true,
              )
            : Directionality(
                textDirection: TextDirection.ltr,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_wrongFlash, _flash]),
                  builder: (context, _) => Chessboard(
                    key: ExerciseKeys.board,
                    size: size,
                    controller: board,
                    settings: boardSettings.chessground,
                    orientation: state.side,
                    shapes: {
                      if (_variation == null && hint is NormalMove)
                        Arrow(
                          color: const Color(0xcc15781b),
                          orig: hint.from,
                          dest: hint.to,
                        ),
                      if (_variation == null &&
                          wrong is NormalMove &&
                          _wrongFlash.isAnimating)
                        Arrow(
                          color: const Color(0xccc62828),
                          orig: wrong.from,
                          dest: wrong.to,
                        ),
                      ..._flash.shapesFor(_variation?.fen ?? state.fen),
                    },
                    onMove: (move, {viaDragAndDrop}) => _variation == null
                        ? context.read<ExerciseCubit>().play(move)
                        : null,
                  ),
                ),
              ),
      ),
    );
  }

  /// Depois de resolver: as estrelas ganhas em tamanho grande e a linha da
  /// solução.
  Widget _belowBoard(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final exercise = state.exercise!;
    if (state.phase != ExercisePhase.done) return const SizedBox.shrink();
    final earned = state.earned ?? 0;
    // Sem linha de "Solução": com o Viktor explicando, a fala já diz; sem
    // fala, só a nota (a estrela).
    if (state.speech != null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: l10n.exerciseEarned(earned, exercise.stars),
            excludeSemantics: true,
            // A estrela entra girando e com rebote ao resolver.
            child: TweenAnimationBuilder<double>(
              key: ExerciseKeys.earnedStar,
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.of(context).celebrate,
              curve: AppMotion.pop,
              builder: (context, value, child) => Transform.rotate(
                angle: (1 - value) * pi,
                child: Transform.scale(scale: value, child: child),
              ),
              child: ValueStar(points: earned, size: 56),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.exerciseEarned(earned, exercise.stars),
            key: ExerciseKeys.earned,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// "Analisar no Lichess": a posição do exercício no tabuleiro de análise.
  Widget _lichessButton(BuildContext context, ExerciseState state) =>
      TextButton.icon(
        key: ExerciseKeys.lichessButton,
        // Dentro do app, na folha da página: a aula fica atrás.
        onPressed: () =>
            showExternalPage(context, GameExport.lichess(state.exercise!.fen)),
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text(context.l10n.exerciseLichess),
      );

  /// O botão principal do resolvido: o próximo exercício, a volta à aula
  /// (treino avulso) ou o resultado (o último da série).
  Widget _primaryButton(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final lesson = state.lesson!;
    final next = state.nextExercise;
    final style = FilledButton.styleFrom(minimumSize: const Size(140, 48));
    if (next != null) {
      return FilledButton(
        key: ExerciseKeys.nextButton,
        style: style,
        onPressed: () =>
            context.pushReplacement(Routes.endgameExercise(lesson.id, next)),
        child: Text(l10n.exerciseNext, maxLines: 1),
      );
    }
    if (state.locked) {
      // Treino avulso: a nota já está fechada, volta à aula.
      return FilledButton(
        key: ExerciseKeys.backButton,
        style: style,
        onPressed: () => context.pop(),
        child: Text(l10n.exerciseBack, maxLines: 1),
      );
    }
    // O último da série: a tela de resultado, que volta à aula.
    return FilledButton(
      key: ExerciseKeys.resultButton,
      style: style,
      onPressed: () =>
          context.pushReplacement(Routes.endgameExercisesDone(lesson.id)),
      child: Text(l10n.exerciseSeeResult, maxLines: 1),
    );
  }

  /// "Ver explicação" (tonal, com o mesmo tamanho do principal) e o próximo
  /// passo. Lado a lado, em metades iguais, quando os textos cabem inteiros
  /// na fonte do aparelho; senão, um sobre o outro. O texto nunca encolhe:
  /// antes ficava num `FittedBox` dentro de um `Flexible` que dividia a sobra
  /// com um `Spacer`, e a letra chegava a ~10 px.
  Widget _solvedButtons(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final cubit = context.read<ExerciseCubit>();
    final explain = state.canExplain
        ? FilledButton.tonalIcon(
            key: ExerciseKeys.explainButton,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: cubit.showExplanation,
            icon: const Icon(Icons.forum_outlined),
            // Empilhado com fonte grande, quebra em duas linhas; lado a lado
            // só fica quando cabe numa.
            label: Text(
              l10n.lessonSeeExplanation,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          )
        : null;
    final lichess = state.locked ? _lichessButton(context, state) : null;
    final primary = _primaryButton(context, state);
    if (explain == null) {
      return Row(children: [?lichess, const Spacer(), primary]);
    }
    final stacked = Column(
      key: ExerciseKeys.solvedStacked,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        explain,
        const SizedBox(height: AppSpacing.sm),
        if (lichess == null)
          primary
        else
          Row(
            children: [
              Flexible(child: lichess),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: primary),
            ],
          ),
      ],
    );
    // Com o Lichess (nota fechada), três botões não cabem numa linha.
    if (lichess != null) return stacked;
    return _HalvesOrStack(gap: AppSpacing.sm, children: [explain, primary]);
  }

  Widget _actions(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ExerciseCubit>();
    if (state.phase == ExercisePhase.done) {
      // Com fundo: o Patrol confere o painel pelo toque no centro dele.
      return Container(
        key: ExerciseKeys.solved,
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nota fechada: este é treino livre.
            if (state.locked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.exerciseScoreLocked,
                  key: ExerciseKeys.locked,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            _solvedButtons(context, state),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (state.interactive)
            OutlinedButton.icon(
              key: ExerciseKeys.hintButton,
              onPressed: cubit.askHint,
              icon: const Icon(Icons.lightbulb_outline),
              // O texto diz o que a dica custa agora: um ponto, o último
              // (o exercício deixa de pontuar) ou nada.
              label: Text(switch (_worth(state, state.exercise!)) {
                0 => l10n.exerciseHintFree,
                1 => l10n.exerciseHintLast,
                _ => l10n.exerciseHint,
              }),
            ),
          // Com a nota fechada, a posição vai para a análise do Lichess.
          if (state.locked && state.interactive) ...[
            const SizedBox(width: 8),
            _lichessButton(context, state),
          ],
          if (state.phase == ExercisePhase.waiting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(l10n.lessonThinking),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dois botões em metades iguais lado a lado se a largura natural de cada um
/// (intrínseca, medida nos próprios botões) cabe na metade; senão, um sobre
/// o outro, inteiros.
class _HalvesOrStack extends StatefulWidget {
  const _HalvesOrStack({required this.children, required this.gap});

  final List<Widget> children;
  final double gap;

  @override
  State<_HalvesOrStack> createState() => _HalvesOrStackState();
}

class _HalvesOrStackState extends State<_HalvesOrStack> {
  final _keys = [GlobalKey(), GlobalKey()];
  bool? _fits;
  double? _width;

  void _measure() {
    if (!mounted || _width == null) {
      return;
    }
    var widest = 0.0;
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox) {
        return;
      }
      widest = max(widest, box.getMaxIntrinsicWidth(double.infinity));
    }
    final fits = 2 * widest + widget.gap <= _width! + .5;
    if (fits != _fits) setState(() => _fits = fits);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      _width = box.maxWidth;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      final first = KeyedSubtree(key: _keys[0], child: widget.children[0]);
      final second = KeyedSubtree(key: _keys[1], child: widget.children[1]);
      if (_fits == false) {
        return Column(
          key: ExerciseKeys.solvedStacked,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            SizedBox(height: widget.gap),
            second,
          ],
        );
      }
      final row = Row(
        children: [
          Expanded(child: first),
          SizedBox(width: widget.gap),
          Expanded(child: second),
        ],
      );
      // Antes da primeira medida, invisível: não pisca cortado.
      return _fits == null ? Opacity(opacity: 0, child: row) : row;
    },
  );
}
