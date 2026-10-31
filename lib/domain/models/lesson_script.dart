import 'package:dartchess/dartchess.dart';

import 'endgame_lesson.dart';
import 'kpk_outcome.dart';

/// O objetivo do aluno num exemplo do roteiro.
enum ScriptGoal {
  ganhar,
  empatar,

  /// Dar mate contra o motor (prática `jogo`): só o mate conta; afogamento,
  /// repetição, limite e material insuficiente são fracasso.
  mate,

  /// Sem adversário (curso de iniciante): mover a peça, achar a casa. A vez
  /// não passa.
  tarefa,

  /// Como `ganhar`, mas o exemplo termina com sucesso assim que o rei do aluno
  /// chega a uma das `casas` do exemplo sem perder o ganho.
  casa;

  static ScriptGoal parse(Object? value) => switch (value) {
    'empatar' => ScriptGoal.empatar,
    'mate' => ScriptGoal.mate,
    'tarefa' => ScriptGoal.tarefa,
    'casa' => ScriptGoal.casa,
    _ => ScriptGoal.ganhar,
  };

  bool get wantsWin => this == ganhar || this == casa;
}

/// O que vem depois do último passo de um exemplo.
enum ScriptEnd {
  /// O próximo exemplo da etapa.
  proximo,

  /// A próxima etapa.
  etapa;

  static ScriptEnd parse(Object? value) =>
      value == 'etapa' ? ScriptEnd.etapa : ScriptEnd.proximo;
}

/// Uma seta do passo: `de` → `para`, com a cor (`g`, `b`, `r`).
class ScriptArrow {
  const ScriptArrow(this.from, this.to, this.color);

  final String from;
  final String to;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is ScriptArrow &&
      other.from == from &&
      other.to == to &&
      other.color == color;

  @override
  int get hashCode => Object.hash(from, to, color);
}

/// Um passo do roteiro: uma posição e uma fala (chave em [t]).
class ScriptStep {
  const ScriptStep({
    required this.fen,
    required this.t,
    this.move,
    this.seq = const [],
    this.jump = false,
    this.marks = const [],
    this.arrows = const [],
  });

  factory ScriptStep.fromJson(Map<String, dynamic> json) => ScriptStep(
    fen: json['fen'] as String,
    t: json['t'] as String,
    move: json['lance'] as String?,
    seq: [for (final uci in json['seq'] as List? ?? const []) uci as String],
    jump: json['salto'] as bool? ?? false,
    marks: [for (final m in json['marcas'] as List? ?? const []) m as String],
    arrows: [
      for (final a in json['setas'] as List? ?? const [])
        ScriptArrow(
          (a as List)[0] as String,
          a[1] as String,
          a.length > 2 ? a[2] as String : 'g',
        ),
    ],
  );

  static List<ScriptStep> list(Object? json) => [
    for (final step in (json as List? ?? const []).cast<Map<String, dynamic>>())
      ScriptStep.fromJson(step),
  ];

  /// A posição depois do passo.
  final String fen;

  /// A chave da fala.
  final String t;

  /// O lance que leva ao [fen] (anima a peça).
  final String? move;

  /// Lances rápidos (300 ms cada) que levam ao [fen].
  final List<String> seq;

  /// Corte com esmaecer (200 ms): a posição não segue a anterior.
  final bool jump;
  final List<String> marks;
  final List<ScriptArrow> arrows;

  /// Os lances que o passo joga, para a lista de lances.
  List<String> get moves => [?move, ...seq];

  bool get hasMove => move != null || seq.isNotEmpty;

  /// O mesmo passo com outra fala.
  ScriptStep withText(String key) => ScriptStep(
    fen: fen,
    t: key,
    move: move,
    seq: seq,
    jump: jump,
    marks: marks,
    arrows: arrows,
  );
}

/// O jogo livre que segue um erro (E4).
class FreePlaySpec {
  const FreePlaySpec({
    required this.machine,
    required this.t,
    required this.ends,
    required this.back,
  });

  factory FreePlaySpec.fromJson(Map<String, dynamic> json) => FreePlaySpec(
    machine: json['maquina'] == 'b' ? Side.black : Side.white,
    t: json['fala'] as String,
    ends: {
      for (final MapEntry(:key, :value)
          in (json['fins'] as Map? ?? const {}).entries)
        key as String: value as String,
    },
    back: json['volta'] as String,
  );

  /// O lado que a máquina joga.
  final Side machine;

  /// A fala ao começar o jogo livre.
  final String t;

  /// A fala de cada fim, pelo nome do [FreeEnd]. O que falta vem da genérica.
  final Map<String, String> ends;

  /// A fala ao voltar à pergunta.
  final String back;
}

/// Quem julga o lance da pergunta.
enum ScriptJudge {
  /// A tabela KPK: lance fora do roteiro é julgado e leva ao jogo livre.
  kpk,

  /// Só os lances do roteiro valem; o resto volta (curso de iniciante).
  lista;

  static ScriptJudge parse(Object? value) =>
      value == 'lista' ? ScriptJudge.lista : ScriptJudge.kpk;
}

/// A pergunta de um exemplo: o aluno sugere o primeiro lance.
/// An authored answer button. Its explanation and continuation come entirely
/// from the lesson package, just like an authored move answer.
class ScriptChoice {
  const ScriptChoice({
    required this.t,
    required this.correct,
    required this.steps,
  });
  factory ScriptChoice.fromJson(Map<String, dynamic> json) => ScriptChoice(
    t: json['t'] as String,
    correct: json['correta'] as bool,
    steps: ScriptStep.list(json['passos']),
  );
  final String t;
  final bool correct;
  final List<ScriptStep> steps;
}

class ScriptQuestion {
  const ScriptQuestion({
    required this.t,
    required this.right,
    required this.rightStep,
    required this.reveal,
    required this.alternatives,
    required this.errors,
    this.free,
    this.judge = ScriptJudge.kpk,
    this.pieces,
    this.outside,
    this.back,
    this.choices = const [],
  });

  factory ScriptQuestion.fromJson(Map<String, dynamic> json) => ScriptQuestion(
    t: json['t'] as String,
    right: [for (final uci in json['certos'] as List) uci as String],
    rightStep: ScriptStep.fromJson(json['certo'] as Map<String, dynamic>),
    reveal: ScriptStep.fromJson(json['revela'] as Map<String, dynamic>),
    alternatives: {
      for (final MapEntry(:key, :value)
          in (json['alternativos'] as Map? ?? const {}).entries)
        key as String: ScriptStep.list(value),
    },
    errors: {
      for (final MapEntry(:key, :value)
          in (json['erros'] as Map? ?? const {}).entries)
        key as String: ScriptStep.list(value),
    },
    free: json['livre'] == null
        ? null
        : FreePlaySpec.fromJson(json['livre'] as Map<String, dynamic>),
    judge: ScriptJudge.parse(json['juiz']),
    pieces: _squares(json['pecas']),
    outside: json['fora'] as String?,
    back: json['volta'] as String?,
    choices: [
      for (final choice in json['escolhas'] as List? ?? const [])
        ScriptChoice.fromJson(Map<String, dynamic>.from(choice as Map)),
    ],
  );

  /// A fala da pergunta.
  final String t;
  final List<ScriptChoice> choices;

  /// Os lances certos (`certos`).
  final List<String> right;

  /// O passo do lance certo (`certo`).
  final ScriptStep rightStep;

  /// O passo de "Ver resposta" (`revela`).
  final ScriptStep reveal;

  /// Outros lances bons, cada um com a explicação própria.
  final Map<String, List<ScriptStep>> alternatives;

  /// Os erros previstos, cada um com a refutação.
  final Map<String, List<ScriptStep>> errors;

  /// O jogo livre depois de um erro; nulo no juiz [ScriptJudge.lista].
  final FreePlaySpec? free;
  final ScriptJudge judge;

  /// As casas das peças que o aluno pode mover; nulo: todas do lado.
  final List<String>? pieces;

  /// Juiz lista: a fala do lance fora do roteiro (senão, `ini.fora`).
  final String? outside;

  /// Juiz lista: a fala da pergunta ao voltar de um erro ou de um fora.
  final String? back;

  /// O lance [uci] está no roteiro (certo, alternativo ou erro).
  bool covers(String uci) =>
      right.contains(uci) ||
      alternatives.containsKey(uci) ||
      errors.containsKey(uci);
}

List<String>? _squares(Object? json) =>
    json == null ? null : [for (final s in json as List) s as String];

/// O tipo da prática da etapa 3.
enum PracticeKind {
  /// Contra a máquina (o padrão).
  jogo,

  /// Pegar as estrelas com a peça, em qualquer ordem; o outro lado não joga.
  estrelas,

  /// Tocar nas casas pedidas, em ordem.
  toque,

  /// Achar o lance (mate em 1, captura...).
  lance;

  static PracticeKind parse(Object? value) =>
      PracticeKind.values.asNameMap()[value] ?? PracticeKind.jogo;
}

/// Uma vez do aluno na prática do tipo lance: os lances aceitos e a resposta.
class PracticeTurn {
  const PracticeTurn({required this.right, this.reply});

  factory PracticeTurn.fromJson(Map<String, dynamic> json) => PracticeTurn(
    right: [for (final uci in json['certos'] as List) uci as String],
    reply: json['resposta'] as String?,
  );

  final List<String> right;
  final String? reply;
}

/// A prática da etapa 3: o aluno joga contra a máquina, pega estrelas, toca
/// casas ou acha o lance.
class PracticeSpec {
  const PracticeSpec({
    required this.t,
    required this.machine,
    required this.limit,
    this.end,
    this.kind = PracticeKind.jogo,
    this.pieces,
    this.stars = const [],
    this.minimum,
    this.targets = const [],
    this.coordinates = false,
    this.line = const [],
    this.errors = const {},
    this.errorsAt = const {},
    this.ends = const {},
  });

  factory PracticeSpec.fromJson(Map<String, dynamic> json) => PracticeSpec(
    t: json['t'] as String,
    machine: json['maquina'] == 'b' ? Side.black : Side.white,
    limit: json['limite'] as int? ?? 40,
    end: json['fim'] as String?,
    ends: {
      for (final MapEntry(:key, :value)
          in (json['fins'] as Map? ?? const {}).entries)
        key as String: value as String,
    },
    kind: PracticeKind.parse(json['tipo']),
    pieces: _squares(json['pecas']),
    stars: _squares(json['estrelas']) ?? const [],
    minimum: json['minimo'] as int?,
    targets: _squares(json['alvos']) ?? const [],
    coordinates: json['coordenadas'] as bool? ?? false,
    line: [
      for (final turn
          in (json['linha'] as List? ?? const []).cast<Map<String, dynamic>>())
        PracticeTurn.fromJson(turn),
    ],
    errors: {
      for (final MapEntry(:key, :value)
          in (json['erros'] as Map? ?? const {}).entries)
        key as String: value as String,
    },
    errorsAt: {
      for (final MapEntry(:key, :value)
          in (json['errosPos'] as Map? ?? const {}).entries)
        fen4(key as String): {
          for (final MapEntry(key: uci, value: text) in (value as Map).entries)
            uci as String: text as String,
        },
    },
  );

  /// Os quatro primeiros campos do FEN (peças, vez, roque, en passant): a
  /// posição sem os contadores.
  static String fen4(String fen) => fen.split(' ').take(4).join(' ');

  final PracticeKind kind;

  /// A fala de cada fim do jogo livre da prática, pelo nome do [FreeEnd] (como
  /// em [FreePlaySpec.ends]). O que falta vem da genérica `gen.fim.*`.
  final Map<String, String> ends;

  /// As casas das peças que o aluno pode mover; nulo: todas do lado.
  final List<String>? pieces;

  /// Estrelas: as casas delas e o menor número de lances (informativo).
  final List<String> stars;
  final int? minimum;

  /// Toque: as casas a tocar, em ordem, e se o tabuleiro mostra as
  /// coordenadas.
  final List<String> targets;
  final bool coordinates;

  /// Lance: as vezes do aluno e a fala de cada erro (lance → chave).
  final List<PracticeTurn> line;
  final Map<String, String> errors;

  /// Erros com fala própria em qualquer vez: FEN (4 campos) → lance → chave.
  final Map<String, Map<String, String>> errorsAt;

  /// A chave da fala do erro [uci] jogado em [fen]: a de `erros` na posição
  /// inicial [start] e, em qualquer posição, a de `errosPos`.
  String? errorKey(String fen, String uci, {required String start}) =>
      (fen4(fen) == fen4(start) ? errors[uci] : null) ??
      errorsAt[fen4(fen)]?[uci];

  /// A chave da frase que fecha a posição quando o objetivo é cumprido,
  /// depois da genérica de sucesso.
  final String? end;

  final String t;
  final Side machine;

  /// O limite de lances (lances completos) antes de a prática parar.
  final int limit;
}

/// Uma referência da folha Curiosidades: o id de uma referência da lição ou
/// um objeto escrito ali mesmo.
class CuriosityRef {
  const CuriosityRef({this.id, this.inline});

  final String? id;
  final Reference? inline;

  /// A referência, procurando [id] em [lessonRefs].
  Reference? resolve(List<Reference> lessonRefs) {
    if (inline != null) return inline;
    for (final reference in lessonRefs) {
      if (reference.id == id) return reference;
    }
    return null;
  }
}

/// A folha Curiosidades de um exemplo.
class Curiosities {
  const Curiosities({
    required this.t,
    this.quote,
    this.quoteAuthor,
    this.references = const [],
  });

  factory Curiosities.fromJson(Map<String, dynamic> json) {
    final quote = json['citacao'] as Map<String, dynamic>?;
    return Curiosities(
      t: json['t'] as String,
      quote: quote?['t'] as String?,
      quoteAuthor: quote?['autor'] as String?,
      references: [
        for (final ref in json['referencias'] as List? ?? const [])
          if (ref is String)
            CuriosityRef(id: ref)
          else
            CuriosityRef(
              inline: Reference(
                id: (ref as Map)['id'] as String? ?? '',
                kind: ref['kind'] as String,
                fields: {
                  for (final MapEntry(:key, :value) in ref.entries)
                    if (key != 'id' && key != 'kind') '$key': '$value',
                },
              ),
            ),
      ],
    );
  }

  /// A chave do texto.
  final String t;

  /// A chave da citação e o nome de quem a disse.
  final String? quote;
  final String? quoteAuthor;
  final List<CuriosityRef> references;
}

/// Um exemplo do roteiro: uma posição, a conversa, a pergunta e a linha.
class ScriptExample {
  const ScriptExample({
    required this.id,
    required this.fen,
    required this.flip,
    required this.goal,
    required this.entry,
    required this.line,
    required this.end,
    this.squares = const [],
    this.curiosities,
    this.question,
    this.practice,
  });

  factory ScriptExample.fromJson(Map<String, dynamic> json) => ScriptExample(
    id: json['id'] as String,
    fen: json['fen'] as String,
    flip: json['vira'] as bool? ?? false,
    goal: ScriptGoal.parse(json['objetivo']),
    squares: [
      for (final name in json['casas'] as List? ?? const [])
        Square.fromName(name as String),
    ],
    curiosities: json['curiosidades'] == null
        ? null
        : Curiosities.fromJson(json['curiosidades'] as Map<String, dynamic>),
    entry: ScriptStep.list(json['entrada']),
    question: json['pergunta'] == null
        ? null
        : ScriptQuestion.fromJson(json['pergunta'] as Map<String, dynamic>),
    practice: json['pratica'] == null
        ? null
        : PracticeSpec.fromJson(json['pratica'] as Map<String, dynamic>),
    line: ScriptStep.list(json['linha']),
    end: ScriptEnd.parse(json['fim']),
  );

  final String id;
  final String fen;

  /// O tabuleiro é visto do lado das pretas (e o aluno joga de pretas).
  final bool flip;
  final ScriptGoal goal;

  /// Objetivo `casa`: as casas em que o rei do aluno encerra o exemplo.
  final List<Square> squares;
  final Curiosities? curiosities;
  final List<ScriptStep> entry;
  final ScriptQuestion? question;
  final PracticeSpec? practice;
  final List<ScriptStep> line;
  final ScriptEnd end;

  /// O lado do aluno (embaixo no tabuleiro).
  Side get student => flip ? Side.black : Side.white;

  /// A posição da pergunta: a do último trecho da entrada.
  String get questionFen => entry.lastOrNull?.fen ?? fen;

  bool get isPractice => practice != null;

  /// Objetivo `casa`: o rei do aluno em [position] está numa das casas do exemplo.
  bool kingOnSquare(Position position) {
    if (goal != ScriptGoal.casa) return false;
    final king = position.board.kingOf(student);
    return king != null && squares.contains(king);
  }
}

/// Uma etapa do roteiro (`ideia`, `demos`, `pratica`).
class ScriptStage {
  const ScriptStage({required this.id, required this.examples});

  factory ScriptStage.fromJson(Map<String, dynamic> json) => ScriptStage(
    id: json['id'] as String,
    examples: [
      for (final e in (json['exemplos'] as List).cast<Map<String, dynamic>>())
        ScriptExample.fromJson(e),
    ],
  );

  final String id;
  final List<ScriptExample> examples;
}

/// O roteiro de uma parte de aula (T70): as etapas, sem texto. As falas vêm
/// à parte ([ScriptTexts]).
class LessonScript {
  const LessonScript({
    required this.lessonId,
    required this.partId,
    required this.stages,
  });

  factory LessonScript.fromJson(Map<String, dynamic> json) => LessonScript(
    lessonId: json['licao'] as String,
    partId: json['parte'] as String,
    stages: [
      for (final s in (json['etapas'] as List).cast<Map<String, dynamic>>())
        ScriptStage.fromJson(s),
    ],
  );

  final String lessonId;
  final String partId;
  final List<ScriptStage> stages;
}

/// As falas do roteiro no idioma pedido: as da lição por cima das genéricas,
/// e o idioma por cima do inglês.
class ScriptTexts {
  const ScriptTexts(this._texts);

  static const empty = ScriptTexts({});

  final Map<String, String> _texts;

  bool has(String key) => _texts.containsKey(key);

  /// O fim da chave da linha principal depois de um alternativo.
  static const principalSuffix = '.principal';

  /// A fala genérica dessa linha, quando a lição não tem a própria.
  static const genericPrincipal = 'gen.principal';

  /// A fala de [key]. Sem ela, a própria chave (o dado está incompleto).
  String say(String key) =>
      _texts[key] ??
      (key.endsWith(principalSuffix) ? _texts[genericPrincipal] : null) ??
      key;
}
