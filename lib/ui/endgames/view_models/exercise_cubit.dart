import 'dart:async';
import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/endgames/exercise_feedback_repository.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/haptic_event.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/wdl.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/exercise_judge.dart';
import '../../../domain/use_cases/exercise_review.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/step_clock.dart';
import '../../core/sound/game_haptics.dart';
import '../../core/sound/game_sounds.dart';
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
    this.exerciseJudge,
    this.opponent,
    this.opponentTimeout = const Duration(seconds: 10),
    this._now = const SystemNow(),
    this.replyDelay = const Duration(milliseconds: 450),
  }) : super(const ExerciseState());

  final Now _now;
  final ExerciseJudge? exerciseJudge;
  final OpponentRepository? opponent;
  final Duration opponentTimeout;
  Future<void>? _writes;
  Future<void>? _closeFuture;
  ({int revision, String lessonId, Exercise exercise})? _stateOwner;
  int? _mateBusyRevision;
  bool get _mate => state.exercise?.completion == ExerciseCompletion.checkmate;

  bool _current(int revision) =>
      !isClosed &&
      !_closing &&
      revision == _loadRevision &&
      _stateOwner?.revision == revision &&
      _stateOwner?.lessonId == state.lesson?.id &&
      identical(_stateOwner?.exercise, state.exercise);

  Future<bool> _foregroundCurrent(int revision) async {
    if (!_current(revision)) return false;
    final changed = _revisionChanged.future;
    while (_pausedAt != null && _current(revision)) {
      final foreground = _foreground;
      if (foreground == null) return false;
      await Future.any([foreground.future, changed]);
    }
    return _current(revision);
  }

  // Only one evaluation/help/reply can own a mate attempt at a time.
  Future<void> _mateOperation(Future<void> Function(int) action) async {
    final revision = _loadRevision;
    if (_mateBusyRevision == revision || !_current(revision)) return;
    _mateBusyRevision = revision;
    try {
      if (_pausedAt == null) {
        await action(revision);
      } else if (await _foregroundCurrent(revision)) {
        await action(revision);
      }
    } finally {
      if (_mateBusyRevision == revision) _mateBusyRevision = null;
    }
  }

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
  Future<void> close() => _closeFuture ??= _closeAndDrain(() => super.close());

  Future<void> _closeAndDrain(Future<void> Function() completeClose) async {
    // Drain captured writes without reopening a left or completed attempt.
    _closing = true;
    _revisionChanged.complete();
    _foreground?.complete();
    _foreground = null;
    await _writes;
    await completeClose();
  }

  Future<void> pauseForBackground() async {
    if (_pausedAt != null || _closing || isClosed) {
      return;
    }
    _pausedAt = _now();
    _foreground = Completer<void>();
    await _save();
  }

  Future<void> resumeFromBackground() async {
    if (_closing || isClosed) return;
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
  Completer<void> _revisionChanged = Completer<void>();

  int _invalidateRevision() {
    _revisionChanged.complete();
    _revisionChanged = Completer<void>();
    return ++_loadRevision;
  }

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
      if (!_current(revision) ||
          payload == null ||
          payload.explanations.isEmpty) {
        return;
      }
      var next = state.copyWith(explanationPayload: payload);
      if (state.phase == ExercisePhase.done) {
        final review = ExerciseReview.full(
          exercise,
          state.played,
          payload: payload,
          wrongs: state.wrongs,
        );
        next = next.copyWith(
          review: review,
          // O erro do aluno segue à vista, mesmo se a aula já o previa.
          seen: {
            ...state.seen,
            ...ExerciseReview.wrongNodeIds(review, state.wrongs),
          },
        );
      }
      super.emit(next);
    } catch (_) {
      /* A notação segue sem as variantes escritas se o dado faltar. */
    }
  }

  Future<void> load(String lessonId, String exerciseId, String language) async {
    if (_closing || isClosed) return;
    final revision = _invalidateRevision();
    _stateOwner = null;
    emit(const ExerciseState());
    _lastError = null;
    _language = language;
    final trail = await _lessons.trail();
    if (isClosed || _closing || revision != _loadRevision) {
      return;
    }
    final lesson = trail.lesson(lessonId);
    final exercise = lesson?.exercise(exerciseId);
    if (lesson == null ||
        exercise == null ||
        (exercise.line.isEmpty &&
            exercise.completion != ExerciseCompletion.checkmate)) {
      if (!isClosed) emit(const ExerciseState(ready: true, missing: true));
      return;
    }
    final texts = await _lessons.texts(language);
    final characters = await _characters.characters();
    await _writes;
    final progress = await _progress.load();
    if (isClosed || _closing || revision != _loadRevision) {
      return;
    }
    Character? viktor;
    for (final character in characters) {
      if (character.id == Character.masterId) viktor = character;
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
        solutionShown: saved.solutionShown,
        phase:
            GameRules.fromFen(saved.fen ?? exercise.fen)?.turn !=
                exercise.step.side
            ? ExercisePhase.waiting
            : ExercisePhase.active,
      );
    }
    if (exercise.completion == ExerciseCompletion.checkmate) {
      final root = ExerciseJudge.exactPosition(exercise.fen);
      final replay = resumed ? _replayCheckpoint(exercise, saved) : root;
      if (root == null ||
          replay == null ||
          exerciseJudge == null ||
          opponent == null) {
        _stateOwner = (
          revision: revision,
          lessonId: lesson.id,
          exercise: exercise,
        );
        emit(
          opened.copyWith(
            technicalFailure: replay == null
                ? 'invalidCheckpoint'
                : 'evaluationUnavailable',
          ),
        );
        return;
      }
      opened = opened.copyWith(
        fen: replay.fen,
        turn: opened.played.length ~/ 2,
        phase: replay.turn == root.turn
            ? ExercisePhase.active
            : ExercisePhase.waiting,
      );
      if (GameRules.endOf(
            replay,
            repetitions: GameRules.repetitionsOf(root, opened.played),
          ) !=
          null) {
        _stateOwner = (
          revision: revision,
          lessonId: lesson.id,
          exercise: exercise,
        );
        emit(opened.copyWith(technicalFailure: 'terminalCheckpoint'));
        return;
      }
    }
    _stateOwner = (revision: revision, lessonId: lesson.id, exercise: exercise);
    emit(opened);
    await _save();
    if (!_current(revision)) return;
    unawaited(_loadPayload(revision));
    if (state.phase == ExercisePhase.waiting) {
      if (_mate) {
        unawaited(_mateOperation(_finishMateReply));
      } else {
        unawaited(_finishReply(exercise.step));
      }
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

  static String _contractIdentity(Exercise exercise) => jsonEncode({
    'id': exercise.id,
    'fen': exercise.fen,
    'completion': exercise.completion.name,
    'goal': exercise.goal.name,
    'stars': exercise.stars,
    'line': [
      for (final turn in exercise.line)
        {'accept': turn.accept.toList(), 'reply': turn.reply},
    ],
  });

  static Position? _replayCheckpoint(
    Exercise exercise,
    ExerciseCheckpoint saved,
  ) {
    if (saved.contractVersion != 1 ||
        saved.contractIdentity != _contractIdentity(exercise) ||
        saved.turn != saved.played.length ~/ 2 ||
        saved.mistakes < 0 ||
        saved.hints < 0) {
      return null;
    }
    var position = ExerciseJudge.exactPosition(exercise.fen);
    if (position == null) return null;
    final root = position;
    final prefix = <String>[];
    for (final uci in saved.played) {
      if (GameRules.endOf(
            position!,
            repetitions: GameRules.repetitionsOf(root, prefix),
          ) !=
          null) {
        return null;
      }
      final move = Move.parse(uci);
      final next = move == null ? null : GameRules.play(position, move);
      if (next == null) return null;
      prefix.add(uci);
      position = next.position;
    }
    return position!.fen == saved.fen ? position : null;
  }

  void _mateUnavailable(String reason) {
    emit(state.copyWith(technicalFailure: reason));
  }

  Future<ExerciseJudgement> _judge(String fen, List<String> played) async {
    final judge = exerciseJudge;
    if (judge == null) return const ExerciseIndeterminate('judgeUnavailable');
    try {
      return await judge.evaluate(
        ExerciseJudgeRequest(
          initialFen: state.exercise!.fen,
          fen: fen,
          student: state.side,
          played: played,
          historyComplete: true,
        ),
      );
    } on Object {
      return const ExerciseIndeterminate('judgeUnavailable');
    }
  }

  Future<void> _playMate(Move move, int revision) async {
    if (!state.interactive) return;
    final position = _position();
    if (position == null || position.turn != state.side) return;
    final played = GameRules.play(position, move);
    if (played == null) return;
    final history = [...state.played, move.uci];
    final judged = await _judge(played.position.fen, history);
    if (!await _foregroundCurrent(revision)) return;
    if (judged is! ExerciseKnown) {
      _mateUnavailable(
        judged is ExerciseIndeterminate ? judged.reason : 'unknownEvaluation',
      );
      return;
    }
    if (judged.wdl != Wdl.win) {
      await _wrong(move);
      return;
    }
    if (_studentMate(played.position, history)) {
      await _solve(played.position.fen, move, history);
      return;
    }
    // A proven win is allowed even outside every authored variation.
    _lastError = null;
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        played: history,
        turn: history.length ~/ 2,
        phase: ExercisePhase.waiting,
        clearHint: true,
        clearWrongMove: true,
        say: ExerciseSay.correct,
        sayMove: (fenBefore: position.fen, uci: move.uci),
        sayTexts: ExerciseReview.commentFor(
          state.explanationPayload,
          position.fen,
          move.uci,
        ),
        emotion: Emotion.happy,
      ),
    );
    await _save();
    if (!await _foregroundCurrent(revision)) return;
    await _finishMateReply(revision);
  }

  bool _studentMate(Position position, List<String> history) {
    final root = ExerciseJudge.exactPosition(state.exercise!.fen);
    if (root == null) return false;
    var replay = root;
    final prefix = <String>[];
    for (final uci in history) {
      if (GameRules.endOf(
            replay,
            repetitions: GameRules.repetitionsOf(root, prefix),
          ) !=
          null) {
        return false;
      }
      final move = Move.parse(uci);
      final next = move == null ? null : GameRules.play(replay, move);
      if (next == null) return false;
      replay = next.position;
      prefix.add(uci);
    }
    if (replay.fen != position.fen) return false;
    final end = GameRules.endOf(
      position,
      repetitions: GameRules.repetitionsOf(root, history),
    );
    return end?.reason == GameEndReason.checkmate && end?.winner == root.turn;
  }

  // Only the exact primary PV prefix authorizes its registered reply.
  String? _registeredMateReply() {
    final exercise = state.exercise!;
    final pv = <String>[];
    for (final turn in exercise.line) {
      if (turn.accept.isEmpty) return null;
      pv.add(turn.accept.first);
      if (state.played.length == pv.length) {
        for (var i = 0; i < pv.length; i++) {
          if (state.played[i] != pv[i]) return null;
        }
        return turn.reply;
      }
      // No registered opponent move means this primary variation ends here.
      if (turn.reply == null) return null;
      pv.add(turn.reply!);
    }
    return null;
  }

  List<Position> _mateHistory() {
    var position = GameRules.fromFen(state.exercise!.fen)!;
    final history = [position];
    for (final uci in state.played) {
      position = GameRules.play(position, Move.parse(uci)!)!.position;
      history.add(position);
    }
    return history;
  }

  Future<void> _finishMateReply(int revision) async {
    if (!await _foregroundCurrent(revision) ||
        state.phase != ExercisePhase.waiting ||
        state.technicalFailure != null) {
      return;
    }
    final position = _position();
    if (position == null || position.turn == state.side) {
      _mateUnavailable('invalidReplyPosition');
      return;
    }
    if (GameRules.endOf(
          position,
          repetitions: GameRules.repetitionsOf(
            GameRules.fromFen(state.exercise!.fen)!,
            state.played,
          ),
        ) !=
        null) {
      _mateUnavailable('unexpectedTerminal');
      return;
    }
    final registered = _registeredMateReply();
    Move? reply = registered == null ? null : Move.parse(registered);
    // An invalid authored reply is a content failure, never an invented move.
    if (registered != null &&
        (reply == null || GameRules.play(position, reply) == null)) {
      _mateUnavailable('illegalRegisteredReply');
      return;
    }
    try {
      await Future<void>.delayed(replyDelay);
      if (!await _foregroundCurrent(revision)) return;
      if (registered == null) {
        final port = opponent;
        if (port == null) {
          _mateUnavailable('opponentUnavailable');
          return;
        }
        reply = await port
            .pickMove(
              position,
              thinkTime: const Duration(seconds: 1),
              history: _mateHistory(),
            )
            .timeout(opponentTimeout);
      }
    } on Object {
      if (await _foregroundCurrent(revision)) {
        _mateUnavailable('opponentUnavailable');
      }
      return;
    }
    if (!await _foregroundCurrent(revision)) return;
    final answered = reply == null ? null : GameRules.play(position, reply);
    if (answered == null) {
      _mateUnavailable('illegalOrMissingReply');
      return;
    }
    final history = [...state.played, reply!.uci];
    emit(
      state.copyWith(
        fen: answered.position.fen,
        lastMove: reply,
        played: history,
        turn: history.length ~/ 2,
        phase: ExercisePhase.active,
      ),
    );
    await _save();
    if (!await _foregroundCurrent(revision)) return;
    final end = GameRules.endOf(
      answered.position,
      repetitions: GameRules.repetitionsOf(
        GameRules.fromFen(state.exercise!.fen)!,
        history,
      ),
    );
    if (end != null) _mateUnavailable('unexpectedOpponentTerminal');
  }

  /// O aluno moveu uma peça.
  Future<void> play(Move move) async {
    if (!_current(_loadRevision)) return;
    if (_mate) {
      if (!state.interactive) return;
      return _mateOperation((revision) => _playMate(move, revision));
    }
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
        // O porquê do lance, se a aula o escreveu; senão, a tela diz o lance
        // com a frase gerada.
        say: ExerciseSay.correct,
        sayMove: (fenBefore: position.fen, uci: move.uci),
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
        sayMove: (fenBefore: fen, uci: move.uci),
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
          ExerciseReview.hasNotation(found) ||
          !_current(revision) ||
          !state.interactive ||
          state.fen != fen ||
          state.say != ExerciseSay.wrong ||
          state.wrongMove != move) {
        return;
      }
      emit(
        state.copyWith(
          say: ExerciseSay.wrong,
          sayMove: state.sayMove,
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
    final revision = _loadRevision;
    final position = _position();
    if (position == null || state.turn >= step.line.length) {
      return;
    }
    final turn = step.line[state.turn];
    final reply = Move.parse(turn.reply ?? '');
    if (turn.reply != null && reply == null) {
      _replyUnavailable();
      return;
    }
    var after = position;
    final fen = state.fen;
    if (reply != null) {
      await Future<void>.delayed(replyDelay);
      await _waitForForeground();
      if (!_current(revision) || state.fen != fen) {
        return;
      }
      final answered = GameRules.play(after, reply);
      if (answered == null) {
        _replyUnavailable();
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

  // Dado inconsistente: indisponibiliza o exercício sem concluir nem
  // alterar o checkpoint já salvo antes da resposta. A retomada pode
  // tentar a resposta novamente após a correção do conteúdo.
  void _replyUnavailable() {
    emit(
      ExerciseState(
        ready: true,
        missing: true,
        lesson: state.lesson,
        exercise: state.exercise,
        texts: state.texts,
        viktor: state.viktor,
        fen: state.fen,
        lastMove: state.lastMove,
        turn: state.turn,
        mistakes: state.mistakes,
        hints: state.hints,
        hintShown: state.hintShown,
        phase: ExercisePhase.waiting,
        locked: state.locked,
        number: state.number,
        count: state.count,
        nextExercise: state.nextExercise,
        startedAt: state.startedAt,
        played: state.played,
        wrongs: state.wrongs,
        firstMoveMistake: state.firstMoveMistake,
        solutionShown: state.solutionShown,
      ),
    );
  }

  /// A dica: a fala conceitual da aula. Custa um ponto (só a primeira vez em
  /// cada vez do aluno).
  Future<void> askHint() async {
    if (!_current(_loadRevision)) return;
    if (_mate) {
      if (!state.interactive) return;
      return _mateOperation((_) => _askHint());
    }
    return _askHint();
  }

  Future<void> _askHint() async {
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
    // O balão nunca mostra notação: o porquê com lances escritos fica de fora.
    if (feedback != null && ExerciseReview.hasNotation(feedback)) {
      feedback = null;
    }
    if (_mate && !await _foregroundCurrent(revision)) return;
    if (!_current(revision) ||
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
        // A pista primeiro, para aparecer no balão cortado em 2 linhas; o
        // enunciado fica depois, visível na folha.
        sayTexts: [
          ?(feedback ?? _hintText() ?? _pick('coach.hint')),
          ?_statement(),
        ],
        emotion: Emotion.focused,
      ),
    );
    await _save();
  }

  /// "Ver solução": joga a linha até o fim, com 0 pontos. O aluno vê a
  /// notação completa e o balão comenta o último lance.
  Future<void> showSolution({bool hidden = false}) async {
    if (!_current(_loadRevision)) return;
    if (_mate) {
      if (!state.interactive) return;
      return _mateOperation(
        (revision) => _showMateSolution(revision, hidden: hidden),
      );
    }
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
      hidden: hidden,
    );
  }

  Future<void> _showMateSolution(int revision, {required bool hidden}) async {
    if (!state.interactive) return;
    // Assistance is durable before reading/playing any solution moves.
    emit(state.copyWith(solutionShown: true));
    await _save();
    if (!await _foregroundCurrent(revision)) return;
    final exercise = state.exercise!;
    var position = _position()!;
    final history = [...state.played];
    Move? last = state.lastMove;
    for (final uci in ExerciseReview.remaining(exercise, state.played)) {
      if (GameRules.endOf(
            position,
            repetitions: GameRules.repetitionsOf(
              GameRules.fromFen(exercise.fen)!,
              history,
            ),
          ) !=
          null) {
        break;
      }
      final move = Move.parse(uci);
      final next = move == null ? null : GameRules.play(position, move);
      if (next == null) break;
      position = next.position;
      history.add(uci);
      last = move;
    }
    if (_studentMate(position, history)) {
      await _finish(
        fen: position.fen,
        lastMove: last,
        history: history,
        earned: 0,
        solutionShown: true,
        hidden: hidden,
      );
      return;
    }
    emit(
      state.copyWith(
        fen: position.fen,
        lastMove: last,
        played: history,
        turn: history.length ~/ 2,
        phase: position.turn == state.side
            ? ExercisePhase.active
            : ExercisePhase.waiting,
        clearHint: true,
      ),
    );
    await _save();
    if (await _foregroundCurrent(revision)) {
      _mateUnavailable('incompleteSolution');
    }
  }

  /// Sair pelo voltar: o exercício fica guardado onde parou.
  Future<void> leave() async {
    if (_closing || isClosed) return;
    if (state.phase == ExercisePhase.done) {
      return;
    }
    if (_mate) {
      final revision = _invalidateRevision();
      _stateOwner = (
        revision: revision,
        lessonId: state.lesson!.id,
        exercise: state.exercise!,
      );
    }
    if (state.technicalFailure != null) {
      final lesson = state.lesson;
      final exercise = state.exercise;
      if (lesson == null || exercise == null) return;
      // Preserve the last stored attempt, including invalid data for diagnosis;
      // only stop automatic reopening after the learner explicitly leaves.
      await _write(() async {
        final all = await _progress.load();
        final each = all.of(lesson.id);
        final saved = each.exercise;
        if (saved == null || saved.exerciseId != exercise.id) return;
        final closed = ExerciseCheckpoint.fromJson({
          ...saved.toJson(),
          'open': false,
        })!;
        await _progress.save(
          all.withLesson(lesson.id, each.copyWith(exercise: closed)),
        );
      });
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
      solutionShown: state.solutionShown,
      earned: state.solutionShown
          ? 0
          : EndgameLessonRules.earned(
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
    bool hidden = false,
  }) async {
    final revision = _loadRevision;
    final lesson = state.lesson!;
    final exercise = state.exercise!;
    if (_mate) {
      final terminal = GameRules.fromFen(fen);
      if (terminal == null || !_studentMate(terminal, history)) {
        _mateUnavailable('completionWithoutStudentMate');
        return;
      }
      solutionShown = solutionShown || state.solutionShown;
      if (solutionShown) earned = 0;
    }
    // Com a nota fechada, o treino não grava nada.
    if (!state.locked) {
      await _write(() async {
        if (!_current(revision)) return;
        final all = await _progress.load();
        if (!await _foregroundCurrent(revision)) return;
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
      });
    }
    if (!_current(revision)) {
      return;
    }
    final review = ExerciseReview.full(
      exercise,
      history,
      payload: state.explanationPayload,
      wrongs: state.wrongs,
    );
    final main = review.where((node) => node.depth == 0).toList();
    final wrongIds = ExerciseReview.wrongNodeIds(review, state.wrongs);
    // Onde a lista para: o erro do aluno, se houve; depois de "Ver solução",
    // a posição final (com o borrar ligado, o 1º lance que ela mostrou); senão
    // o lance-chave, o primeiro lance do aluno (canvas PropV2ExA4/5/9/10).
    ReviewNode? cursor;
    if (solutionShown) {
      cursor = hidden && main.isNotEmpty
          ? main[state.played.length.clamp(0, main.length - 1)]
          : main.lastOrNull;
    } else if (wrongIds.isNotEmpty) {
      cursor = review.firstWhere((node) => node.id == wrongIds.first);
    } else {
      cursor = main.firstOrNull;
    }
    final corrected =
        state.mistakes > 0 ||
        state.hints > 0 ||
        state.firstMoveMistake ||
        solutionShown;
    emit(
      state.copyWith(
        fen: cursor?.fenAfter ?? fen,
        lastMove: cursor == null ? lastMove : Move.parse(cursor.uci),
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
          // O que o aluno jogou ou viu no tabuleiro conta como visto, e o
          // lance errado dele também (mesmo sendo uma variante prevista); só
          // as outras variantes e o que a solução mostrou ficam por ver.
          for (final node in main.take(
            solutionShown ? state.played.length : history.length,
          ))
            node.id,
          ...wrongIds,
        },
        browsed: 0,
        say: solutionShown ? ExerciseSay.node : ExerciseSay.solved,
        sayNode: cursor,
        sayTexts: cursor?.comments ?? const [],
        sayZeroed: corrected,
        emotion: earned == exercise.stars ? Emotion.happy : Emotion.calm,
      ),
    );
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
        sayTexts: node.comments,
        browsed: state.browsed + 1,
        clearWrongMove: true,
      ),
    );
  }

  Future<void> _save({bool open = true}) async {
    final snapshot = state;
    final revision = _loadRevision;
    final pausedAt = _pausedAt;
    final lesson = snapshot.lesson;
    final exercise = snapshot.exercise;
    if (lesson == null || exercise == null || !_current(revision)) {
      return;
    }
    if (snapshot.phase == ExercisePhase.done ||
        snapshot.locked ||
        snapshot.technicalFailure != null) {
      return;
    }
    // A captured checkpoint is a committed UI change. Its write survives
    // cancellation/close; the next load drains the queue before reading it.
    await _write(() async {
      final all = await _progress.load();
      await _progress.save(
        all.withLesson(
          lesson.id,
          all
              .of(lesson.id)
              .copyWith(
                exercise: ExerciseCheckpoint(
                  exerciseId: exercise.id,
                  fen: snapshot.fen,
                  turn: snapshot.turn,
                  mistakes: snapshot.mistakes,
                  hints: snapshot.hints,
                  hintTurn: snapshot.hintShown ? snapshot.turn : null,
                  open: open,
                  startedAt: snapshot.startedAt,
                  pausedAt: pausedAt,
                  played: snapshot.played,
                  wrongs: [
                    for (final wrong in snapshot.wrongs)
                      '${wrong.turn}:${wrong.uci}',
                  ],
                  firstMoveMistake: snapshot.firstMoveMistake,
                  solutionShown: snapshot.solutionShown,
                  contractVersion:
                      exercise.completion == ExerciseCompletion.checkmate
                      ? 1
                      : null,
                  contractIdentity:
                      exercise.completion == ExerciseCompletion.checkmate
                      ? _contractIdentity(exercise)
                      : null,
                ),
              ),
        ),
      );
    });
  }

  Future<void> _write(Future<void> Function() action) {
    final previous = _writes;
    final next = previous == null
        ? Future<void>.sync(action)
        : previous.then((_) => action());
    late final Future<void> drained;
    void release() {
      if (identical(_writes, drained)) _writes = null;
    }

    drained = next.then<void>(
      (_) => release(),
      onError: (Object _, StackTrace _) => release(),
    );
    _writes = drained;
    return next;
  }

  Position? _position() {
    final fen = state.fen;
    return fen == null ? null : GameRules.fromFen(fen);
  }

  String? _statement() =>
      state.texts.say('${state.lesson!.id}.ex.${state.exercise!.id}');

  String? _hintText() => ExerciseReview.plainParagraphs(
    state.texts.say('${state.lesson!.id}.ex.${state.exercise!.id}.hint'),
  );

  String? _pick(String key) {
    final index = _said[key] ?? 0;
    _said[key] = index + 1;
    return state.texts.say(key, index);
  }
}
