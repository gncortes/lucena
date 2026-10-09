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
import '../../core/widgets/teacher_speech.dart';
import '../../../domain/models/app_settings.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_cubit.dart';
import 'lesson_part_widgets.dart';
import 'lesson_finished.dart';
import 'star_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// Uma aula com o Viktor: ele em cima, falando; o tabuleiro no meio; a barra
/// dos passos e o botão do passo embaixo.
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

  ChessboardController? _board;

  // Sacode o tabuleiro no lance errado.
  // A casa ou o lance tocado na fala, por um instante no tabuleiro.
  final _flash = SpeechFlash();

  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );

  // O relógio do passo de pensar e o ritmo da demonstração (T51).
  Timer? _ticker;

  // A folha da fala: a cada passo novo ela volta ao mínimo, para o
  // tabuleiro aparecer inteiro.
  final _sheet = DraggableScrollableController();
  double _sheetMin = 0.3;

  // A fala cabe na folha fechada: ela não abre (sem o vaivém do "x").
  bool _speechFits = false;

  bool _onSpeechMetrics(ScrollMetricsNotification notification) {
    // Só vale medindo com a folha fechada.
    final closed = !_sheet.isAttached || _sheet.size <= _sheetMin + 0.005;
    final fits = notification.metrics.maxScrollExtent <= 0;
    if (closed && fits != _speechFits) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _speechFits = fits);
      });
    }
    return false;
  }

  final _demoClock = Stopwatch();
  String? _demoAt;
  bool _demoSpoke = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  /// O aluno ainda não escolheu o tempo de pensar e a aula tem passo de
  /// pensar: a escolha vem antes (e o relógio espera).
  bool _asksThinkTime(BuildContext context, LessonState state) {
    final chosen = context.read<SettingsCubit>().state?.thinkChosen ?? true;
    if (chosen || state.finished) return false;
    return state.lesson?.steps.any((step) => step is ThinkStep) ?? false;
  }

  void _tick() {
    if (!mounted) return;
    final cubit = context.read<LessonCubit>();
    final state = cubit.state;
    if (state.finished || _asksThinkTime(context, state)) return;
    switch (state.current) {
      case ThinkStep() when state.thinking:
        unawaited(cubit.tick());
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

  void _onState(BuildContext context, LessonState state) {
    final previous = _previous;
    _previous = state;
    if (state.step != previous.step && _sheet.isAttached) {
      _sheet.animateTo(
        _sheetMin,
        duration: AppMotion.of(context).component,
        curve: AppMotion.enter,
      );
    }
    if (state.mistakes > previous.mistakes) _shake.forward(from: 0);
    if (previous.current != null &&
        state.current?.id != previous.current?.id &&
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
    // Escolhido o tempo de pensar, a tela troca da escolha para a aula.
    context.select((SettingsCubit cubit) => cubit.state?.thinkChosen);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<LessonCubit, LessonState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && state.current != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
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
            body: SafeArea(
              child: _asksThinkTime(context, state)
                  // Primeira aula com passo de pensar: antes, quanto tempo.
                  ? _ThinkTimeChooser(
                      onChosen: (minutes) {
                        unawaited(
                          context.read<SettingsCubit>().setThinkMinutes(
                            minutes,
                          ),
                        );
                        cubit.useThinkMinutes(minutes);
                      },
                    )
                  : _body(context, state, boardSettings),
            ),
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
                      // O tempo de pensar, no topo, como o relógio do desafio
                      // das estrelas.
                      if (step is ThinkStep && state.thinking)
                        ThinkClock(state: state),
                      if (hasBoard) ...[
                        // Com tabuleiro: ele fica fixo no alto, inteiro, e a
                        // fala vem numa folha embaixo, com umas linhas à
                        // vista. Fala longa: o aluno puxa a folha para cima e
                        // ela sobe por cima do tabuleiro; puxando de volta,
                        // desce e o tabuleiro reaparece.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final size = max(
                                min(
                                  box.maxWidth - 16,
                                  box.maxHeight - _sheetRoom,
                                ),
                                120.0,
                              );
                              final minSheet =
                                  ((box.maxHeight - size - 8) / box.maxHeight)
                                      .clamp(0.12, 0.9);
                              _sheetMin = minSheet;
                              return Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: _boardArea(
                                        context,
                                        state,
                                        boardSettings,
                                        board,
                                        size: size,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DraggableScrollableSheet(
                                      controller: _sheet,
                                      initialChildSize: minSheet,
                                      minChildSize: minSheet,
                                      // Fala curta: a folha fica fechada.
                                      maxChildSize: _speechFits
                                          ? minSheet
                                          : _sheetMax,
                                      snap: !_speechFits,
                                      snapSizes: _speechFits
                                          ? null
                                          : [minSheet, _sheetMax],
                                      builder: (context, scroll) =>
                                          _speechSheet(
                                            context,
                                            state,
                                            step,
                                            viktor,
                                            scroll,
                                          ),
                                    ),
                                  ),
                                  // Folha cobrindo o tabuleiro: um "x" com respiro
                                  // acima dela, para descer de uma vez.
                                  ListenableBuilder(
                                    listenable: _sheet,
                                    builder: (context, _) {
                                      final open = _sheet.isAttached
                                          ? _sheet.size
                                          : minSheet;
                                      final covering = open > minSheet + 0.03;
                                      final top =
                                          box.maxHeight * (1 - open) - 68;
                                      return Positioned(
                                        top: max(0.0, top),
                                        right: 12,
                                        child: IgnorePointer(
                                          ignoring: !covering,
                                          child: AnimatedOpacity(
                                            duration: AppMotion.of(context)
                                                .component,
                                            opacity: covering ? 1 : 0,
                                            child: IconButton.filled(
                                              key: LessonKeys.closeSheet,
                                              // A mesma cor da folha da fala.
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerLow,
                                                foregroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                elevation: 2,
                                              ),
                                              tooltip: l10n.lessonCloseSpeech,
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                              onPressed: () => _sheet.animateTo(
                                                minSheet,
                                                duration: AppMotion.of(context)
                                                    .component,
                                                curve: AppMotion.enter,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
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
                  // toda e passa por baixo deles.
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: _actions(context, state),
                  ),
                ],
              ),
            ),
    );
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

  /// Entre o tabuleiro e a fala: o título da aula e o que fazer no passo.
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
        ThinkStep() =>
          state.thinking ? l10n.lessonGuideThink : l10n.lessonGuideThinkDone,
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
    // A tarefa do passo numa faixa logo abaixo do tabuleiro, alinhada à
    // esquerda, como nos apps de ensino (o nome da aula já está na tela da
    // aula e a parte, na barra de cima).
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
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _onSpeechMetrics,
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
                    text: _speechText(context, state),
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
      ),
    );
  }

  Widget _actions(BuildContext context, LessonState state) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final step = state.current!;
    final isLast = state.step + 1 >= state.stepCount;
    final canHint =
        state.phase == StepPhase.active &&
        (step is MoveStep || step is PlayStep);
    final canGo = state.canContinue;
    final colors = Theme.of(context).colorScheme;
    if (step is DemoStep && state.phase != StepPhase.done) {
      return DemoControls(state: state, height: _actionsHeight);
    }
    final background = Theme.of(context).scaffoldBackgroundColor;
    // A fala usa a tela até perto da borda de baixo, passando ao lado (e por
    // trás) dos botões; só uma faixa fina no fim esmaece até a cor do fundo,
    // para ela não terminar cortada seco e dar para ver que continua
    // (rolando, o fim dela sobe acima dos botões).
    return DecoratedBox(
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
            if (canHint)
              FloatingActionButton.extended(
                key: LessonKeys.hintButton,
                heroTag: null,
                shape: const StadiumBorder(),
                elevation: 2,
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                onPressed: cubit.askHint,
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(l10n.lessonHint),
              ),
            // Pensando: os dois botões dividem a largura e o texto encolhe
            // se não couber (letra grande, tela estreita).
            if (step is ThinkStep && state.thinking)
              Expanded(
                child: _ThinkAction(
                  key: LessonKeys.thinkReset,
                  onPressed: cubit.resetThink,
                  icon: Icons.replay,
                  label: l10n.lessonThinkReset,
                  background: colors.surface,
                  foreground: colors.primary,
                ),
              ),
            if (state.canHint)
              FloatingActionButton.extended(
                key: LessonKeys.moreHintButton,
                heroTag: null,
                shape: const StadiumBorder(),
                elevation: 2,
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                onPressed: cubit.moreHint,
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(l10n.lessonMoreHint),
              ),
            if (state.phase == StepPhase.waiting)
              Material(
                elevation: 2,
                color: colors.surface,
                shape: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
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
                ),
              ),
            if (step is ThinkStep && state.thinking)
              const SizedBox(width: AppSpacing.sm)
            else
              const Spacer(),
            // Não quer esperar o tempo todo: a explicação do Viktor já,
            // no mesmo lugar onde ela aparece quando o tempo acaba.
            if (step is ThinkStep && state.thinking)
              Expanded(
                child: _ThinkAction(
                  key: LessonKeys.thinkSkip,
                  onPressed: cubit.skipThink,
                  // A explicação do Viktor (a lâmpada é da dica).
                  icon: Icons.forum_outlined,
                  label: l10n.lessonThinkSkip,
                  background: colors.secondaryContainer,
                  foreground: colors.onSecondaryContainer,
                ),
              ),
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
            if (canGo)
              FloatingActionButton.extended(
                key: LessonKeys.nextButton,
                heroTag: null,
                shape: const StadiumBorder(),
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: cubit.next,
                label: Text(
                  step is ThinkStep
                      ? l10n.lessonSeeExplanation
                      : isLast && state.part != null
                      ? l10n.lessonFinishPart
                      : isLast
                      ? l10n.lessonFinish
                      : l10n.lessonContinue,
                ),
              ),
          ],
        ),
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

  /// A fala do balão. Enquanto o aluno pensa, o Viktor só diz quanto
  /// tempo ele tem (o tempo das preferências; a frase vem das traduções).
  String? _speechText(BuildContext context, LessonState state) {
    final step = state.current;
    if (step is ThinkStep && state.thinking) {
      // Quem joga, o que procurar e o tempo.
      final l10n = context.l10n;
      return [
        l10n.lessonThinkTurn(step.turn == Side.white ? 'white' : 'black'),
        l10n.lessonThinkAsk(step.ask.name),
        l10n.lessonThinkAnnounce(state.thinkTime.inMinutes),
      ].join(' ');
    }
    return state.speech;
  }
}

/// A estrela de uma casa a alcançar: entra com um salto e fica parada (uma
/// animação sem fim não deixaria a tela "assentar" nos testes).
/// Abre a próxima aula da trilha no lugar desta.
void openLesson(BuildContext context, String lessonId) =>
    context.pushReplacement(Routes.lesson(lessonId));

/// Um botão do rodapé enquanto o aluno pensa: da altura dos outros, com o
/// texto numa linha só que encolhe se faltar largura.
class _ThinkAction extends StatelessWidget {
  const _ThinkAction({
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
  Widget build(BuildContext context) => FilledButton.icon(
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
    icon: Icon(icon),
    label: OneLine(label),
  );
}

/// Antes da primeira aula com passo de pensar: quanto tempo o aluno quer
/// pensar sozinho em cada posição. A escolha fica nas Configurações.
class _ThinkTimeChooser extends StatelessWidget {
  const _ThinkTimeChooser({required this.onChosen});

  final ValueChanged<int> onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      key: LessonKeys.thinkChooser,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 56, color: colors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.lessonThinkChooseTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.lessonThinkChooseBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final minutes in AppSettings.thinkChoices) ...[
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: LessonKeys.thinkChoice(minutes),
                leading: Icon(
                  minutes == 0
                      ? Icons.auto_awesome_rounded
                      : Icons.hourglass_bottom_outlined,
                  color: colors.primary,
                ),
                title: Text(
                  minutes == 0
                      ? l10n.settingsThinkRecommended
                      : l10n.endgamePartMinutes(minutes),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: minutes == 0
                    ? Text(l10n.lessonThinkRecommendedHint)
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onChosen(minutes),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
