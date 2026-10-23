import 'package:dartchess/dartchess.dart';

import 'endgame_position.dart';
import 'game_end.dart';

/// A fila do final do dia (`assets/daily/queue.json`): os ids do catálogo na
/// ordem em que saem, a partir de [epoch]. [version] sobe quando a fila
/// cresce; os dias já usados não mudam de final.
class DailyQueue {
  const DailyQueue({
    required this.version,
    required this.epoch,
    required this.ids,
  });

  factory DailyQueue.fromJson(Map<String, dynamic> json) => DailyQueue(
    version: json['version'] as int,
    epoch: DateTime.parse(json['epoch'] as String),
    ids: [for (final id in json['ids'] as List) id as String],
  );

  static final empty = DailyQueue(version: 0, epoch: DateTime(2026), ids: []);

  final int version;

  /// O primeiro dia da fila, o que leva o primeiro id.
  final DateTime epoch;
  final List<String> ids;
}

/// O final de um dia: a posição do catálogo, a mesma para todo mundo.
class DailyFinal {
  const DailyFinal({required this.date, required this.position});

  /// O dia, à meia-noite.
  final DateTime date;
  final EndgamePosition position;
}

/// A cor do quadradinho de um lance da pessoa.
enum DailySquare {
  /// Mantém o resultado teórico.
  right,

  /// Ainda vence, mais devagar. Só com DTZ ou DTM, que o app ainda não tem.
  slow,

  /// Piora o resultado.
  bad;

  static DailySquare? fromCode(String? code) => values.asNameMap()[code];
}

/// Como acabou a primeira tentativa do dia.
enum DailyOutcome {
  won,
  drew,
  lost;

  static DailyOutcome? fromCode(String? code) => values.asNameMap()[code];

  /// O fim da partida visto por quem joga com [user].
  static DailyOutcome of(GameEnd end, Side user) => switch (end.winner) {
    null => drew,
    final winner => winner == user ? won : lost,
  };

  /// O objetivo [goal] foi cumprido: ganhar, ou não perder no de empatar.
  bool fulfills(PositionGoal goal) => switch (goal) {
    PositionGoal.win => this == won,
    PositionGoal.draw => this != lost,
  };
}

/// A primeira tentativa do dia: é ela que vale para a sequência e para os
/// quadradinhos, mesmo que a pessoa jogue de novo.
class DailyRecord {
  const DailyRecord({
    required this.date,
    required this.positionId,
    required this.outcome,
    required this.fulfilled,
    required this.squares,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
    date: DateTime.parse(json['date'] as String),
    positionId: json['position'] as String,
    outcome:
        DailyOutcome.fromCode(json['outcome'] as String?) ?? DailyOutcome.lost,
    fulfilled: json['fulfilled'] as bool? ?? false,
    squares: [
      for (final code in json['squares'] as List? ?? const [])
        ?DailySquare.fromCode(code as String?),
    ],
  );

  final DateTime date;
  final String positionId;
  final DailyOutcome outcome;

  /// Cumpriu o objetivo do final (ganhar ou segurar o empate).
  final bool fulfilled;
  final List<DailySquare> squares;

  /// Quantos lances a pessoa fez.
  int get moves => squares.length;

  Map<String, dynamic> toJson() => {
    'date': dayCode(date),
    'position': positionId,
    'outcome': outcome.name,
    'fulfilled': fulfilled,
    'squares': [for (final square in squares) square.name],
  };

  /// `aaaa-mm-dd`, o dia na chave e no documento do dia.
  static String dayCode(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
