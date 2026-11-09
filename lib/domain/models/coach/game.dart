import 'json.dart';
import 'progress.dart';

enum TimeControl {
  bullet('bullet'),
  blitz('blitz'),
  rapid('rapida');

  const TimeControl(this.wire);

  final String wire;

  static TimeControl? parse(Object? value) =>
      byWire(values, (r) => r.wire, value);
}

enum GameResult {
  win('vitoria'),
  loss('derrota'),
  draw('empate');

  const GameResult(this.wire);

  final String wire;

  static GameResult? parse(Object? value) =>
      byWire(values, (r) => r.wire, value);
}

enum GameColor {
  white('brancas'),
  black('pretas');

  const GameColor(this.wire);

  final String wire;

  /// Aceita também `white`/`black` e `w`/`b`.
  static GameColor parse(Object? value) => switch (value) {
    'pretas' || 'black' || 'b' => black,
    _ => white,
  };
}

/// Em que pé está a análise da partida no servidor.
enum GameStatus {
  newGame('nova'),
  queued('na_fila'),
  analyzing('analisando'),
  ready('pronta'),
  error('erro');

  const GameStatus(this.wire);

  final String wire;

  static GameStatus parse(Object? value) =>
      byWire(values, (s) => s.wire, value) ?? newGame;

  /// Pedida e ainda sem resultado.
  bool get inProgress => this == queued || this == analyzing;
}

enum ExerciseType {
  /// Ver a ideia do adversário.
  opponent('adversario'),

  /// Impedir a ameaça.
  prophylaxis('profilaxia'),

  /// O melhor lance dele na partida (também o exercício único de uma
  /// partida sem posição-chave, gap 3).
  yourBest('seu_melhor'),

  /// O lance que decidiu a partida (em geral no final).
  decisive('decisivo');

  const ExerciseType(this.wire);

  final String wire;

  static ExerciseType parse(Object? value) =>
      byWire(values, (t) => t.wire, value) ?? decisive;
}

enum MoveClass {
  ok('ok'),
  inaccuracy('imprecisao'),
  error('erro'),
  blunder('grave');

  const MoveClass(this.wire);

  final String wire;

  static MoveClass parse(Object? value) =>
      byWire(values, (c) => c.wire, value) ?? ok;

  bool get isBad => this == error || this == blunder;
}

final class Opponent {
  const Opponent({required this.name, this.rating});

  final String name;
  final int? rating;

  static Opponent fromJson(Object? json) {
    final m = asMap(json);
    return Opponent(
      name: text(m['nome']) ?? '?',
      rating: intOrNull(m['rating']),
    );
  }

  Map<String, Object?> toJson() => {'nome': name, 'rating': rating};
}

final class GameOpening {
  const GameOpening({required this.eco, required this.name});

  final String eco;
  final String name;

  static GameOpening? fromJson(Object? json) {
    final m = asMap(json);
    final name = text(m['nome']);
    if (name == null) return null;
    return GameOpening(eco: text(m['eco']) ?? '', name: name);
  }

  Map<String, Object?> toJson() => {'eco': eco, 'nome': name};
}

/// O que o Viktor diz no exercício.
final class ExerciseLines {
  const ExerciseLines({
    required this.prompt,
    required this.correct,
    required this.error,
    required this.solution,
  });

  final String prompt;
  final String correct;
  final String error;
  final String solution;

  static ExerciseLines fromJson(Object? json) {
    final m = asMap(json);
    return ExerciseLines(
      prompt: text(m['enunciado']) ?? '',
      correct: text(m['acerto']) ?? '',
      error: text(m['erro']) ?? '',
      solution: text(m['solucao']) ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'enunciado': prompt,
    'acerto': correct,
    'erro': error,
    'solucao': solution,
  };
}

/// Uma posição-chave da partida virada exercício.
final class CoachExercise {
  const CoachExercise({
    required this.n,
    required this.type,
    required this.fen,
    required this.chessMove,
    required this.solution,
    this.accepted = const [],
    this.played,
    this.motif,
    this.stars = 1,
    this.lines = const ExerciseLines(
      prompt: '',
      correct: '',
      error: '',
      solution: '',
    ),
  });

  /// 1 a N, na ordem da partida.
  final int n;
  final ExerciseType type;

  /// A posição antes do lance a achar.
  final String fen;

  /// O número do lance na partida (para "Lance 8").
  final int chessMove;

  /// O lance certo, em UCI.
  final String solution;

  /// Outros lances certos, em UCI.
  final List<String> accepted;

  /// O que ele jogou na partida, em SAN.
  final String? played;

  /// O tema (só no histórico: o exercício não diz o tema).
  final String? motif;

  /// 1 a 3.
  final int stars;
  final ExerciseLines lines;

  /// [uci] resolve o exercício.
  bool accepts(String uci) => uci == solution || accepted.contains(uci);

  static CoachExercise? fromJson(Object? json, int index) {
    final m = asMap(json);
    final fen = text(m['fen']);
    final solution = text(m['solucao']);
    if (fen == null || solution == null) return null;
    return CoachExercise(
      n: integer(m['n'], index + 1),
      type: ExerciseType.parse(m['tipo']),
      fen: fen,
      chessMove: integer(m['lance']),
      solution: solution,
      accepted: texts(m['aceitos']),
      played: text(m['jogado']),
      motif: text(m['tema']),
      stars: integer(m['estrelas'], 1).clamp(1, 3),
      lines: ExerciseLines.fromJson(m['falas']),
    );
  }

  Map<String, Object?> toJson() => {
    'n': n,
    'tipo': type.wire,
    'fen': fen,
    'lance': chessMove,
    'solucao': solution,
    'aceitos': accepted,
    'jogado': played,
    'tema': motif,
    'estrelas': stars,
    'falas': lines.toJson(),
  };
}

/// Um meio-lance da partida com a avaliação do servidor.
final class AnalyzedMove {
  const AnalyzedMove({
    required this.san,
    required this.fen,
    this.cp,
    this.mate,
    this.best,
    this.moveClass = MoveClass.ok,
    this.comment,
  });

  final String san;

  /// A posição depois do lance.
  final String fen;

  /// Centipeões do ponto de vista das brancas (nulo com [mate]).
  final int? cp;

  /// Mate em N (positivo: brancas dão).
  final int? mate;

  /// O melhor lance na posição anterior, em SAN.
  final String? best;
  final MoveClass moveClass;

  /// A frase do treinador sobre o lance.
  final String? comment;

  static AnalyzedMove? fromJson(Object? json) {
    final m = asMap(json);
    final san = text(m['san']);
    final fen = text(m['fen']);
    if (san == null || fen == null) return null;
    return AnalyzedMove(
      san: san,
      fen: fen,
      cp: intOrNull(m['cp']),
      mate: intOrNull(m['mate']),
      best: text(m['melhor']),
      moveClass: MoveClass.parse(m['classe']),
      comment: text(m['comentario']),
    );
  }

  Map<String, Object?> toJson() => {
    'san': san,
    'fen': fen,
    'cp': cp,
    'mate': mate,
    'melhor': best,
    'classe': moveClass.wire,
    'comentario': comment,
  };
}

final class TheoryCandidate {
  const TheoryCandidate({
    required this.san,
    required this.games,
    required this.white,
    required this.draws,
    required this.black,
    this.line = const [],
  });

  final String san;
  final int games;

  /// Vitórias das brancas, empates e vitórias das pretas, em partidas.
  final int white;
  final int draws;
  final int black;

  /// A linha a que o lance chega, em SAN.
  final List<String> line;

  static TheoryCandidate? fromJson(Object? json) {
    final m = asMap(json);
    final san = text(m['san']);
    if (san == null) return null;
    return TheoryCandidate(
      san: san,
      games: integer(m['partidas']),
      white: integer(m['brancas']),
      draws: integer(m['empates']),
      black: integer(m['pretas']),
      line: texts(m['linha']),
    );
  }

  Map<String, Object?> toJson() => {
    'san': san,
    'partidas': games,
    'brancas': white,
    'empates': draws,
    'pretas': black,
    'linha': line,
  };
}

/// O lance em que ele saiu da teoria e o que a teoria joga ali.
final class GameTheory {
  const GameTheory({
    required this.chessMove,
    required this.fen,
    required this.candidates,
  });

  /// O índice do meio-lance (0 = 1º lance das brancas) em que saiu.
  final int chessMove;
  final String fen;
  final List<TheoryCandidate> candidates;

  static GameTheory? fromJson(Object? json) {
    final m = asMap(json);
    final fen = text(m['fen']);
    if (fen == null) return null;
    final candidates = [
      for (final c in list(m['candidatos'])) ?TheoryCandidate.fromJson(c),
    ];
    if (candidates.isEmpty) return null;
    return GameTheory(
      chessMove: integer(m['lance']),
      fen: fen,
      candidates: candidates,
    );
  }

  Map<String, Object?> toJson() => {
    'lance': chessMove,
    'fen': fen,
    'candidatos': [for (final c in candidates) c.toJson()],
  };
}

/// A precisão (0 a 100) em cada fase. Nulo: a partida não chegou à fase.
final class GamePhases {
  const GamePhases({this.opening, this.middlegame, this.ending});

  final double? opening;
  final double? middlegame;
  final double? ending;

  static GamePhases fromJson(Object? json) {
    final m = asMap(json);
    return GamePhases(
      opening: number(m['abertura']),
      middlegame: number(m['meio']),
      ending: number(m['final']),
    );
  }

  Map<String, Object?> toJson() => {
    'abertura': opening,
    'meio': middlegame,
    'final': ending,
  };
}

/// `users/{uid}/partidas/{id}` (id = `plataforma_idExterno`).
final class CoachGame {
  const CoachGame({
    required this.id,
    required this.moveAt,
    required this.color,
    required this.opponent,
    required this.result,
    this.url,
    this.timeControl,
    this.cadence,
    this.rating,
    this.opening,
    this.pgn,
    this.status = GameStatus.newGame,
    this.summary,
    this.accuracy,
    this.exercises = const [],
    this.moves = const [],
    this.theory,
    this.phases = const GamePhases(),
    this.motifs = const [],
    this.analyzedAt,
    this.errorReason,
    this.progress,
  });

  final String id;
  final String? url;
  final DateTime moveAt;
  final TimeControl? timeControl;

  /// "5+0".
  final String? cadence;
  final GameColor color;
  final Opponent opponent;

  /// O rating dele na partida.
  final int? rating;
  final GameResult result;
  final GameOpening? opening;
  final String? pgn;
  final GameStatus status;

  /// A frase do resumo da partida.
  final String? summary;

  /// 0 a 100.
  final double? accuracy;
  final List<CoachExercise> exercises;
  final List<AnalyzedMove> moves;
  final GameTheory? theory;
  final GamePhases phases;
  final List<String> motifs;
  final DateTime? analyzedAt;

  /// Por que a análise falhou (só com [GameStatus.error]): `variante`
  /// (não dá para refazer), `tempo`, `pgn` ou `outro`.
  final String? errorReason;

  /// A análise falhou de um jeito que tentar de novo resolve.
  bool get canRedo => errorReason != 'variante';

  /// O espelho do progresso gravado pelo app.
  final GameProgress? progress;

  bool get ready => status == GameStatus.ready;

  /// Só a parte de antes do `_`.
  String get platform => id.split('_').first;

  static CoachGame? fromJson(String id, Object? json) {
    final m = asMap(json);
    final moveAt = data(m['jogadaEm']);
    final result = GameResult.parse(m['resultado']);
    if (moveAt == null || result == null) return null;
    final exercises = <CoachExercise>[];
    for (final (i, e) in list(m['exercicios']).indexed) {
      if (CoachExercise.fromJson(e, i) case final ex?) exercises.add(ex);
    }
    exercises.sort((a, b) => a.n.compareTo(b.n));
    return CoachGame(
      id: id,
      url: text(m['url']),
      moveAt: moveAt,
      timeControl: TimeControl.parse(m['ritmo']),
      cadence: text(m['cadencia']),
      color: GameColor.parse(m['cor']),
      opponent: Opponent.fromJson(m['adversario']),
      rating: intOrNull(m['rating']),
      result: result,
      opening: GameOpening.fromJson(m['abertura']),
      pgn: text(m['pgn']),
      status: GameStatus.parse(m['status']),
      summary: text(m['resumo']),
      accuracy: number(m['precisao']),
      exercises: exercises,
      moves: [for (final l in list(m['lances'])) ?AnalyzedMove.fromJson(l)],
      theory: GameTheory.fromJson(m['teoria']),
      phases: GamePhases.fromJson(m['fases']),
      motifs: texts(m['temas']),
      analyzedAt: data(m['analisadaEm']),
      errorReason: text(m['erroMotivo']),
      progress: m['progresso'] == null
          ? null
          : GameProgress.fromJson(m['progresso']),
    );
  }

  Map<String, Object?> toJson() => {
    'url': url,
    'jogadaEm': moveAt.toIso8601String(),
    'ritmo': timeControl?.wire,
    'cadencia': cadence,
    'cor': color.wire,
    'adversario': opponent.toJson(),
    'rating': rating,
    'resultado': result.wire,
    'abertura': opening?.toJson(),
    'pgn': pgn,
    'status': status.wire,
    'resumo': summary,
    'precisao': accuracy,
    'exercicios': [for (final e in exercises) e.toJson()],
    'lances': [for (final l in moves) l.toJson()],
    'teoria': theory?.toJson(),
    'fases': phases.toJson(),
    'temas': motifs,
    'analisadaEm': analyzedAt?.toIso8601String(),
    if (errorReason != null) 'erroMotivo': errorReason,
    if (progress != null) 'progresso': progress!.toJson(),
  };

  CoachGame copyWith({GameStatus? status, GameProgress? progress}) => CoachGame(
    id: id,
    url: url,
    moveAt: moveAt,
    timeControl: timeControl,
    cadence: cadence,
    color: color,
    opponent: opponent,
    rating: rating,
    result: result,
    opening: opening,
    pgn: pgn,
    status: status ?? this.status,
    summary: summary,
    accuracy: accuracy,
    exercises: exercises,
    moves: moves,
    theory: theory,
    phases: phases,
    motifs: motifs,
    analyzedAt: analyzedAt,
    errorReason: errorReason,
    progress: progress ?? this.progress,
  );
}
