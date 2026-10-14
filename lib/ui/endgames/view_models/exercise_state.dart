import 'package:dartchess/dartchess.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/explanation.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/exercise_review.dart';

/// Em que pé está o exercício.
enum ExercisePhase {
  /// O aluno procura o lance.
  active,

  /// O outro lado está respondendo.
  waiting,

  /// Resolvido: a notação completa e os pontos ganhos.
  done,
}

/// O que o balão do Viktor diz agora (T72). O cubit não tem l10n: a tela
/// monta a frase com os textos da aula em [ExerciseState.sayTexts].
enum ExerciseSay {
  /// O enunciado.
  goal,

  /// A dica (enunciado e pista).
  hint,

  /// "Correto." + o porquê do lance + "Sua vez.".
  correct,

  /// "Não." + o porquê + "Tente outro lance.".
  wrong,

  /// O exercício acabou: "Correto." ou "Resolvido, mas com um erro.".
  solved,

  /// Um lance da notação, tocado pelo aluno.
  node,
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
    this.say = ExerciseSay.goal,
    this.sayTexts = const [],
    this.sayZeroed = false,
    this.sayNode,
    this.sayMove,
    this.explanationPayload,
    this.hintShown = false,
    this.emotion = Emotion.calm,
    this.earned,
    this.locked = false,
    this.number = 0,
    this.count = 0,
    this.nextExercise,
    this.startedAt,
    this.played = const [],
    this.wrongs = const [],
    this.firstMoveMistake = false,
    this.solutionShown = false,
    this.review = const [],
    this.cursorId,
    this.seen = const {},
    this.browsed = 0,
  });

  final bool ready;

  /// Quando o exercício abriu: o cronômetro conta daqui.
  final DateTime? startedAt;

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

  /// Lances errados e dicas pedidas: cada um tira um ponto.
  final int mistakes;
  final int hints;

  /// A seta da dica.
  final Move? hint;

  /// O último lance errado, para o tabuleiro mostrar o que o aluno fez.
  final Move? wrongMove;
  final ExercisePhase phase;

  /// O balão: o que ele diz ([say]) com os textos da aula ([sayTexts]); o
  /// aviso de que o erro zerou os pontos ([sayZeroed]); o lance comentado
  /// ([sayNode]).
  final ExerciseSay say;
  final List<String> sayTexts;
  final bool sayZeroed;
  final ReviewNode? sayNode;

  /// O lance que o balão comenta ao dizer "Correto." ou "Não.": a posição de
  /// antes e o lance, para a frase gerada quando a aula não o comentou.
  final ({String fenBefore, String uci})? sayMove;
  final ExplanationPayload? explanationPayload;
  final bool hintShown;
  final Emotion emotion;

  /// Os pontos ganhos, quando resolvido.
  final int? earned;

  /// A nota da aula já fechou (todos os exercícios resolvidos): este é
  /// treino livre, e o resultado não muda. Só "refazer os exercícios" zera.
  final bool locked;

  /// O número do exercício na aula (1 é o primeiro) e quantos há.
  final int number;
  final int count;

  /// O exercício seguinte ainda por resolver. Nulo se não há.
  final String? nextExercise;

  /// Os lances jogados (UCI), do aluno e do outro lado, na ordem.
  final List<String> played;

  /// Os lances errados do aluno (a vez, o lance e o porquê, se há).
  final List<ReviewWrong> wrongs;

  /// Errou o primeiro lance: o exercício não pontua mais.
  final bool firstMoveMistake;

  /// O aluno pediu "Ver solução": o exercício vale 0.
  final bool solutionShown;

  /// A notação completa, quando o exercício acabou.
  final List<ReviewNode> review;

  /// O lance da notação em que o tabuleiro está, e os já vistos (o botão de
  /// borrar cobre os outros).
  final String? cursorId;
  final Set<String> seen;

  /// Quantas vezes o aluno foi a um lance da notação depois de acabar.
  final int browsed;

  bool get interactive => phase == ExercisePhase.active;

  /// Quanto o exercício vale agora: as estrelas dele menos erros e dicas;
  /// errar o primeiro lance zera. Depois de resolvido, o que ganhou.
  int get worth {
    final exercise = this.exercise;
    if (phase == ExercisePhase.done) return earned ?? 0;
    if (exercise == null || firstMoveMistake) return 0;
    final left = exercise.stars - mistakes - hints;
    return left < 0 ? 0 : left;
  }

  /// O exercício já não pontua (e continua assim até o fim).
  bool get zeroed => exercise != null && worth == 0;

  /// A solução em texto da aula, quando há.
  String? get explanation => lesson == null || exercise == null
      ? null
      : texts.say('${lesson!.id}.ex.${exercise!.id}.solution');

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
    ExerciseSay? say,
    List<String>? sayTexts,
    bool? sayZeroed,
    ReviewNode? sayNode,
    ({String fenBefore, String uci})? sayMove,
    ExplanationPayload? explanationPayload,
    bool? hintShown,
    Emotion? emotion,
    int? earned,
    DateTime? startedAt,
    List<String>? played,
    List<ReviewWrong>? wrongs,
    bool? firstMoveMistake,
    bool? solutionShown,
    List<ReviewNode>? review,
    String? cursorId,
    Set<String>? seen,
    int? browsed,
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
    say: say ?? this.say,
    sayTexts: sayTexts ?? this.sayTexts,
    sayZeroed: sayZeroed ?? (say != null ? false : this.sayZeroed),
    sayNode: say == null ? this.sayNode : sayNode,
    sayMove: say == null ? this.sayMove : sayMove,
    explanationPayload: explanationPayload ?? this.explanationPayload,
    hintShown: hintShown ?? (clearHint ? false : this.hintShown),
    emotion: emotion ?? this.emotion,
    earned: earned ?? this.earned,
    locked: locked,
    number: number,
    count: count,
    nextExercise: nextExercise,
    startedAt: startedAt ?? this.startedAt,
    played: played ?? this.played,
    wrongs: wrongs ?? this.wrongs,
    firstMoveMistake: firstMoveMistake ?? this.firstMoveMistake,
    solutionShown: solutionShown ?? this.solutionShown,
    review: review ?? this.review,
    cursorId: cursorId ?? this.cursorId,
    seen: seen ?? this.seen,
    browsed: browsed ?? this.browsed,
  );
}
