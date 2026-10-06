import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_cubit.dart';
import 'lesson_finished.dart';
import 'star_shape.dart';

/// Uma aula com o Viktor: ele em cima, falando; o tabuleiro no meio; a barra
/// dos passos e o botão do passo embaixo.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  ChessboardController? _board;

  // Sacode o tabuleiro no lance errado.
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _board?.dispose();
    _shake.dispose();
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
    if (state.mistakes > previous.mistakes) _shake.forward(from: 0);
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
              // Só o número: o título da aula fica sob o tabuleiro.
              title: lesson == null
                  ? null
                  : Text(
                      l10n.lessonNumber(state.lessonNumber, state.lessonCount),
                    ),
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
      duration: const Duration(milliseconds: 350),
      child: state.finished
          ? LessonFinished(key: LessonKeys.finished, state: state)
          : LayoutBuilder(
              builder: (context, constraints) => Column(
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
                        const SizedBox(width: 12),
                        Text(
                          l10n.lessonStepShort(state.step + 1, state.stepCount),
                          key: LessonKeys.stepCounter,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasBoard) ...[
                    // Com tabuleiro: ele no alto (até metade da tela), o
                    // título e o que fazer, e a fala do Viktor embaixo, com
                    // o espaço que sobra (rola se for longa).
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _boardArea(
                        context,
                        state,
                        boardSettings,
                        board,
                        size: max(
                          min(
                            constraints.maxWidth - 16,
                            constraints.maxHeight * 0.5,
                          ),
                          120.0,
                        ),
                      ),
                    ),
                    _guide(context, state, step),
                    if (viktor != null)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: TeacherSpeech(
                            teacher: viktor,
                            text: state.speech,
                            emotion: state.emotion,
                            avatarSize: 56,
                            bubbleKey: LessonKeys.speech,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                  ] else ...[
                    if (viktor != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TeacherSpeech(
                          teacher: viktor,
                          text: state.speech,
                          emotion: state.emotion,
                          avatarSize: 72,
                          bubbleKey: LessonKeys.speech,
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
                  _actions(context, state),
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
    final step = state.current!;
    final colors = Theme.of(context).colorScheme;
    final hint = state.hint;
    final shapes = <Shape>{
      if (step is TalkStep) ...[
        for (final (from, to) in step.arrows)
          Arrow(
            color: colors.primary.withValues(alpha: 0.75),
            orig: Square.fromName(from),
            dest: Square.fromName(to),
          ),
        for (final mark in step.marks)
          Circle(color: const Color(0xcc15781b), orig: Square.fromName(mark)),
      ],
      for (final star in state.stars)
        CustomShape(
          orig: Square.fromName(star),
          scale: 0.7,
          child: StarShape(key: LessonKeys.star(star)),
        ),
      if (hint is NormalMove)
        Arrow(color: const Color(0xcc15781b), orig: hint.from, dest: hint.to),
    };
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 4) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      // O tabuleiro não espelha em idiomas da direita para a esquerda.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Chessboard(
          key: LessonKeys.board,
          size: size,
          controller: board,
          settings: boardSettings.chessground,
          orientation: step.side,
          shapes: shapes,
          onMove: (move, {viaDragAndDrop}) =>
              context.read<LessonCubit>().play(move),
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
        MoveStep() => l10n.lessonGuideMove(
          step.side == Side.white ? 'white' : 'black',
        ),
        PlayStep() => l10n.lessonGuidePlay(
          step.goal == PlayGoal.mate ? 'mate' : 'promote',
        ),
      },
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Text(
            state.texts.lessonTitle(state.lesson!.id),
            key: LessonKeys.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            key: LessonKeys.guide,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
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
    final canGo =
        state.phase == StepPhase.done ||
        (step is TalkStep && state.phase == StepPhase.active);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (canHint)
            OutlinedButton.icon(
              key: LessonKeys.hintButton,
              onPressed: cubit.askHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l10n.lessonHint),
            ),
          if (state.phase == StepPhase.waiting)
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
          const Spacer(),
          if (state.phase == StepPhase.failed)
            FilledButton.icon(
              key: LessonKeys.retryButton,
              style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
              onPressed: cubit.retry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.lessonRetry),
            ),
          if (canGo)
            FilledButton(
              key: LessonKeys.nextButton,
              style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
              onPressed: cubit.next,
              child: Text(isLast ? l10n.lessonFinish : l10n.lessonContinue),
            ),
        ],
      ),
    );
  }
}

/// A estrela de uma casa a alcançar: entra com um salto e fica parada (uma
/// animação sem fim não deixaria a tela "assentar" nos testes).
/// Abre a próxima aula da trilha no lugar desta.
void openLesson(BuildContext context, String lessonId) =>
    context.pushReplacement(Routes.lesson(lessonId));
