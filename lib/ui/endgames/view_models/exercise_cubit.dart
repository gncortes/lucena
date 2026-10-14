import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/endgames/exercise_feedback_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/haptic_event.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/exercise_review.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/step_clock.dart';
import '../../core/sound/game_haptics.dart';
import '../../core/sound/game_sounds.dart';
import '../../school/view_models/lesson_cubit.dart';
import 'exercise_state.dart';

export 'exercise_state.dart';

/// Um exercício de uma aula de final: o aluno acha os lances da técnica;
/// cada erro ou dica tira um ponto, e errar o primeiro lance zera. Cada
/// mudança é gravada: o app fechado à força volta no mesmo exercício e na
/// mesma posição.
class ExerciseCubit extends Cubit<ExerciseState> {
  ExerciseCubit({
    required this._lessons,
    required this._progress,
    required this._characters,
    this._feedback,
    this._sounds,
    this._haptics,
    this._now = const SystemNow(),
    this.replyDelay = const Duration(milliseconds: 450),
  }) : super(const ExerciseState());

  final Now _now;
  DateTime? _pausedAt;
  Completer<void>? _foreground;
  bool _closing = false;

  Future<void> _waitForForeground() async {
    while (_pausedAt != null && !_closing && !isClosed) {
      final foreground = _foreground;
      if (foreground == null) {
        return;
      }
      await foreground.future;
    }
  }

  @override
  Future<void> close() {
    _closing = true;
    _foreground?.complete();
    _foreground = null;
    return super.close();
  }

  Future<void> pauseForBackground() async {
    if (_pausedAt != null) {
      return;
    }
    _pausedAt = _now();
    _foreground = Completer<void>();
    await _save();
  }

  Future<void> resumeFromBackground() async {
    final pausedAt = _pausedAt;
    if (pausedAt == null) {
      return;
    }
    _pausedAt = null;
    _foreground?.complete();
    _foreground = null;
    final startedAt = state.startedAt;
    if (startedAt != null) {
      emit(
        state.copyWith(
          startedAt: StepClock.resume(
            startedAt: startedAt,
            pausedAt: pausedAt,
            now: _now(),
          ),
        ),
      );
    }
    await _save();
  }

  /// O cronômetro do exercício: quanto tempo passou desde que ele abriu (a
  /// tela lê a cada instante e o congela na resposta).
  Duration get elapsed {
    final startedAt = state.startedAt;
    if (startedAt == null) return Duration.zero;
    return StepClock.elapsed(startedAt: startedAt, now: _pausedAt ?? _now());
  }

  final EndgameLessonRepository _lessons;
  final EndgameProgressRepository _progress;
  final CharacterRepository _characters;
  final ExerciseFeedbackRepository? _feedback;
  String _language = 'en';
  int _loadRevision = 0;
  // Ephemeral: a checkpoint resumes play without reviving an old error's text.
  ({String lessonId, String exerciseId, int turn, String fen, String uci})?
  _lastError;

  // Os sons do jogo; nulo: o exercício fica mudo.
  final GameSounds? _sounds;

  // A vibração; nula: sem retorno tátil.
  final GameHaptics? _haptics;

  /// A pausa antes da resposta do outro lado.
  final Duration replyDelay;

  final _said = <String, int>{};

  /// As explicações escritas na aula (variantes e porquês), se há: chegam
  /// depois de abrir e enriquecem a notação.
  Future<void> _loadPayload(int revision) async {
    final feedback = _feedback;
    final lesson = state.lesson;
    final exercise = state.exercise;
    if (feedback == null || lesson == null || exercise == null) return;
    try {
      final payload = await feedback.findExerciseReview(
        lessonId: lesson.id,
        exerciseId: exercise.id,
        language: _language,
      );
      if (isClosed ||
          revision != _loadRevision ||
          payload == null ||
          payload.explanations.isEmpty) {
        return;
      }
      var next = state.copyWith(explanationPayload: payload);
      if (state.phase == ExercisePhase.done) {
        next = next.copyWith(
          review: ExerciseReview.full(
            exercise,
            state.played,
            payload: payload,
            wrongs: state.wrongs,
          ),
        );
      }
      super.emit(next);
    } catch (_) {
      /* A notação segue sem as variantes escritas se o dado faltar. */
    }
  }

  Future<void> load(String lessonId, String exerciseId, String language) async {
    final revision = ++_loadRevision;
    _lastError = null;
    _language = language;
    final trail = await _lessons.trail();
    if (isClosed || revision != _loadRevision) {
      return;
    }
    final lesson = trail.lesson(lessonId);
    final exercise = lesson?.exercise(exerciseId);
    if (lesson == null || exercise == null || exercise.line.isEmpty) {
      if (!isClosed) emit(const ExerciseState(ready: true, missing: true));
      return;
    }
    final texts = await _lessons.texts(language);
    final characters = await _characters.characters();
    final progress = await _progress.load();
    if (isClosed || revision != _loadRevision) {
      return;
    }
    Character? viktor;
    for (final character in characters) {
      if (character.id == LessonCubit.viktorId) viktor = character;
    }
    final each = progress.of(lessonId);
    final index = lesson.exercises.indexOf(exercise);
    String? next;
    for (final other in lesson.exercises.skip(index + 1)) {
      if (!each.stars.containsKey(other.id)) {
        next = other.id;
        break;
      }
    }
    next ??= lesson.exercises
        .where(
          (other) => other != exercise && !each.stars.containsKey(other.id),
        )
        .firstOrNull
        ?.id;
    final saved = each.exercise;
    final resumed = saved != null && saved.exerciseId == exerciseId;
    var opened = ExerciseState(
      ready: true,
      lesson: lesson,
      exercise: exercise,
      texts: texts,
      viktor: viktor,
      fen: exercise.fen,
      emotion: Emotion.focused,
      number: index + 1,
      count: lesson.exercises.length,
      nextExercise: next,
      locked: lesson.exercises.every(
        (other) => each.stars.containsKey(other.id),
      ),
      // Voltando ao exercício, o cronômetro continua de onde estava.
      startedAt: resumed && saved.startedAt != null && saved.pausedAt != null
          ? StepClock.resume(
              startedAt: saved.startedAt!,
              pausedAt: saved.pausedAt!,
              now: _now(),
            )
          : (resumed ? saved.startedAt : null) ?? _now(),
      // O balão abre com o enunciado.
      sayTexts: [?texts.say('${lesson.id}.ex.${exercise.id}')],
    );
    if (resumed) {
      opened = opened.copyWith(
        fen: saved.fen,
        turn: saved.turn,
        mistakes: saved.mistakes,
        hints: saved.hints,
        hintShown: saved.hintTurn == saved.turn,
        played: saved.played,
        wrongs: [for (final wrong in saved.wrongs) ?_parseWrong(wrong)],
        firstMoveMistake: saved.firstMoveMistake,
        phase:
            GameRules.fromFen(saved.fen ?? exercise.fen)?.turn !=
                exercise.step.side
            ? ExercisePhase.waiting
            : ExercisePhase.active,
      );
    }
    emit(opened);
    await _save();
    unawaited(_loadPayload(revision));
    if (state.phase == ExercisePhase.waiting) {
      unawaited(_finishReply(exercise.step));
    }
  }

  static ReviewWrong? _parseWrong(String text) {
    final at = text.indexOf(':');
    final turn = at < 0 ? null : int.tryParse(text.substring(0, at));
    if (turn == null) return null;
    return (
      turn: turn,
      uci: text.substring(at + 1),
      comments: const <String>[],
    );
  }

  /// O aluno moveu uma peça.
  Future<void> play(Move move) async {
    if (!state.interactive) {
      return;
    }
    final exercise = state.exercise!;
    final step = exercise.step;
    final position = _position();
    if (position == null || GameRules.play(position, move) == null) {
      return;
    }
    if (!LessonRules.accepts(step, state.turn, move.uci)) {
      await _wrong(move);
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) {
      return;
    }
    _lastError = null;
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    final turn = step.line[state.turn];
    final ends = LessonRules.endsLine(step, state.turn, move.uci);
    final history = [...state.played, move.uci];
    if (ends) {
      await _solve(played.position.fen, move, history);
      return;
    }
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        played: history,
        clearHint: true,
        clearWrongMove: true,
        phase: turn.reply == null
            ? ExercisePhase.active
            : ExercisePhase.waiting,
        // O porquê do lance, se a aula o escreveu; senão, só "Correto.".
        say: ExerciseSay.correct,
        sayTexts: ExerciseReview.commentFor(
          state.explanationPayload,
          position.fen,
          move.uci,
        ),
        emotion: Emotion.happy,
      ),
    );
    await _save();
    await _finishReply(step);
  }

  /// O lance errado: o tabuleiro treme e o lance volta; o balão diz "Não." e
  /// o porquê, se há. Errar o primeiro lance zera os pontos. O porquê escrito
  /// na aula chega depois, sem segurar o tabuleiro.
  Future<void> _wrong(Move move) async {
    final exercise = state.exercise!;
    final lesson = state.lesson!;
    final fen = state.fen!;
    final turn = state.turn;
    _lastError = (
      lessonId: lesson.id,
      exerciseId: exercise.id,
      turn: turn + 1,
      fen: fen,
      uci: move.uci,
    );
    final why = ExerciseReview.commentFor(
      state.explanationPayload,
      fen,
      move.uci,
    );
    final first = state.played.isEmpty;
    emit(
      state.copyWith(
        mistakes: state.mistakes + 1,
        wrongMove: move,
        wrongs: [
          for (final each in state.wrongs)
            if (!(each.turn == turn && each.uci == move.uci)) each,
          (turn: turn, uci: move.uci, comments: why),
        ],
        firstMoveMistake: state.firstMoveMistake || first,
        say: ExerciseSay.wrong,
        sayTexts: why,
        sayZeroed: first && !state.firstMoveMistake,
        emotion: Emotion.focused,
      ),
    );
    if (why.isEmpty && _feedback != null) {
      explaining = _explainWrong(move, turn, fen);
    }
    await _save();
  }

  /// Termina quando o porquê do último erro já foi buscado (para os testes).
  Future<void>? explaining;

  Future<void> _explainWrong(Move move, int turn, String fen) async {
    final revision = _loadRevision;
    try {
      final found = await _feedback!.find(
        lessonId: state.lesson!.id,
        exerciseId: state.exercise!.id,
        kind: 'exercise',
        turn: turn + 1,
        fen: fen,
        uci: move.uci,
        language: _language,
      );
      if (found == null ||
          found.isEmpty ||
          isClosed ||
          revision != _loadRevision ||
          !state.interactive ||
          state.fen != fen ||
          state.say != ExerciseSay.wrong ||
          state.wrongMove != move) {
        return;
      }
      emit(
        state.copyWith(
          say: ExerciseSay.wrong,
          sayTexts: [found],
          sayZeroed: state.sayZeroed,
          wrongs: [
            for (final each in state.wrongs)
              if (each.turn == turn && each.uci == move.uci)
                (turn: turn, uci: move.uci, comments: [found])
              else
                each,
          ],
        ),
      );
    } catch (_) {
      /* Sem o porquê escrito, o balão diz só que não. */
    }
  }

  Future<void> _finishReply(MoveStep step) async {
    final position = _position();
    if (position == null || state.turn >= step.line.length) {
      return;
    }
    final turn = step.line[state.turn];
    final reply = Move.parse(turn.reply ?? '');
    var after = position;
    final fen = state.fen;
    if (reply != null) {
      await Future<void>.delayed(replyDelay);
      await _waitForForeground();
      if (isClosed || _closing || state.fen != fen) {
        return;
      }
      final answered = GameRules.play(after, reply);
      if (answered == null) {
        // A resposta combinada não cabe no tabuleiro (aula com dado
        // inconsistente): a linha acaba aqui, com o exercício resolvido.
        await _solve(after.fen, state.lastMove, state.played);
        return;
      }
      unawaited(_sounds?.move(answered.san));
      after = answered.position;
    }
    emit(
      state.copyWith(
        fen: after.fen,
        lastMove: reply ?? state.lastMove,
        turn: state.turn + 1,
        played: reply == null ? null : [...state.played, reply.uci],
        phase: ExercisePhase.active,
      ),
    );
    await _save();
  }

  /// A dica: a fala conceitual da aula. Custa um ponto (só a primeira vez em
  /// cada vez do aluno).
  Future<void> askHint() async {
    if (!state.interactive) {
      return;
    }
    final error = _lastError;
    final revision = _loadRevision;
    final fen = state.fen;
    final turn = state.turn;
    String? feedback;
    if (error != null && _feedback != null) {
      try {
        feedback = await _feedback.find(
          lessonId: error.lessonId,
          exerciseId: error.exerciseId,
          kind: 'exercise',
          turn: error.turn,
          fen: error.fen,
          uci: error.uci,
          language: _language,
        );
      } catch (_) {
        // Existing conceptual hint stays available if optional data fails.
      }
    }
    if (isClosed ||
        revision != _loadRevision ||
        !state.interactive ||
        fen != state.fen ||
        turn != state.turn ||
        error != _lastError) {
      return;
    }
    emit(
      state.copyWith(
        clearHint: true,
        hintShown: true,
        clearWrongMove: true,
        hints: !state.hintShown ? state.hints + 1 : state.hints,
        // A ajuda traz o enunciado e a pista, sem antecipar o lance.
        say: ExerciseSay.hint,
        sayTexts: [
          ?_statement(),
          ?(feedback ?? _hintText() ?? _pick('coach.hint')),
        ],
        emotion: Emotion.focused,
      ),
    );
    await _save();
  }

  /// "Ver solução": joga a linha até o fim, com 0 pontos. O aluno vê a
  /// notação completa e o balão comenta o último lance.
  Future<void> showSolution() async {
    if (!state.interactive) {
      return;
    }
    final exercise = state.exercise!;
    var position = _position();
    if (position == null) return;
    final history = [...state.played];
    Move? last = state.lastMove;
    for (final uci in ExerciseReview.remaining(exercise, state.played)) {
      final move = Move.parse(uci);
      final result = move == null ? null : GameRules.play(position!, move);
      if (result == null) break;
      position = result.position;
      history.add(uci);
      last = move;
    }
    await _finish(
      fen: position!.fen,
      lastMove: last,
      history: history,
      earned: 0,
      solutionShown: true,
    );
  }

  /// Sair pelo voltar: o exercício fica guardado onde parou.
  Future<void> leave() async {
    if (state.phase == ExercisePhase.done) {
      return;
    }
    await _save(open: false);
  }

  Future<void> _solve(String fen, Move? move, List<String> history) async {
    _lastError = null;
    unawaited(_haptics?.play(HapticEvent.success));
    final exercise = state.exercise!;
    await _finish(
      fen: fen,
      lastMove: move,
      history: history,
      earned: EndgameLessonRules.earned(
        exercise.stars,
        mistakes: state.mistakes,
        hints: state.hints,
        firstMoveMistake: state.firstMoveMistake,
      ),
    );
  }

  /// Fecha o exercício: grava os pontos, monta a notação completa e põe o
  /// balão no último lance.
  Future<void> _finish({
    required String fen,
    required Move? lastMove,
    required List<String> history,
    required int earned,
    bool solutionShown = false,
  }) async {
    final lesson = state.lesson!;
    final exercise = state.exercise!;
    // Com a nota fechada, o treino não grava nada.
    if (!state.locked) {
      final all = await _progress.load();
      final each = all.of(lesson.id);
      await _progress.save(
        all.withLesson(
          lesson.id,
          each.copyWith(
            stars: {...each.stars, exercise.id: earned},
            clearExercise: true,
          ),
        ),
      );
    }
    if (isClosed) {
      return;
    }
    final review = ExerciseReview.full(
      exercise,
      history,
      payload: state.explanationPayload,
      wrongs: state.wrongs,
    );
    final cursor = review.where((node) => node.depth == 0).lastOrNull;
    final corrected =
        state.mistakes > 0 ||
        state.hints > 0 ||
        state.firstMoveMistake ||
        solutionShown;
    emit(
      state.copyWith(
        fen: fen,
        lastMove: lastMove,
        turn: state.turn + 1,
        played: history,
        clearHint: true,
        clearWrongMove: true,
        phase: ExercisePhase.done,
        earned: earned,
        solutionShown: solutionShown,
        review: review,
        cursorId: cursor?.id,
        seen: {
          ?cursor?.id,
          // O que o aluno jogou ou viu no tabuleiro conta como visto; só as
          // variantes e o que a solução mostrou depois ficam por ver.
          for (final node
              in review
                  .where((node) => node.depth == 0)
                  .take(solutionShown ? state.played.length : history.length))
            node.id,
        },
        browsed: 0,
        say: solutionShown ? ExerciseSay.node : ExerciseSay.solved,
        sayNode: cursor,
        sayTexts: cursor == null ? const [] : _nodeTexts(cursor, review),
        sayZeroed: corrected,
        emotion: earned == exercise.stars ? Emotion.happy : Emotion.calm,
      ),
    );
  }

  /// O que o Viktor diz de um lance: o que a aula escreveu dele; no último
  /// da linha principal, a solução escrita.
  List<String> _nodeTexts(ReviewNode node, List<ReviewNode> review) {
    if (node.comments.isNotEmpty) return node.comments;
    final main = review.where((each) => each.depth == 0).lastOrNull;
    final solution = state.explanation;
    if (main != null && main.id == node.id && solution != null) {
      return [solution];
    }
    return const [];
  }

  /// O aluno foi a um lance da notação (depois de acabar): o tabuleiro vai à
  /// posição e o balão comenta o lance. Com o borrar ligado ([hide]), um
  /// lance coberto revela UM lance: o primeiro ainda não visto no caminho.
  void goToReview(String id, {bool hide = false}) {
    if (state.phase != ExercisePhase.done) return;
    final byId = {for (final node in state.review) node.id: node};
    var target = byId[id];
    if (target == null) return;
    if (hide && !state.seen.contains(id)) {
      while (target!.previousId != null) {
        final before = byId[target.previousId];
        if (before == null || state.seen.contains(before.id)) break;
        target = before;
      }
    }
    final node = target;
    emit(
      state.copyWith(
        fen: node.fenAfter,
        lastMove: Move.parse(node.uci),
        cursorId: node.id,
        seen: {...state.seen, node.id},
        say: ExerciseSay.node,
        sayNode: node,
        sayTexts: _nodeTexts(node, state.review),
        browsed: state.browsed + 1,
        clearWrongMove: true,
      ),
    );
  }

  Future<void> _save({bool open = true}) async {
    final lesson = state.lesson;
    final exercise = state.exercise;
    if (lesson == null || exercise == null) {
      return;
    }
    if (state.phase == ExercisePhase.done || state.locked) {
      return;
    }
    final all = await _progress.load();
    await _progress.save(
      all.withLesson(
        lesson.id,
        all
            .of(lesson.id)
            .copyWith(
              exercise: ExerciseCheckpoint(
                exerciseId: exercise.id,
                fen: state.fen,
                turn: state.turn,
                mistakes: state.mistakes,
                hints: state.hints,
                hintTurn: state.hintShown ? state.turn : null,
                open: open,
                startedAt: state.startedAt,
                pausedAt: _pausedAt,
                played: state.played,
                wrongs: [
                  for (final wrong in state.wrongs)
                    '${wrong.turn}:${wrong.uci}',
                ],
                firstMoveMistake: state.firstMoveMistake,
              ),
            ),
      ),
    );
  }

  Position? _position() {
    final fen = state.fen;
    return fen == null ? null : GameRules.fromFen(fen);
  }

  String? _statement() =>
      state.texts.say('${state.lesson!.id}.ex.${state.exercise!.id}');

  String? _hintText() =>
      state.texts.say('${state.lesson!.id}.ex.${state.exercise!.id}.hint');

  String? _pick(String key) {
    final index = _said[key] ?? 0;
    _said[key] = index + 1;
    return state.texts.say(key, index);
  }
}
