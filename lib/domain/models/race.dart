import 'package:dartchess/dartchess.dart';

/// O objetivo dos problemas que a Corrida sorteia: ganhar, segurar o empate
/// (Defender) ou os dois.
enum RaceGoal {
  win,
  defend,
  both;

  /// Sem valor (preferência de antes do filtro): Ganhar.
  static RaceGoal fromCode(String? code) => values.asNameMap()[code] ?? win;

  bool accepts(RaceProblem problem) => switch (this) {
    win => !problem.defend,
    defend => problem.defend,
    both => true,
  };
}

/// O filtro da Corrida: o objetivo e os tipos de final (subcategorias) que o
/// jogador tirou. Guarda o que saiu, não o que ficou: tipo novo no banco entra
/// marcado.
class RaceFilter {
  const RaceFilter({this.goal = RaceGoal.win, this.excluded = const {}});

  factory RaceFilter.fromJson(Map<String, dynamic> json) => RaceFilter(
    goal: RaceGoal.fromCode(json['goal'] as String?),
    excluded: {for (final key in json['excluded'] as List? ?? const []) '$key'},
  );

  final RaceGoal goal;
  final Set<String> excluded;

  bool matches(RaceProblem problem) =>
      goal.accepts(problem) && !excluded.contains(problem.subcategory);

  RaceFilter copyWith({RaceGoal? goal, Set<String>? excluded}) =>
      RaceFilter(goal: goal ?? this.goal, excluded: excluded ?? this.excluded);

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'excluded': [...excluded]..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is RaceFilter &&
      other.goal == goal &&
      other.excluded.length == excluded.length &&
      other.excluded.containsAll(excluded);

  @override
  int get hashCode => Object.hash(goal, Object.hashAllUnordered(excluded));
}

/// Quanto dura a Corrida: 3 ou 5 minutos. Cada duração tem o seu recorde.
enum RaceDuration {
  threeMinutes(Duration(minutes: 3)),
  fiveMinutes(Duration(minutes: 5));

  const RaceDuration(this.limit);

  final Duration limit;

  /// Quanto tempo a Corrida tem.
  int get minutes => limit.inMinutes;

  /// Sem valor (Corridas e preferências de antes da escolha): 3 minutos.
  static RaceDuration fromMinutes(int? minutes) => values.firstWhere(
    (duration) => duration.minutes == minutes,
    orElse: () => threeMinutes,
  );
}

/// O que vem depois de um lance certo: a resposta da defesa (sozinha) e a
/// vez seguinte do jogador. Sem os dois, o lance encerra o problema (mate ou
/// fim da linha).
class RaceBranch {
  const RaceBranch({this.reply, this.next});

  factory RaceBranch.fromJson(Map<String, dynamic> json) => RaceBranch(
    reply: json['r'] as String?,
    next: json['n'] == null
        ? null
        : RaceNode.fromJson(json['n'] as Map<String, dynamic>),
  );

  /// A resposta da defesa, em UCI: o lance que mais demora para perder.
  final String? reply;
  final RaceNode? next;

  bool get isEnd => next == null;
}

/// Uma vez do jogador num problema: os lances que mantêm a distância ótima
/// até o objetivo (todos valem), cada um com a continuação, e os que ainda
/// ganham, mas mais devagar (contam como erro). No Defender, os lances que
/// mantêm o empate (distância 0).
class RaceNode {
  const RaceNode({
    required this.distance,
    required this.moves,
    this.slower = const {},
    this.alternatives = const {},
  });

  factory RaceNode.fromJson(Map<String, dynamic> json) => RaceNode(
    distance: json['d'] as int,
    moves: {
      for (final entry in (json['m'] as Map<String, dynamic>).entries)
        entry.key: RaceBranch.fromJson(entry.value as Map<String, dynamic>),
    },
    slower: {for (final move in (json['w'] as List? ?? const [])) '$move'},
    alternatives: {
      for (final move in (json['a'] as List? ?? const [])) '$move',
    },
  );

  /// Meios-lances até o mate, jogando o mais rápido (a DTM da tablebase).
  final int distance;

  /// Os lances ótimos (UCI) e o que vem depois de cada um.
  final Map<String, RaceBranch> moves;

  /// Lances que também ganham, só que mais devagar.
  final Set<String> slower;

  /// Lances que ganham um lance mais devagar, mas valem: só em problema de
  /// objetivo longe (a diferença de um lance, num final de 40, seria sorte).
  /// Aceitos, encerram o problema.
  final Set<String> alternatives;

  /// Em quantos lances (do jogador) sai o mate pelo caminho mais rápido.
  int get mateIn => (distance + 1) ~/ 2;

  List<String> get best => moves.keys.toList();
}

/// Um problema do banco da Corrida: uma sequência de lances ótimos, conferida
/// na tablebase, até o mate ou o fim da linha (ou, no Defender, segurando o
/// empate). O formato está em `tools/build_race_problems.py`.
class RaceProblem {
  const RaceProblem({
    required this.id,
    required this.fen,
    required this.tree,
    required this.category,
    required this.subcategory,
    required this.level,
    this.defend = false,
  });

  factory RaceProblem.fromJson(Map<String, dynamic> json) => RaceProblem(
    id: json['id'] as String,
    fen: json['fen'] as String,
    tree: RaceNode.fromJson(json['tree'] as Map<String, dynamic>),
    category: json['category'] as String,
    subcategory: json['subcategory'] as String,
    level: json['level'] as int,
    defend: json['goal'] == 'draw',
  );

  final String id;
  final String fen;

  /// Os lances ótimos da primeira vez do jogador e o que vem depois.
  final RaceNode tree;

  /// A categoria e o tipo de final do catálogo de Finais (`rookPawn`,
  /// `rookTwoPawnsVsRook`); fora do catálogo, o tipo é montado do material.
  final String category;
  final String subcategory;

  /// Defender: o jogador segura o empate (vale todo lance que não perde).
  final bool defend;

  /// A dificuldade, na escala de rating (`1620`).
  final int level;

  /// Quem joga na posição.
  Side get side => fen.split(' ')[1] == 'b' ? Side.black : Side.white;

  /// A faixa do problema: de 50 em 50 pontos até 1500 e de 25 em 25 depois.
  int get bucket => level < 1500 ? level ~/ 50 * 50 : level ~/ 25 * 25;
}

/// Um tipo de final do filtro da Corrida: a categoria e as peças de cada
/// lado, sem o rei, na ordem dama, torre, bispo, cavalo, peão (a peça
/// repetida vem repetida). [mine] é o lado de quem joga.
class RaceEndgameType {
  const RaceEndgameType({
    required this.subcategory,
    required this.category,
    required this.mine,
    required this.theirs,
  });

  /// O tipo de [problem], com as peças da posição inicial dele.
  factory RaceEndgameType.of(RaceProblem problem) {
    final board = problem.fen.split(' ').first;
    List<Role> pieces(Side side) => [
      for (final role in order)
        for (final char in board.split(''))
          if (char == (side == Side.white ? role.uppercaseLetter : role.letter))
            role,
    ];
    return RaceEndgameType(
      subcategory: problem.subcategory,
      category: problem.category,
      mine: pieces(problem.side),
      theirs: pieces(problem.side.opposite),
    );
  }

  static const order = [
    Role.queen,
    Role.rook,
    Role.bishop,
    Role.knight,
    Role.pawn,
  ];

  final String subcategory;
  final String category;
  final List<Role> mine;
  final List<Role> theirs;

  /// Quantas peças tem a posição (sem os reis).
  int get size => mine.length + theirs.length;
}

/// Como terminou uma Corrida.
enum RaceEnd { time, errors, quit }

/// O que o jogador fez num problema.
/// Como terminou um problema: acertou, errou, ou jogou uma vitória mais lenta.
enum RaceOutcomeKind { correct, wrong, slowWin }

class RaceAnswer {
  const RaceAnswer({
    required this.problemId,
    required this.level,
    required this.move,
    required this.correct,
    this.fen,
    this.best = const [],
    this.distance = 0,
    this.slower = false,
    this.subcategory,
    this.defend = false,
  });

  factory RaceAnswer.fromJson(Map<String, dynamic> json) => RaceAnswer(
    problemId: json['id'] as String,
    level: json['level'] as int,
    move: json['move'] as String,
    correct: json['correct'] as bool,
    fen: json['fen'] as String?,
    best: [for (final move in (json['best'] as List? ?? const [])) '$move'],
    distance: json['distance'] as int? ?? 0,
    slower: json['slower'] as bool? ?? false,
    subcategory: json['subcategory'] as String?,
    defend: json['defend'] as bool? ?? false,
  );

  final String problemId;
  final int level;

  /// O tipo de final do problema (para saber em que finais o jogador acerta).
  /// Nulo nas respostas gravadas antes de existir.
  final String? subcategory;

  /// O problema era de Defender (segurar o empate).
  final bool defend;

  /// Acerto, erro ou vitória mais lenta.
  RaceOutcomeKind get kind => correct
      ? RaceOutcomeKind.correct
      : slower
      ? RaceOutcomeKind.slowWin
      : RaceOutcomeKind.wrong;

  /// O lance jogado, em UCI. Num problema de vários lances, o último (o que
  /// errou, ou o que fechou a sequência).
  final String move;
  final bool correct;

  /// Nos erros: a posição em que o lance foi jogado (a vez do jogador dentro
  /// da sequência).
  final String? fen;

  /// Nos erros: os lances mais rápidos (UCI) daquela posição; no Defender,
  /// os que seguravam o empate.
  final List<String> best;

  /// Nos erros: meios-lances até o mate pelo caminho mais rápido.
  final int distance;

  /// O lance ainda ganhava, só que mais devagar (não é derrota nem empate).
  final bool slower;

  /// Nos erros: em quantos lances saía o mate pelo caminho mais rápido.
  int get mateIn => (distance + 1) ~/ 2;

  Map<String, dynamic> toJson() => {
    'id': problemId,
    'level': level,
    if (subcategory != null) 'subcategory': subcategory,
    if (defend) 'defend': true,
    'move': move,
    'correct': correct,
    if (fen != null) 'fen': fen,
    if (best.isNotEmpty) 'best': best,
    if (distance != 0) 'distance': distance,
    if (slower) 'slower': true,
  };
}

/// Uma Corrida: o instante em que começou, o filtro e as respostas até aqui.
/// Quanto falta sai do instante de início, como no relógio da partida: sobrevive
/// ao app em segundo plano e ao fechamento forçado.
class RaceRun {
  const RaceRun({
    required this.startedAt,
    this.filter = const RaceFilter(),
    this.answers = const [],
    this.duration = RaceDuration.threeMinutes,
  });

  factory RaceRun.fromJson(Map<String, dynamic> json) => RaceRun(
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      json['startedAt'] as int,
      isUtc: true,
    ),
    // Corrida de antes do filtro (o tema antigo): Ganhar, todos os finais.
    filter: json['filter'] == null
        ? const RaceFilter()
        : RaceFilter.fromJson(json['filter'] as Map<String, dynamic>),
    answers: [
      for (final answer in json['answers'] as List)
        RaceAnswer.fromJson(answer as Map<String, dynamic>),
    ],
    // Corrida de antes da escolha de duração: 3 minutos.
    duration: RaceDuration.fromMinutes(json['minutes'] as int?),
  );

  final DateTime startedAt;

  /// A duração com que esta Corrida começou.
  final RaceDuration duration;

  /// Os problemas que a Corrida sorteia (o recorde vale com qualquer filtro).
  final RaceFilter filter;
  final List<RaceAnswer> answers;

  int get corrects => answers.where((answer) => answer.correct).length;
  int get errors => answers.length - corrects;

  /// O nível mais alto resolvido. Zero se ninguém acertou.
  int get hardestSolved => answers
      .where((answer) => answer.correct)
      .fold(0, (best, answer) => answer.level > best ? answer.level : best);

  RaceRun withAnswer(RaceAnswer answer) => RaceRun(
    startedAt: startedAt,
    filter: filter,
    answers: [...answers, answer],
    duration: duration,
  );

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'filter': filter.toJson(),
    'minutes': duration.minutes,
    'answers': [for (final answer in answers) answer.toJson()],
  };
}

/// O recorde da Corrida: mais acertos e o problema mais difícil resolvido.
class RaceRecord {
  const RaceRecord({this.corrects = 0, this.hardest = 0});

  factory RaceRecord.fromJson(Map<String, dynamic> json) => RaceRecord(
    corrects: json['corrects'] as int,
    hardest: json['hardest'] as int,
  );

  final int corrects;
  final int hardest;

  bool get isEmpty => corrects == 0;

  Map<String, dynamic> toJson() => {'corrects': corrects, 'hardest': hardest};
}

/// Uma Corrida já terminada, como fica no histórico.
class RaceResult {
  const RaceResult({
    required this.run,
    required this.end,
    required this.finishedAt,
  });

  factory RaceResult.fromJson(Map<String, dynamic> json) => RaceResult(
    run: RaceRun.fromJson(json['run'] as Map<String, dynamic>),
    end: RaceEnd.values.byName(json['end'] as String),
    finishedAt: DateTime.fromMillisecondsSinceEpoch(
      json['finishedAt'] as int,
      isUtc: true,
    ),
  );

  final RaceRun run;
  final RaceEnd end;
  final DateTime finishedAt;

  Map<String, dynamic> toJson() => {
    'run': run.toJson(),
    'end': end.name,
    'finishedAt': finishedAt.millisecondsSinceEpoch,
  };
}

/// O que o fim de uma Corrida mudou no recorde.
class RaceOutcome {
  const RaceOutcome({
    required this.result,
    required this.previous,
    required this.isRecord,
  });

  final RaceResult result;

  /// O recorde de antes.
  final RaceRecord previous;
  final bool isRecord;
}
