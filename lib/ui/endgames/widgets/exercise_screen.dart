import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/exercise_cubit.dart';
import 'stars_row.dart';

/// Um exercício: o Viktor dá o enunciado, o aluno acha os lances no
/// tabuleiro; no fim, a solução, as estrelas ganhas e o próximo exercício.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with SingleTickerProviderStateMixin {
  ChessboardController? _board;

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
    _previous = state;
    if (state.mistakes > previous.mistakes) _shake.forward(from: 0);
    if (state.fen == null) return;
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
          }
          final lesson = state.lesson;
          return Scaffold(
            key: ExerciseKeys.screen,
            appBar: AppBar(
              title: lesson == null
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.texts.lessonTitle(lesson.id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.exerciseTitle(state.number, state.count),
                          key: ExerciseKeys.counter,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    if (!state.ready) return const SizedBox.shrink();
    final exercise = state.exercise;
    if (state.missing || exercise == null) {
      return Center(
        child: Text(l10n.exerciseMissing, key: ExerciseKeys.missing),
      );
    }
    final viktor = state.viktor;
    return Column(
      children: [
        SizedBox.shrink(key: ExerciseKeys.open(state.lesson!.id, exercise.id)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: StepProgress(
                  total: exercise.line.length,
                  value: state.progress * exercise.line.length,
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: l10n.endgameStars(exercise.stars),
                excludeSemantics: true,
                child: StarsRow(
                  key: ExerciseKeys.stars,
                  total: exercise.stars,
                  earned: state.phase == ExercisePhase.done
                      ? state.earned
                      : max(0, exercise.stars - state.mistakes - state.hints),
                ),
              ),
            ],
          ),
        ),
        if (viktor != null)
          Container(
            constraints: const BoxConstraints(minHeight: 172),
            alignment: AlignmentDirectional.topStart,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TeacherSpeech(
              teacher: viktor,
              text: state.speech,
              emotion: state.emotion,
              avatarSize: 56,
              maxLines: 6,
              bubbleKey: ExerciseKeys.speech,
            ),
          ),
        Expanded(child: _boardArea(context, state, boardSettings)),
        _actions(context, state),
      ],
    );
  }

  Widget _boardArea(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final board = _board;
    if (board == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth - 16, constraints.maxHeight - 8);
        final hint = state.hint;
        return Align(
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                sin(_shake.value * pi * 4) * 8 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Chessboard(
                key: ExerciseKeys.board,
                size: max(size, 120),
                controller: board,
                settings: boardSettings.chessground,
                orientation: state.side,
                shapes: {
                  if (hint is NormalMove)
                    Arrow(
                      color: const Color(0xcc15781b),
                      orig: hint.from,
                      dest: hint.to,
                    ),
                },
                onMove: (move, {viaDragAndDrop}) =>
                    context.read<ExerciseCubit>().play(move),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ExerciseCubit>();
    final lesson = state.lesson!;
    if (state.phase == ExercisePhase.done) {
      final next = state.nextExercise;
      return Padding(
        key: ExerciseKeys.solved,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exerciseSolved,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.exerciseEarned(
                      state.earned ?? 0,
                      state.exercise!.stars,
                    ),
                    key: ExerciseKeys.earned,
                  ),
                ],
              ),
            ),
            if (next != null)
              FilledButton(
                key: ExerciseKeys.nextButton,
                style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
                onPressed: () => context.pushReplacement(
                  Routes.endgameExercise(lesson.id, next),
                ),
                child: Text(l10n.exerciseNext),
              )
            else
              FilledButton(
                key: ExerciseKeys.backButton,
                style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
                onPressed: () => context.pop(),
                child: Text(l10n.exerciseBack),
              ),
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
              label: Text(l10n.exerciseHint),
            ),
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
