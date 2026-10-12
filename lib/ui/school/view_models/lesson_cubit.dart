import '../../../domain/models/explanation.dart';

import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/exercise_feedback_repository.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/lesson_source.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/step_clock.dart';
import '../../core/sound/game_sounds.dart';
import '../../../domain/models/game_sound.dart';
import '../../../domain/models/haptic_event.dart';
import '../../core/sound/game_haptics.dart';

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

/// Como a tela se organiza (T60).
enum LessonLayoutMode {
  /// O aluno resolve: o tabuleiro no centro, o enunciado curto em cima e o
  /// cronômetro com as ações embaixo.
  solving,

  /// O professor fala: o tabuleiro no alto e a folha da fala embaixo.
  explaining,
}

class LessonState {
  const LessonState({
    this.ready = false,
    this.missing = false,
    this.lesson,
    this.texts = LessonTexts.empty,
    this.viktor,
    this.step = 0,
    this.reached = 0,
    this.fen,
    this.lastMove,
    this.collected = const [],
    this.turn = 0,
    this.moves = const [],
    this.phase = StepPhase.active,
    this.speech,
    this.explanation,
    this.emotion = Emotion.calm,
    this.hint,
    this.result,
    this.finished = false,
    this.courseFinished = false,
    this.graduationPath = const [],
    this.finishedAt,
    this.lessonNumber = 0,
    this.lessonCount = 0,
    this.mistakes = 0,
    this.nextLesson,
    this.endgame = false,
    this.part,
    this.partNumber = 0,
    this.partCount = 0,
    this.nextPart,
    this.stepStartedAt,
    this.hintsShown = 0,
    this.demoMove = 0,
    this.demoPlaying = true,
    this.references = const [],
    this.reviewStep,
    this.returnTo,
    this.genericMistake = false,
    this.thinkMistake,
    this.attemptedSan,
  });

  /// Depois de um lance errado previsto: o id do passo da lição que explica
  /// o ponto ("Rever este ponto"). Nulo: sem passo para rever.
  final String? reviewStep;

  /// Revendo um ponto a partir de um teste: o índice do passo do teste, para
  /// onde "continuar" volta.
  final int? returnTo;

  /// O lance errado não tem explicação própria: a tela mostra a fala
  /// genérica do app.
  final bool genericMistake;

  /// Lance errado no passo de pensar, sem fala própria (`mistakes`): o lance
  /// do aluno numerado, em SAN com as letras inglesas (`1...Kd7`). A
  /// explicação aberta começa pela frase genérica do app com ele
  /// (`lessonThinkMistakeGeneric`), antes de [speech].
  final String? thinkMistake;
  final String? attemptedSan;

  /// A demonstração aberta mostra a linha errada.
  bool get wrongDemo => switch (current) {
    DemoStep(:final wrong) => wrong,
    _ => false,
  };

  /// As referências da aula (partidas, estudos...), que o `ref` de um passo
  /// aponta. Vazia na escola.
  final List<Reference> references;

  /// O link do passo atual para a partida ou o estudo de onde vem a
  /// posição. Nulo sem `ref`, sem `url` ou no passo de pensar (o link
  /// entregaria a resposta; a explicação vem no passo seguinte).
  Reference? get link {
    if (current is ThinkStep) {
      return null;
    }
    final reference = Reference.resolve(references, current?.ref);
    return reference?.url == null ? null : reference;
  }

  final bool ready;

  /// A aula pedida não existe no curso.
  final bool missing;
  final Lesson? lesson;
  final LessonTexts texts;

  /// O professor. Nulo só se a ficha dele faltar.
  final Character? viktor;

  /// O índice do passo aberto.
  final int step;

  /// O passo mais adiante a que o aluno já chegou. Voltando para rever, os
  /// passos até ele podem ser pulados com "continuar", sem refazer o lance.
  final int reached;

  /// Está revendo um passo já passado.
  bool get reviewing => step < reached;

  /// "Continuar" vale: a fala, o passo cumprido ou um passo revisto.
  bool get canContinue =>
      current != null &&
      phase != StepPhase.waiting &&
      (phase == StepPhase.done ||
          reviewing ||
          (current is TalkStep && phase == StepPhase.active) ||
          // "Ver explicação": quando o aluno quiser (T60).
          current is ThinkStep);

  /// Há passo antes deste para rever.
  bool get canGoBack => step > 0 && phase != StepPhase.waiting && !finished;

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
  final ExplanationPayload? explanation;
  final Emotion emotion;

  /// O lance que o mestre sugere (seta no tabuleiro).
  final Move? hint;

  /// Como acabou o passo de jogar.
  final PlayResult? result;

  /// A aula terminou: aparece o cartão de fim.
  final bool finished;

  /// Era a última aula do curso: a formatura.
  final bool courseFinished;

  /// Na formatura: os módulos da escola, em ordem (o caminho no diploma e na
  /// imagem de compartilhar).
  final List<CourseModule> graduationPath;

  /// Quando a aula foi concluída (a data do diploma, na formatura).
  final DateTime? finishedAt;

  /// A posição da aula no curso (1 é a primeira) e quantas há.
  final int lessonNumber;
  final int lessonCount;

  /// Lances errados no passo aberto (a tela sacode o tabuleiro a cada um).
  final int mistakes;

  /// Com a aula terminada, a próxima da trilha. Nula na última.
  final String? nextLesson;

  /// É a lição de uma aula de final: o fim volta para a aula, com os
  /// exercícios, em vez de seguir a trilha da escola.
  final bool endgame;

  /// A parte aberta (aula em partes, T51). Nula: a aula inteira.
  final LessonPart? part;

  /// A posição da parte na aula (1 é a primeira) e quantas há.
  final int partNumber;
  final int partCount;

  /// Com a parte terminada, a próxima recomendada. Nula com todas feitas.
  final String? nextPart;

  /// Quando o passo aberto começou: o cronômetro do passo (T60) conta daqui.
  final DateTime? stepStartedAt;

  /// Quantas dicas do passo de pensar já apareceram.
  final int hintsShown;

  /// Na demonstração: quantos lances já foram jogados e se ela anda sozinha.
  final int demoMove;
  final bool demoPlaying;

  /// No passo de pensar, há mais uma dica para mostrar (desde o começo).
  bool get canHint => switch (current) {
    ThinkStep(:final hints) => hintsShown < hints,
    _ => false,
  };

  /// O passo aberto é de exercício: o aluno age no tabuleiro.
  bool get exercise => switch (current) {
    ThinkStep() || MoveStep() || PlayStep() || TapStep() || StarsStep() => true,
    TalkStep() || DemoStep() || null => false,
  };

  /// Resolvendo (tabuleiro no centro, cronômetro) enquanto um passo de
  /// exercício não foi respondido; depois da resposta (cumprido ou falhado),
  /// e nos passos de conversa e demonstração, o professor fala.
  LessonLayoutMode get layout =>
      exercise && (phase == StepPhase.active || phase == StepPhase.waiting)
      ? LessonLayoutMode.solving
      : LessonLayoutMode.explaining;

  /// As setas do momento: as do passo de pensar depois do tempo, as do
  /// lance da demonstração, ou as de uma fala.
  List<(String, String)> get arrows => switch (current) {
    TalkStep(:final arrows) => arrows,
    ThinkStep(:final arrows) when hintsShown > 0 => arrows,
    DemoStep(:final line) when demoMove > 0 => line[demoMove - 1].arrows,
    _ => const [],
  };

  List<String> get marks => switch (current) {
    TalkStep(:final marks) => marks,
    ThinkStep(:final marks) when hintsShown > 0 => marks,
    DemoStep(:final line) when demoMove > 0 => line[demoMove - 1].marks,
    _ => const [],
  };

  LessonStep? get current {
    final steps = lesson?.steps;
    if (steps == null || step >= steps.length) {
      return null;
    }
    return steps[step];
  }

  int get stepCount => lesson?.steps.length ?? 0;

  /// Quanto da aula já foi feito, de 0 a 1 (o passo cumprido conta inteiro).
  double get progress {
    if (stepCount == 0) return 0;
    if (finished) return 1;
    if (phase == StepPhase.done) return (step + 1) / stepCount;
    // Dentro do passo, cada estrela pega e cada lance certo já enchem a barra.
    final within = switch (current) {
      StarsStep(:final stars) => collected.length / stars.length,
      TapStep(:final targets) => collected.length / targets.length,
      MoveStep(:final line) => turn / line.length,
      DemoStep(:final line) => demoMove / line.length,
      _ => 0.0,
    };
    return (step + within) / stepCount;
  }

  /// O aluno pode mexer no tabuleiro (no passo de tocar, só tocar).
  bool get interactive =>
      phase == StepPhase.active &&
      current is! TalkStep &&
      current is! TapStep &&
      current is! DemoStep &&
      current != null;

  /// No passo de tocar, a casa que o Viktor pediu agora. Nula fora dele.
  String? get tapTarget => switch (current) {
    TapStep(:final targets)
        when phase == StepPhase.active && collected.length < targets.length =>
      targets[collected.length],
    _ => null,
  };

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
    int? reached,
    String? fen,
    bool clearFen = false,
    Move? lastMove,
    bool clearLastMove = false,
    List<String>? collected,
    int? turn,
    List<String>? moves,
    StepPhase? phase,
    String? speech,
    ExplanationPayload? explanation,
    Emotion? emotion,
    Move? hint,
    bool clearHint = false,
    PlayResult? result,
    bool clearResult = false,
    bool? finished,
    bool? courseFinished,
    List<CourseModule>? graduationPath,
    DateTime? finishedAt,
    int? lessonNumber,
    int? lessonCount,
    int? mistakes,
    String? nextLesson,
    bool? endgame,
    LessonPart? part,
    int? partNumber,
    int? partCount,
    String? nextPart,
    DateTime? stepStartedAt,
    int? hintsShown,
    int? demoMove,
    bool? demoPlaying,
    List<Reference>? references,
    String? reviewStep,
    bool clearReview = false,
    int? returnTo,
    bool? genericMistake,
    String? thinkMistake,
    String? attemptedSan,
    bool clearAttemptedSan = false,
  }) => LessonState(
    ready: ready ?? this.ready,
    missing: missing ?? this.missing,
    lesson: lesson ?? this.lesson,
    texts: texts ?? this.texts,
    viktor: viktor ?? this.viktor,
    step: step ?? this.step,
    reached: reached ?? this.reached,
    fen: clearFen ? null : fen ?? this.fen,
    lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
    collected: collected ?? this.collected,
    turn: turn ?? this.turn,
    moves: moves ?? this.moves,
    phase: phase ?? this.phase,
    speech: speech ?? this.speech,
    explanation:
        explanation ??
        (speech == null && step == null && fen == null
            ? this.explanation
            : null),
    emotion: emotion ?? this.emotion,
    hint: clearHint ? null : hint ?? this.hint,
    result: clearResult ? null : result ?? this.result,
    finished: finished ?? this.finished,
    courseFinished: courseFinished ?? this.courseFinished,
    graduationPath: graduationPath ?? this.graduationPath,
    finishedAt: finishedAt ?? this.finishedAt,
    lessonNumber: lessonNumber ?? this.lessonNumber,
    lessonCount: lessonCount ?? this.lessonCount,
    mistakes: mistakes ?? this.mistakes,
    nextLesson: nextLesson ?? this.nextLesson,
    endgame: endgame ?? this.endgame,
    part: part ?? this.part,
    partNumber: partNumber ?? this.partNumber,
    partCount: partCount ?? this.partCount,
    nextPart: nextPart ?? this.nextPart,
    stepStartedAt: stepStartedAt ?? this.stepStartedAt,
    hintsShown: hintsShown ?? this.hintsShown,
    demoMove: demoMove ?? this.demoMove,
    demoPlaying: demoPlaying ?? this.demoPlaying,
    references: references ?? this.references,
    reviewStep: clearReview ? null : reviewStep ?? this.reviewStep,
    returnTo: returnTo ?? this.returnTo,
    // Uma fala nova apaga a genérica, a não ser que venha junto.
    genericMistake:
        genericMistake ?? (speech != null ? false : this.genericMistake),
    // Idem para o lance errado do passo de pensar.
    thinkMistake: thinkMistake ?? (speech != null ? null : this.thinkMistake),
    attemptedSan: clearAttemptedSan
        ? null
        : attemptedSan ??
              (speech != null || step != null ? null : this.attemptedSan),
  );
}

/// Uma aula com o Viktor: ele fala a cada passo, o aluno joga no tabuleiro e
/// cada mudança é gravada (o app fechado à força volta no mesmo passo, com o
/// mesmo tabuleiro).
class LessonCubit extends Cubit<LessonState> {
  /// Com [source], a aula vem de lá (a trilha de finais); sem ela, da escola
  /// ([lessons] e [progress]).
  LessonCubit({
    LessonRepository? lessons,
    SchoolProgressRepository? progress,
    LessonSource? source,
    required this._characters,
    required this._opponent,
    this._sounds,
    this._feedback,
    this._haptics,
    this._now = const SystemNow(),
    this.replyDelay = const Duration(milliseconds: 450),
  }) : _source = source ?? SchoolLessonSource(lessons!, progress!),
       super(const LessonState());

  final LessonSource _source;
  ({
    int step,
    String id,
    String kind,
    String fen,
    int turn,
    String uci,
    bool incorrect,
  })?
  _decision;
  LessonCheckpoint? _reviewReturn;

  @override
  void emit(LessonState state) {
    final decision = _decision;
    if (decision != null &&
        decision.incorrect &&
        (state.step == decision.step ||
            (decision.kind == 'think' && state.step == decision.step + 1))) {
      final move = Move.parse(decision.uci);
      if (move != null) {
        state = state.copyWith(attemptedSan: _numbered(decision.fen, move));
      }
    }
    if (decision != null && !decision.incorrect) {
      state = state.copyWith(clearAttemptedSan: true);
    }
    super.emit(state);
    if (state.ready &&
        !state.finished &&
        state.current != null &&
        state.phase != StepPhase.waiting &&
        !(decision?.kind == 'move' &&
            decision?.incorrect == true &&
            state.step == decision?.step)) {
      unawaited(_loadExplanation(state));
    }
  }

  Future<void> _loadExplanation(LessonState snapshot) async {
    final repository = _feedback;
    final step = snapshot.current;
    if (repository == null || step == null || step.fen == null) {
      return;
    }
    final decision = _decision;
    final followsThink =
        decision != null &&
        decision.kind == 'think' &&
        snapshot.step == decision.step + 1;
    final useDecision =
        decision != null &&
        ((snapshot.step == decision.step &&
                (step is! PlayStep || snapshot.fen == decision.fen) &&
                (step is! MoveStep ||
                    snapshot.fen == decision.fen ||
                    snapshot.phase == StepPhase.done)) ||
            (followsThink && step is! DemoStep));
    final kind = switch (step) {
      ThinkStep() => 'think',
      DemoStep() => 'demo',
      MoveStep() => 'move',
      PlayStep() => 'play',
      TalkStep() => 'talk',
      _ => 'context',
    };
    final requested = useDecision
        ? (decision.incorrect
              ? ExplanationState.incorrect
              : ExplanationState.correct)
        : snapshot.interactive && !snapshot.reviewing
        ? ExplanationState.intro
        : ExplanationState.review;
    try {
      var payload = await repository.findPayload(
        lessonId: snapshot.lesson!.id,
        exerciseId: useDecision ? decision.id : step.id,
        kind: useDecision ? decision.kind : kind,
        turn: useDecision
            ? decision.turn
            : (step is MoveStep
                  ? snapshot.turn + 1
                  : step is PlayStep
                  ? (snapshot.moves.length + 1) ~/ 2 + 1
                  : 1),
        fen: useDecision
            ? decision.fen
            : (step is MoveStep || step is PlayStep
                  ? snapshot.fen!
                  : step.fen!),
        language: _language,
        state: requested,
        playedUci: useDecision ? decision.uci : null,
      );
      if (payload != null && step is DemoStep) {
        payload = ExplanationPayload(
          positionId: payload.positionId,
          reviewStepId: payload.reviewStepId,
          state: payload.state,
          explanations: [
            for (final block in payload.explanations)
              ExplanationBlock(
                id: block.id,
                kind: block.kind,
                title: block.title,
                texts: snapshot.demoMove == 0 || block.variations.isEmpty
                    ? block.texts
                    : block.variations.firstOrNull?.explanationByPly[snapshot
                              .demoMove] ??
                          (snapshot.speech == null
                              ? block.texts
                              : [snapshot.speech!]),
                variations: block.variations,
              ),
          ],
        );
        if (followsThink && snapshot.demoMove <= 1) {
          final feedback = await repository.findPayload(
            lessonId: snapshot.lesson!.id,
            exerciseId: decision.id,
            kind: decision.kind,
            turn: decision.turn,
            fen: decision.fen,
            language: _language,
            state: decision.incorrect
                ? ExplanationState.incorrect
                : ExplanationState.correct,
            playedUci: decision.uci,
          );
          payload = ExplanationPayload(
            positionId: payload.positionId,
            reviewStepId: payload.reviewStepId,
            state: payload.state,
            explanations: [
              for (final block
                  in feedback?.explanations ?? <ExplanationBlock>[])
                if (block.kind == ExplanationKind.playedCorrect ||
                    block.kind == ExplanationKind.playedIncorrect)
                  block,
              ...payload.explanations,
            ],
          );
        }
      }
      if (!isClosed &&
          !_closing &&
          identical(state, snapshot) &&
          payload != null &&
          payload.explanations.isNotEmpty) {
        super.emit(
          snapshot.copyWith(
            explanation: payload,
            attemptedSan: snapshot.attemptedSan,
            speech: payload.explanations.expand((b) => b.texts).join('\n\n'),
          ),
        );
      }
    } catch (_) {
      /* Authored data is optional; preserve the original explanation. */
    }
  }

  final ExerciseFeedbackRepository? _feedback;
  String _language = 'en';
  int _loadRevision = 0;
  final Now _now;
  final CharacterRepository _characters;
  final OpponentRepository _opponent;

  // Os sons do jogo; nulo: a lição fica muda.
  final GameSounds? _sounds;

  // A vibração; nula: sem retorno tátil.
  final GameHaptics? _haptics;

  /// A pausa antes da resposta combinada do outro lado, para o aluno ver o
  /// próprio lance antes.
  final Duration replyDelay;

  /// Quanto a máquina pensa em cada lance (e na dica).
  static const thinkTime = Duration(milliseconds: 400);

  // Contadores das falas de incentivo: cada vez sai a próxima da lista.
  final _said = <String, int>{};

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
    final startedAt = state.stepStartedAt;
    if (startedAt != null) {
      emit(
        state.copyWith(
          stepStartedAt: StepClock.resume(
            startedAt: startedAt,
            pausedAt: pausedAt,
            now: _now(),
          ),
        ),
      );
    }
    await _save();
  }

  /// Abre a aula [lessonId]. Numa aula em partes, abre a parte [part] (ou a
  /// do passo guardado, ou a primeira): a lição toca só os passos dela.
  Future<void> load(String lessonId, String language, {String? part}) async {
    _decision = null;
    _reviewReturn = null;
    final revision = ++_loadRevision;
    _language = language;
    final full = await _source.lesson(lessonId);
    final texts = await _source.texts(language);
    final characters = await _characters.characters();
    var saved = await _source.checkpoint();
    final (number, count) = await _source.placeOf(lessonId);
    final references = await _source.references(lessonId);
    if (isClosed || revision != _loadRevision) {
      return;
    }
    if (full == null || full.steps.isEmpty) {
      emit(const LessonState(ready: true, missing: true));
      return;
    }
    if (saved != null && saved.lessonId != lessonId) saved = null;
    LessonPart? opened;
    var lesson = full;
    if (full.parts.isNotEmpty) {
      // Checkpoint de antes das partes: o passo contava na aula inteira.
      if (saved != null && saved.part == null) {
        final located = full.locate(saved.step);
        saved = located == null
            ? null
            : LessonCheckpoint(
                lessonId: saved.lessonId,
                step: located.$2,
                fen: saved.fen,
                collected: saved.collected,
                turn: saved.turn,
                moves: saved.moves,
                open: saved.open,
                part: located.$1.id,
                stepId: saved.stepId,
                stepStartedAt: saved.stepStartedAt,
                stepPausedAt: saved.stepPausedAt,
                hintsShown: saved.hintsShown,
                mistakes: saved.mistakes,
                demoMove: saved.demoMove,
                demoPlaying: saved.demoPlaying,
                reviewReturn: saved.reviewReturn,
                attempt: saved.attempt,
                failed: saved.failed,
                reviewStep: saved.reviewStep,
                attemptedSan: saved.attemptedSan,
                thinkMistake: saved.thinkMistake,
              );
      }
      opened =
          full.part(part ?? '') ??
          full.part(saved?.part ?? '') ??
          full.parts.first;
      if (saved?.part != opened.id) saved = null;
      lesson = full.only(opened);
    }
    Character? viktor;
    for (final character in characters) {
      if (character.id == viktorId) viktor = character;
    }
    final base = LessonState(
      ready: true,
      lesson: lesson,
      texts: texts,
      viktor: viktor,
      lessonNumber: number,
      lessonCount: count,
      endgame: _source.endgame,
      part: opened,
      partNumber: opened == null ? 0 : full.parts.indexOf(opened) + 1,
      partCount: full.parts.length,
      references: references,
    );
    if (saved != null && saved.step < lesson.steps.length) {
      _reviewReturn = saved.reviewReturn;
      emit(
        _resumeAttempt(
          _restore(base, saved).copyWith(returnTo: _reviewReturn?.step),
          saved,
        ),
      );
      // A wrong move keeps its explanation: emit() does not fetch it for a
      // move answered at the same step (the live path asks it explicitly).
      if (_decision case final decision?
          when decision.incorrect &&
              decision.kind != 'think' &&
              decision.step == state.step) {
        await _loadExplanation(state);
      }
    } else {
      emit(_open(base, 0));
    }
    await _save();
    if (state.phase == StepPhase.waiting) {
      switch (state.current) {
        case MoveStep step:
          unawaited(_finishLineReply(step));
        case PlayStep step:
          unawaited(_replyPlay(step));
        case ThinkStep():
          unawaited(_finishThink());
        default:
          break;
      }
    }
  }

  /// O id do Viktor nas fichas dos personagens.
  static const viktorId = 'master';

  /// "Continuar": passa da fala, ou do passo cumprido, para o próximo; no
  /// último, conclui a aula.
  Future<void> next() async {
    _decision = null;
    if (!state.canContinue) {
      return;
    }
    // Revendo um ponto a partir do teste: depois do passo revisto (e da
    // explicação, se ele era de pensar), "continuar" volta ao teste.
    final returnTo = state.returnTo;
    if (returnTo != null && state.current is! ThinkStep) {
      final saved = _reviewReturn;
      _reviewReturn = null;
      emit(saved == null ? _open(state, returnTo) : _restore(state, saved));
      await _save();
      return;
    }
    final nextStep = state.step + 1;
    if (nextStep < state.stepCount) {
      emit(_carryReturn(_open(state, nextStep), returnTo));
      await _save();
      return;
    }
    await _finish();
  }

  /// "Rever este ponto": abre o passo da lição indicado pelo lance errado;
  /// "continuar" depois volta a este teste.
  Future<void> reviewPoint() async {
    final id = state.reviewStep;
    final steps = state.lesson?.steps ?? const <LessonStep>[];
    final index = steps.indexWhere((step) => step.id == id);
    if (id == null || index < 0 || index >= state.step) {
      return;
    }
    _reviewReturn = _checkpoint();
    _decision = null;
    emit(_open(state, index).copyWith(returnTo: state.step));
    await _save();
  }

  // Leva o passo do teste para onde voltar, enquanto ainda não chegou nele.
  LessonState _carryReturn(LessonState opened, int? returnTo) =>
      returnTo == null || returnTo <= opened.step
      ? opened
      : opened.copyWith(returnTo: returnTo);

  /// Volta um passo, para rever: ele abre do começo (dá para jogar de
  /// novo ou seguir com "continuar").
  Future<void> back() async {
    _decision = null;
    if (!state.canGoBack) {
      return;
    }
    emit(_carryReturn(_open(state, state.step - 1), state.returnTo));
    await _save();
  }

  /// Tenta de novo o passo de jogar, do começo.
  Future<void> retry() async {
    _decision = null;
    final step = state.current;
    // Depois de um lance errado previsto, o tabuleiro está como antes dele:
    // o aluno joga de novo dali.
    if (state.phase == StepPhase.failed &&
        state.result == null &&
        (step is MoveStep || step is PlayStep)) {
      emit(
        state.copyWith(
          phase: StepPhase.active,
          clearReview: true,
          genericMistake: false,
          speech: _pick('coach.retry'),
          emotion: Emotion.focused,
        ),
      );
      await _save();
      return;
    }
    if (step is! PlayStep) {
      return;
    }
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
    if (state.finished) {
      return;
    }
    await _source.leave();
  }

  /// O aluno moveu uma peça no tabuleiro.
  Future<void> play(Move move) async {
    if (!state.interactive) {
      return;
    }
    final origin = state;
    final current = origin.current;
    if (origin.fen != null && _position()?.isLegal(move) == true) {
      _decision = (
        step: origin.step,
        id: current!.id,
        kind: current is ThinkStep
            ? 'think'
            : current is MoveStep
            ? 'move'
            : 'play',
        fen: origin.fen!,
        turn: current is PlayStep
            ? (origin.moves.length + 1) ~/ 2 + 1
            : origin.turn + 1,
        uci: move.uci,
        incorrect: current is MoveStep
            ? !LessonRules.accepts(current, origin.turn, move.uci)
            : current is ThinkStep
            ? !LessonRules.acceptsThink(current, move.uci)
            : false,
      );
    }
    switch (state.current) {
      case StarsStep step:
        await _playStar(step, move);
      case MoveStep step:
        await _playLine(step, move);
      case PlayStep step:
        await _playOut(step, move);
      case ThinkStep():
        await _playThink(move);
      case TalkStep() || TapStep() || DemoStep() || null:
        return;
    }
  }

  // --- pensar (T51, T60) ---------------------------------------------------

  /// O cronômetro do passo (T60): quanto tempo passou desde que o passo
  /// aberto começou. A tela lê a cada instante, sem passar pelo estado.
  Duration get stepElapsed {
    final startedAt = state.stepStartedAt;
    if (startedAt == null) return Duration.zero;
    return StepClock.elapsed(startedAt: startedAt, now: _pausedAt ?? _now());
  }

  /// "Mais uma dica", quando o aluno quiser.
  Future<void> moreHint() async {
    final step = state.current;
    if (step is! ThinkStep || !state.canHint) {
      return;
    }
    final shown = state.hintsShown + 1;
    emit(
      state.copyWith(
        hintsShown: shown,
        speech: state.texts.thinkHint(_lessonId, step.id, shown),
        emotion: Emotion.focused,
      ),
    );
    await _save();
  }

  /// "Voltar à posição": o tabuleiro do passo de pensar de novo.
  void resetThink() {
    final step = state.current;
    if (step is! ThinkStep) {
      return;
    }
    emit(state.copyWith(fen: step.fen, clearLastMove: true));
  }

  // No passo de pensar, o lance do aluno é a resposta: o cronômetro para e
  // a explicação vem logo, com um "correto" se ele achou o lance da aula
  // (T59) ou, se errou, começando por que o lance dele não funciona.
  // "Ver explicação" faz o mesmo sem lance.
  Future<void> _playThink(Move move) async {
    final position = _position();
    if (position == null) {
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) {
      return;
    }
    unawaited(_sounds?.move(played.san));
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        moves: [move.uci],
        phase: StepPhase.waiting,
      ),
    );
    await _save();
    await _finishThink();
  }

  Future<void> _finishThink() async {
    final stepIndex = state.step;
    final step = state.current! as ThinkStep;
    final move = state.moves.isEmpty ? null : Move.parse(state.moves.last);
    if (move == null) {
      await _waitForForeground();
      if (!isClosed && !_closing) await _explain();
      return;
    }
    final answerFen = state.fen;
    await Future<void>.delayed(replyDelay);
    await _waitForForeground();
    if (isClosed || _closing || state.step != stepIndex) {
      return;
    }
    final nextIndex = stepIndex + 1;
    if (nextIndex < state.stepCount) {
      final steps = state.lesson!.steps;
      final thinkFen = steps[stepIndex].fen;
      if (LessonRules.acceptsThink(step, move.uci)) {
        _explainGuessed(nextIndex, answerFen, move);
        await _save();
        return;
      }
      // O lance que a explicação mostra: o tabuleiro segue dele.
      if (_guessed(steps[nextIndex], move.uci)) {
        _explainGuessed(nextIndex, answerFen, move);
        await _save();
        return;
      }
      // Outro lance que a aula também aceita (o passo de jogar da mesma
      // posição): está certo, mas a explicação parte da posição dela.
      if (_alsoAccepted(steps, nextIndex, thinkFen, move.uci)) {
        _explainGuessed(nextIndex, null, move);
        await _save();
        return;
      }
      if (_thinkMistake(step, steps[nextIndex], move)) {
        await _save();
        return;
      }
    }
    await _explain();
  }

  /// Lance errado no passo de pensar: a explicação abre na hora, começando
  /// por que o lance perde (a fala de `mistakes`, ou a frase genérica do app
  /// com o lance numerado). Sem lance certo conhecido (nem `accept` nem um
  /// lance mostrado na explicação), não há como dizer que errou: falso.
  bool _thinkMistake(ThinkStep step, LessonStep next, Move move) {
    final said = _mistakeText(step.mistakes[move.uci]?.say);
    if (said == null &&
        step.accept.isEmpty &&
        !_showsMove(next) &&
        !step.mistakes.containsKey(move.uci)) {
      return false;
    }
    final opened = _open(state, state.step + 1);
    if (said != null) {
      emit(_thinkSaid(opened, step, said));
      return true;
    }
    final numbered = _numbered(step.fen, move);
    emit(opened.copyWith(thinkMistake: numbered, emotion: Emotion.focused));
    return true;
  }

  /// The step after a think step, opened by a wrong move that has its own
  /// speech: the speech first, then the context of the step.
  static LessonState _thinkSaid(
    LessonState opened,
    ThinkStep step,
    String said,
  ) => opened.copyWith(
    speech: [said, ?opened.speech].join('\n\n'),
    explanation: ExplanationPayload(
      positionId: step.id,
      state: ExplanationState.incorrect,
      explanations: [
        ExplanationBlock(
          id: 'played',
          kind: ExplanationKind.playedIncorrect,
          texts: [said],
        ),
        if (opened.speech case final text?)
          ExplanationBlock(
            id: 'context',
            kind: ExplanationKind.context,
            texts: [text],
          ),
      ],
    ),
    emotion: Emotion.focused,
  );

  /// Reopening the app on a wrong answer (T65 §7): the failed phase, the
  /// numbered move and the explanation come back. The decision is restored
  /// too, so the repository returns the same payload for the step id.
  LessonState _resumeAttempt(LessonState restored, LessonCheckpoint saved) {
    final attempt = saved.attempt;
    final steps = restored.lesson?.steps ?? const <LessonStep>[];
    if (attempt == null ||
        attempt.step < 0 ||
        attempt.step >= steps.length ||
        steps[attempt.step].id != attempt.id ||
        !(attempt.step == restored.step ||
            (attempt.kind == 'think' && restored.step == attempt.step + 1))) {
      return restored;
    }
    _decision = (
      step: attempt.step,
      id: attempt.id,
      kind: attempt.kind,
      fen: attempt.fen,
      turn: attempt.turn,
      uci: attempt.uci,
      incorrect: attempt.incorrect,
    );
    if (!attempt.incorrect) return restored;
    final texts = restored.texts;
    final lessonId = restored.lesson!.id;
    final answered = steps[attempt.step];
    if (attempt.kind == 'think' && answered is ThinkStep) {
      final said = _mistakeTextIn(
        texts,
        lessonId,
        answered.mistakes[attempt.uci]?.say,
      );
      if (said != null) return _thinkSaid(restored, answered, said);
      return restored.copyWith(
        thinkMistake: saved.thinkMistake,
        emotion: Emotion.focused,
      );
    }
    final step = restored.current;
    final mistake = switch (step) {
      MoveStep(:final mistakes) ||
      PlayStep(:final mistakes) => mistakes[attempt.uci],
      _ => null,
    };
    if (saved.failed) {
      final text = _mistakeTextIn(texts, lessonId, mistake?.say);
      return restored.copyWith(
        phase: StepPhase.failed,
        speech: text ?? texts.say('coach.wrong'),
        genericMistake: mistake != null && text == null,
        reviewStep: saved.reviewStep,
        clearReview: saved.reviewStep == null,
        clearHint: true,
        attemptedSan: saved.attemptedSan,
        emotion: Emotion.focused,
      );
    }
    if (step is! MoveStep) return restored;
    // A wrong move in a move step: the piece went back, the hint speaks and,
    // from the second mistake, the arrow shows the move.
    final hint = texts.hint(lessonId, step.id);
    return restored.copyWith(
      speech: hint ?? texts.say('coach.wrong'),
      genericMistake: hint == null,
      hint: restored.mistakes >= 2 && restored.turn < step.line.length
          ? Move.parse(step.line[restored.turn].accept.first)
          : null,
      attemptedSan: saved.attemptedSan,
      emotion: Emotion.focused,
    );
  }

  /// A explicação [next] mostra um lance (seta, demonstração ou passo de
  /// lance).
  static bool _showsMove(LessonStep next) => switch (next) {
    TalkStep(:final arrows) => arrows.isNotEmpty,
    DemoStep(:final line) => line.isNotEmpty,
    MoveStep(:final line) => line.isNotEmpty,
    _ => false,
  };

  /// [move] em SAN numerado a partir de [fen] (`1.Kd2`, `55...Ke5`).
  static String? _numbered(String fen, Move move) {
    final position = GameRules.fromFen(fen);
    final played = position == null ? null : GameRules.play(position, move);
    if (position == null || played == null) {
      return null;
    }
    final dots = position.turn == Side.white ? '.' : '...';
    return '${position.fullmoves}$dots${played.san}';
  }

  /// A explicação: o passo seguinte (ou o fim da parte).
  Future<void> _explain() async {
    final nextStep = state.step + 1;
    if (nextStep < state.stepCount) {
      emit(_open(state, nextStep));
      await _save();
      return;
    }
    await _finish();
  }

  /// [uci] é aceito pelo passo de jogar que vem depois da explicação, na
  /// mesma posição do passo de pensar (antes do próximo passo de pensar).
  static bool _alsoAccepted(
    List<LessonStep> steps,
    int from,
    String? fen,
    String uci,
  ) {
    for (final step in steps.skip(from)) {
      if (step is ThinkStep) return false;
      if (step is MoveStep && step.fen == fen && step.line.isNotEmpty) {
        return step.line.first.accept.contains(uci);
      }
    }
    return false;
  }

  /// O lance [uci] é o que o passo [next] (a explicação) mostra primeiro.
  static bool _guessed(LessonStep next, String uci) => switch (next) {
    TalkStep(:final arrows) when arrows.isNotEmpty =>
      '${arrows.first.$1}${arrows.first.$2}' == uci,
    DemoStep(:final line) when line.isNotEmpty => line.first.uci == uci,
    MoveStep(:final line) when line.isNotEmpty => line.first.accept.contains(
      uci,
    ),
    _ => false,
  };

  /// Acertou o lance pensando: a explicação abre com um "correto" antes da
  /// fala e, com [fen] (o lance que ela mostra), o tabuleiro onde o aluno
  /// deixou, sem voltar e refazer o lance.
  void _explainGuessed(int index, String? fen, Move move) {
    final step = state.lesson!.steps[index];
    var opened = _open(state, index);
    // Sem [fen]: certo, mas não é o lance que a explicação mostra; ela
    // parte da posição dela.
    if (fen != null && step is TalkStep) {
      opened = opened.copyWith(fen: fen, lastMove: move);
    } else if (fen != null && step is DemoStep) {
      opened = _demoAt(opened, step, 1);
    }
    final right = _pick('coach.thinkRight') ?? _pick('coach.praise');
    final speech = opened.speech;
    emit(
      opened.copyWith(
        speech: [?right, ?speech].join(' '),
        emotion: Emotion.happy,
      ),
    );
  }

  // --- demonstração (T51) -------------------------------------------------

  /// O próximo lance da demonstração (a tela chama no ritmo da fala, ou o
  /// aluno avança na mão): ela volta a andar sozinha.
  Future<void> demoForward() async {
    final step = state.current;
    if (step is! DemoStep || state.demoMove >= step.line.length) {
      return;
    }
    emit(_demoAt(state.copyWith(demoPlaying: true), step, state.demoMove + 1));
    await _save();
  }

  /// Volta um lance: desfaz no tabuleiro e mostra a fala daquele ponto.
  Future<void> demoBack() async {
    final step = state.current;
    if (step is! DemoStep || state.demoMove == 0) {
      return;
    }
    emit(_demoAt(state, step, state.demoMove - 1).copyWith(demoPlaying: false));
    await _save();
  }

  /// Pausa a demonstração (ela para de andar sozinha) ou a retoma.
  void demoTogglePause() {
    if (state.current is! DemoStep) {
      return;
    }
    emit(state.copyWith(demoPlaying: !state.demoPlaying));
    unawaited(_save());
  }

  /// Repete a demonstração do começo.
  Future<void> demoReplay() async {
    final step = state.current;
    if (step is! DemoStep) {
      return;
    }
    emit(_demoAt(state, step, 0).copyWith(demoPlaying: true));
    await _save();
  }

  /// A demonstração depois de [count] lances: o tabuleiro, o último lance e
  /// a fala dele (zero: a fala de abertura).
  LessonState _demoAt(LessonState base, DemoStep step, int count) {
    var position = GameRules.fromFen(step.fen);
    Move? last;
    for (final move in step.line.take(count)) {
      final parsed = Move.parse(move.uci);
      final played = position == null || parsed == null
          ? null
          : GameRules.play(position, parsed);
      if (played == null) break;
      position = played.position;
      last = parsed;
      if (count == base.demoMove + 1 && move == step.line[count - 1]) {
        unawaited(_sounds?.move(played.san));
      }
    }
    final done = count >= step.line.length;
    return LessonState(
      ready: true,
      lesson: base.lesson,
      texts: base.texts,
      viktor: base.viktor,
      lessonNumber: base.lessonNumber,
      lessonCount: base.lessonCount,
      endgame: base.endgame,
      part: base.part,
      partNumber: base.partNumber,
      partCount: base.partCount,
      references: base.references,
      step: base.step,
      reached: base.reached,
      stepStartedAt: base.stepStartedAt,
      fen: position?.fen ?? step.fen,
      lastMove: last,
      demoMove: count,
      demoPlaying: base.demoPlaying && !done,
      phase: done ? StepPhase.done : StepPhase.active,
      speech: count == 0
          ? base.texts.step(base.lesson!.id, step.id)
          : base.texts.demoMove(base.lesson!.id, step.id, count),
      emotion: done ? Emotion.happy : Emotion.calm,
    );
  }

  /// O aluno tocou numa casa (no passo de tocar): certa, vai para a
  /// próxima; errada, o Viktor dá a dica.
  Future<void> tap(String square) async {
    final step = state.current;
    final target = state.tapTarget;
    if (step is! TapStep || target == null) {
      return;
    }
    if (square != target) {
      emit(
        state.copyWith(
          speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.hint'),
          emotion: Emotion.focused,
        ),
      );
      return;
    }
    unawaited(_sounds?.play(GameSound.move));
    unawaited(_haptics?.play(HapticEvent.selection));
    final collected = [...state.collected, square];
    final allDone = collected.length >= step.targets.length;
    emit(
      state.copyWith(
        collected: collected,
        phase: allDone ? StepPhase.done : StepPhase.active,
        speech: allDone
            ? state.texts.done(_lessonId, step.id) ?? _pick('coach.praise')
            : _pick('coach.star'),
        emotion: allDone ? Emotion.happy : Emotion.calm,
      ),
    );
    await _save();
  }

  /// Pede ao mestre o melhor lance (vira uma seta no tabuleiro).
  Future<void> askHint() async {
    final current = state.current;
    if (!state.interactive) {
      return;
    }
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
        if (position == null) {
          return;
        }
        final fen = state.fen;
        final move = await _opponent.pickMove(position, thinkTime: thinkTime);
        if (isClosed || _closing || state.fen != fen || move == null) {
          return;
        }
        emit(
          state.copyWith(
            hint: move,
            speech: _pick('coach.hint'),
            emotion: Emotion.focused,
          ),
        );
      case StarsStep() || TalkStep() || TapStep() || ThinkStep() || null:
        return;
      case DemoStep():
        return;
    }
  }

  /// Num passo de estrelas, o aluno levou a peça de [from] para [to], aonde
  /// ela não anda (o tabuleiro só ignora o lance): a peça fica onde estava e
  /// o Viktor diz, curto, como ela anda. Soltar em cima de outra peça do
  /// aluno é só escolher outra peça: sem fala.
  void refuseStar(Square from, Square to) {
    final step = state.current;
    if (step is! StarsStep || !state.interactive || from == to) {
      return;
    }
    final board = LessonRules.starsBoard(state.fen!);
    final piece = board.pieceAt(from);
    if (piece == null || piece.color != step.side) {
      return;
    }
    if (board.pieceAt(to)?.color == step.side) {
      return;
    }
    if (LessonRules.moveStar(board, step.side, from, to) != null) {
      return;
    }
    _refusal =
        _pick('coach.illegal.${piece.role.name}') ?? _pick('coach.wrong');
    emit(state.copyWith(speech: _refusal, emotion: Emotion.focused));
  }

  // A última fala de lance proibido: o lance certo seguinte a tira.
  String? _refusal;

  Future<void> _playStar(StarsStep step, Move move) async {
    if (move is! NormalMove) {
      return;
    }
    final board = LessonRules.starsBoard(state.fen!);
    final moved = LessonRules.moveStar(board, step.side, move.from, move.to);
    if (moved == null) {
      return;
    }
    unawaited(_sounds?.play(GameSound.move));
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
            : state.speech == _refusal
            ? state.texts.step(_lessonId, step.id) ?? state.speech
            : state.speech,
        emotion: allDone ? Emotion.happy : state.emotion,
      ),
    );
    await _save();
  }

  Future<void> _playLine(MoveStep step, Move move) async {
    final position = _position();
    if (position == null || GameRules.play(position, move) == null) {
      return;
    }
    if (!LessonRules.accepts(step, state.turn, move.uci)) {
      if (step.mistakes[move.uci] case final mistake?) {
        await _explainMistake(mistake);
        await _loadExplanation(state);
        return;
      }
      if (_feedback is ExplanationRepository &&
          await _explainContextualMistake(move)) {
        return;
      }
      // A peça volta: a tela redesenha o tabuleiro a cada estado novo. No
      // segundo erro, o mestre já mostra a seta.
      final mistakes = state.mistakes + 1;
      final hint = state.texts.hint(_lessonId, step.id);
      emit(
        state.copyWith(
          speech: hint ?? _pick('coach.wrong'),
          genericMistake: hint == null,
          emotion: Emotion.focused,
          hint: mistakes >= 2
              ? Move.parse(step.line[state.turn].accept.first)
              : null,
          clearHint: mistakes < 2,
          mistakes: mistakes,
        ),
      );
      await _loadExplanation(state);
      await _save();
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) {
      return;
    }
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    final turn = step.line[state.turn];
    final ends = LessonRules.endsLine(step, state.turn, move.uci);
    if (ends) {
      emit(
        state.copyWith(
          fen: played.position.fen,
          lastMove: move,
          turn: state.turn + 1,
          clearHint: true,
          phase: StepPhase.done,
          speech: state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
          emotion: Emotion.happy,
          genericMistake: false,
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
        genericMistake: false,
        emotion: Emotion.happy,
      ),
    );
    await _save();
    await _finishLineReply(step);
  }

  Future<void> _finishLineReply(MoveStep step) async {
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
        // inconsistente): o passo acaba aqui, cumprido.
        emit(
          state.copyWith(
            turn: step.line.length,
            phase: StepPhase.done,
            speech:
                state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
            emotion: Emotion.happy,
          ),
        );
        await _save();
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
        phase: StepPhase.active,
      ),
    );
    await _save();
  }

  Future<void> _playOut(PlayStep step, Move move) async {
    final position = _position();
    if (position == null) {
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) {
      return;
    }
    if (step.mistakes[move.uci] case final mistake?) {
      final decision = _decision;
      if (decision != null) {
        _decision = (
          step: decision.step,
          id: decision.id,
          kind: decision.kind,
          fen: decision.fen,
          turn: decision.turn,
          uci: decision.uci,
          incorrect: true,
        );
      }
      await _explainMistake(mistake);
      await _loadExplanation(state);
      return;
    }
    if (_feedback is ExplanationRepository &&
        await _explainContextualMistake(move)) {
      return;
    }
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    var moves = [...state.moves, move.uci];
    final start = GameRules.fromFen(step.fen)!;
    var result = LessonRules.resultOf(
      played.position,
      goal: step.goal,
      student: step.side,
      lastMove: move,
      repetitions: GameRules.repetitionsOf(start, moves),
      studentMoves: (moves.length + 1) ~/ 2,
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
    await _replyPlay(step);
  }

  Future<void> _replyPlay(PlayStep step) async {
    final position = _position();
    if (position == null) {
      return;
    }
    final start = GameRules.fromFen(step.fen)!;
    var moves = state.moves;
    final reply = await _opponent.pickMove(
      position,
      thinkTime: thinkTime,
      kind: step.opponent.kind,
      level: step.opponent.level,
      history: [start],
    );
    await _waitForForeground();
    if (isClosed || _closing || state.fen != position.fen) {
      return;
    }
    final answered = reply == null ? null : GameRules.play(position, reply);
    if (answered == null) {
      emit(state.copyWith(phase: StepPhase.active));
      return;
    }
    unawaited(_sounds?.move(answered.san));
    moves = [...moves, reply!.uci];
    final result = LessonRules.resultOf(
      answered.position,
      goal: step.goal,
      student: step.side,
      lastMove: reply,
      repetitions: GameRules.repetitionsOf(start, moves),
      studentMoves: (moves.length + 1) ~/ 2,
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

  // Content metadata alone may reject a move, and only at this exact origin.
  Future<bool> _explainContextualMistake(Move move) async {
    final repository = _feedback;
    final decision = _decision;
    if (repository is! ExplanationRepository || decision == null) return false;
    ExplanationPayload? payload;
    try {
      payload = await repository!.findPayload(
        lessonId: _lessonId,
        exerciseId: decision.id,
        kind: decision.kind,
        turn: decision.turn,
        fen: decision.fen,
        language: _language,
        state: ExplanationState.incorrect,
        playedUci: move.uci,
      );
    } catch (_) {
      return false;
    }
    if (isClosed ||
        _closing ||
        _decision != decision ||
        state.step != decision.step ||
        state.fen != decision.fen ||
        !state.interactive) {
      return true;
    }
    final steps = state.lesson!.steps;
    final target = steps.indexWhere((step) => step.id == payload?.reviewStepId);
    if (payload == null || target < 0 || target >= state.step) return false;
    final roots = payload.variations.where(
      (v) =>
          v.parentId == null &&
          v.originFen == decision.fen &&
          v.firstUci == move.uci &&
          payload!.openVariation(v) != null,
    );
    if (roots.any((v) => v.outcome == VariationOutcome.accepted) ||
        !roots.any((v) => v.outcome != VariationOutcome.accepted)) {
      return false;
    }
    _decision = (
      step: decision.step,
      id: decision.id,
      kind: decision.kind,
      fen: decision.fen,
      turn: decision.turn,
      uci: decision.uci,
      incorrect: true,
    );
    emit(
      state.copyWith(
        phase: StepPhase.failed,
        mistakes: state.mistakes + 1,
        reviewStep: payload.reviewStepId,
        clearHint: true,
        explanation: payload,
        speech: payload.explanations.expand((b) => b.texts).join('\n\n'),
        genericMistake: false,
        emotion: Emotion.focused,
      ),
    );
    await _loadExplanation(state);
    await _save();
    return true;
  }

  /// O lance errado previsto: a peça volta, o Viktor explica o erro e o
  /// rodapé oferece rever o ponto da lição e tentar de novo.
  Future<void> _explainMistake(StepMistake mistake) async {
    final text = _mistakeText(mistake.say);
    final review = mistake.review;
    final steps = state.lesson?.steps ?? const <LessonStep>[];
    final index = steps.indexWhere((step) => step.id == review);
    final reviewable = index >= 0 && index < state.step;
    emit(
      state.copyWith(
        phase: StepPhase.failed,
        mistakes: state.mistakes + 1,
        speech: text ?? _pick('coach.wrong'),
        genericMistake: text == null,
        reviewStep: reviewable ? review : null,
        clearReview: !reviewable,
        clearHint: true,
        emotion: Emotion.focused,
      ),
    );
    await _save();
  }

  /// A fala de um lance errado: `step.x` do arquivo de falas da aula vira
  /// `<aula>.x`; outra chave vale como está.
  String? _mistakeText(String? key) =>
      _mistakeTextIn(state.texts, _lessonId, key);

  static String? _mistakeTextIn(
    LessonTexts texts,
    String lessonId,
    String? key,
  ) {
    if (key == null) {
      return null;
    }
    final local = key.startsWith('step.')
        ? '$lessonId.${key.substring('step.'.length)}'
        : '$lessonId.$key';
    return texts.say(local) ?? texts.say(key);
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
    final part = state.part;
    if (part != null) {
      // Parte concluída: o cartão "Parte N concluída" com a próxima.
      final outcome = await _source.completePart(lesson.id, part.id);
      if (isClosed) {
        return;
      }
      unawaited(_haptics?.play(HapticEvent.success));
      emit(
        state.copyWith(
          finished: true,
          nextPart: outcome.nextPart,
          speech: _pick('coach.partDone') ?? _pick('coach.lessonDone'),
          emotion: Emotion.confident,
        ),
      );
      return;
    }
    final outcome = await _source.complete(lesson.id);
    if (isClosed) {
      return;
    }
    // A formatura é só da escola: na trilha de finais, a última lição
    // termina como as outras.
    final courseFinished = outcome.last && !state.endgame;
    unawaited(
      _haptics?.play(
        courseFinished ? HapticEvent.celebrate : HapticEvent.success,
      ),
    );
    emit(
      state.copyWith(
        finished: true,
        courseFinished: courseFinished,
        graduationPath: courseFinished ? outcome.path : const [],
        finishedAt: _now(),
        nextLesson: outcome.next,
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
    return LessonState(
      ready: true,
      lesson: base.lesson,
      texts: base.texts,
      viktor: base.viktor,
      lessonNumber: base.lessonNumber,
      lessonCount: base.lessonCount,
      endgame: base.endgame,
      part: base.part,
      partNumber: base.partNumber,
      partCount: base.partCount,
      step: index,
      reached: index > base.reached ? index : base.reached,
      fen: step.fen,
      speech: _speechOf(base, index),
      emotion: index == 0 ? Emotion.happy : Emotion.calm,
      // O cronômetro do passo começa ao abrir.
      stepStartedAt: _now(),
      references: base.references,
    );
  }

  /// A fala do passo [index]. Logo depois de um passo de pensar, a
  /// explicação começa pelo contexto que o enunciado dele trazia: o passo
  /// de pensar só pergunta, curto, para o tabuleiro ficar no centro.
  String? _speechOf(LessonState base, int index) {
    final lessonId = base.lesson!.id;
    final steps = base.lesson!.steps;
    final speech = base.texts.step(lessonId, steps[index].id);
    final previous = index == 0 ? null : steps[index - 1];
    if (previous is! ThinkStep || steps[index] is ThinkStep) return speech;
    final prompt = base.texts.step(lessonId, previous.id);
    final context = prompt == null ? '' : LessonRules.thinkContext(prompt);
    if (context.isEmpty) return speech;
    return [context, ?speech].join(' ');
  }

  /// O passo guardado, com o tabuleiro de quando o app fechou.
  LessonState _restore(LessonState base, LessonCheckpoint saved) {
    final opened = _open(base, saved.step);
    final step = opened.current!;
    // Só reaproveita o tempo se ele foi salvo para este mesmo passo. Um
    // checkpoint sem id é de uma versão anterior e não pode trazer a duração
    // de outro passo para a aula atual.
    var restored = opened.copyWith(
      collected: saved.collected,
      turn: saved.turn,
      moves: saved.moves,
      mistakes: saved.mistakes,
      stepStartedAt: saved.stepId == step.id
          ? (saved.stepStartedAt != null && saved.stepPausedAt != null
                ? StepClock.resume(
                    startedAt: saved.stepStartedAt!,
                    pausedAt: saved.stepPausedAt!,
                    now: _now(),
                  )
                : saved.stepStartedAt)
          : opened.stepStartedAt,
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
          restored = restored.copyWith(
            fen: position.fen,
            lastMove: last,
            phase: position.turn != step.side
                ? StepPhase.waiting
                : StepPhase.active,
          );
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
          phase: saved.turn >= line.length
              ? StepPhase.done
              : GameRules.fromFen(saved.fen ?? step.fen)?.turn != step.side
              ? StepPhase.waiting
              : StepPhase.active,
        );
      case TapStep(:final targets):
        restored = restored.copyWith(
          phase: saved.collected.length >= targets.length
              ? StepPhase.done
              : StepPhase.active,
        );
      case ThinkStep():
        final pending =
            saved.fen != null &&
            saved.fen != step.fen &&
            GameRules.fromFen(saved.fen!)?.turn != step.side;
        final hints = saved.hintsShown;
        restored = restored.copyWith(
          fen: saved.fen,
          hintsShown: hints,
          phase: pending ? StepPhase.waiting : StepPhase.active,
          lastMove: pending && saved.moves.isNotEmpty
              ? Move.parse(saved.moves.last)
              : null,
          speech: hints == 0
              ? base.texts.step(base.lesson!.id, step.id)
              : base.texts.thinkHint(base.lesson!.id, step.id, hints),
        );
      case DemoStep():
        // Retoma o lance guardado, preservando a pausa escolhida pelo aluno.
        restored = _demoAt(
          restored.copyWith(demoPlaying: saved.demoPlaying),
          step,
          saved.demoMove,
        );
      case TalkStep():
        break;
    }
    // Passo já cumprido: o Viktor volta dizendo o que disse ao cumprir.
    if (restored.phase == StepPhase.done) {
      final done = base.texts.done(base.lesson!.id, step.id);
      if (done != null) restored = restored.copyWith(speech: done);
    }
    return restored;
  }

  Future<void> _save() async {
    final lesson = state.lesson;
    if (lesson == null || state.finished) {
      return;
    }
    await _source.saveCheckpoint(_checkpoint());
  }

  LessonCheckpoint _checkpoint() => LessonCheckpoint(
    lessonId: state.lesson!.id,
    step: state.step,
    fen: state.fen,
    collected: state.collected,
    turn: state.turn,
    moves: state.moves,
    part: state.part?.id,
    stepId: state.current?.id,
    stepStartedAt: state.stepStartedAt,
    stepPausedAt: _pausedAt,
    hintsShown: state.hintsShown,
    mistakes: state.mistakes,
    demoMove: state.demoMove,
    demoPlaying: state.demoPlaying,
    reviewReturn: _reviewReturn,
    attempt: switch (_decision) {
      final d? => LessonAttempt(
        step: d.step,
        id: d.id,
        kind: d.kind,
        fen: d.fen,
        turn: d.turn,
        uci: d.uci,
        incorrect: d.incorrect,
      ),
      null => null,
    },
    failed: state.phase == StepPhase.failed && state.result == null,
    reviewStep: state.reviewStep,
    attemptedSan: state.attemptedSan,
    thinkMistake: state.thinkMistake,
  );

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
