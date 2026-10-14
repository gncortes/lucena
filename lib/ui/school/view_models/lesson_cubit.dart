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
import '../../../domain/models/failed_alternative.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/branch_comments.dart';
import '../../../domain/use_cases/engine_fallback.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/step_clock.dart';
import '../../core/sound/game_sounds.dart';
import '../../../domain/models/game_end.dart';
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

/// A fala genérica do app que a tela escreve (l10n) no lugar de um texto da
/// aula: o motor respondeu (T70, crit. 8) ou o aluno achou outro lance bom.
enum LessonNote {
  /// "Também é correto. A aula segue com {move}." ([LessonState.noteSan]).
  alsoCorrect,

  /// Comentário do lance do aluno / da resposta do motor (neutros).
  engineMove,
  engineReply,

  /// O motor diz que o lance mantém o resultado (ganhar / empatar), sem e
  /// com o "agora veja o caminho que a lição mostra" (aprendizado).
  alsoWins,
  alsoHolds,
  alsoWinsShowMain,
  alsoHoldsShowMain,

  /// Fim de partida na demonstração fora do roteiro: o tabuleiro trava.
  gameMate,
  gameStalemate,
  gameInsufficient,
  gameRepetition,
  gameFifty;

  /// A partida acabou (o tabuleiro não aceita mais lance).
  bool get isGameEnd => index >= gameMate.index;
}

/// Um lance do aluno com a resposta da máquina no prático (T70): a unidade do
/// "Voltar" e do "Continuar".
class PracticePair {
  const PracticePair({
    required this.fenBefore,
    required this.turnBefore,
    required this.movesBefore,
    required this.student,
    this.reply,
    this.onLine = true,
    this.commentBefore,
    this.lastMoveBefore,
    this.note,
    this.speech,
  });

  final String fenBefore;
  final int turnBefore;
  final List<String> movesBefore;
  final String student;
  final String? reply;

  /// O par segue a linha da aula (o "Voltar" o devolve ao "Continuar");
  /// fora dela (erro, motor), o "Voltar" o descarta.
  final bool onLine;
  final String? commentBefore;
  final Move? lastMoveBefore;

  /// Par fora da linha: a nota genérica do motor ou a fala do erro que ele
  /// mostrou, para o "Continuar" refazer o par como estava.
  final LessonNote? note;
  final String? speech;
}

class LessonState {
  const LessonState({
    this.ready = false,
    this.missing = false,
    this.toScript = false,
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
    this.wrongMove = false,
    this.solutionSeen = false,
    this.presenting = false,
    this.correct = false,
    this.thinkPlayed,
    this.fullSpeech,
    this.alternatives = const [],
    this.seen = const {},
    this.wrongNotice = false,
    this.note,
    this.noteSan,
    this.typing = false,
    this.engineErrors = 0,
    this.engineLine = const [],
    this.practiceGate = false,
    this.practiceComment,
    this.practiceHint = false,
    this.practiceUndo = const [],
    this.practiceRedo = const [],
    this.offLine = false,
    this.demoOff = const [],
    this.demoOffFrom = 0,
  });

  // --- T70: fluxo da lição ---------------------------------------------------

  /// O estado correto do passo de pensar (crit. 7): o tabuleiro depois do
  /// lance principal, o mesmo por acerto, por erro + "Ver resposta" ou por
  /// "Ver resposta" do enunciado.
  final bool correct;

  /// O lance (UCI) que o aluno jogou no passo de pensar, se jogou.
  final String? thinkPlayed;

  /// O texto inteiro da explicação, quando o estado correto mostra a curta
  /// (`.short`): "Ver explicação completa" troca [speech] por ele. Nulo: o
  /// texto já é o completo.
  final String? fullSpeech;

  /// "Alternativas que falham" do estado correto, com o "Já visto".
  final List<FailedAlternative> alternatives;

  /// Os lances (UCI) que o aluno já abriu.
  final Set<String> seen;

  /// Erro sem ramo e sem motor (crit. 1, opção A): a peça voltou e a 1ª linha
  /// da folha vira "Lance errado. Tente outro lance."
  final bool wrongNotice;

  /// A fala genérica do app em vez de [speech] (a tela escreve).
  final LessonNote? note;
  final String? noteSan;

  /// A máquina está pensando: três pontinhos no lugar do comentário.
  final bool typing;

  /// Quantas vezes o motor falhou (a tela mostra o snackbar a cada mudança).
  final int engineErrors;

  /// A linha "lance do aluno + resposta do motor" (UCI) que a tela mostra no
  /// modo variante como um ramo comum (crit. 8b).
  final List<String> engineLine;

  /// O convite "Vamos praticar": antes do 1º move/play da parte. O tabuleiro
  /// não responde até [LessonCubit.startPractice].
  final bool practiceGate;

  /// O texto do balão do Viktor no prático.
  final String? practiceComment;

  /// O balão mostra a Dica (leva o selo "Dica").
  final bool practiceHint;

  /// Os pares lance + resposta jogados (para "Voltar") e os desfeitos (para
  /// "Continuar").
  final List<PracticePair> practiceUndo;
  final List<PracticePair> practiceRedo;
  bool get canUndo => practiceUndo.isNotEmpty;
  bool get canRedo => practiceRedo.isNotEmpty;

  /// O prático saiu da linha da aula (erro com refutação, motor): só o
  /// "Voltar" devolve a vez.
  final bool offLine;

  /// Na demonstração: os lances (UCI) que o aluno jogou fora do roteiro, com
  /// a resposta, e o lance do roteiro em que ele saiu.
  final List<String> demoOff;
  final int demoOffFrom;
  bool get offScript => demoOff.isNotEmpty;

  /// A abertura de um passo de exercício (T65 §8): o Viktor apresenta o
  /// objetivo e o relógio do passo ainda não começou. Não é salvo: fechar o
  /// app durante a apresentação reabre com o relógio correndo.
  final bool presenting;

  /// "Ver solução" (T65 §4): depois de um lance errado, o aluno pediu a
  /// solução. O tabuleiro fica na posição anterior ao erro, sem toque, com
  /// a seta no lance certo; o rodapé oferece tentar de novo, voltar e
  /// continuar. Persistido: fechar o app reabre aqui.
  final bool solutionSeen;

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

  /// Lance errado num passo de lance: a folha explica o erro (LANCE ERRADO,
  /// LANCE CERTO) e o tabuleiro segue livre, com o rodapé de prática.
  final bool wrongMove;

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

  /// A parte aberta ([part]; nula: a aula [lesson] inteira) toca na tela de
  /// roteiro (T70/T71): a tela da lição troca de rota.
  final bool toScript;
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
          // Lance errado explicado: "Continuar" vale sem refazer (§3).
          (showsMistake &&
              result == null &&
              (explanation != null || wrongMove) &&
              (current is MoveStep || current is ThinkStep)) ||
          // "Ver explicação": quando o aluno quiser (T60).
          current is ThinkStep);

  /// O erro do aluno está na tela: o passo falhou (`failed`) ou o lance errado
  /// só devolveu a peça e abriu a explicação (`wrongMove`, passo de lance sem
  /// erro previsto). Nos dois, valem Voltar | Ver solução | Continuar.
  bool get showsMistake => phase == StepPhase.failed || wrongMove;

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

  /// O lance certo do passo falhado, para a seta da Solução vista: o da
  /// linha (passo de lance) ou o primeiro da solução principal da explicação.
  Move? get solutionMove {
    final step = current;
    if (step is MoveStep && turn < step.line.length) {
      final accepted = step.line[turn].accept;
      if (accepted.isNotEmpty) return Move.parse(accepted.first);
    }
    for (final block in explanation?.explanations ?? const []) {
      if (block.kind != ExplanationKind.mainSolution) continue;
      for (final variation in block.variations) {
        if (variation.parentId != null) continue;
        final uci = variation.firstUci;
        if (uci != null) return Move.parse(uci);
      }
    }
    return null;
  }

  LessonStep? get current {
    final steps = lesson?.steps;
    if (steps == null || step >= steps.length) {
      return null;
    }
    return steps[step];
  }

  int get stepCount => lesson?.steps.length ?? 0;

  /// Quanto da aula já foi feito, de 0 a 1: anda por passo, e só por passo
  /// (passo 1 de 3 vale 1/3; no último a barra fica cheia).
  double get progress {
    if (stepCount == 0) return 0;
    if (finished) return 1;
    return ((step + 1) / stepCount).clamp(0.0, 1.0);
  }

  /// O aluno pode mexer no tabuleiro (no passo de tocar, só tocar).
  bool get interactive =>
      phase == StepPhase.active &&
      !practiceGate &&
      !offLine &&
      !typing &&
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
    bool? wrongMove,
    bool? solutionSeen,
    bool? presenting,
    bool clearAttemptedSan = false,
    bool? correct,
    String? thinkPlayed,
    String? fullSpeech,
    bool clearFullSpeech = false,
    List<FailedAlternative>? alternatives,
    Set<String>? seen,
    bool? wrongNotice,
    LessonNote? note,
    String? noteSan,
    bool clearNote = false,
    bool? typing,
    int? engineErrors,
    List<String>? engineLine,
    bool? practiceGate,
    String? practiceComment,
    bool clearPracticeComment = false,
    bool? practiceHint,
    List<PracticePair>? practiceUndo,
    List<PracticePair>? practiceRedo,
    bool? offLine,
    List<String>? demoOff,
    int? demoOffFrom,
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
    wrongMove:
        wrongMove ??
        (speech != null || step != null || phase != null
            ? false
            : this.wrongMove),
    presenting: presenting ?? this.presenting,
    solutionSeen:
        solutionSeen ??
        (step != null || fen != null ? false : this.solutionSeen),
    attemptedSan: clearAttemptedSan
        ? null
        : attemptedSan ??
              (speech != null || step != null ? null : this.attemptedSan),
    correct: correct ?? this.correct,
    thinkPlayed: thinkPlayed ?? this.thinkPlayed,
    fullSpeech: clearFullSpeech ? null : fullSpeech ?? this.fullSpeech,
    alternatives: alternatives ?? this.alternatives,
    seen: seen ?? this.seen,
    wrongNotice: wrongNotice ?? this.wrongNotice,
    // Uma fala nova apaga a genérica, a não ser que venha junto.
    note: clearNote ? null : note ?? (speech != null ? null : this.note),
    noteSan: clearNote ? null : noteSan ?? this.noteSan,
    typing: typing ?? this.typing,
    engineErrors: engineErrors ?? this.engineErrors,
    engineLine: engineLine ?? this.engineLine,
    practiceGate: practiceGate ?? this.practiceGate,
    practiceComment: clearPracticeComment || clearNote
        ? null
        : practiceComment ?? this.practiceComment,
    practiceHint: practiceHint ?? this.practiceHint,
    practiceUndo: practiceUndo ?? this.practiceUndo,
    practiceRedo: practiceRedo ?? this.practiceRedo,
    offLine: offLine ?? this.offLine,
    demoOff: demoOff ?? this.demoOff,
    demoOffFrom: demoOffFrom ?? this.demoOffFrom,
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
    this.holdDelay = const Duration(milliseconds: 550),
    this.typingDelay = const Duration(milliseconds: 600),
    this._engine,
    this.practiceV2 = false,
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
        // Voltar a um passo para refazê-lo (não "Rever este ponto", que traz
        // `returnTo`): o painel é o objetivo, nunca a solução (T65 §4).
        : snapshot.interactive &&
              (!snapshot.reviewing || snapshot.returnTo == null)
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
        // A fala do passo (T70) não é trocada pela do feedback: o estado
        // correto, o comentário do motor, a demo fora do roteiro e o prático
        // têm a fala própria. O feedback só alimenta a explicação (variações).
        final keepsSpeech =
            practiceV2 &&
            (snapshot.correct ||
                snapshot.note != null ||
                snapshot.offScript ||
                step is MoveStep);
        super.emit(
          keepsSpeech
              ? snapshot.copyWith(
                  explanation: payload,
                  attemptedSan: snapshot.attemptedSan,
                )
              : snapshot.copyWith(
                  explanation: payload,
                  attemptedSan: snapshot.attemptedSan,
                  speech: payload.explanations
                      .expand((b) => b.texts)
                      .join('\n\n'),
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

  /// Quanto o lance do aluno fica na tela antes de a peça voltar (outro lance
  /// correto, erro sem ramo): somada a [replyDelay], cerca de 1 s (T70).
  final Duration holdDelay;

  /// Os três pontinhos antes do texto da resposta no prático (crit. 12a).
  final Duration typingDelay;

  /// O motor para o lance fora dos dados (crit. 8). Nulo: sem motor.
  final EngineFallback? _engine;

  /// O prático no desenho novo (T70, lotes 3 a 5): convite, Voltar/Continuar,
  /// balão. Desligado, a tela de hoje segue funcionando.
  final bool practiceV2;

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
    if (full == null) {
      emit(const LessonState(ready: true, missing: true));
      return;
    }
    if (saved != null && saved.lessonId != lessonId) saved = null;
    // Fechar o app de verdade reabre no INÍCIO da parte (ou da lição, sem
    // partes) em que o aluno estava (decisão do Gabriel, 2026-10-13): o
    // checkpoint é lido só para saber a parte; o passo salvo não se usa. O
    // segundo plano não passa por aqui (fica em memória).
    LessonPart? opened;
    var lesson = full;
    if (full.parts.isNotEmpty) {
      // Checkpoint de antes das partes: o passo contava na aula inteira.
      final savedPart = saved == null
          ? null
          : saved.part ?? full.locate(saved.step)?.$1.id;
      opened =
          full.part(part ?? '') ??
          full.part(savedPart ?? '') ??
          full.parts.first;
      lesson = full.only(opened);
    }
    // A parte (ou a aula) virou roteiro: quem toca é a tela de roteiro (o
    // app reabria aqui pelo checkpoint e ficava em branco).
    // Na escola, os passos de uma aula com roteiro ficam de reserva.
    final script = opened == null
        ? full.script != null && full.steps.isEmpty
        : opened.script != null;
    if (script) {
      emit(
        LessonState(
          ready: true,
          toScript: true,
          lesson: full,
          part: opened,
          endgame: _source.endgame,
        ),
      );
      return;
    }
    if (lesson.steps.isEmpty) {
      // Sem passos nem roteiro: o checkpoint não serve mais.
      if (saved != null) await _source.clearCheckpoint();
      if (isClosed || revision != _loadRevision) return;
      emit(const LessonState(ready: true, missing: true));
      return;
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
    emit(_open(base, 0));
    await _save();
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
    if (practiceV2 &&
        returnTo == null &&
        nextStep < state.stepCount &&
        nextStep == LessonRules.practiceStart(state.lesson!.steps) &&
        !state.reviewing) {
      emit(_open(state, nextStep).copyWith(practiceGate: true, speech: null));
      await _save();
      return;
    }
    if (nextStep < state.stepCount) {
      emit(_carryReturn(_open(state, nextStep), returnTo));
      await _save();
      return;
    }
    await _finish();
  }

  /// "Ver solução" (T65 §4): depois de um lance errado explicado, mostra a
  /// solução com o tabuleiro parado. Guardado: fechar o app reabre nela.
  Future<void> seeSolution() async {
    if (state.solutionSeen ||
        !state.showsMistake ||
        state.result != null ||
        (state.explanation == null && !state.wrongMove)) {
      return;
    }
    emit(state.copyWith(solutionSeen: true));
    await _save();
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
    // Passo de lance errado (T65 §4): volta ao estado inicial, como na
    // abertura (as peças voltam animadas); o erro já contado fica como está.
    if (state.showsMistake && state.result == null && step is MoveStep) {
      final opened = _open(
        state,
        state.step,
      ).copyWith(mistakes: state.mistakes);
      emit(
        state.returnTo == null
            ? opened
            : opened.copyWith(returnTo: state.returnTo),
      );
      await _save();
      return;
    }
    // Depois de um lance errado previsto, o tabuleiro está como antes dele:
    // o aluno joga de novo dali.
    if (state.phase == StepPhase.failed &&
        state.result == null &&
        step is PlayStep) {
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

  /// Sai da aula pelo voltar: a parte fica guardada, mas o app não reabre
  /// nela. Entrar de novo recomeça a parte, como ao fechar o app.
  Future<void> leave() async {
    if (state.finished) {
      return;
    }
    await _source.leave();
  }

  /// O aluno moveu uma peça no tabuleiro.
  Future<void> play(Move move) async {
    if (state.current is DemoStep) {
      return _demoStudent(move);
    }
    if (!state.interactive) {
      return;
    }
    // Quem joga já viu o objetivo: o relógio do passo começa.
    if (state.presenting) {
      emit(state.copyWith(presenting: false, stepStartedAt: _now()));
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
        await (practiceV2 ? _playPractice(step, move) : _playLine(step, move));
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
    await Future<void>.delayed(replyDelay);
    await _waitForForeground();
    if (isClosed || _closing || state.step != stepIndex) {
      return;
    }
    final nextIndex = stepIndex + 1;
    if (nextIndex < state.stepCount) {
      final steps = state.lesson!.steps;
      final thinkFen = steps[stepIndex].fen;
      // Acertou: o lance da aula, o que a explicação mostra ou outro lance
      // que a aula também aceita. Os três chegam ao mesmo estado correto.
      if (LessonRules.acceptsThink(step, move.uci) ||
          _guessed(steps[nextIndex], move.uci) ||
          _alsoAccepted(steps, nextIndex, thinkFen, move.uci)) {
        await _acceptThink(stepIndex, move);
        return;
      }
      // Sem como dizer que errou (nem lance certo nem erro previsto): segue.
      if (_mistakeText(step.mistakes[move.uci]?.say) == null &&
          step.accept.isEmpty &&
          !_showsMove(steps[nextIndex]) &&
          !step.mistakes.containsKey(move.uci)) {
        await _explain();
        return;
      }
      if (await _knownBranch(stepIndex, step, move)) {
        if (isClosed || _closing || state.step != stepIndex) return;
        _thinkMistake(step, steps[nextIndex], move);
        await _save();
        return;
      }
      if (isClosed || _closing || state.step != stepIndex) return;
      await _outsideData(stepIndex, step, move);
      return;
    }
    await _explain();
  }

  /// Existe um ramo nos dados para o lance errado [move] do aluno (T70, "Texto
  /// por lance"): erro previsto, demo errada da parte cuja posição é a de
  /// depois do lance, ou alternativa que falha no feedback.
  Future<bool> _knownBranch(int index, ThinkStep step, Move move) async {
    if (step.mistakes.containsKey(move.uci) ||
        step.refusals.containsKey(move.uci)) {
      return true;
    }
    final steps = state.lesson!.steps;
    final afterKey = _fenKey(state.fen);
    for (final other in steps.skip(index + 1)) {
      if (other is ThinkStep) break;
      if (other is DemoStep &&
          _isMistakeDemo(other) &&
          _fenKey(other.fen) == afterKey) {
        return true;
      }
    }
    final repository = _feedback;
    if (repository == null) return false;
    try {
      final payload = await repository.findPayload(
        lessonId: _lessonId,
        exerciseId: step.id,
        kind: 'think',
        turn: 1,
        fen: step.fen,
        language: _language,
        state: ExplanationState.incorrect,
        playedUci: move.uci,
      );
      if (payload == null) return false;
      return payload.explanations.any(
        (block) => block.variations.any(
          (v) =>
              v.parentId == null &&
              v.firstUci == move.uci &&
              v.outcome != VariationOutcome.accepted,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Demo do que não fazer: marcada `wrong` ou, como nos dados das partes,
  /// de id `err_...`.
  static bool _isMistakeDemo(DemoStep demo) =>
      demo.wrong || demo.id.startsWith('err_');

  /// A posição sem os contadores de lances (para comparar FENs).
  static String? _fenKey(String? fen) => fen?.split(" ").take(4).join(" ");

  /// O aluno acertou no passo de pensar. Outro lance correto (que não o
  /// principal) fica ~1 s na tela com a fala "Também é correto"; depois a
  /// peça volta e o principal anima. Em todos os casos o estado é o mesmo.
  Future<void> _acceptThink(int index, Move move) async {
    final principal = _principalUci(index);
    if (principal != null && principal != move.uci) {
      final think = state.lesson!.steps[index] as ThinkStep;
      emit(
        state.copyWith(
          note: LessonNote.alsoCorrect,
          noteSan: _san(think.fen, principal),
        ),
      );
      await Future<void>.delayed(holdDelay);
      await _waitForForeground();
      if (isClosed || _closing || state.step != index) return;
    }
    await _revealCorrect(index);
  }

  /// "Ver resposta" (T70, crit. 3 e 6): na posição inicial do passo de pensar
  /// ou depois de um lance errado, anima o lance principal e abre o estado
  /// correto, o mesmo do acerto.
  Future<void> showAnswer() async {
    final index = _thinkIndex();
    if (index == null || state.phase == StepPhase.waiting || state.typing) {
      return;
    }
    await _revealCorrect(index);
  }

  /// O índice do passo de pensar a que o "Ver resposta" se refere: o passo
  /// aberto, ou o anterior depois de um lance errado (a explicação aberta).
  int? _thinkIndex() {
    final steps = state.lesson?.steps;
    if (steps == null || state.correct) return null;
    if (state.current is ThinkStep) return state.step;
    final previous = state.step - 1;
    if (previous >= 0 &&
        steps[previous] is ThinkStep &&
        (state.thinkPlayed != null || state.engineLine.isNotEmpty)) {
      return previous;
    }
    return null;
  }

  /// O lance principal do passo de pensar: o que o passo seguinte ensina ou
  /// mostra primeiro; senão, o primeiro aceito do próprio passo.
  String? _principalUci(int index) {
    final steps = state.lesson!.steps;
    final think = steps[index] as ThinkStep;
    final next = index + 1 < steps.length ? steps[index + 1] : null;
    final shown = switch (next) {
      TalkStep(:final arrows) when arrows.isNotEmpty =>
        '${arrows.first.$1}${arrows.first.$2}',
      DemoStep(:final line) when line.isNotEmpty => line.first.uci,
      MoveStep(:final line)
          when line.isNotEmpty && line.first.accept.isNotEmpty =>
        line.first.accept.first,
      _ => null,
    };
    for (final uci in [?shown, ...think.accept]) {
      final parsed = Move.parse(uci);
      final position = GameRules.fromFen(think.fen);
      if (parsed != null &&
          position != null &&
          GameRules.play(position, parsed) != null) {
        return uci;
      }
    }
    return null;
  }

  /// O estado correto (crit. 7), o mesmo por acerto, por erro + "Ver
  /// resposta" e por "Ver resposta" do enunciado: o passo da explicação, com
  /// o tabuleiro depois do principal, sem frase de acerto.
  Future<void> _revealCorrect(int index) async {
    final steps = state.lesson!.steps;
    final think = steps[index] as ThinkStep;
    final nextIndex = index + 1;
    if (nextIndex >= steps.length) {
      await _explain();
      return;
    }
    final next = steps[nextIndex];
    final seen = state.seen;
    // A tela de hoje ainda pede o payload "correto" da decisão.
    if (practiceV2) _decision = null;
    var opened = _open(state, nextIndex);
    final uci = _principalUci(index) ?? state.moves.lastOrNull;
    final principal = uci == null ? null : Move.parse(uci);
    final position = GameRules.fromFen(think.fen);
    final played = position == null || principal == null
        ? null
        : GameRules.play(position, principal);
    if (next is TalkStep && played != null) {
      opened = opened.copyWith(fen: played.position.fen, lastMove: principal);
    } else if (next is DemoStep) {
      opened = _demoAt(opened, next, 1);
    }
    // A fala curta só no desenho novo (lotes 3 a 5); a tela de hoje não tem
    // o "Ver explicação completa".
    final short = practiceV2 && (next is TalkStep || next is DemoStep)
        ? state.texts.say('$_lessonId.${next.id}.short')
        : null;
    final full = state.texts.step(_lessonId, next.id) ?? opened.speech;
    emit(
      opened.copyWith(
        correct: next is TalkStep || next is DemoStep,
        seen: seen,
        speech: short ?? full,
        fullSpeech: short == null ? null : full,
        emotion: Emotion.happy,
      ),
    );
    await _save();
    if (next is TalkStep || next is DemoStep) {
      // Dado opcional que chega depois: o estado correto já está na tela.
      unawaited(_loadAlternatives(index));
    }
  }

  /// "Ver explicação completa" (crit. 3b): troca a curta pelo texto inteiro.
  void showFullExplanation() {
    final full = state.fullSpeech;
    if (!state.correct || full == null) return;
    emit(state.copyWith(speech: full, clearFullSpeech: true));
  }

  /// O aluno abriu o ramo de [uci] (lista do estado correto): vira "Já visto".
  void markSeen(String uci) {
    if (state.seen.contains(uci)) return;
    emit(
      state.copyWith(
        seen: {...state.seen, uci},
        alternatives: [
          for (final alternative in state.alternatives)
            alternative.uci == uci
                ? alternative.copyWith(seen: true)
                : alternative,
        ],
      ),
    );
  }

  /// O ramo do lance [uci] do passo de pensar (T70, "Texto por lance"): os
  /// lances (o do aluno e a continuação) e o comentário de cada um, `''` onde
  /// não há. A continuação é a da demo errada da parte cuja posição é a de
  /// depois do lance; sem ela, a variação do feedback; sem as duas, só o
  /// lance. [fallback] é o comentário neutro do lance do aluno.
  ({List<String> ucis, List<String> texts, bool refuted}) thinkBranch(
    String uci, {
    required String fallback,
    bool played = true,
  }) {
    final steps = state.lesson?.steps ?? const <LessonStep>[];
    final current = state.current;
    final index = current is ThinkStep ? state.step : state.step - 1;
    final think =
        index >= 0 && index < steps.length && steps[index] is ThinkStep
        ? steps[index] as ThinkStep
        : null;
    if (think == null) return (ucis: [uci], texts: [fallback], refuted: false);
    var ucis = [uci];
    String? demoId;
    String? altId;
    List<String> variationTexts = const [];
    final position = GameRules.fromFen(think.fen);
    final move = Move.parse(uci);
    final after = position == null || move == null
        ? null
        : GameRules.play(position, move)?.position.fen;
    for (final other in steps.skip(index + 1)) {
      if (other is ThinkStep) break;
      if (other is DemoStep &&
          _isMistakeDemo(other) &&
          _fenKey(other.fen) == _fenKey(after)) {
        ucis = [uci, for (final m in other.line) m.uci];
        demoId = other.id;
        break;
      }
    }
    for (final variation
        in state.explanation?.variations ?? const <ExplanationVariation>[]) {
      if (variation.parentId == null &&
          variation.firstUci == uci &&
          variation.movesUci.isNotEmpty) {
        altId = variation.id;
        variationTexts = played && variation.playedTexts.isNotEmpty
            ? variation.playedTexts
            : variation.texts;
        if (demoId == null) ucis = List.of(variation.movesUci);
        break;
      }
    }
    final say = _mistakeText(think.mistakes[uci]?.say);
    // O texto escrito vence: fala do erro, da demo ou da alternativa; depois
    // o do feedback da variante; o neutro só quando não há nada escrito.
    final fromFeedback = variationTexts.join('\n\n');
    final texts = [
      for (var ply = 1; ply <= ucis.length; ply++)
        _withoutMove(
          BranchComments.at(
                texts: state.texts,
                lessonId: _lessonId,
                ply: ply,
                mistakeSay: say,
                demoId: demoId,
                altStepId: think.id,
                altId: altId,
              ) ??
              (ply == 1
                  ? (fromFeedback.isEmpty ? fallback : fromFeedback)
                  : null),
          ply,
        ),
    ];
    return (ucis: ucis, texts: texts, refuted: demoId != null);
  }

  /// O comentário do lance sem o lance no começo (`1...Re7. O rei…`): a faixa
  /// já o mostra. O do aluno (ply 1) fica como está.
  static String _withoutMove(String? text, int ply) => ply <= 1
      ? text ?? ''
      : (text ?? '').replaceFirst(RegExp(r'^\d+\.(?:\.\.)?[^\s.]+\.\s*'), '');

  /// "Alternativas que falham" do estado correto (crit. 7c): a união, sem
  /// repetir o lance, das alternativas que falham do feedback (ordem dele) e
  /// das demos erradas da parte. Nunca um lance aceito.
  Future<void> _loadAlternatives(int index) async {
    final steps = state.lesson!.steps;
    final think = steps[index] as ThinkStep;
    final fen = think.fen;
    final position = GameRules.fromFen(fen);
    if (position == null) return;
    final ucis = <String>[];
    final repository = _feedback;
    if (repository != null) {
      try {
        final payload = await repository.findPayload(
          lessonId: _lessonId,
          exerciseId: think.id,
          kind: 'think',
          turn: 1,
          fen: fen,
          language: _language,
          state: ExplanationState.review,
        );
        for (final block in payload?.explanations ?? <ExplanationBlock>[]) {
          for (final v in block.variations) {
            final uci = v.firstUci;
            if (v.parentId == null &&
                uci != null &&
                v.outcome != VariationOutcome.accepted &&
                !ucis.contains(uci)) {
              ucis.add(uci);
            }
          }
        }
      } catch (_) {
        /* Dado opcional: segue só com as demos. */
      }
    }
    for (final other in steps.skip(index + 1)) {
      if (other is ThinkStep) break;
      if (other is! DemoStep || !_isMistakeDemo(other)) continue;
      final key = _fenKey(other.fen);
      for (final move in position.legalMoves.entries.expand(
        (e) => e.value.squares.map((to) => NormalMove(from: e.key, to: to)),
      )) {
        final played = GameRules.play(position, move);
        if (played != null &&
            _fenKey(played.position.fen) == key &&
            !ucis.contains(move.uci)) {
          ucis.add(move.uci);
        }
      }
    }
    final principal = _principalUci(index);
    final alternatives = [
      for (final uci in ucis)
        if (uci != principal && !think.accept.contains(uci))
          if (_numbered(fen, Move.parse(uci)!) case final label?)
            FailedAlternative(
              uci: uci,
              label: '$label?',
              seen: state.seen.contains(uci),
            ),
    ];
    if (isClosed || _closing || !state.correct || state.step != index + 1) {
      return;
    }
    emit(state.copyWith(alternatives: alternatives));
  }

  /// [uci] em SAN (letras inglesas) a partir de [fen].
  static String? _san(String fen, String uci) {
    final position = GameRules.fromFen(fen);
    final move = Move.parse(uci);
    final played = position == null || move == null
        ? null
        : GameRules.play(position, move);
    return played?.san;
  }

  /// Lição de vencer (o lado do aluno deve seguir ganhando) ou de segurar o
  /// empate (algum passo de jogar com objetivo de empatar).
  bool get _mustWin => !(state.lesson?.steps ?? const <LessonStep>[]).any(
    (step) => step is PlayStep && step.goal == PlayGoal.draw,
  );

  /// Lance fora dos dados no passo de pensar (crit. 8): o Stockfish responde.
  /// Sem motor, a peça volta e a folha avisa (crit. 1, opção A).
  Future<void> _outsideData(int index, ThinkStep step, Move move) async {
    final thinkFen = step.fen;
    void revert({bool error = false, bool notice = false}) => emit(
      state.copyWith(
        fen: thinkFen,
        clearLastMove: true,
        moves: const [],
        phase: StepPhase.active,
        typing: false,
        wrongNotice: notice,
        mistakes: notice ? state.mistakes + 1 : null,
        engineErrors: error ? state.engineErrors + 1 : null,
      ),
    );
    final engine = _engine;
    final after = _position();
    if (engine == null || after == null) {
      await Future<void>.delayed(holdDelay);
      await _waitForForeground();
      if (isClosed || _closing || state.step != index) return;
      revert(notice: true);
      await _save();
      return;
    }
    emit(state.copyWith(typing: true));
    final answer = await engine.respond(
      after,
      student: step.side,
      mustWin: _mustWin,
    );
    await _waitForForeground();
    if (isClosed || _closing || state.step != index) return;
    switch (answer.verdict) {
      case EngineVerdict.failed:
        revert(error: true);
        await _save();
      case EngineVerdict.keeps:
        emit(
          state.copyWith(
            typing: false,
            note: _mustWin
                ? LessonNote.alsoWinsShowMain
                : LessonNote.alsoHoldsShowMain,
          ),
        );
        await Future<void>.delayed(holdDelay);
        await _waitForForeground();
        if (isClosed || _closing || state.step != index) return;
        await _revealCorrect(index);
      case EngineVerdict.loses:
        final reply = answer.reply!;
        final played = GameRules.play(after, reply);
        if (played == null) {
          revert(error: true);
          return;
        }
        unawaited(_sounds?.move(played.san));
        final opened = _open(state, index + 1).copyWith(
          thinkMistake: _numbered(thinkFen, move),
          thinkPlayed: move.uci,
          seen: {move.uci},
          engineLine: [move.uci, reply.uci],
          note: LessonNote.engineMove,
          mistakes: state.mistakes + 1,
          engineErrors: state.engineErrors,
          emotion: Emotion.focused,
        );
        emit(opened);
        await _save();
    }
  }

  /// Lance errado no passo de pensar: a explicação abre na hora, começando
  /// por que o lance perde (a fala de `mistakes`, ou a frase genérica do app
  /// com o lance numerado). Sem lance certo conhecido (nem `accept` nem um
  /// lance mostrado na explicação), não há como dizer que errou: falso.
  bool _thinkMistake(ThinkStep step, LessonStep next, Move move) {
    final said = _mistakeText(step.mistakes[move.uci]?.say);
    final opened = _open(
      state,
      state.step + 1,
    ).copyWith(thinkPlayed: move.uci, seen: {move.uci});
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

  // --- prático (T70, crit. 11 a 16) ------------------------------------------

  /// O convite "Vamos praticar": o tabuleiro passa a responder.
  void startPractice() {
    if (!state.practiceGate) return;
    final step = state.current;
    emit(
      state.copyWith(
        practiceGate: false,
        // A fala do próprio passo (`step.<id>`), não a do pensar anterior.
        speech: step == null
            ? null
            : state.texts.step(_lessonId, step.id) ??
                  _speechOf(state, state.step),
        emotion: Emotion.calm,
      ),
    );
    unawaited(_save());
  }

  /// "Voltar" do convite: a explicação anterior, como o "Voltar" de sempre.
  Future<void> practiceInviteBack() async {
    emit(state.copyWith(practiceGate: false));
    await back();
  }

  /// O comentário que o Viktor dá ao n-ésimo lance do aluno (`r<n>`).
  /// Sem a chave, a fala reserva `coach.good`: o balão sempre comenta o
  /// último lance.
  String? _practiceReply(MoveStep step, int turn) =>
      state.texts.say('$_lessonId.${step.id}.r${turn + 1}') ??
      _pick('coach.good');

  Future<void> _playPractice(MoveStep step, Move move) async {
    final start = _position();
    if (start == null || GameRules.play(start, move) == null) return;
    final index = state.step;
    final before = PracticePair(
      fenBefore: state.fen!,
      turnBefore: state.turn,
      movesBefore: state.moves,
      student: move.uci,
      commentBefore: state.speech,
      lastMoveBefore: state.lastMove,
    );
    final turn = state.turn;
    var student = move;
    if (LessonRules.accepts(step, turn, move.uci)) {
      final main = step.line[turn].accept.first;
      if (main != move.uci) {
        // Outro lance que a aula aceita: nota, a peça volta, o principal entra.
        emit(
          state.copyWith(
            note: LessonNote.alsoCorrect,
            noteSan: _san(state.fen!, main),
          ),
        );
        await Future<void>.delayed(holdDelay);
        await _waitForForeground();
        if (isClosed || _closing || state.step != index) return;
        emit(state.copyWith(clearNote: true, clearLastMove: true));
        student = Move.parse(main)!;
      }
      await _practiceLine(step, index, before, student);
      return;
    }
    // Lance fora da linha da aula.
    final said = _mistakeText(step.mistakes[move.uci]?.say);
    if (said != null) {
      final played = GameRules.play(start, move)!;
      unawaited(_sounds?.move(played.san));
      emit(
        state.copyWith(
          fen: played.position.fen,
          lastMove: move,
          moves: [...state.moves, move.uci],
          speech: said,
          clearNote: true,
          practiceHint: false,
          practiceUndo: [
            ...state.practiceUndo,
            _offPair(before, speech: said),
          ],
          practiceRedo: const [],
          offLine: true,
          mistakes: state.mistakes + 1,
          emotion: Emotion.focused,
        ),
      );
      await _save();
      return;
    }
    final engine = _engine;
    if (engine == null) {
      final mistakes = state.mistakes + 1;
      final hint = state.texts.hint(_lessonId, step.id);
      emit(
        state.copyWith(
          speech: hint ?? _pick('coach.wrong'),
          genericMistake: hint == null,
          emotion: Emotion.focused,
          mistakes: mistakes,
          wrongMove: true,
        ),
      );
      await _save();
      return;
    }
    final played = GameRules.play(start, move)!;
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        typing: true,
        practiceHint: false,
      ),
    );
    final answer = await engine.respond(
      played.position,
      student: step.side,
      mustWin: _mustWin,
      replyOnKeep: true,
    );
    await _waitForForeground();
    if (isClosed || _closing || state.step != index) return;
    final reply = answer.reply;
    final answered = reply == null
        ? null
        : GameRules.play(played.position, reply);
    if (answer.verdict == EngineVerdict.failed || answered == null) {
      emit(
        state.copyWith(
          fen: before.fenBefore,
          lastMove: before.lastMoveBefore,
          clearLastMove: before.lastMoveBefore == null,
          typing: false,
          engineErrors: state.engineErrors + 1,
        ),
      );
      return;
    }
    unawaited(_sounds?.move(answered.san));
    final keeps = answer.verdict == EngineVerdict.keeps;
    // O texto escrito do feedback para este lance vence a nota do motor.
    final written = keeps ? null : await _writtenMistake(move);
    if (isClosed || _closing || state.step != index) return;
    final note = keeps
        ? (_mustWin ? LessonNote.alsoWins : LessonNote.alsoHolds)
        : LessonNote.engineReply;
    emit(
      state.copyWith(
        fen: answered.position.fen,
        lastMove: reply,
        typing: false,
        moves: [...state.moves, move.uci, reply!.uci],
        note: note,
        practiceComment: written,
        practiceUndo: [
          ...state.practiceUndo,
          _offPair(before, reply: reply.uci, note: note),
        ],
        practiceRedo: const [],
        offLine: true,
        mistakes: keeps ? null : state.mistakes + 1,
        emotion: keeps ? Emotion.happy : Emotion.focused,
      ),
    );
    await _save();
  }

  /// O comentário escrito do feedback para o lance errado [move] da decisão
  /// atual (`playedTexts` da variante dele), ou `null` se não há.
  Future<String?> _writtenMistake(Move move) async {
    final repository = _feedback;
    final decision = _decision;
    if (repository is! ExplanationRepository || decision == null) return null;
    try {
      final payload = await repository!.findPayload(
        lessonId: _lessonId,
        exerciseId: decision.id,
        kind: decision.kind,
        turn: decision.turn,
        fen: decision.fen,
        language: _language,
        state: ExplanationState.incorrect,
        playedUci: move.uci,
      );
      for (final v in payload?.variations ?? const <ExplanationVariation>[]) {
        if (v.parentId != null || v.firstUci != move.uci) continue;
        final texts = v.playedTexts.isNotEmpty ? v.playedTexts : v.texts;
        if (texts.isNotEmpty) return texts.join('\n\n');
      }
    } catch (_) {}
    return null;
  }

  PracticePair _offPair(
    PracticePair base, {
    String? reply,
    LessonNote? note,
    String? speech,
  }) => PracticePair(
    note: note,
    speech: speech,
    fenBefore: base.fenBefore,
    turnBefore: base.turnBefore,
    movesBefore: base.movesBefore,
    student: base.student,
    reply: reply,
    onLine: false,
    commentBefore: base.commentBefore,
    lastMoveBefore: base.lastMoveBefore,
  );

  /// O lance da aula [student] entra, a máquina "digita" e responde.
  Future<void> _practiceLine(
    MoveStep step,
    int index,
    PracticePair before,
    Move student,
  ) async {
    final start = _position()!;
    final played = GameRules.play(start, student)!;
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    final turn = state.turn;
    final ends = turn + 1 >= step.line.length;
    final replyUci = step.line[turn].reply;
    final reply = replyUci == null ? null : Move.parse(replyUci);
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: student,
        clearNote: true,
        practiceHint: false,
        offLine: false,
        wrongMove: false,
        genericMistake: false,
        clearHint: true,
        typing: !ends && reply != null,
        phase: ends ? StepPhase.done : StepPhase.active,
      ),
    );
    var after = played.position;
    var answered = reply == null ? null : GameRules.play(after, reply);
    if (!ends && reply != null) {
      await Future<void>.delayed(typingDelay);
      await _waitForForeground();
      if (isClosed || _closing || state.step != index) return;
    }
    final comment = ends
        ? state.texts.done(_lessonId, step.id) ?? _pick('coach.praise')
        : _practiceReply(step, turn);
    if (!ends && answered != null) {
      unawaited(_sounds?.move(answered.san));
      after = answered.position;
    }
    emit(
      state.copyWith(
        fen: after.fen,
        lastMove: ends ? student : (answered != null ? reply : student),
        turn: turn + 1,
        typing: false,
        moves: [
          ...state.moves,
          student.uci,
          if (!ends && answered != null) reply!.uci,
        ],
        speech: comment,
        practiceUndo: [
          ...state.practiceUndo,
          PracticePair(
            fenBefore: before.fenBefore,
            turnBefore: before.turnBefore,
            movesBefore: before.movesBefore,
            student: student.uci,
            reply: answered != null && !ends ? reply!.uci : null,
            commentBefore: before.commentBefore,
            lastMoveBefore: before.lastMoveBefore,
            speech: comment,
          ),
        ],
        practiceRedo: const [],
        emotion: ends ? Emotion.happy : Emotion.calm,
      ),
    );
    await _save();
  }

  /// "Voltar" do prático (crit. 12): desfaz um par; na vez inicial, volta ao
  /// convite. No passo de jogar desfaz pares da partida, sem "Continuar".
  Future<void> practiceBack() async {
    final current = state.current;
    if (current is PlayStep) {
      await _playBack(current);
      return;
    }
    if (current is! MoveStep) return;
    if (state.practiceUndo.isEmpty) {
      emit(state.copyWith(practiceGate: true, speech: null));
      await _save();
      return;
    }
    final pair = state.practiceUndo.last;
    emit(
      state.copyWith(
        fen: pair.fenBefore,
        turn: pair.turnBefore,
        moves: pair.movesBefore,
        lastMove: pair.lastMoveBefore,
        clearLastMove: pair.lastMoveBefore == null,
        speech: pair.commentBefore,
        phase: StepPhase.active,
        practiceUndo: state.practiceUndo.sublist(
          0,
          state.practiceUndo.length - 1,
        ),
        // O "Continuar" refaz qualquer par, inclusive o do motor (4.7).
        practiceRedo: [...state.practiceRedo, pair],
        offLine: false,
        clearNote: true,
        practiceHint: false,
        wrongMove: false,
        typing: false,
      ),
    );
    await _save();
  }

  Future<void> _playBack(PlayStep step) async {
    final moves = state.moves;
    if (moves.isEmpty) return;
    final keep = moves.length.isOdd ? moves.length - 1 : moves.length - 2;
    final kept = moves.sublist(0, keep < 0 ? 0 : keep);
    var position = GameRules.fromFen(step.fen)!;
    Move? last;
    for (final uci in kept) {
      final parsed = Move.parse(uci)!;
      position = GameRules.play(position, parsed)!.position;
      last = parsed;
    }
    emit(
      state.copyWith(
        fen: position.fen,
        moves: kept,
        lastMove: last,
        clearLastMove: last == null,
        phase: StepPhase.active,
        clearHint: true,
      ),
    );
    await _save();
  }

  /// "Continuar" do prático (crit. 12): refaz o par desfeito; sem ele, no fim
  /// do passo, segue para o próximo.
  Future<void> practiceForward() async {
    final step = state.current;
    if (step is MoveStep && state.practiceRedo.isNotEmpty) {
      final pair = state.practiceRedo.last;
      var position = GameRules.fromFen(pair.fenBefore)!;
      final student = Move.parse(pair.student)!;
      position = GameRules.play(position, student)!.position;
      Move last = student;
      final reply = pair.reply == null ? null : Move.parse(pair.reply!);
      if (reply != null) {
        position = GameRules.play(position, reply)!.position;
        last = reply;
      }
      if (!pair.onLine) {
        // Par fora da linha (erro, motor): volta como estava, sem contar de
        // novo o erro.
        emit(
          state.copyWith(
            fen: position.fen,
            lastMove: last,
            moves: [...pair.movesBefore, pair.student, ?pair.reply],
            speech: pair.speech,
            note: pair.note,
            clearNote: pair.note == null,
            practiceUndo: [...state.practiceUndo, pair],
            practiceRedo: state.practiceRedo.sublist(
              0,
              state.practiceRedo.length - 1,
            ),
            offLine: true,
            emotion: Emotion.focused,
          ),
        );
        await _save();
        return;
      }
      final turn = pair.turnBefore + 1;
      final ends = turn >= step.line.length;
      emit(
        state.copyWith(
          fen: position.fen,
          lastMove: last,
          turn: turn,
          moves: [...pair.movesBefore, pair.student, ?pair.reply],
          speech:
              pair.speech ??
              (ends
                  ? state.texts.done(_lessonId, step.id) ??
                        _pick('coach.praise')
                  : _practiceReply(step, pair.turnBefore)),
          phase: ends ? StepPhase.done : StepPhase.active,
          practiceUndo: [...state.practiceUndo, pair],
          practiceRedo: state.practiceRedo.sublist(
            0,
            state.practiceRedo.length - 1,
          ),
          clearNote: true,
        ),
      );
      await _save();
      return;
    }
    await next();
  }

  /// Fim da parte (crit. 17): abre a parte seguinte.
  Future<void> continueToNextPart() async {
    final next = state.partNumber + 1;
    final full = await _source.lesson(_lessonId);
    if (full == null || next > full.parts.length) return;
    await load(_lessonId, _language, part: full.parts[next - 1].id);
  }

  // --- demonstração (T51) -------------------------------------------------

  /// O próximo lance da demonstração (a tela chama no ritmo da fala, ou o
  /// aluno avança na mão). Pausada, segue pausada (T70, crit. 19): só o play
  /// retoma. Fora do roteiro, volta ao roteiro e anda um lance, pausada.
  Future<void> demoForward() async {
    final step = state.current;
    if (step is! DemoStep || state.typing) return;
    if (state.offScript) {
      // Fora do roteiro (pg. 2.5): volta ao roteiro e anda um lance, pausado.
      final next = state.demoOffFrom + 1;
      if (next > step.line.length) return;
      _offNotes.clear();
      emit(_demoAt(state, step, next).copyWith(demoPlaying: false));
      await _save();
      return;
    }
    if (state.demoMove >= step.line.length) return;
    emit(_demoAt(state, step, state.demoMove + 1));
    await _save();
  }

  /// Volta um lance: desfaz no tabuleiro e mostra a fala daquele ponto. Fora
  /// do roteiro, desfaz um par (lance do aluno + resposta); sem mais lances
  /// fora, volta ao ponto do roteiro em que o aluno saiu.
  Future<void> demoBack() async {
    final step = state.current;
    if (step is! DemoStep || state.typing) {
      return;
    }
    if (state.offScript) {
      final pairs = (state.demoOff.length - 1) ~/ 2;
      if (pairs == 0) {
        _offNotes.clear();
        emit(
          _demoAt(state, step, state.demoOffFrom).copyWith(demoPlaying: false),
        );
      } else {
        _offNotes.length = pairs;
        emit(
          _demoOffAt(
            state,
            step,
            state.demoOffFrom,
            state.demoOff.take(pairs * 2).toList(),
            _offNotes.last,
          ),
        );
      }
      await _save();
      return;
    }
    if (state.demoMove == 0) {
      return;
    }
    emit(_demoAt(state, step, state.demoMove - 1).copyWith(demoPlaying: false));
    await _save();
  }

  /// "Voltar à demonstração" (T70, pg. 2.5): ao lance do roteiro em que o
  /// aluno saiu, com a demonstração ainda pausada.
  Future<void> demoBackToScript() async {
    final step = state.current;
    if (step is! DemoStep || !state.offScript) {
      return;
    }
    _offNotes.clear();
    emit(_demoAt(state, step, state.demoOffFrom).copyWith(demoPlaying: false));
    await _save();
  }

  /// Pausa a demonstração (ela para de andar sozinha) ou a retoma. Fora do
  /// roteiro, o play volta ao roteiro e retoma dali.
  void demoTogglePause() {
    final step = state.current;
    if (step is! DemoStep) {
      return;
    }
    if (state.offScript && !state.demoPlaying) {
      _offNotes.clear();
      emit(_demoAt(state, step, state.demoOffFrom).copyWith(demoPlaying: true));
    } else {
      emit(state.copyWith(demoPlaying: !state.demoPlaying));
    }
    unawaited(_save());
  }

  /// Repete a demonstração do começo.
  Future<void> demoReplay() async {
    final step = state.current;
    if (step is! DemoStep) {
      return;
    }
    _offNotes.clear();
    emit(_demoAt(state, step, 0).copyWith(demoPlaying: true));
    await _save();
  }

  // As falas de cada par fora do roteiro (para o ⏮ devolver a do par).
  final _offNotes = <_OffNote>[];

  /// O aluno jogou [move] com a demonstração em pausa: a máquina responde.
  Future<void> demoPlay(Move move) => _demoStudent(move);

  /// O lance do aluno na demonstração (T70, "ponto 2"): só o lado e a vez
  /// dele. O lance pausa a demonstração. Igual ao próximo do roteiro: é o ⏭.
  /// Fora dele, o Stockfish responde (crit. 8) e o Viktor comenta na folha.
  Future<void> _demoStudent(Move move) async {
    final step = state.current;
    final position = _position();
    if (step is! DemoStep ||
        position == null ||
        state.phase != StepPhase.active ||
        state.typing ||
        state.note?.isGameEnd == true ||
        position.turn != step.side ||
        !position.isLegal(move)) {
      return;
    }
    if (!state.offScript &&
        state.demoMove < step.line.length &&
        step.line[state.demoMove].uci == move.uci) {
      emit(
        _demoAt(state.copyWith(demoPlaying: false), step, state.demoMove + 1),
      );
      await _save();
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) return;
    unawaited(_sounds?.move(played.san));
    final branch = state.offScript ? null : _branchFor(step, move);
    if (branch != null) {
      await _demoBranch(step, played.position, move, branch);
      return;
    }
    final before = state;
    final index = state.step;
    final off = [...state.demoOff, move.uci];
    final fromScript = state.offScript ? state.demoOffFrom : state.demoMove;
    final endedNow = _gameNote(step, played.position, fromScript, off);
    if (endedNow != null) {
      _offNotes
        ..length = (off.length - 1) ~/ 2
        ..add(_OffNote(note: endedNow));
      emit(
        state.copyWith(
          fen: played.position.fen,
          lastMove: move,
          demoOff: off,
          demoOffFrom: fromScript,
          demoPlaying: false,
          clearHint: true,
          note: endedNow,
        ),
      );
      await _save();
      return;
    }
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        demoOff: off,
        demoOffFrom: state.offScript ? state.demoOffFrom : state.demoMove,
        demoPlaying: false,
        typing: true,
        clearHint: true,
      ),
    );
    final engine = _engine;
    final answer = engine == null
        ? const EngineAnswer(EngineVerdict.failed)
        : await engine.respond(
            played.position,
            student: step.side,
            mustWin: _mustWin,
            replyOnKeep: true,
          );
    await Future<void>.delayed(typingDelay);
    await _waitForForeground();
    if (isClosed || _closing || state.step != index || state.demoOff != off) {
      return;
    }
    final reply = answer.reply;
    final answered = reply == null
        ? null
        : GameRules.play(played.position, reply);
    if (answer.verdict == EngineVerdict.failed || answered == null) {
      // Erro inesperado do motor: volta à posição de antes (crit. 8e).
      emit(
        before.copyWith(typing: false, engineErrors: before.engineErrors + 1),
      );
      return;
    }
    unawaited(_sounds?.move(answered.san));
    final replied = [...off, reply!.uci];
    final note =
        _gameNote(step, answered.position, fromScript, replied) ??
        (answer.verdict == EngineVerdict.keeps
            ? (_mustWin ? LessonNote.alsoWins : LessonNote.alsoHolds)
            : LessonNote.engineReply);
    _offNotes
      ..length = (off.length - 1) ~/ 2
      ..add(_OffNote(note: note));
    emit(
      state.copyWith(
        fen: answered.position.fen,
        lastMove: reply,
        demoOff: replied,
        typing: false,
        note: note,
      ),
    );
    await _save();
  }

  /// O fim de partida em [position], depois dos lances do roteiro até
  /// [scriptPlies] e dos lances do aluno [off]; nulo se a partida continua.
  LessonNote? _gameNote(
    DemoStep step,
    Position position,
    int scriptPlies,
    List<String> off,
  ) {
    final start = GameRules.fromFen(step.fen);
    final script = [for (final m in step.line.take(scriptPlies)) m.uci];
    final end = GameRules.endOf(
      position,
      repetitions: start == null
          ? null
          : GameRules.repetitionsOf(start, [...script, ...off]),
    );
    return switch (end?.reason) {
      GameEndReason.checkmate => LessonNote.gameMate,
      GameEndReason.stalemate => LessonNote.gameStalemate,
      GameEndReason.insufficientMaterial => LessonNote.gameInsufficient,
      GameEndReason.repetition => LessonNote.gameRepetition,
      GameEndReason.fiftyMoves => LessonNote.gameFifty,
      _ => null,
    };
  }

  /// O ramo dos dados (`lines` do passo) que o lance do aluno segue na
  /// posição atual da demonstração (T70, pg. 2.3, ponto 2c).
  CitedBranch? _branchFor(DemoStep step, Move move) {
    final script = [for (final m in step.line) m.uci];
    for (final line in step.lines) {
      if (!line.matches(script)) continue;
      for (final branch in line.branches) {
        if (branch.at == state.demoMove &&
            branch.uci.isNotEmpty &&
            branch.uci.first == move.uci) {
          return branch;
        }
      }
    }
    return null;
  }

  /// O aluno seguiu um ramo dos dados: joga o lance dele e a resposta do
  /// ramo, pausa, e o Viktor lê o comentário do ramo. Sem motor.
  Future<void> _demoBranch(
    DemoStep step,
    Position afterStudent,
    Move move,
    CitedBranch branch,
  ) async {
    var position = afterStudent;
    var last = move;
    final off = [move.uci];
    if (branch.uci.length > 1) {
      final reply = Move.parse(branch.uci[1]);
      final answered = reply == null ? null : GameRules.play(position, reply);
      if (reply != null && answered != null) {
        position = answered.position;
        last = reply;
        off.add(reply.uci);
        unawaited(_sounds?.move(answered.san));
      }
    }
    final text = state.texts.alternative(
      state.lesson?.id ?? '',
      step.id,
      branch.id,
    );
    final note = _OffNote(
      speech: text,
      note: text == null
          ? (_mustWin ? LessonNote.alsoWins : LessonNote.alsoHolds)
          : null,
    );
    _offNotes
      ..clear()
      ..add(note);
    emit(
      state.copyWith(
        fen: position.fen,
        lastMove: last,
        demoOff: off,
        demoOffFrom: state.demoMove,
        demoPlaying: false,
        note: note.note,
        speech: note.speech,
        clearHint: true,
      ),
    );
    await _save();
  }

  /// A demonstração fora do roteiro depois de [off] (lances em UCI, a partir
  /// do lance [count] do roteiro), com a fala genérica [note].
  LessonState _demoOffAt(
    LessonState base,
    DemoStep step,
    int count,
    List<String> off,
    _OffNote note,
  ) {
    final onScript = _demoAt(base, step, count);
    var position = GameRules.fromFen(onScript.fen!);
    Move? last;
    for (final uci in off) {
      final parsed = Move.parse(uci);
      final played = position == null || parsed == null
          ? null
          : GameRules.play(position, parsed);
      if (played == null) break;
      position = played.position;
      last = parsed;
    }
    return onScript.copyWith(
      fen: position?.fen,
      lastMove: last,
      demoOff: off,
      demoOffFrom: count,
      demoPlaying: false,
      note: note.note,
      speech: note.speech,
      phase: StepPhase.active,
    );
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
      case MoveStep step when practiceV2:
        // A dica só no balão (crit. 14): sem seta no tabuleiro.
        emit(
          state.copyWith(
            practiceHint: true,
            speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.hint'),
            emotion: Emotion.focused,
          ),
        );
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
          wrongMove: true,
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
      // O cronômetro do passo começa ao abrir; no passo de exercício, só
      // depois da apresentação do Viktor (startStepClock).
      stepStartedAt: _isExercise(step) ? null : _now(),
      presenting: _isExercise(step),
      references: base.references,
    );
  }

  static bool _isExercise(LessonStep step) => switch (step) {
    ThinkStep() || MoveStep() || PlayStep() || TapStep() || StarsStep() => true,
    TalkStep() || DemoStep() => false,
  };

  /// Fim da apresentação (T65 §8): o relógio do passo começa agora.
  Future<void> startStepClock() async {
    if (!state.presenting) return;
    emit(state.copyWith(presenting: false, stepStartedAt: _now()));
    await _save();
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
                : (saved.stepStartedAt ?? _now()))
          : _now(),
      presenting: false,
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

/// A fala de um par fora do roteiro: a genérica do app ([note]) ou o
/// comentário de um ramo dos dados ([speech]).
class _OffNote {
  const _OffNote({this.note, this.speech});

  final LessonNote? note;
  final String? speech;
}
