import 'package:dartchess/dartchess.dart';

import 'endgame_lesson.dart';
import 'kpk_outcome.dart';

/// O objetivo do aluno num exemplo do roteiro.
enum ScriptGoal {
  ganhar,
  empatar;

  static ScriptGoal parse(Object? value) =>
      value == 'empatar' ? ScriptGoal.empatar : ScriptGoal.ganhar;

  bool get wantsWin => this == ganhar;
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

/// A pergunta de um exemplo: o aluno sugere o primeiro lance.
class ScriptQuestion {
  const ScriptQuestion({
    required this.t,
    required this.right,
    required this.rightStep,
    required this.reveal,
    required this.alternatives,
    required this.errors,
    required this.free,
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
    free: FreePlaySpec.fromJson(json['livre'] as Map<String, dynamic>),
  );

  /// A fala da pergunta.
  final String t;

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
  final FreePlaySpec free;

  /// O lance [uci] está no roteiro (certo, alternativo ou erro).
  bool covers(String uci) =>
      right.contains(uci) ||
      alternatives.containsKey(uci) ||
      errors.containsKey(uci);
}

/// A prática da etapa 3: o aluno joga contra a máquina.
class PracticeSpec {
  const PracticeSpec({
    required this.t,
    required this.machine,
    required this.limit,
    this.end,
  });

  factory PracticeSpec.fromJson(Map<String, dynamic> json) => PracticeSpec(
    t: json['t'] as String,
    machine: json['maquina'] == 'b' ? Side.black : Side.white,
    limit: json['limite'] as int? ?? 40,
    end: json['fim'] as String?,
  );

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
    this.curiosities,
    this.question,
    this.practice,
  });

  factory ScriptExample.fromJson(Map<String, dynamic> json) => ScriptExample(
    id: json['id'] as String,
    fen: json['fen'] as String,
    flip: json['vira'] as bool? ?? false,
    goal: ScriptGoal.parse(json['objetivo']),
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

  /// A fala de [key]. Sem ela, a própria chave (o dado está incompleto).
  String say(String key) => _texts[key] ?? key;
}
