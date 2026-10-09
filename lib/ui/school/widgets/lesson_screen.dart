import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/one_line.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/speech_flash.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/step_timer.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_cubit.dart';
import '../../core/board/exercise_layout.dart';
import 'lesson_part_widgets.dart';
import 'lesson_finished.dart';
import 'star_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// Uma aula com o Viktor. Enquanto o aluno resolve um passo de exercício
/// (T60), o enunciado curto fica em cima, o tabuleiro no centro e o
/// cronômetro com as ações embaixo; respondido o passo (e nos passos de
/// conversa e demonstração), o tabuleiro sobe e o Viktor fala numa folha
/// embaixo dele.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {
  // O tabuleiro "pousa" a cada passo novo: um fade curto e uma leve escala.
  late final _landing = AnimationController(
    vsync: this,
    duration: AppMotion.component,
    value: 1,
  );

  // O layout do tabuleiro: 0 resolvendo (no centro), 1 explicando (no alto,
  // com a folha da fala). Uma animação só move o tabuleiro e traz a folha.
  late final _mode = AnimationController(
    vsync: this,
    duration: AppMotion.component,
    value: 1,
  );
  double _target = 1;

  // A tela inteira e a margem de baixo do sistema, para achar o centro da
  // tela dentro da área do tabuleiro.
  Size _screen = Size.zero;
  double _bottomInset = 0;

  // A altura do enunciado no passo aberto: só cresce dentro do passo, para
  // o tabuleiro não pular quando a fala muda de tamanho no meio dele.
  final _header = HeaderMemo();

  ChessboardController? _board;

  // Sacode o tabuleiro no lance errado.
  // A casa ou o lance tocado na fala, por um instante no tabuleiro.
  final _flash = SpeechFlash();

  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );

  // O cronômetro do passo (T60) e o ritmo da demonstração (T51).
  Timer? _ticker;

  // O tempo decorrido no passo, só para o cronômetro: parado quando o passo
  // é respondido, fica com o tempo final até a transição levar.
  final _elapsed = ValueNotifier(Duration.zero);

  // A folha da fala: a cada passo novo ela volta ao mínimo, para o
  // tabuleiro aparecer inteiro.
  final _sheet = DraggableScrollableController();
  double _sheetMin = 0.3;
  final _demoClock = Stopwatch();
  String? _demoAt;
  bool _demoSpoke = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final cubit = context.read<LessonCubit>();
    final state = cubit.state;
    if (state.finished) return;
    if (state.layout == LessonLayoutMode.solving) {
      _elapsed.value = cubit.stepElapsed;
    }
    switch (state.current) {
      case DemoStep(:final line)
          when state.demoPlaying && state.demoMove < line.length:
        _paceDemo(cubit, state);
      default:
        break;
    }
  }

  /// A demonstração anda sozinha no ritmo da fala (docs/spikes/T51-ritmo.md):
  /// com a voz, espera ela terminar e mais uma pausa; sem voz, um tempo de
  /// leitura pelo tamanho da fala. A velocidade da voz vale para os dois.
  void _paceDemo(LessonCubit cubit, LessonState state) {
    final at = '${state.current!.id}:${state.demoMove}';
    if (_demoAt != at) {
      _demoAt = at;
      _demoSpoke = false;
      _demoClock
        ..reset()
        ..start();
    }
    final speech = TeacherSpeech.speechOf(context)?.state;
    final speed = speech?.settings.speed ?? 1.0;
    final text = state.speech ?? '';
    if (speech != null && speech.isSpeaking(text)) {
      // Ainda falando: o relógio conta a partir do fim da fala.
      _demoSpoke = true;
      _demoClock
        ..reset()
        ..start();
      return;
    }
    final reading = max(DemoPace.minReadMs, text.length * DemoPace.msPerChar);
    final waitMs =
        ((_demoSpoke ? 0 : reading) + DemoPace.pauseMs) / max(speed, 0.5);
    if (_demoClock.elapsedMilliseconds >= waitMs) {
      _demoAt = null;
      unawaited(cubit.demoForward());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _board?.dispose();
    _sheet.dispose();
    _shake.dispose();
    _landing.dispose();
    _mode.dispose();
    _elapsed.dispose();
    _flash.dispose();
    super.dispose();
  }

  GameData _gameData(LessonState state) {
    final fen = state.fen!;
    final step = state.current!;
    final side = step.side;
    final player = state.interactive
        ? (side == Side.white ? PlayerSide.white : PlayerSide.black)
        : PlayerSide.none;
    if (step is StarsStep) {
      return GameData(
        fen: fen,
        playerSide: player,
        sideToMove: side,
        validMoves: LessonRules.starsMoves(LessonRules.starsBoard(fen), side),
        lastMove: state.lastMove,
      );
    }
    final position = GameRules.fromFen(fen);
    return GameData(
      fen: fen,
      playerSide: position == null ? PlayerSide.none : player,
      sideToMove: position?.turn ?? side,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  // O estado anterior, para saber o que mudou.
  LessonState _previous = const LessonState();

  /// O layout que o estado pede: 0 resolvendo, 1 explicando.
  static double _targetOf(LessonState state) =>
      state.fen != null && state.layout == LessonLayoutMode.solving ? 0 : 1;

  /// Leva o tabuleiro ao layout [target]: animado, ou direto na abertura da
  /// tela e com "reduzir movimento" ligado.
  void _setMode(BuildContext context, double target, {required bool animate}) {
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

  void _onState(BuildContext context, LessonState state) {
    final previous = _previous;
    _previous = state;
    final cubit = context.read<LessonCubit>();
    final target = _targetOf(state);
    final modeChanged = target != _target;
    if (modeChanged) {
      _setMode(context, target, animate: previous.current != null);
    }
    if (state.step != previous.step) {
      // Passo novo de exercício: o cronômetro já mostra o tempo dele (zero).
      // Saindo para a fala, ele fica parado no tempo final até sumir.
      if (state.layout == LessonLayoutMode.solving) {
        _elapsed.value = cubit.stepElapsed;
      }
      if (_sheet.isAttached) {
        _sheet.animateTo(
          _sheetMin,
          duration: AppMotion.of(context).component,
          curve: AppMotion.enter,
        );
      }
    }
    if (state.mistakes > previous.mistakes) _shake.forward(from: 0);
    // O pouso do passo novo; com o tabuleiro já se movendo, só o movimento.
    if (previous.current != null &&
        state.current?.id != previous.current?.id &&
        !modeChanged &&
        !AppMotion.of(context).disabled) {
      _landing.forward(from: 0);
    }
    if (state.fen == null || state.current == null) return;
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
      return;
    }
    // Sempre redesenha: a peça de um lance recusado volta para a casa dela.
    board.updatePosition(
      _gameData(state),
      animate: previous.step == state.step || previous.fen != state.fen,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    _screen = MediaQuery.sizeOf(context);
    _bottomInset = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<LessonCubit, LessonState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && state.current != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
            _setMode(context, _targetOf(state), animate: false);
            _elapsed.value = cubit.stepElapsed;
          }
          final lesson = state.lesson;
          return Scaffold(
            key: LessonKeys.screen,
            appBar: AppBar(
              // Só o título (da parte, na aula em partes, ou da aula) e, no
              // canto, onde ela está: "1/5".
              // Na formatura, a barra fica limpa: não é mais uma aula.
              title: lesson == null || state.courseFinished
                  ? null
                  : Text(
                      state.part == null
                          ? state.texts.lessonTitle(lesson.id)
                          : state.texts.partTitle(lesson.id, state.part!.id) ??
                                '',
                      key: LessonKeys.appBarTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              actions: [
                if (lesson != null && !state.courseFinished)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Center(
                      child: Semantics(
                        label: state.part == null
                            ? l10n.lessonNumber(
                                state.lessonNumber,
                                state.lessonCount,
                              )
                            : l10n.homeEndgamePart(
                                state.partNumber,
                                state.partCount,
                              ),
                        excludeSemantics: true,
                        child: Text(
                          state.part == null
                              ? '${state.lessonNumber}/${state.lessonCount}'
                              : '${state.partNumber}/${state.partCount}',
                          key: LessonKeys.place,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(child: _body(context, state, boardSettings)),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    LessonState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    if (!state.ready) return const SizedBox.shrink();
    if (state.missing) {
      return Center(child: Text(l10n.lessonMissing, key: LessonKeys.missing));
    }
    final viktor = state.viktor;
    final step = state.current!;
    final theme = Theme.of(context);
    final board = _board;
    final hasBoard = state.fen != null && board != null;
    return AnimatedSwitcher(
      duration: AppMotion.component,
      child: state.finished && state.part != null
          ? PartFinished(key: LessonKeys.finished, state: state)
          : state.finished
          ? LessonFinished(key: LessonKeys.finished, state: state)
          : LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Column(
                    children: [
                      SizedBox.shrink(
                        key: LessonKeys.step(state.lesson!.id, step.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: l10n.lessonStep(
                                  state.step + 1,
                                  state.stepCount,
                                ),
                                child: ExcludeSemantics(
                                  child: StepProgress(
                                    key: LessonKeys.progress,
                                    total: state.stepCount,
                                    value: state.progress * state.stepCount,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasBoard) ...[
                        Expanded(
                          child: _exerciseArea(
                            context,
                            state,
                            step,
                            viktor,
                            boardSettings,
                            board,
                          ),
                        ),
                      ] else ...[
                        if (viktor != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: TeacherSpeech(
                              speechContext: SpeechContext.teaching,
                              teacher: viktor,
                              text: state.speech,
                              emotion: state.emotion,
                              avatarSize: 56,
                              bubbleKey: LessonKeys.speech,
                              speaks: true,
                            ),
                          ),
                        // Passo só de conversa: o espaço fica com o símbolo da
                        // aula, para a fala ter destaque.
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.school_outlined,
                              size: 96,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Os botões flutuam sobre a tela: a fala usa a altura
                  // toda e passa por baixo deles. Resolvendo, o rodapé é o
                  // cronômetro e as ações do passo; respondido, troca num
                  // esmaecer, com o cronômetro parado no tempo final.
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context).component,
                      child: KeyedSubtree(
                        key: ValueKey(state.layout),
                        child: state.layout == LessonLayoutMode.solving
                            ? _solvingFooter(context, state)
                            : _actions(context, state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// O espaço do tabuleiro. Resolvendo, o enunciado em cima e o tabuleiro
  /// no centro do que sobra; respondido, o tabuleiro no alto e a folha da
  /// fala entrando por baixo. Uma animação só ([_mode]) leva de um ao
  /// outro: o delegate mede o enunciado e posiciona tudo a cada quadro.
  Widget _exerciseArea(
    BuildContext context,
    LessonState state,
    LessonStep step,
    Character? viktor,
    BoardSettings boardSettings,
    ChessboardController board,
  ) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final area = Size(box.maxWidth, box.maxHeight);
        final explaining = ExerciseLayout.explainingRect(
          area,
          sheetRoom: _sheetRoom,
        );
        final minSheet =
            ((area.height - explaining.height - ExerciseLayout.gutter) /
                    area.height)
                .clamp(0.12, 0.9);
        _sheetMin = minSheet;
        return AnimatedBuilder(
          animation: _mode,
          builder: (context, _) {
            final t = _mode.value;
            return CustomMultiChildLayout(
              delegate: _ExerciseLayoutDelegate(
                header: _header..stepKey = '${state.lesson?.id}.${step.id}',
                // A área vai até o fim da tela (menos a margem do sistema):
                // o centro da tela, nas coordenadas dela.
                centerY:
                    _screen.height / 2 -
                    (_screen.height - _bottomInset - area.height),
                mode: _mode,
                sheet: _sheet,
                footer: _actionsHeight,
                sheetRoom: _sheetRoom,
              ),
              children: [
                if (t < 1)
                  LayoutId(
                    id: _Slot.prompt,
                    child: FadeTransition(
                      opacity: ReverseAnimation(_mode),
                      child: _prompt(context, state, step, viktor),
                    ),
                  ),
                LayoutId(
                  id: _Slot.board,
                  child: LayoutBuilder(
                    builder: (context, slot) => _boardArea(
                      context,
                      state,
                      boardSettings,
                      board,
                      size: slot.maxWidth,
                    ),
                  ),
                ),
                if (t > 0) ...[
                  // A fala vem numa folha embaixo do tabuleiro, com umas
                  // linhas à vista. Fala longa: o aluno puxa a folha para
                  // cima e ela sobe por cima do tabuleiro; puxando de volta,
                  // desce e o tabuleiro reaparece.
                  LayoutId(
                    id: _Slot.sheet,
                    child: DraggableScrollableSheet(
                      controller: _sheet,
                      initialChildSize: minSheet,
                      minChildSize: minSheet,
                      maxChildSize: _sheetMax,
                      snap: true,
                      snapSizes: [minSheet, _sheetMax],
                      builder: (context, scroll) =>
                          _speechSheet(context, state, step, viktor, scroll),
                    ),
                  ),
                  // Folha cobrindo o tabuleiro: um "x" logo acima dela, para
                  // descer de uma vez.
                  LayoutId(
                    id: _Slot.close,
                    child: ListenableBuilder(
                      listenable: _sheet,
                      builder: (context, _) {
                        final open = _sheet.isAttached ? _sheet.size : minSheet;
                        final covering = open > minSheet + 0.03;
                        return IgnorePointer(
                          ignoring: !covering,
                          child: AnimatedOpacity(
                            duration: AppMotion.of(context).component,
                            opacity: covering ? 1 : 0,
                            child: IconButton.filled(
                              key: LessonKeys.closeSheet,
                              // A mesma cor da folha da fala.
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                                elevation: 2,
                              ),
                              tooltip: l10n.lessonCloseSpeech,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => _sheet.animateTo(
                                minSheet,
                                duration: AppMotion.of(context).component,
                                curve: AppMotion.enter,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  /// O enunciado do passo, enquanto o aluno resolve: o retrato pequeno do
  /// Viktor e o balão ao lado, como numa fala de jogo. No passo de tocar,
  /// a casa pedida logo abaixo. Fala comprida demais rola, para o tabuleiro
  /// não sumir.
  Widget _prompt(
    BuildContext context,
    LessonState state,
    LessonStep step,
    Character? viktor,
  ) {
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: LessonKeys.prompt,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (viktor != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TeacherSpeech(
                  speechContext: SpeechContext.game,
                  teacher: viktor,
                  text: _promptText(context, state, step),
                  emotion: state.emotion,
                  avatarSize: 40,
                  bubbleKey: LessonKeys.speech,
                  onLink: (link) => _flash.toggle(
                    link,
                    fen: state.fen ?? step.fen,
                    color: theme.colorScheme.primary,
                  ),
                  onSpoken: (link) => _flash.show(
                    link,
                    fen: state.fen ?? step.fen,
                    color: theme.colorScheme.primary,
                  ),
                  speaks: true,
                ),
              ),
            if (step is TapStep) _guide(context, state, step),
          ],
        ),
      ),
    );
  }

  /// A fala do enunciado. No passo de pensar, antes de qualquer dica, o
  /// Viktor diz quem joga e faz a pergunta da aula (sem tempo: o aluno
  /// pensa o que quiser).
  String? _promptText(
    BuildContext context,
    LessonState state,
    LessonStep step,
  ) {
    if (step is ThinkStep && state.hintsShown == 0) {
      final l10n = context.l10n;
      return [
        l10n.lessonThinkTurn(step.turn == Side.white ? 'white' : 'black'),
        state.speech ?? l10n.lessonThinkAsk(step.ask.name),
      ].join(' ');
    }
    return state.speech;
  }

  Widget _boardArea(
    BuildContext context,
    LessonState state,
    BoardSettings boardSettings,
    ChessboardController board, {
    required double size,
  }) {
    final colors = Theme.of(context).colorScheme;
    final hint = state.hint;
    final shapes = <Shape>{
      for (final (from, to) in state.arrows)
        Arrow(
          color: colors.primary.withValues(alpha: 0.75),
          orig: Square.fromName(from),
          dest: Square.fromName(to),
        ),
      for (final mark in state.marks)
        Circle(color: const Color(0xcc15781b), orig: Square.fromName(mark)),
      for (final star in state.stars)
        CustomShape(
          orig: Square.fromName(star),
          scale: 0.7,
          child: StarShape(key: LessonKeys.star(star)),
        ),
      if (hint is NormalMove)
        Arrow(color: const Color(0xcc15781b), orig: hint.from, dest: hint.to),
    };
    // Cada passo novo: o tabuleiro "pousa" (o controle volta do zero ao
    // trocar de passo, sem refazer o tabuleiro).
    return AnimatedBuilder(
      animation: _landing,
      builder: (context, child) {
        final value = AppMotion.enter.transform(_landing.value);
        return Opacity(
          opacity: 0.3 + 0.7 * value,
          child: Transform.scale(scale: 0.95 + 0.05 * value, child: child),
        );
      },
      child: _shakingBoard(context, state, boardSettings, board, size, shapes),
    );
  }

  Widget _shakingBoard(
    BuildContext context,
    LessonState state,
    BoardSettings boardSettings,
    ChessboardController board,
    double size,
    Set<Shape> shapes,
  ) {
    final step = state.current!;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 4) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      // O tabuleiro não espelha em idiomas da direita para a esquerda.
      child: Directionality(
        textDirection: TextDirection.ltr,
        // O destaque da fala muda sozinho: só o tabuleiro é refeito.
        child: ListenableBuilder(
          listenable: _flash,
          builder: (context, _) => Chessboard(
            key: LessonKeys.board,
            size: size,
            controller: board,
            // Ler o tabuleiro sem as letras e os números da borda.
            settings: step is TapStep && !step.coordinates
                ? boardSettings.copyWith(coordinates: false).chessground
                : boardSettings.chessground,
            orientation: step.side,
            // O destaque da fala, só na posição em que foi tocado.
            shapes: {...shapes, ..._flash.shapesFor(state.fen ?? step.fen)},
            onMove: (move, {viaDragAndDrop}) =>
                context.read<LessonCubit>().play(move),
            // No passo de tocar, o toque na casa é a resposta.
            onTouchedSquare: step is TapStep
                ? (square) => context.read<LessonCubit>().tap(square.name)
                : null,
          ),
        ),
      ),
    );
  }

  /// Sob o enunciado: o que fazer no passo (a casa pedida, no passo de
  /// tocar).
  Widget _guide(BuildContext context, LessonState state, LessonStep step) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = switch (state.phase) {
      StepPhase.waiting => l10n.lessonThinking,
      StepPhase.done => l10n.lessonGuideDone,
      StepPhase.failed => l10n.lessonRetry,
      StepPhase.active => switch (step) {
        TalkStep() => l10n.lessonGuideTalk,
        StarsStep() => l10n.lessonGuideStars,
        TapStep() => l10n.lessonGuideTap(state.tapTarget ?? ''),
        MoveStep() => l10n.lessonGuideMove(
          step.side == Side.white ? 'white' : 'black',
        ),
        PlayStep() => l10n.lessonGuidePlay(step.goal.name),
        ThinkStep() => l10n.lessonGuideThink,
        DemoStep() => l10n.lessonGuideDemo,
      },
    };
    // O ícone do que se faz no passo.
    final icon = switch (state.phase) {
      StepPhase.waiting => Icons.pending_rounded,
      StepPhase.done => Icons.check_circle_rounded,
      StepPhase.failed => Icons.replay_rounded,
      StepPhase.active => switch (step) {
        TalkStep() => Icons.visibility_outlined,
        StarsStep() => Icons.star_rounded,
        TapStep() => Icons.touch_app_outlined,
        MoveStep() || PlayStep() => Icons.sports_esports_outlined,
        ThinkStep() => Icons.psychology_outlined,
        DemoStep() => Icons.play_circle_outline,
      },
    };
    final done = state.phase == StepPhase.done;
    // A tarefa do passo numa faixa, alinhada à esquerda, como nos apps de
    // ensino (o nome da aula já está na tela da aula e a parte, na barra de
    // cima).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AnimatedContainer(
        duration: AppMotion.of(context).state,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: done ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: done ? colors.onPrimaryContainer : colors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                key: LessonKeys.guide,
                // No passo de tocar, a casa pedida é o que importa: grande.
                style: state.tapTarget != null
                    ? theme.textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: done
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A folha da fala: o puxador, a faixa da tarefa (no passo de tocar) e o
  /// balão do Viktor, rolando por [scroll] (o controle da folha: puxar sobe a
  /// folha antes de rolar o texto).
  Widget _speechSheet(
    BuildContext context,
    LessonState state,
    LessonStep? step,
    Character? viktor,
    ScrollController scroll,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppShape.large),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppShape.large),
        ),
        child: ListView(
          key: LessonKeys.scroll,
          controller: scroll,
          padding: const EdgeInsets.only(bottom: _actionsHeight),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppShape.full),
                  ),
                ),
              ),
            ),
            // A faixa da tarefa só no passo de tocar: lá a casa pedida é o
            // exercício. No resto, o Viktor já diz o que fazer.
            if (step is TapStep) _guide(context, state, step),
            if (viktor != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TeacherSpeech(
                  teacher: viktor,
                  text: state.speech,
                  emotion: state.emotion,
                  avatarSize: 56,
                  bubbleKey: LessonKeys.speech,
                  onLink: (link) => _flash.toggle(
                    link,
                    fen: state.fen ?? state.current?.fen,
                    color: theme.colorScheme.primary,
                  ),
                  onSpoken: (link) => _flash.show(
                    link,
                    fen: state.fen ?? state.current?.fen,
                    color: theme.colorScheme.primary,
                  ),
                  speaks: true,
                  speechContext: SpeechContext.teaching,
                  typed: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// O esmaecer no fim da tela, por trás dos botões: a fala usa a tela até
  /// perto da borda de baixo, passando ao lado (e por trás) deles; só uma
  /// faixa fina no fim esmaece até a cor do fundo, para ela não terminar
  /// cortada seco e dar para ver que continua (rolando, o fim dela sobe
  /// acima dos botões).
  Widget _footer(BuildContext context, {required Widget child}) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return DecoratedBox(
      key: LessonKeys.footer,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            background.withValues(alpha: 0),
            background.withValues(alpha: 0),
            background,
          ],
          stops: const [0, 0.7, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: child,
      ),
    );
  }

  /// O texto do botão principal: "Ver explicação" no passo de pensar,
  /// "Concluir" no último passo, "Continuar" no resto.
  String _nextLabel(BuildContext context, LessonState state, LessonStep step) {
    final l10n = context.l10n;
    final isLast = state.step + 1 >= state.stepCount;
    if (step is ThinkStep) return l10n.lessonSeeExplanation;
    if (isLast && state.part != null) return l10n.lessonFinishPart;
    return isLast ? l10n.lessonFinish : l10n.lessonContinue;
  }

  /// Enquanto o aluno resolve: as ações do passo no canto de início (voltar
  /// um passo, dica, voltar à posição e o principal com o texto, "Ver
  /// explicação" ou "Continuar" ao rever, que encolhe se não couber) e o
  /// cronômetro no canto de fim. Todos os botões da mesma altura.
  Widget _solvingFooter(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    final colors = Theme.of(context).colorScheme;
    final canHint =
        state.phase == StepPhase.active &&
        (step is MoveStep || step is PlayStep);
    final moved = step is ThinkStep && state.fen != step.fen;
    Widget round(Key key, IconData icon, String tooltip, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          child: FloatingActionButton(
            key: key,
            heroTag: null,
            shape: const CircleBorder(),
            elevation: 2,
            backgroundColor: colors.surface,
            foregroundColor: colors.primary,
            tooltip: tooltip,
            onPressed: onTap,
            child: Icon(icon),
          ),
        );
    return _footer(
      context,
      child: Row(
        children: [
          if (state.canGoBack)
            round(
              LessonKeys.backButton,
              Icons.arrow_back,
              l10n.lessonPrevious,
              cubit.back,
            ),
          if (canHint)
            round(
              LessonKeys.hintButton,
              Icons.lightbulb_outline,
              l10n.lessonHint,
              cubit.askHint,
            ),
          // No passo de pensar: a próxima dica, quando o aluno quiser.
          if (state.canHint)
            round(
              LessonKeys.moreHintButton,
              Icons.lightbulb_outline,
              l10n.lessonMoreHint,
              cubit.moreHint,
            ),
          // Mexeu nas peças: de volta à posição do passo.
          if (moved)
            round(
              LessonKeys.thinkReset,
              Icons.replay,
              l10n.lessonThinkReset,
              cubit.resetThink,
            ),
          if (state.phase == StepPhase.waiting)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: _waiting(context),
            ),
          // Com botão principal, ele toma o espaço que sobra; sem ele, o
          // cronômetro vai sozinho para o canto de fim.
          if (state.canContinue)
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                child: _FooterAction(
                  key: LessonKeys.nextButton,
                  onPressed: cubit.next,
                  // A explicação do Viktor (a lâmpada é da dica).
                  icon: step is ThinkStep
                      ? Icons.forum_outlined
                      : Icons.arrow_forward_rounded,
                  label: _nextLabel(context, state, step),
                  background: colors.primary,
                  foreground: colors.onPrimary,
                ),
              ),
            )
          else
            const Spacer(),
          StepTimer(key: LessonKeys.stepTimer, elapsed: _elapsed),
        ],
      ),
    );
  }

  /// A máquina está respondendo.
  Widget _waiting(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: colors.surface,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(context.l10n.lessonThinking),
          ],
        ),
      ),
    );
  }

  /// Com o professor falando: voltar um passo, tentar de novo e continuar.
  Widget _actions(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    final colors = Theme.of(context).colorScheme;
    if (step is DemoStep && state.phase != StepPhase.done) {
      return KeyedSubtree(
        key: LessonKeys.footer,
        child: DemoControls(state: state, height: _actionsHeight),
      );
    }
    return _footer(
      context,
      child: Row(
        children: [
          if (state.canGoBack) ...[
            FloatingActionButton(
              key: LessonKeys.backButton,
              heroTag: null,
              // Redondo e da altura dos outros botões da fileira.
              shape: const CircleBorder(),
              elevation: 2,
              backgroundColor: colors.surface,
              foregroundColor: colors.primary,
              tooltip: l10n.lessonPrevious,
              onPressed: cubit.back,
              child: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
          ],
          if (state.phase == StepPhase.waiting) _waiting(context),
          const Spacer(),
          if (state.phase == StepPhase.failed)
            FloatingActionButton.extended(
              key: LessonKeys.retryButton,
              heroTag: null,
              shape: const StadiumBorder(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: cubit.retry,
              icon: const Icon(Icons.replay),
              label: Text(l10n.lessonRetry),
            ),
          if (state.canContinue)
            FloatingActionButton.extended(
              key: LessonKeys.nextButton,
              heroTag: null,
              shape: const StadiumBorder(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: cubit.next,
              label: Text(_nextLabel(context, state, step)),
            ),
        ],
      ),
    );
  }

  /// O espaço que os botões flutuantes tomam embaixo: a fala rola até
  /// passar deles.
  static const _actionsHeight = 96.0;

  /// O que fica para a fala embaixo do tabuleiro fixo: o título, o retrato e
  /// umas 3 linhas, mais os botões.
  static const _sheetRoom = 280.0;

  /// Até onde a folha da fala sobe: quase a tela toda.
  static const _sheetMax = 0.94;
}

/// Abre a próxima aula da trilha no lugar desta.
void openLesson(BuildContext context, String lessonId) =>
    context.pushReplacement(Routes.lesson(lessonId));

/// O botão principal do rodapé enquanto o aluno resolve: da altura dos
/// outros, com o texto numa linha só que encolhe se faltar largura.
class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 2,
      // Sem contorno, como os outros botões da fileira.
      side: BorderSide.none,
      shape: const StadiumBorder(),
      textStyle: Theme.of(context).textTheme.labelLarge,
    ),
    onPressed: onPressed,
    // O texto flexível de verdade: encolhe em vez de estourar.
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: OneLine(label)),
      ],
    ),
  );
}

/// As partes do espaço do tabuleiro.
enum _Slot { prompt, board, sheet, close }

/// Posiciona o enunciado, o tabuleiro, a folha da fala e o "x" dela pelo
/// andamento de [mode] (0 resolvendo, 1 explicando). O enunciado é medido
/// aqui, no mesmo quadro, e a área não muda de tamanho durante a animação.
class _ExerciseLayoutDelegate extends MultiChildLayoutDelegate {
  _ExerciseLayoutDelegate({
    required this.header,
    required this.centerY,
    required this.mode,
    required this.sheet,
    required this.footer,
    required this.sheetRoom,
  }) : super(relayout: Listenable.merge([mode, sheet]));

  final HeaderMemo header;
  final double centerY;
  final Animation<double> mode;
  final DraggableScrollableController sheet;
  final double footer;
  final double sheetRoom;

  @override
  void performLayout(Size size) {
    final t = mode.value;
    final hasPrompt = hasChild(_Slot.prompt);
    var top = header.held;
    var measured = false;
    if (hasPrompt && top == null) {
      // Passo novo: o enunciado medido (comprido demais, rola).
      top = layoutChild(
        _Slot.prompt,
        BoxConstraints(maxWidth: size.width, maxHeight: size.height * 0.4),
      ).height;
      header.hold(top);
      measured = true;
    }
    final solving = ExerciseLayout.solvingRect(
      size,
      header: top ?? 0,
      footer: footer,
      centerY: centerY,
    );
    if (hasPrompt && !measured) {
      // Enunciado já medido: cresce até o topo do tabuleiro, que não sai do
      // lugar (fala maior rola).
      layoutChild(
        _Slot.prompt,
        BoxConstraints(
          maxWidth: size.width,
          maxHeight: max(top!, solving.top - ExerciseLayout.gutter),
        ),
      );
    }
    if (hasPrompt) positionChild(_Slot.prompt, Offset(0, -t * 24));
    final explaining = ExerciseLayout.explainingRect(
      size,
      sheetRoom: sheetRoom,
    );
    final rect = Rect.lerp(solving, explaining, t)!;
    layoutChild(_Slot.board, BoxConstraints.tight(rect.size));
    positionChild(_Slot.board, rect.topLeft);
    if (hasChild(_Slot.sheet)) {
      layoutChild(_Slot.sheet, BoxConstraints.tight(size));
      positionChild(_Slot.sheet, Offset(0, size.height * (1 - t)));
    }
    if (hasChild(_Slot.close)) {
      final close = layoutChild(_Slot.close, BoxConstraints.loose(size));
      final open = sheet.isAttached ? sheet.size : 0.0;
      positionChild(
        _Slot.close,
        Offset(
          size.width - 12 - close.width,
          max(0.0, size.height * (1 - open) - 56),
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_ExerciseLayoutDelegate old) =>
      old.header != header ||
      old.centerY != centerY ||
      old.mode != mode ||
      old.sheet != sheet ||
      old.footer != footer ||
      old.sheetRoom != sheetRoom;
}
