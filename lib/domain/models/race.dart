import 'package:dartchess/dartchess.dart';

/// O tema de um problema da Corrida: casa com os filtros "Quais finais".
enum RaceTheme {
  rook,
  pawns,
  queen,
  minor;

  static RaceTheme? fromCode(String? code) => values.asNameMap()[code];

  /// O tema da Corrida que treina a subcategoria de um final da Jornada.
  /// Nulo quando nenhum tema cobre o final.
  static RaceTheme? ofSubcategory(String subcategory) => switch (subcategory) {
    'queen' || 'queenVsPawn' || 'queenVsRook' => queen,
    'rook' || 'twoRooks' || 'rookPawnVsRook' || 'rookVsPawn' => rook,
    'pawnVsKing' => pawns,
    'twoBishopsVsKing' || 'knightBishopVsKing' => minor,
    _ => null,
  };
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
/// ganham, mas mais devagar (contam como erro).
class RaceNode {
  const RaceNode({
    required this.distance,
    required this.moves,
    this.slower = const {},
  });

  factory RaceNode.fromJson(Map<String, dynamic> json) => RaceNode(
    distance: json['d'] as int,
    moves: {
      for (final entry in (json['m'] as Map<String, dynamic>).entries)
        entry.key: RaceBranch.fromJson(entry.value as Map<String, dynamic>),
    },
    slower: {for (final move in (json['w'] as List? ?? const [])) '$move'},
  );

  /// Meios-lances até o mate, jogando o mais rápido (a DTM da tablebase).
  final int distance;

  /// Os lances ótimos (UCI) e o que vem depois de cada um.
  final Map<String, RaceBranch> moves;

  /// Lances que também ganham, só que mais devagar.
  final Set<String> slower;

  /// Em quantos lances (do jogador) sai o mate pelo caminho mais rápido.
  int get mateIn => (distance + 1) ~/ 2;

  List<String> get best => moves.keys.toList();
}

/// Um problema do banco da Corrida: uma sequência de lances ótimos, conferida
/// na tablebase, até o mate ou o fim da linha. O formato está em
/// `tools/build_race_problems.py`.
class RaceProblem {
  const RaceProblem({
    required this.id,
    required this.fen,
    required this.tree,
    required this.theme,
    required this.level,
  });

  factory RaceProblem.fromJson(Map<String, dynamic> json) => RaceProblem(
    id: json['id'] as String,
    fen: json['fen'] as String,
    tree: RaceNode.fromJson(json['tree'] as Map<String, dynamic>),
    theme: RaceTheme.fromCode(json['theme'] as String?) ?? RaceTheme.rook,
    level: json['level'] as int,
  );

  final String id;
  final String fen;

  /// Os lances ótimos da primeira vez do jogador e o que vem depois.
  final RaceNode tree;
  final RaceTheme theme;

  /// A dificuldade, na escala de rating (`1620`).
  final int level;

  /// Quem joga na posição.
  Side get side => fen.split(' ')[1] == 'b' ? Side.black : Side.white;

  /// A faixa do problema (de 50 em 50 pontos).
  int get bucket => level ~/ 50 * 50;
}

/// Como terminou uma Corrida.
enum RaceEnd { time, errors, quit }

/// O que o jogador fez num problema.
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
  );

  final String problemId;
  final int level;

  /// O lance jogado, em UCI. Num problema de vários lances, o último (o que
  /// errou, ou o que fechou a sequência).
  final String move;
  final bool correct;

  /// Nos erros: a posição em que o lance foi jogado (a vez do jogador dentro
  /// da sequência).
  final String? fen;

  /// Nos erros: os lances mais rápidos (UCI) daquela posição.
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
  const RaceRun({required this.startedAt, this.theme, this.answers = const []});

  factory RaceRun.fromJson(Map<String, dynamic> json) => RaceRun(
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      json['startedAt'] as int,
      isUtc: true,
    ),
    theme: RaceTheme.fromCode(json['theme'] as String?),
    answers: [
      for (final answer in json['answers'] as List)
        RaceAnswer.fromJson(answer as Map<String, dynamic>),
    ],
  );

  final DateTime startedAt;

  /// Só problemas deste tema. Nulo: todos os finais.
  final RaceTheme? theme;
  final List<RaceAnswer> answers;

  int get corrects => answers.where((answer) => answer.correct).length;
  int get errors => answers.length - corrects;

  /// O nível mais alto resolvido. Zero se ninguém acertou.
  int get hardestSolved => answers
      .where((answer) => answer.correct)
      .fold(0, (best, answer) => answer.level > best ? answer.level : best);

  RaceRun withAnswer(RaceAnswer answer) => RaceRun(
    startedAt: startedAt,
    theme: theme,
    answers: [...answers, answer],
  );

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'theme': theme?.name,
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
