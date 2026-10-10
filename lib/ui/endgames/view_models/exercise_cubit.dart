import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/step_clock.dart';
import '../../school/view_models/lesson_cubit.dart';
import '../../core/sound/game_sounds.dart';
import '../../../domain/models/haptic_event.dart';
import '../../core/sound/game_haptics.dart';

/// Em que pé está o exercício.
enum ExercisePhase {
  /// O aluno procura o lance.
  active,

  /// O outro lado está respondendo.
  waiting,

  /// Resolvido: a solução e as estrelas ganhas.
  done,
}

/// Como a tela se organiza (T60), como na lição.
enum ExerciseLayoutMode {
  /// O aluno resolve: o enunciado curto em cima, o tabuleiro no centro e a
  /// dica com o cronômetro embaixo.
  solving,

  /// Resolvido: o tabuleiro no alto e, embaixo, as estrelas, a solução e a
  /// fala do Viktor.
  explaining,
}

class ExerciseState {
  const ExerciseState({
    this.ready = false,
    this.missing = false,
    this.lesson,
    this.exercise,
    this.texts = LessonTexts.empty,
    this.viktor,
    this.fen,
    this.lastMove,
    this.turn = 0,
    this.mistakes = 0,
    this.hints = 0,
    this.hint,
    this.wrongMove,
    this.phase = ExercisePhase.active,
    this.speech,
    this.emotion = Emotion.calm,
    this.earned,
    this.explained = false,
    this.locked = false,
    this.number = 0,
    this.count = 0,
    this.nextExercise,
    this.startedAt,
  });

  final bool ready;

  /// Quando o exercício abriu: o cronômetro conta daqui.
  final DateTime? startedAt;

  /// Resolvendo até a resposta; resolvido com erro ou dica (ou com a
  /// explicação aberta), o professor fala. No acerto limpo o tabuleiro fica
  /// onde estava: embaixo, só "você acertou" e o próximo.
  ExerciseLayoutMode get layout =>
      phase == ExercisePhase.done && (!cleanSolve || explained)
      ? ExerciseLayoutMode.explaining
      : ExerciseLayoutMode.solving;

  /// Resolvido de primeira, sem erro nem dica.
  bool get cleanSolve =>
      phase == ExercisePhase.done && mistakes == 0 && hints == 0;

  /// A aula ou o exercício pedido não existem.
  final bool missing;
  final EndgameLesson? lesson;
  final Exercise? exercise;
  final LessonTexts texts;
  final Character? viktor;

  /// O tabuleiro agora.
  final String? fen;
  final Move? lastMove;

  /// A vez do aluno na linha do exercício.
  final int turn;

  /// Lances errados e dicas pedidas: cada um tira uma estrela.
  final int mistakes;
  final int hints;

  /// A seta da dica.
  final Move? hint;

  /// O último lance errado, para o tabuleiro mostrar o que o aluno fez.
  final Move? wrongMove;
  final ExercisePhase phase;
  final String? speech;
  final Emotion emotion;

  /// As estrelas ganhas, quando resolvido.
  final int? earned;

  /// O aluno abriu a explicação detalhada da solução.
  final bool explained;

  /// A nota da aula já fechou (todos os exercícios resolvidos): este é
  /// treino livre, e o resultado não muda. Só "refazer os exercícios" zera.
  final bool locked;

  /// O número do exercício na aula (1 é o primeiro) e quantos há.
  final int number;
  final int count;

  /// O exercício seguinte ainda por resolver. Nulo se não há.
  final String? nextExercise;

  bool get interactive => phase == ExercisePhase.active;

  /// A explicação detalhada da solução, quando a aula tem.
  String? get explanation => lesson == null || exercise == null
      ? null
      : texts.say('${lesson!.id}.ex.${exercise!.id}.solution');

  /// Resolvido, com explicação a pedir: o botão "Ver explicação".
  bool get canExplain =>
      phase == ExercisePhase.done && !explained && explanation != null;

  /// O lado do aluno: o que joga no FEN do exercício.
  Side get side => exercise?.step.side ?? Side.white;

  /// Quanto do exercício está feito, para a barra.
  double get progress {
    final line = exercise?.line;
    if (line == null || line.isEmpty) return 0;
    if (phase == ExercisePhase.done) return 1;
    return turn / line.length;
  }

  ExerciseState copyWith({
    String? fen,
    Move? lastMove,
    int? turn,
    int? mistakes,
    int? hints,
    Move? hint,
    Move? wrongMove,
    bool clearWrongMove = false,
    bool clearHint = false,
    ExercisePhase? phase,
    String? speech,
    bool clearSpeech = false,
    Emotion? emotion,
    int? earned,
    bool? explained,
  }) => ExerciseState(
    ready: ready,
    missing: missing,
    lesson: lesson,
    exercise: exercise,
    texts: texts,
    viktor: viktor,
    fen: fen ?? this.fen,
    lastMove: lastMove ?? this.lastMove,
    turn: turn ?? this.turn,
    mistakes: mistakes ?? this.mistakes,
    hints: hints ?? this.hints,
    hint: clearHint ? null : hint ?? this.hint,
    wrongMove: clearWrongMove ? null : wrongMove ?? this.wrongMove,
    phase: phase ?? this.phase,
    speech: clearSpeech ? null : speech ?? this.speech,
    emotion: emotion ?? this.emotion,
    earned: earned ?? this.earned,
    explained: explained ?? this.explained,
    locked: locked,
    number: number,
    count: count,
    nextExercise: nextExercise,
    startedAt: startedAt,
  );
}

/// Um exercício de uma aula de final: o aluno acha os lances da técnica;
/// cada erro ou dica tira uma estrela. Cada mudança é gravada: o app fechado
/// à força volta no mesmo exercício e na mesma posição.
class ExerciseCubit extends Cubit<ExerciseState> {
  ExerciseCubit({
    required this._lessons,
    required this._progress,
    required this._characters,
    this._sounds,
    this._haptics,
    this._now = const SystemNow(),
    this.replyDelay = const Duration(milliseconds: 450),
  }) : super(const ExerciseState());

  final Now _now;

  /// O cronômetro do exercício: quanto tempo passou desde que ele abriu (a
  /// tela lê a cada instante e o congela na resposta).
  Duration get elapsed {
    final startedAt = state.startedAt;
    if (startedAt == null) return Duration.zero;
    return StepClock.elapsed(startedAt: startedAt, now: _now());
  }

  final EndgameLessonRepository _lessons;
  final EndgameProgressRepository _progress;
  final CharacterRepository _characters;

  // Os sons do jogo; nulo: o exercício fica mudo.
  final GameSounds? _sounds;

  // A vibração; nula: sem retorno tátil.
  final GameHaptics? _haptics;

  /// A pausa antes da resposta do outro lado.
  final Duration replyDelay;

  final _said = <String, int>{};

  Future<void> load(String lessonId, String exerciseId, String language) async {
    final trail = await _lessons.trail();
    final lesson = trail.lesson(lessonId);
    final exercise = lesson?.exercise(exerciseId);
    if (lesson == null || exercise == null || exercise.line.isEmpty) {
      if (!isClosed) emit(const ExerciseState(ready: true, missing: true));
      return;
    }
    final texts = await _lessons.texts(language);
    final characters = await _characters.characters();
    final progress = await _progress.load();
    if (isClosed) return;
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
      // O objetivo fica sob o tabuleiro; o Viktor só fala com erro, dica ou
      // explicação pedida.
      emotion: Emotion.focused,
      number: index + 1,
      count: lesson.exercises.length,
      nextExercise: next,
      locked: lesson.exercises.every(
        (other) => each.stars.containsKey(other.id),
      ),
      // Voltando ao exercício, o cronômetro continua de onde estava.
      startedAt: (resumed ? saved.startedAt : null) ?? _now(),
    );
    if (resumed) {
      opened = opened.copyWith(
        fen: saved.fen,
        turn: saved.turn,
        mistakes: saved.mistakes,
        hints: saved.hints,
      );
    }
    emit(opened);
    await _save();
  }

  /// O aluno moveu uma peça.
  Future<void> play(Move move) async {
    if (!state.interactive) return;
    final exercise = state.exercise!;
    final step = exercise.step;
    final position = _position();
    if (position == null) return;
    if (!LessonRules.accepts(step, state.turn, move.uci)) {
      final mistakes = state.mistakes + 1;
      emit(
        state.copyWith(
          mistakes: mistakes,
          wrongMove: move,
          // A pista fica para a dica: aqui só o "não é esse".
          speech: _pick('coach.wrong'),
          emotion: Emotion.focused,
        ),
      );
      await _save();
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) return;
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    final turn = step.line[state.turn];
    final ends = LessonRules.endsLine(step, state.turn, move.uci);
    if (ends) {
      await _solve(played.position.fen, move);
      return;
    }
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        clearHint: true,
        clearWrongMove: true,
        phase: turn.reply == null
            ? ExercisePhase.active
            : ExercisePhase.waiting,
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
      if (answered == null) {
        // A resposta combinada não cabe no tabuleiro (aula com dado
        // inconsistente): a linha acaba aqui, com o exercício resolvido.
        await _solve(after.fen, move);
        return;
      }
      unawaited(_sounds?.move(answered.san));
      after = answered.position;
    }
    emit(
      state.copyWith(
        fen: after.fen,
        lastMove: reply ?? move,
        turn: state.turn + 1,
        phase: ExercisePhase.active,
      ),
    );
    await _save();
  }

  /// A dica: a fala da aula e a seta com o lance. Custa uma estrela (só a
  /// primeira vez em cada vez do aluno).
  Future<void> askHint() async {
    if (!state.interactive) return;
    final step = state.exercise!.step;
    final accepted = step.line[state.turn].accept.first;
    emit(
      state.copyWith(
        hint: Move.parse(accepted),
        clearWrongMove: true,
        hints: state.hint == null ? state.hints + 1 : state.hints,
        // A ajuda traz o enunciado e a pista (e a seta).
        speech: [
          ?_statement(),
          ?(_hintText() ?? _pick('coach.hint')),
        ].join(' '),
        emotion: Emotion.focused,
      ),
    );
    await _save();
  }

  /// "Ver explicação": a fala detalhada da solução, depois de resolver.
  void showExplanation() {
    final text = state.explanation;
    if (!state.canExplain || text == null) return;
    emit(
      state.copyWith(speech: text, explained: true, emotion: Emotion.focused),
    );
  }

  /// Sair pelo voltar: o exercício fica guardado onde parou.
  Future<void> leave() async {
    if (state.phase == ExercisePhase.done) return;
    await _save(open: false);
  }

  Future<void> _solve(String fen, Move move) async {
    unawaited(_haptics?.play(HapticEvent.success));
    final lesson = state.lesson!;
    final exercise = state.exercise!;
    final earned = EndgameLessonRules.earned(
      exercise.stars,
      mistakes: state.mistakes,
      hints: state.hints,
    );
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
    if (isClosed) return;
    // Acerto limpo: o Viktor fica quieto, e a explicação vem a pedido. Com
    // erro ou dica, a correção vem sozinha.
    final corrected = state.mistakes > 0 || state.hints > 0;
    emit(
      state.copyWith(
        fen: fen,
        lastMove: move,
        turn: state.turn + 1,
        clearHint: true,
        clearWrongMove: true,
        phase: ExercisePhase.done,
        earned: earned,
        clearSpeech: !corrected,
        speech: corrected ? (state.explanation ?? _pick('coach.praise')) : null,
        explained: corrected,
        emotion: earned == exercise.stars ? Emotion.happy : Emotion.calm,
      ),
    );
  }

  Future<void> _save({bool open = true}) async {
    final lesson = state.lesson;
    final exercise = state.exercise;
    if (lesson == null || exercise == null) return;
    if (state.phase == ExercisePhase.done || state.locked) return;
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
                open: open,
                startedAt: state.startedAt,
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
