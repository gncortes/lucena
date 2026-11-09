import '../../models/coach/coach.dart';

/// Abaixo disto a aba mostra só o estilo e a precisão média ("poucas
/// partidas", `SeuJogoPoucas` do canvas).
const minYourGameGames = 10;

/// Lances completos (do branco e do preto) que contam como abertura quando a
/// posição ainda não é de final.
const openingMoves = 12;

enum GamePhase { opening, middlegame, ending }

/// Aproveitamento de um grupo de partidas (ritmo, cor ou abertura).
final class ScoreRate {
  const ScoreRate({this.wins = 0, this.draws = 0, this.losses = 0});

  final int wins, draws, losses;

  int get games => wins + draws + losses;

  /// Pontos feitos a cada 100 possíveis (empate vale meio).
  int get percent =>
      games == 0 ? 0 : ((wins + draws / 2) * 100 / games).round();

  ScoreRate most(GameResult r) => ScoreRate(
    wins: wins + (r == GameResult.win ? 1 : 0),
    draws: draws + (r == GameResult.draw ? 1 : 0),
    losses: losses + (r == GameResult.loss ? 1 : 0),
  );
}

/// Onde ele sai da teoria numa abertura: o lance mais repetido.
final class TheoryExitView {
  const TheoryExitView({
    required this.chessMove,
    required this.san,
    required this.black,
    required this.times,
    required this.recentGame,
  });

  /// Número do lance (o 8 de "8...Bg4").
  final int chessMove;

  /// O lance dele, em SAN inglesa (sem número).
  final String san;

  /// Lance das pretas (escreve "8...").
  final bool black;
  final int times;

  /// A partida mais nova com essa saída: abre a teoria.
  final String recentGame;
}

final class OpeningSummary {
  const OpeningSummary({
    required this.name,
    required this.eco,
    required this.color,
    required this.scoreRate,
    this.exit,
    this.course,
  });

  final String name, eco;
  final GameColor color;
  final ScoreRate scoreRate;
  final TheoryExitView? exit;

  /// O lugar no curso que o servidor ligou (se veio).
  final LinkedCourse? course;
}

/// Uma posição de um tema, já com a partida para a linha da lista.
final class MotifPositionView {
  const MotifPositionView({required this.position, required this.game});

  final MotifPosition position;
  final CoachGame game;
}

final class MotifSummary {
  const MotifSummary({required this.motif, required this.positions});

  final String motif;

  /// Da mais recente.
  final List<MotifPositionView> positions;
}

sealed class YourGameFocus {
  const YourGameFocus();
}

/// Onde focar: a abertura em que ele sai da teoria sempre no mesmo lance.
final class OpeningFocus extends YourGameFocus {
  const OpeningFocus(this.opening);

  final OpeningSummary opening;
  TheoryExitView get exit => opening.exit!;
}

/// Onde focar: o tema com mais posições.
final class MotifFocus extends YourGameFocus {
  const MotifFocus(this.motif);

  final MotifSummary motif;
}

final class YourGameSummary {
  const YourGameSummary({
    required this.games,
    required this.accuracy,
    required this.accuracyChange,
    required this.scoreRate,
    required this.errorsByPhase,
    required this.weeksAccuracy,
    required this.motifs,
    required this.timeControls,
    required this.white,
    required this.black,
    required this.openings,
    required this.focus,
  });

  /// Partidas prontas no filtro.
  final int games;

  /// Precisão média (0 a 100), arredondada.
  final int? accuracy;

  /// Últimos 30 dias contra os 30 de antes, em pontos.
  final int? accuracyChange;
  final ScoreRate scoreRate;
  final Map<GamePhase, int> errorsByPhase;

  /// As 8 últimas semanas (a mais antiga primeiro); `null` = sem partida.
  final List<int?> weeksAccuracy;
  final List<MotifSummary> motifs;
  final Map<TimeControl, ScoreRate> timeControls;
  final ScoreRate white, black;
  final List<OpeningSummary> openings;
  final YourGameFocus? focus;

  bool get few => games < minYourGameGames;

  int get totalErrors => errorsByPhase.values.fold(0, (a, b) => a + b);

  GamePhase? get phaseMostErrors {
    if (totalErrors == 0) return null;
    return GamePhase.values.reduce(
      (a, b) => (errorsByPhase[b] ?? 0) > (errorsByPhase[a] ?? 0) ? b : a,
    );
  }
}

/// Os números da aba Seu jogo, calculados no aparelho a partir das partidas
/// prontas (assim o filtro de ritmo vale para tudo). Do documento de
/// estatísticas do servidor vêm só as posições por tema e o curso ligado a
/// cada abertura.
YourGameSummary summarizeYourGame({
  required List<CoachGame> games,
  required CoachStats stats,
  required DateTime currentTime,
  TimeControl? timeControl,
}) {
  final readyOnes =
      games
          .where(
            (p) =>
                p.ready &&
                (timeControl == null || p.timeControl == timeControl),
          )
          .toList()
        ..sort((a, b) => b.moveAt.compareTo(a.moveAt));
  final byId = {for (final p in readyOnes) p.id: p};

  var scoreRate = const ScoreRate();
  var white = const ScoreRate();
  var black = const ScoreRate();
  final timeControls = <TimeControl, ScoreRate>{};
  final errors = {for (final f in GamePhase.values) f: 0};
  for (final p in readyOnes) {
    scoreRate = scoreRate.most(p.result);
    if (p.color == GameColor.white) {
      white = white.most(p.result);
    } else {
      black = black.most(p.result);
    }
    if (p.timeControl case final r?) {
      timeControls[r] = (timeControls[r] ?? const ScoreRate()).most(p.result);
    }
    for (final (ply, chessMove) in p.moves.indexed) {
      if (!_hisMove(p.color, ply)) continue;
      if (chessMove.moveClass != MoveClass.error &&
          chessMove.moveClass != MoveClass.blunder) {
        continue;
      }
      final phase = phaseOfMove(ply, chessMove.fen);
      errors[phase] = errors[phase]! + 1;
    }
  }

  final motifs = <MotifSummary>[];
  for (final MapEntry(key: motif, value: positions)
      in stats.errorsByMotif.entries) {
    final list = [
      for (final pos in positions)
        if (byId[pos.game] case final game?)
          MotifPositionView(position: pos, game: game),
    ]..sort((a, b) => b.game.moveAt.compareTo(a.game.moveAt));
    if (list.isNotEmpty) {
      motifs.add(MotifSummary(motif: motif, positions: list));
    }
  }
  motifs.sort((a, b) {
    final c = b.positions.length.compareTo(a.positions.length);
    return c != 0 ? c : a.motif.compareTo(b.motif);
  });

  final openings = _openings(readyOnes, stats);

  return YourGameSummary(
    games: readyOnes.length,
    accuracy: _average(readyOnes),
    accuracyChange: _variation(readyOnes, currentTime),
    scoreRate: scoreRate,
    errorsByPhase: errors,
    weeksAccuracy: _weeks(readyOnes, currentTime),
    motifs: motifs,
    timeControls: {for (final r in TimeControl.values) r: ?timeControls[r]},
    white: white,
    black: black,
    openings: openings,
    focus: _focus(openings, motifs),
  );
}

bool _hisMove(GameColor color, int ply) =>
    color == GameColor.white ? ply.isEven : ply.isOdd;

/// Final: até 6 peças além de reis e peões (a mesma régua do servidor);
/// abertura: até o lance [openingMoves]; o resto é meio-jogo.
GamePhase phaseOfMove(int ply, String fen) {
  final board = fen.split(' ').first;
  final pieces = RegExp('[qrbnQRBN]').allMatches(board).length;
  if (board.isNotEmpty && pieces <= 6) return GamePhase.ending;
  if (ply ~/ 2 + 1 <= openingMoves) return GamePhase.opening;
  return GamePhase.middlegame;
}

int? _average(Iterable<CoachGame> games) {
  final values = [for (final p in games) ?p.accuracy];
  if (values.isEmpty) return null;
  return (values.reduce((a, b) => a + b) / values.length).round();
}

int? _variation(List<CoachGame> games, DateTime currentTime) {
  final cutoff = currentTime.subtract(const Duration(days: 30));
  final before = currentTime.subtract(const Duration(days: 60));
  final recent = _average(games.where((p) => p.moveAt.isAfter(cutoff)));
  final previousOnes = _average(
    games.where((p) => !p.moveAt.isAfter(cutoff) && p.moveAt.isAfter(before)),
  );
  if (recent == null || previousOnes == null) return null;
  return recent - previousOnes;
}

/// Semanas de segunda a domingo, na hora local.
List<int?> _weeks(List<CoachGame> games, DateTime currentTime) {
  final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
  final second = today.subtract(Duration(days: today.weekday - 1));
  return [
    for (var i = 7; i >= 0; i--)
      _average(
        games.where((p) {
          final local = p.moveAt.toLocal();
          final start = DateTime(second.year, second.month, second.day - 7 * i);
          final end = DateTime(start.year, start.month, start.day + 7);
          return !local.isBefore(start) && local.isBefore(end);
        }),
      ),
  ];
}

List<OpeningSummary> _openings(List<CoachGame> readyOnes, CoachStats stats) {
  final groups = <(String, GameColor), List<CoachGame>>{};
  for (final p in readyOnes) {
    final a = p.opening;
    if (a == null || a.name.isEmpty) continue;
    groups.putIfAbsent((a.name, p.color), () => []).add(p);
  }
  final list = <OpeningSummary>[];
  for (final MapEntry(key: (name, color), value: matches) in groups.entries) {
    var rate = const ScoreRate();
    for (final p in matches) {
      rate = rate.most(p.result);
    }
    final eco = matches.first.opening!.eco;
    final server = stats.openings
        .where((a) => a.color == color && (a.name == name || a.eco == eco))
        .firstOrNull;
    list.add(
      OpeningSummary(
        name: name,
        eco: eco,
        color: color,
        scoreRate: rate,
        exit: _exit(matches),
        course: server?.course,
      ),
    );
  }
  list.sort((a, b) {
    final c = b.scoreRate.games.compareTo(a.scoreRate.games);
    return c != 0 ? c : a.name.compareTo(b.name);
  });
  return list;
}

/// O lance em que ele mais sai da teoria (`teoria.lance` é o índice do meio
/// lance; o lance jogado é `lances[índice]`).
TheoryExitView? _exit(List<CoachGame> matches) {
  final count = <(int, String), List<CoachGame>>{};
  for (final p in matches) {
    final ply = p.theory?.chessMove;
    if (ply == null || ply < 0 || ply >= p.moves.length) continue;
    if (!_hisMove(p.color, ply)) continue;
    count.putIfAbsent((ply, p.moves[ply].san), () => []).add(p);
  }
  if (count.isEmpty) return null;
  final bigger = count.entries.reduce(
    (a, b) => b.value.length > a.value.length ? b : a,
  );
  final (ply, san) = bigger.key;
  return TheoryExitView(
    chessMove: ply ~/ 2 + 1,
    san: san,
    black: ply.isOdd,
    times: bigger.value.length,
    recentGame: bigger.value.first.id,
  );
}

/// Abertura com a mesma saída em pelo menos 3 partidas e na metade delas;
/// senão o tema com 3 posições ou mais; senão nada.
YourGameFocus? _focus(
  List<OpeningSummary> openings,
  List<MotifSummary> motifs,
) {
  final candidateMoves = [
    for (final a in openings)
      if (a.exit case final s?
          when s.times >= 3 && s.times * 2 >= a.scoreRate.games)
        a,
  ]..sort((a, b) => b.exit!.times.compareTo(a.exit!.times));
  if (candidateMoves.isNotEmpty) return OpeningFocus(candidateMoves.first);
  if (motifs.firstOrNull case final t? when t.positions.length >= 3) {
    return MotifFocus(t);
  }
  return null;
}
