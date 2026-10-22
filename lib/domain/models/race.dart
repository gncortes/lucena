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

/// Um problema do banco da Corrida: uma posição ganha em que só um lance
/// mantém o ganho (conferido na tablebase). O formato do arquivo está em
/// `docs/tasks/E1.31-corrida-problemas.md`.
class RaceProblem {
  const RaceProblem({
    required this.id,
    required this.fen,
    required this.solution,
    required this.theme,
    required this.level,
  });

  factory RaceProblem.fromJson(Map<String, dynamic> json) => RaceProblem(
    id: json['id'] as String,
    fen: json['fen'] as String,
    solution: json['solution'] as String,
    theme: RaceTheme.fromCode(json['theme'] as String?) ?? RaceTheme.rook,
    level: json['level'] as int,
  );

  final String id;
  final String fen;

  /// O único lance que ganha, em UCI (`a1g7`).
  final String solution;
  final RaceTheme theme;

  /// A dificuldade, na escala de rating (`1620`).
  final int level;

  /// Quem joga na posição.
  Side get side => fen.split(' ')[1] == 'b' ? Side.black : Side.white;
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
  });

  factory RaceAnswer.fromJson(Map<String, dynamic> json) => RaceAnswer(
    problemId: json['id'] as String,
    level: json['level'] as int,
    move: json['move'] as String,
    correct: json['correct'] as bool,
  );

  final String problemId;
  final int level;

  /// O lance jogado, em UCI.
  final String move;
  final bool correct;

  Map<String, dynamic> toJson() => {
    'id': problemId,
    'level': level,
    'move': move,
    'correct': correct,
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
