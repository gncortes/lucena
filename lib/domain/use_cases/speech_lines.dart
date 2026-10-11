import 'package:dartchess/dartchess.dart';

import 'speech_links.dart';

/// Uma variante citada numa fala ("1.Re4? Re6 2.Rf4"): os lances, na ordem,
/// jogados a partir de uma posição.
class SpeechLine {
  const SpeechLine({
    required this.links,
    required this.fens,
    required this.moves,
  });

  /// Os trechos da fala, um por lance.
  final List<SpeechLink> links;

  /// A posição de partida (`fens[0]`) e a de depois de cada lance
  /// (`fens[i]`, depois do lance `i`).
  final List<String> fens;

  /// Os lances, já resolvidos na posição.
  final List<Move> moves;

  int get length => moves.length;

  /// Quantos lances da variante levam até [link] (1 é o primeiro). Nulo: o
  /// trecho não é desta variante.
  int? plyOf(SpeechLink link) {
    for (var i = 0; i < links.length; i++) {
      if (links[i].start == link.start && links[i].text == link.text) {
        return i + 1;
      }
    }
    return null;
  }
}

/// Onde o aluno está numa variante: [ply] lances jogados (0 é a posição de
/// partida).
class SpeechLineCursor {
  SpeechLineCursor(this.line, [this.ply = 0])
    : assert(ply >= 0 && ply <= line.moves.length);

  final SpeechLine line;
  final int ply;

  String get fen => line.fens[ply];

  /// O último lance jogado, para marcar no tabuleiro.
  Move? get lastMove => ply == 0 ? null : line.moves[ply - 1];

  bool get canPrevious => ply > 0;
  bool get canNext => ply < line.moves.length;

  SpeechLineCursor previous() =>
      canPrevious ? SpeechLineCursor(line, ply - 1) : this;

  SpeechLineCursor next() => canNext ? SpeechLineCursor(line, ply + 1) : this;
}

/// Acha as variantes de uma fala: os lances seguidos ("1.Re4 Re6 2.Rf4" ou
/// "1.Re4? Aí o rei responde 1...Re6") viram uma linha, jogada a partir da
/// posição do passo. Toda regra vem do `dartchess`.
abstract final class SpeechLines {
  /// As variantes dos [links] de uma fala (de [SpeechLinks.find], com as
  /// [letters] do idioma dela). Cada uma é jogada a partir da primeira das
  /// [bases] (FENs) em que vai mais longe; o lance que não cabe em nenhuma
  /// começa outra. Lance que não se joga em lugar nenhum fica de fora.
  static List<SpeechLine> find(
    List<SpeechLink> links,
    Map<String, Role> letters,
    List<String> bases,
  ) {
    final positions = <Position>[
      for (final fen in {...bases}) ?_position(fen),
    ];
    if (positions.isEmpty) return const [];
    final lines = <SpeechLine>[];
    for (final group in _groups(links.where((link) => link.isMove).toList())) {
      var rest = group;
      while (rest.isNotEmpty) {
        final line = _longest(rest, letters, [
          ..._branches(rest.first, lines),
          ...positions,
        ]);
        if (line == null) {
          rest = rest.sublist(1);
          continue;
        }
        lines.add(line);
        rest = rest.sublist(line.length);
      }
    }
    return lines;
  }

  /// A variante de [link] entre as [lines]: a primeira que o tem.
  static SpeechLine? lineOf(List<SpeechLine> lines, SpeechLink link) {
    for (final line in lines) {
      if (line.plyOf(link) != null) return line;
    }
    return null;
  }

  /// O lance de [link] na [position], com as [letters] do idioma da fala.
  /// Nulo se não for um lance legal ali.
  static Move? moveOf(
    Position position,
    SpeechLink link,
    Map<String, Role> letters,
  ) {
    if (!link.isMove) return null;
    final san = _san(link.text, letters);
    if (san == null) return null;
    final move = position.parseSan(san);
    if (move == null) return null;
    // O peão na última fila sem a peça escolhida não é lance.
    if (move case NormalMove(:final from, :final to, promotion: null)) {
      if (position.board.roleAt(from) == Role.pawn &&
          SquareSet.backranks.has(to)) {
        return null;
      }
    }
    return move;
  }

  /// O número escrito antes do lance, em meios-lances desde o lance 1 das
  /// brancas ("1." é 0, "1..." é 1, "2." é 2). Nulo: sem número.
  static int? plyNumberOf(SpeechLink link) {
    final match = _number.firstMatch(link.text);
    if (match == null) return null;
    final number = int.parse(match.group(1)!);
    if (number == 0) return null;
    return (number - 1) * 2 + (match.group(2) != null ? 1 : 0);
  }

  static final _number = RegExp(r'^(\d{1,3})\.(\.\.)?');

  // Os lances seguidos: o número que não continua o anterior começa outro
  // grupo; o lance sem número continua o anterior, e o número depois de um
  // lance sem número também (o que não se joga começa outro depois).
  static List<List<SpeechLink>> _groups(List<SpeechLink> moves) {
    final groups = <List<SpeechLink>>[];
    int? last;
    for (final link in moves) {
      final ply = plyNumberOf(link);
      final continues =
          groups.isNotEmpty && (ply == null || last == null || ply == last + 1);
      if (continues) {
        groups.last.add(link);
      } else {
        groups.add([link]);
      }
      last = ply ?? (last == null ? null : last + 1);
    }
    return groups;
  }

  // A variante que sai de um lance de outra já achada: "1.Re4 Re6 2.Rf4 ...
  // em vez disso, 2.Rd5" joga 2.Rd5 depois de 1...Re6.
  static Iterable<Position> _branches(
    SpeechLink first,
    List<SpeechLine> lines,
  ) sync* {
    final ply = plyNumberOf(first);
    if (ply == null) return;
    for (final line in lines.reversed) {
      final start = plyNumberOf(line.links.first);
      if (start == null) continue;
      final at = ply - start;
      if (at <= 0 || at > line.length) continue;
      if (_position(line.fens[at]) case final position?) yield position;
    }
  }

  // A linha mais longa de [links] a partir de uma das [starts] (na ordem,
  // a primeira ganha o empate). Nula se nenhum lance se joga.
  static SpeechLine? _longest(
    List<SpeechLink> links,
    Map<String, Role> letters,
    List<Position> starts,
  ) {
    SpeechLine? best;
    final ply = plyNumberOf(links.first);
    for (final start in starts) {
      // "1..." é lance das pretas: só vale com as pretas a jogar.
      if (ply != null && (ply.isEven) != (start.turn == Side.white)) continue;
      final fens = [start.fen];
      final moves = <Move>[];
      var position = start;
      for (final link in links) {
        final move = moveOf(position, link, letters);
        if (move == null) break;
        position = position.play(move);
        moves.add(move);
        fens.add(position.fen);
      }
      if (moves.isEmpty) continue;
      if (best == null || moves.length > best.length) {
        best = SpeechLine(
          links: links.sublist(0, moves.length),
          fens: fens,
          moves: moves,
        );
      }
    }
    return best;
  }

  // O lance em notação inglesa, como o dartchess lê: sem o número nem a
  // avaliação, com as letras das peças do inglês.
  static String? _san(String text, Map<String, Role> letters) {
    var san = text
        .replaceFirst(_number, '')
        .replaceAll(RegExp(r'[?!]+$'), '')
        .replaceAll('0', 'O');
    if (san.isEmpty) return null;
    if (san.startsWith('O')) return san;
    String english(String letter) => letters[letter]?.uppercaseLetter ?? letter;
    final first = san[0];
    if (letters.containsKey(first)) {
      san = english(first) + san.substring(1);
    }
    final promotion = san.indexOf('=');
    if (promotion >= 0 && promotion + 1 < san.length) {
      san =
          san.substring(0, promotion + 1) +
          english(san[promotion + 1]) +
          san.substring(promotion + 2);
    }
    return san;
  }

  static Position? _position(String fen) {
    try {
      return Chess.fromSetup(Setup.parseFen(fen));
    } on FenException {
      return null;
    } on PositionSetupException {
      return null;
    }
  }
}
