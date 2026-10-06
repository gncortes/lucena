import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/exercise_cubit.dart';
import 'endgame_ui.dart';
import 'stars_row.dart';

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
    with TickerProviderStateMixin {
  ChessboardController? _board;

  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// O lance errado fica um instante no tabuleiro, em vermelho.
  late final _wrongFlash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void dispose() {
    _board?.dispose();
    _shake.dispose();
    _wrongFlash.dispose();
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
    if (state.mistakes > previous.mistakes) {
      _shake.forward(from: 0);
      _wrongFlash.forward(from: 0);
    }
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
            // Só o número: o título da aula, longo, ficou na tela dela.
            appBar: AppBar(
              title: lesson == null
                  ? null
                  : Text(
                      l10n.exerciseTitle(state.number, state.count),
                      key: ExerciseKeys.counter,
                    ),
            ),
            body: SafeArea(child: _body(context, state, boardSettings)),
          );
        },
      ),
    );
  }

  /// O tabuleiro fica com chave: a coluna troca de filhos quando o exercício
  /// carrega, e o voo da miniatura só continua se o widget for o mesmo.
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
        Expanded(
          key: _boardAreaKey,
          child: _boardArea(context, state, boardSettings),
        ),
        _actions(context, state),
      ],
    );
  }

  /// Enquanto o exercício carrega: o mesmo desenho, com a posição parada no
  /// lugar do tabuleiro (se a rota a trouxe), para a miniatura pousar nela.
  Widget _loading(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    if (widget.previewFen == null) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Expanded(child: StepProgress(total: 1, value: 0)),
              const SizedBox(width: 12),
              const StarsRow(total: 1, earned: 0),
            ],
          ),
        ),
        Container(constraints: const BoxConstraints(minHeight: 172)),
        Expanded(
          key: _boardAreaKey,
          child: _boardArea(context, state, boardSettings),
        ),
        const SizedBox(height: 64),
      ],
    );
  }

  Widget _boardArea(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final board = _board;
    final previewFen = widget.previewFen;
    if (board == null && previewFen == null) return const SizedBox.shrink();
    final lessonId = state.lesson?.id ?? widget.lessonId ?? '';
    final exerciseId = state.exercise?.id ?? widget.exerciseId ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        // O que sobra sob o tabuleiro leva o objetivo (antes) ou as estrelas
        // e a solução (depois).
        const strip = 96.0;
        final size = max(
          min(constraints.maxWidth - 16, constraints.maxHeight - 8 - strip),
          120.0,
        );
        final hint = state.hint;
        final wrong = state.wrongMove;
        return Column(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_shake, _wrongFlash]),
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  sin(_shake.value * pi * 4) * 8 * (1 - _shake.value),
                  0,
                ),
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
                          animation: _wrongFlash,
                          builder: (context, _) => Chessboard(
                            key: ExerciseKeys.board,
                            size: size,
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
                              if (wrong is NormalMove &&
                                  _wrongFlash.isAnimating)
                                Arrow(
                                  color: const Color(0xccc62828),
                                  orig: wrong.from,
                                  dest: wrong.to,
                                ),
                            },
                            onMove: (move, {viaDragAndDrop}) =>
                                context.read<ExerciseCubit>().play(move),
                          ),
                        ),
                      ),
              ),
            ),
            if (state.ready && state.exercise != null)
              Expanded(child: _belowBoard(context, state, boardSettings)),
          ],
        );
      },
    );
  }

  /// Antes de resolver: de quem é a vez e o objetivo. Depois: as estrelas
  /// ganhas em tamanho grande e a linha da solução.
  Widget _belowBoard(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final exercise = state.exercise!;
    if (state.phase != ExercisePhase.done) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.interactive ? l10n.exerciseYourMove : l10n.lessonThinking,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  exercise.goal == PositionGoal.win
                      ? Icons.flag_rounded
                      : Icons.shield_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.exerciseGoal(
                    state.side == Side.white ? 'white' : 'black',
                    exercise.goal == PositionGoal.win ? 'win' : 'hold',
                  ),
                  key: ExerciseKeys.goal,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final earned = state.earned ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: l10n.exerciseEarned(earned, exercise.stars),
            excludeSemantics: true,
            child: StarsRow(total: exercise.stars, earned: earned, size: 36),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.exerciseEarned(earned, exercise.stars),
            key: ExerciseKeys.earned,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          _SolutionLine(
            moves: EndgameLessonRules.solution(exercise),
            fen: exercise.fen,
            pieceLetters: boardSettings.notation.pieceLetters(l10n),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ExerciseCubit>();
    final lesson = state.lesson!;
    if (state.phase == ExercisePhase.done) {
      final next = state.nextExercise;
      // Com fundo: o Patrol confere o painel pelo toque no centro dele.
      return Container(
        key: ExerciseKeys.solved,
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.exerciseSolved,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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

/// A linha da solução ("1.Kd4 Kg5 2.Nf4"), com figurinos ou as letras do
/// idioma, conforme a notação escolhida.
class _SolutionLine extends StatelessWidget {
  const _SolutionLine({
    required this.moves,
    required this.fen,
    required this.pieceLetters,
  });

  final List<String> moves;
  final String fen;
  final Map<String, String>? pieceLetters;

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final parts = fen.split(' ');
    final blackFirst = parts.length > 1 && parts[1] == 'b';
    var number = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final figurineStyle = TextStyle(
      fontFamily: Figurine.fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: (style?.fontSize ?? 14) * 1.15,
    );
    final spans = <InlineSpan>[];
    final spoken = StringBuffer();
    var whiteToMove = !blackFirst;
    for (final (index, san) in moves.indexed) {
      if (index > 0) {
        spans.add(const TextSpan(text: '  '));
        spoken.write(' ');
      }
      if (whiteToMove) {
        spans.add(TextSpan(text: '$number.'));
        spoken.write('$number.');
      } else if (index == 0) {
        spans.add(TextSpan(text: '$number...'));
        spoken.write('$number...');
      }
      for (final char in san.split('')) {
        final letter = pieceLetters?[char];
        if (letter != null) {
          spans.add(TextSpan(text: letter));
          spoken.write(letter);
        } else if (Figurine.ofLetter[char] case final figurine?
            when pieceLetters == null) {
          spans.add(TextSpan(text: figurine, style: figurineStyle));
          spoken.write(char);
        } else {
          spans.add(TextSpan(text: char));
          spoken.write(char);
        }
      }
      if (!whiteToMove) number++;
      whiteToMove = !whiteToMove;
    }
    return Semantics(
      label: '${l10n.exerciseSolution}: $spoken',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${l10n.exerciseSolution}: ',
              style: style?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ...spans,
          ],
        ),
        key: ExerciseKeys.solution,
        style: style,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
