import 'json.dart';
import 'json.dart' as j;
import 'game.dart';

/// Uma posição do histórico de um tema (Seu jogo › Erros por tema).
final class MotifPosition {
  const MotifPosition({
    required this.game,
    required this.chessMove,
    required this.fen,
  });

  /// O id da partida.
  final String game;
  final int chessMove;
  final String fen;

  static MotifPosition? fromJson(Object? json) {
    final m = asMap(json);
    final game = text(m['partida']);
    final fen = text(m['fen']);
    if (game == null || fen == null) return null;
    return MotifPosition(game: game, chessMove: integer(m['lance']), fen: fen);
  }

  Map<String, Object?> toJson() => {
    'partida': game,
    'lance': chessMove,
    'fen': fen,
  };
}

/// Onde a abertura sai da teoria com mais frequência.
final class TheoryExit {
  const TheoryExit({required this.chessMove, required this.times});

  final int chessMove;
  final int times;

  static TheoryExit? fromJson(Object? json) {
    if (json is! Map) return null;
    final m = asMap(json);
    return TheoryExit(
      chessMove: integer(m['lance']),
      times: integer(m['vezes']),
    );
  }

  Map<String, Object?> toJson() => {'lance': chessMove, 'vezes': times};
}

/// O lugar da abertura num curso do Lucena (ligação com Pilares/Metas).
final class LinkedCourse {
  const LinkedCourse({required this.id, required this.part});

  final String id;
  final int part;

  static LinkedCourse? fromJson(Object? json) {
    final m = asMap(json);
    final id = text(m['id']);
    if (id == null) return null;
    return LinkedCourse(id: id, part: integer(m['parte']));
  }

  Map<String, Object?> toJson() => {'id': id, 'parte': part};
}

final class PlayedOpening {
  const PlayedOpening({
    required this.name,
    required this.eco,
    required this.color,
    required this.games,
    required this.wins,
    this.theoryExit,
    this.course,
  });

  final String name;
  final String eco;
  final GameColor color;
  final int games;
  final int wins;
  final TheoryExit? theoryExit;
  final LinkedCourse? course;

  static PlayedOpening? fromJson(Object? json) {
    final m = asMap(json);
    final name = text(m['nome']);
    if (name == null) return null;
    return PlayedOpening(
      name: name,
      eco: text(m['eco']) ?? '',
      color: GameColor.parse(m['cor']),
      games: integer(m['partidas']),
      wins: integer(m['vitorias']),
      theoryExit: TheoryExit.fromJson(m['saidaTeoria']),
      course: m['curso'] == null ? null : LinkedCourse.fromJson(m['curso']),
    );
  }

  Map<String, Object?> toJson() => {
    'nome': name,
    'eco': eco,
    'cor': color.wire,
    'partidas': games,
    'vitorias': wins,
    'saidaTeoria': theoryExit?.toJson(),
    'curso': course?.toJson(),
  };
}

/// Até 19 partidas = primeira leitura; 20 a 49 = em formação; 50+ = firme.
enum StyleLevel {
  first('primeira'),
  forming('formacao'),
  solid('firme');

  const StyleLevel(this.wire);

  final String wire;

  static StyleLevel parse(Object? value) =>
      byWire(values, (n) => n.wire, value) ?? first;
}

/// Um ponto do estilo: o texto, em quantas partidas apareceu e a ação.
/// O servidor pode mandar só o texto.
final class StylePoint {
  const StylePoint({required this.text, this.games, this.motif});

  final String text;
  final int? games;

  /// O tema ligado (leva à aula ou ao exercício).
  final String? motif;

  static StylePoint? fromJson(Object? json) {
    if (json is String) return StylePoint(text: json);
    final m = asMap(json);
    final t = j.text(m['texto']);
    if (t == null) return null;
    return StylePoint(
      text: t,
      games: intOrNull(m['partidas']),
      motif: j.text(m['tema']),
    );
  }

  Map<String, Object?> toJson() => {
    'texto': text,
    'partidas': games,
    'tema': motif,
  };
}

final class PlayerStyle {
  const PlayerStyle({
    this.level = StyleLevel.first,
    this.strengths = const [],
    this.solve = const [],
  });

  final StyleLevel level;
  final List<StylePoint> strengths;
  final List<StylePoint> solve;

  static PlayerStyle fromJson(Object? json) {
    final m = asMap(json);
    return PlayerStyle(
      level: StyleLevel.parse(m['nivel']),
      strengths: [for (final p in list(m['fortes'])) ?StylePoint.fromJson(p)],
      solve: [for (final p in list(m['acertar'])) ?StylePoint.fromJson(p)],
    );
  }

  Map<String, Object?> toJson() => {
    'nivel': level.wire,
    'fortes': [for (final p in strengths) p.toJson()],
    'acertar': [for (final p in solve) p.toJson()],
  };
}

/// A precisão média de uma semana.
final class WeekAccuracy {
  const WeekAccuracy({required this.accuracy, this.week});

  /// O início da semana (nulo se o servidor mandou só o número).
  final DateTime? week;
  final double accuracy;

  static WeekAccuracy? fromJson(Object? json) {
    if (json is num) return WeekAccuracy(accuracy: json.toDouble());
    final m = asMap(json);
    final p = number(m['precisao']);
    if (p == null) return null;
    return WeekAccuracy(accuracy: p, week: data(m['semana']));
  }

  Map<String, Object?> toJson() => {
    'semana': week?.toIso8601String(),
    'precisao': accuracy,
  };
}

/// Quantos erros em cada fase.
final class ErrorsByPhase {
  const ErrorsByPhase({this.opening = 0, this.middlegame = 0, this.ending = 0});

  final int opening;
  final int middlegame;
  final int ending;

  int get total => opening + middlegame + ending;

  static ErrorsByPhase fromJson(Object? json) {
    final m = asMap(json);
    return ErrorsByPhase(
      opening: integer(m['abertura']),
      middlegame: integer(m['meio']),
      ending: integer(m['final']),
    );
  }

  Map<String, Object?> toJson() => {
    'abertura': opening,
    'meio': middlegame,
    'final': ending,
  };
}

/// `users/{uid}/treinador/estatisticas`.
final class CoachStats {
  const CoachStats({
    this.analyzedGames = 0,
    this.weeksAccuracy = const [],
    this.errorsByPhase = const ErrorsByPhase(),
    this.errorsByMotif = const {},
    this.openings = const [],
    this.style = const PlayerStyle(),
  });

  static const blank = CoachStats();

  final int analyzedGames;
  final List<WeekAccuracy> weeksAccuracy;
  final ErrorsByPhase errorsByPhase;

  /// Tema → posições, da mais recente.
  final Map<String, List<MotifPosition>> errorsByMotif;
  final List<PlayedOpening> openings;
  final PlayerStyle style;

  static CoachStats fromJson(Object? json) {
    final m = asMap(json);
    return CoachStats(
      analyzedGames: integer(m['partidasAnalisadas']),
      weeksAccuracy: [
        for (final p in list(m['precisaoSemanas'])) ?WeekAccuracy.fromJson(p),
      ],
      errorsByPhase: ErrorsByPhase.fromJson(m['errosPorFase']),
      errorsByMotif: {
        for (final e in asMap(m['errosPorTema']).entries)
          e.key: [for (final p in list(e.value)) ?MotifPosition.fromJson(p)],
      },
      openings: [
        for (final a in list(m['aberturas'])) ?PlayedOpening.fromJson(a),
      ],
      style: PlayerStyle.fromJson(m['estilo']),
    );
  }

  Map<String, Object?> toJson() => {
    'partidasAnalisadas': analyzedGames,
    'precisaoSemanas': [for (final p in weeksAccuracy) p.toJson()],
    'errosPorFase': errorsByPhase.toJson(),
    'errosPorTema': {
      for (final e in errorsByMotif.entries)
        e.key: [for (final p in e.value) p.toJson()],
    },
    'aberturas': [for (final a in openings) a.toJson()],
    'estilo': style.toJson(),
  };
}
