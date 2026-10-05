import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';

/// Em que pé está o passo aberto.
enum StepPhase {
  /// O aluno lê (fala) ou joga (estrelas, lance, jogar).
  active,

  /// A máquina está respondendo.
  waiting,

  /// Cumprido: o botão leva ao próximo passo.
  done,

  /// Num passo de jogar, a posição acabou sem o objetivo (afogamento, empate
  /// ou mate no aluno): o botão tenta de novo.
  failed,
}

class LessonState {
  const LessonState({
    this.ready = false,
    this.missing = false,
    this.lesson,
    this.texts = LessonTexts.empty,
    this.viktor,
    this.step = 0,
    this.fen,
    this.lastMove,
    this.collected = const [],
    this.turn = 0,
    this.moves = const [],
    this.phase = StepPhase.active,
    this.speech,
    this.emotion = Emotion.calm,
    this.hint,
    this.result,
    this.finished = false,
    this.courseFinished = false,
    this.lessonNumber = 0,
    this.lessonCount = 0,
    this.mistakes = 0,
    this.nextLesson,
  });

  final bool ready;

  /// A aula pedida não existe no curso.
  final bool missing;
  final Lesson? lesson;
  final LessonTexts texts;

  /// O professor. Nulo só se a ficha dele faltar.
  final Character? viktor;

  /// O índice do passo aberto.
  final int step;

  /// O tabuleiro agora. Nulo num passo sem tabuleiro.
  final String? fen;
  final Move? lastMove;

  /// As estrelas já pegas no passo.
  final List<String> collected;

  /// A vez do aluno num passo de lance.
  final int turn;

  /// Os lances do passo de jogar, em UCI.
  final List<String> moves;
  final StepPhase phase;

  /// O que o Viktor está dizendo.
  final String? speech;
  final Emotion emotion;

  /// O lance que o mestre sugere (seta no tabuleiro).
  final Move? hint;

  /// Como acabou o passo de jogar.
  final PlayResult? result;

  /// A aula terminou: aparece o cartão de fim.
  final bool finished;

  /// Era a última aula do curso: a formatura.
  final bool courseFinished;

  /// A posição da aula no curso (1 é a primeira) e quantas há.
  final int lessonNumber;
  final int lessonCount;

  /// Lances errados no passo aberto (a tela sacode o tabuleiro a cada um).
  final int mistakes;

  /// Com a aula terminada, a próxima da trilha. Nula na última.
  final String? nextLesson;

  LessonStep? get current {
    final steps = lesson?.steps;
    if (steps == null || step >= steps.length) return null;
    return steps[step];
  }

  int get stepCount => lesson?.steps.length ?? 0;

  /// Quanto da aula já foi feito, de 0 a 1 (o passo cumprido conta inteiro).
  double get progress {
    if (stepCount == 0) return 0;
    if (finished) return 1;
    final done = phase == StepPhase.done ? step + 1 : step;
    return done / stepCount;
  }

  /// O aluno pode mexer no tabuleiro.
  bool get interactive =>
      phase == StepPhase.active && current is! TalkStep && current != null;

  /// As estrelas que faltam.
  List<String> get stars => switch (current) {
    StarsStep(:final stars) => [
      for (final star in stars)
        if (!collected.contains(star)) star,
    ],
    _ => const [],
  };

  LessonState copyWith({
    bool? ready,
    bool? missing,
    Lesson? lesson,
    LessonTexts? texts,
    Character? viktor,
    int? step,
    String? fen,
    bool clearFen = false,
    Move? lastMove,
    bool clearLastMove = false,
    List<String>? collected,
    int? turn,
    List<String>? moves,
    StepPhase? phase,
    String? speech,
    Emotion? emotion,
    Move? hint,
    bool clearHint = false,
    PlayResult? result,
    bool clearResult = false,
    bool? finished,
    bool? courseFinished,
    int? lessonNumber,
    int? lessonCount,
    int? mistakes,
    String? nextLesson,
  }) => LessonState(
    ready: ready ?? this.ready,
    missing: missing ?? this.missing,
    lesson: lesson ?? this.lesson,
    texts: texts ?? this.texts,
    viktor: viktor ?? this.viktor,
    step: step ?? this.step,
    fen: clearFen ? null : fen ?? this.fen,
    lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
    collected: collected ?? this.collected,
    turn: turn ?? this.turn,
    moves: moves ?? this.moves,
    phase: phase ?? this.phase,
    speech: speech ?? this.speech,
    emotion: emotion ?? this.emotion,
    hint: clearHint ? null : hint ?? this.hint,
    result: clearResult ? null : result ?? this.result,
    finished: finished ?? this.finished,
    courseFinished: courseFinished ?? this.courseFinished,
    lessonNumber: lessonNumber ?? this.lessonNumber,
    lessonCount: lessonCount ?? this.lessonCount,
    mistakes: mistakes ?? this.mistakes,
    nextLesson: nextLesson ?? this.nextLesson,
  );
}

/// Uma aula com o Viktor: ele fala a cada passo, o aluno joga no tabuleiro e
/// cada mudança é gravada (o app fechado à força volta no mesmo passo, com o
/// mesmo tabuleiro).
class LessonCubit extends Cubit<LessonState> {
  LessonCubit({
    required this._lessons,
    required this._progress,
    required this._characters,
    required this._opponent,
    this.replyDelay = const Duration(milliseconds: 450),
  }) : super(const LessonState());

  final LessonRepository _lessons;
  final SchoolProgressRepository _progress;
  final CharacterRepository _characters;
  final OpponentRepository _opponent;

  /// A pausa antes da resposta combinada do outro lado, para o aluno ver o
  /// próprio lance antes.
  final Duration replyDelay;

  /// Quanto a máquina pensa em cada lance (e na dica).
  static const thinkTime = Duration(milliseconds: 400);

  // Contadores das falas de incentivo: cada vez sai a próxima da lista.
  final _said = <String, int>{};

  Future<void> load(String lessonId, String language) async {
    final course = await _lessons.course();
    final texts = await _lessons.texts(language);
    final characters = await _characters.characters();
    final progress = await _progress.load();
    final lesson = course.lesson(lessonId);
    if (isClosed) return;
    if (lesson == null || lesson.steps.isEmpty) {
      emit(const LessonState(ready: true, missing: true));
      return;
    }
    Character? viktor;
    for (final character in characters) {
      if (character.id == viktorId) viktor = character;
    }
    final lessons = course.lessons;
    final base = LessonState(
      ready: true,
      lesson: lesson,
      texts: texts,
      viktor: viktor,
      lessonNumber: lessons.indexOf(lesson) + 1,
      lessonCount: lessons.length,
    );
    final saved = progress.ongoing;
    if (saved != null &&
        saved.lessonId == lessonId &&
        saved.step < lesson.steps.length) {
      emit(_restore(base, saved));
    } else {
      emit(_open(base, 0));
    }
    await _save();
  }

  /// O id do Viktor nas fichas dos personagens.
  static const viktorId = 'master';

  /// "Continuar": passa da fala, ou do passo cumprido, para o próximo; no
  /// último, conclui a aula.
  Future<void> next() async {
    final current = state.current;
    if (current == null) return;
    final canGo =
        state.phase == StepPhase.done ||
        (current is TalkStep && state.phase == StepPhase.active);
    if (!canGo) return;
    final nextStep = state.step + 1;
    if (nextStep < state.stepCount) {
      emit(_open(state, nextStep));
      await _save();
      return;
    }
    await _finish();
  }

  /// Tenta de novo o passo de jogar, do começo.
  Future<void> retry() async {
    if (state.current is! PlayStep) return;
    emit(
      _open(
        state,
        state.step,
      ).copyWith(speech: _pick('coach.retry'), emotion: Emotion.focused),
    );
    await _save();
  }

  /// Sai da aula pelo voltar: o passo fica guardado, mas o app não reabre
  /// nela.
  Future<void> leave() async {
    final progress = await _progress.load();
    final ongoing = progress.ongoing;
    if (ongoing == null || state.finished) return;
    await _progress.save(
      progress.copyWith(ongoing: ongoing.copyWith(open: false)),
    );
  }

  /// O aluno moveu uma peça no tabuleiro.
  Future<void> play(Move move) async {
    if (!state.interactive) return;
    switch (state.current) {
      case StarsStep step:
        await _playStar(step, move);
      case MoveStep step:
        await _playLine(step, move);
      case PlayStep step:
        await _playOut(step, move);
      case TalkStep() || null:
        return;
    }
  }

  /// Pede ao mestre o melhor lance (vira uma seta no tabuleiro).
  Future<void> askHint() async {
    final current = state.current;
    if (!state.interactive) return;
    switch (current) {
      case MoveStep step:
        final accepted = step.line[state.turn].accept.first;
        emit(
          state.copyWith(
            hint: Move.parse(accepted),
            speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.hint'),
            emotion: Emotion.focused,
          ),
        );
      case PlayStep():
        final position = _position();
        if (position == null) return;
        final fen = state.fen;
        final move = await _opponent.pickMove(position, thinkTime: thinkTime);
        if (isClosed || state.fen != fen || move == null) return;
        emit(
          state.copyWith(
            hint: move,
            speech: _pick('coach.hint'),
            emotion: Emotion.focused,
          ),
        );
      case StarsStep() || TalkStep() || null:
        return;
    }
  }

  Future<void> _playStar(StarsStep step, Move move) async {
    if (move is! NormalMove) return;
    final board = LessonRules.starsBoard(state.fen!);
    final moved = LessonRules.moveStar(board, step.side, move.from, move.to);
    if (moved == null) return;
    final star = move.to.name;
    final collected = [
      ...state.collected,
      if (step.stars.contains(star) && !state.collected.contains(star)) star,
    ];
    final fen = LessonRules.starsFen(moved, step.side);
    final allDone = step.stars.every(collected.contains);
    emit(
      state.copyWith(
        fen: fen,
        lastMove: move,
        collected: collected,
        clearHint: true,
        phase: allDone ? StepPhase.done : StepPhase.active,
        speech: allDone
            ? state.texts.done(_lessonId, step.id) ?? _pick('coach.praise')
            : collected.length > state.collected.length
            ? _pick('coach.star')
            : state.speech,
        emotion: allDone ? Emotion.happy : state.emotion,
      ),
    );
    await _save();
  }

  Future<void> _playLine(MoveStep step, Move move) async {
    final position = _position();
    if (position == null) return;
    if (!LessonRules.accepts(step, state.turn, move.uci)) {
      // A peça volta: a tela redesenha o tabuleiro a cada estado novo. No
      // segundo erro, o mestre já mostra a seta.
      final mistakes = state.mistakes + 1;
      emit(
        state.copyWith(
          speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.wrong'),
          emotion: Emotion.focused,
          hint: mistakes >= 2
              ? Move.parse(step.line[state.turn].accept.first)
              : null,
          clearHint: mistakes < 2,
          mistakes: mistakes,
        ),
      );
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) return;
    final turn = step.line[state.turn];
    final last = state.turn + 1 >= step.line.length;
    if (last) {
      emit(
        state.copyWith(
          fen: played.position.fen,
          lastMove: move,
          turn: state.turn + 1,
          clearHint: true,
          phase: StepPhase.done,
          speech: state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
          emotion: Emotion.happy,
        ),
      );
      await _save();
      return;
    }
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        clearHint: true,
        phase: turn.reply == null ? StepPhase.active : StepPhase.waiting,
        speech: _pick('coach.good'),
        emotion: Emotion.happy,
      ),
    );
    final reply = Move.parse(turn.reply ?? '');
    var after = played.position;
    if (reply != null) {
      await Future<void>.delayed(replyDelay);
      if (isClosed) return;
      final answered = GameRules.play(after, reply);
      if (answered == null) return;
      after = answered.position;
    }
    emit(
      state.copyWith(
        fen: after.fen,
        lastMove: reply ?? move,
        turn: state.turn + 1,
        phase: StepPhase.active,
      ),
    );
    await _save();
  }

  Future<void> _playOut(PlayStep step, Move move) async {
    final position = _position();
    if (position == null) return;
    final played = GameRules.play(position, move);
    if (played == null) return;
    var moves = [...state.moves, move.uci];
    final start = GameRules.fromFen(step.fen)!;
    var result = LessonRules.resultOf(
      played.position,
      goal: step.goal,
      student: step.side,
      lastMove: move,
      repetitions: GameRules.repetitionsOf(start, moves),
    );
    final userMoves = (moves.length + 1) ~/ 2;
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        moves: moves,
        clearHint: true,
        phase: result == PlayResult.ongoing ? StepPhase.waiting : null,
        speech: result == PlayResult.ongoing && userMoves % 3 == 0
            ? _tip(step)
            : null,
        emotion: result == PlayResult.ongoing ? Emotion.focused : null,
      ),
    );
    if (result != PlayResult.ongoing) {
      await _endPlay(step, result);
      return;
    }
    await _save();
    final reply = await _opponent.pickMove(
      played.position,
      thinkTime: thinkTime,
      kind: step.opponent.kind,
      level: step.opponent.level,
      history: [start],
    );
    if (isClosed || state.fen != played.position.fen) return;
    final answered = reply == null
        ? null
        : GameRules.play(played.position, reply);
    if (answered == null) {
      emit(state.copyWith(phase: StepPhase.active));
      return;
    }
    moves = [...moves, reply!.uci];
    result = LessonRules.resultOf(
      answered.position,
      goal: step.goal,
      student: step.side,
      lastMove: reply,
      repetitions: GameRules.repetitionsOf(start, moves),
    );
    emit(
      state.copyWith(
        fen: answered.position.fen,
        lastMove: reply,
        moves: moves,
        phase: StepPhase.active,
      ),
    );
    if (result != PlayResult.ongoing) {
      await _endPlay(step, result);
      return;
    }
    await _save();
  }

  Future<void> _endPlay(PlayStep step, PlayResult result) async {
    final success = result == PlayResult.success;
    emit(
      state.copyWith(
        phase: success ? StepPhase.done : StepPhase.failed,
        result: result,
        speech: switch (result) {
          PlayResult.success =>
            state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
          PlayResult.stalemate => _pick('coach.stalemate'),
          PlayResult.lost => _pick('coach.lost'),
          PlayResult.draw || PlayResult.ongoing => _pick('coach.draw'),
        },
        emotion: switch (result) {
          PlayResult.success => Emotion.happy,
          PlayResult.stalemate => Emotion.surprised,
          _ => Emotion.calm,
        },
      ),
    );
    await _save();
  }

  Future<void> _finish() async {
    final lesson = state.lesson!;
    final course = await _lessons.course();
    final progress = await _progress.load();
    final completed = {...progress.completed, lesson.id};
    final lessons = course.lessons;
    final courseFinished =
        lessons.last.id == lesson.id ||
        lessons.every((each) => completed.contains(each.id));
    final index = lessons.indexWhere((each) => each.id == lesson.id);
    final nextLesson = index >= 0 && index + 1 < lessons.length
        ? lessons[index + 1].id
        : null;
    await _progress.save(SchoolProgress(completed: completed));
    if (isClosed) return;
    emit(
      state.copyWith(
        finished: true,
        courseFinished: courseFinished,
        nextLesson: nextLesson,
        speech: courseFinished
            ? _pick('coach.graduation')
            : _pick('coach.lessonDone'),
        emotion: Emotion.confident,
      ),
    );
  }

  /// O passo [index] do começo, com a fala de abertura dele.
  LessonState _open(LessonState base, int index) {
    final step = base.lesson!.steps[index];
    final lessonId = base.lesson!.id;
    return LessonState(
      ready: true,
      lesson: base.lesson,
      texts: base.texts,
      viktor: base.viktor,
      lessonNumber: base.lessonNumber,
      lessonCount: base.lessonCount,
      step: index,
      fen: step.fen,
      speech: base.texts.step(lessonId, step.id),
      emotion: index == 0 ? Emotion.happy : Emotion.calm,
    );
  }

  /// O passo guardado, com o tabuleiro de quando o app fechou.
  LessonState _restore(LessonState base, LessonCheckpoint saved) {
    final opened = _open(base, saved.step);
    final step = opened.current!;
    var restored = opened.copyWith(
      collected: saved.collected,
      turn: saved.turn,
      moves: saved.moves,
    );
    switch (step) {
      case PlayStep():
        var position = GameRules.fromFen(step.fen);
        Move? last;
        for (final uci in saved.moves) {
          final move = Move.parse(uci);
          final played = position == null || move == null
              ? null
              : GameRules.play(position, move);
          if (played == null) break;
          position = played.position;
          last = move;
        }
        if (position != null) {
          restored = restored.copyWith(fen: position.fen, lastMove: last);
          final result = LessonRules.resultOf(
            position,
            goal: step.goal,
            student: step.side,
            lastMove: last,
            repetitions: GameRules.repetitionsOf(
              GameRules.fromFen(step.fen)!,
              saved.moves,
            ),
          );
          if (result != PlayResult.ongoing) {
            restored = restored.copyWith(
              result: result,
              phase: result == PlayResult.success
                  ? StepPhase.done
                  : StepPhase.failed,
            );
          }
        }
      case StarsStep(:final stars):
        restored = restored.copyWith(
          fen: saved.fen,
          phase: stars.every(saved.collected.contains)
              ? StepPhase.done
              : StepPhase.active,
        );
      case MoveStep(:final line):
        restored = restored.copyWith(
          fen: saved.fen,
          phase: saved.turn >= line.length ? StepPhase.done : StepPhase.active,
        );
      case TalkStep():
        break;
    }
    return restored;
  }

  Future<void> _save() async {
    final lesson = state.lesson;
    if (lesson == null || state.finished) return;
    final progress = await _progress.load();
    await _progress.save(
      progress.copyWith(
        ongoing: LessonCheckpoint(
          lessonId: lesson.id,
          step: state.step,
          fen: state.fen,
          collected: state.collected,
          turn: state.turn,
          moves: state.moves,
        ),
      ),
    );
  }

  Position? _position() {
    final fen = state.fen;
    return fen == null ? null : GameRules.fromFen(fen);
  }

  String get _lessonId => state.lesson!.id;

  /// Uma dica da aula para o meio da partida, ou um incentivo.
  String? _tip(PlayStep step) {
    final key = '$_lessonId.${step.id}.tips';
    if (state.texts.all(key).isNotEmpty) return _pick(key);
    return _pick('coach.keepGoing');
  }

  /// A próxima fala da lista [key], dando a volta.
  String? _pick(String key) {
    final index = _said[key] ?? 0;
    _said[key] = index + 1;
    return state.texts.say(key, index);
  }
}
