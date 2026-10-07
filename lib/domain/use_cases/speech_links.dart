import 'package:dartchess/dartchess.dart';

/// Um trecho tocável de uma fala: uma casa (`e4`) ou um lance (`Tf7`,
/// `Cxe5+`, `O-O`, `e8=D`), com a posição dele no texto.
class SpeechLink {
  const SpeechLink({
    required this.start,
    required this.end,
    required this.text,
    this.square,
    this.role,
    this.isMove = false,
    this.castle,
    this.fromFile,
    this.fromRank,
  });

  /// Do caractere [start] até antes de [end].
  final int start;
  final int end;
  final String text;

  /// A casa citada, ou o destino do lance. Nula só no roque.
  final Square? square;

  /// A peça que move (nula: peão, ou casa sozinha).
  final Role? role;

  /// Um lance, não só uma casa.
  final bool isMove;

  /// Roque: o pequeno (`true`) ou o grande (`false`).
  final bool? castle;

  /// A coluna ou a fileira de saída escrita no lance (`Tad1`, `C5f3`,
  /// `exd5`).
  final File? fromFile;
  final Rank? fromRank;

  @override
  String toString() => 'SpeechLink($text @ $start)';
}

/// Acha as casas e os lances numa fala do professor, para tocar neles e ver
/// no tabuleiro. A letra das peças depende do idioma da fala.
abstract final class SpeechLinks {
  /// As letras das peças em inglês (e nos idiomas sem aulas próprias, que
  /// mostram as falas em inglês).
  static const english = {
    'K': Role.king,
    'Q': Role.queen,
    'R': Role.rook,
    'B': Role.bishop,
    'N': Role.knight,
  };

  /// As letras em português (rei, dama, torre, bispo, cavalo).
  static const portuguese = {
    'R': Role.king,
    'D': Role.queen,
    'T': Role.rook,
    'B': Role.bishop,
    'C': Role.knight,
  };

  /// As letras das falas no idioma [languageCode]: as aulas existem em
  /// português e em inglês.
  static Map<String, Role> lettersFor(String languageCode) =>
      languageCode == 'pt' ? portuguese : english;

  /// Os trechos tocáveis de [text], na ordem.
  static List<SpeechLink> find(String text, Map<String, Role> letters) {
    final pieces = letters.keys.join();
    // Isolado: nem letra nem número colado antes ou depois ("be4" dentro de
    // uma palavra não vale).
    final pattern = RegExp(
      r'(?<![\p{L}\p{N}])(?:(O-O-O|O-O|0-0-0|0-0)|'
      '([$pieces])?([a-h])?([1-8])?(x)?([a-h][1-8])'
      '(?:=([$pieces]))?)'
      r'([+#])?(?![\p{L}\p{N}])',
      unicode: true,
    );
    final links = <SpeechLink>[];
    for (final match in pattern.allMatches(text)) {
      final castle = match.group(1);
      if (castle != null) {
        links.add(
          SpeechLink(
            start: match.start,
            end: match.end,
            text: match.group(0)!,
            isMove: true,
            castle: castle.length <= 3,
          ),
        );
        continue;
      }
      final piece = match.group(2);
      final file = match.group(3);
      final rank = match.group(4);
      final capture = match.group(5) != null;
      final promotion = match.group(7) != null;
      final check = match.group(8) != null;
      final dest = Square.fromName(match.group(6)!);
      final isMove =
          piece != null ||
          file != null ||
          rank != null ||
          capture ||
          promotion ||
          check;
      // "a2a4" sem peça é um lance em coordenadas; a coluna e a fileira de
      // saída só valem num lance.
      links.add(
        SpeechLink(
          start: match.start,
          end: match.end,
          text: match.group(0)!,
          square: dest,
          role: piece == null ? null : letters[piece],
          isMove: isMove,
          fromFile: file == null ? null : File.values[file.codeUnitAt(0) - 97],
          fromRank: rank == null ? null : Rank.values[int.parse(rank) - 1],
        ),
      );
    }
    return links;
  }

  /// A seta de [link] na [position]: de onde a peça sai e aonde chega. Nula
  /// quando não dá para saber de onde (casa sozinha, peça que não está lá ou
  /// mais de uma candidata): aí o tabuleiro só marca o destino.
  static (Square from, Square to)? arrowFor(
    Position position,
    SpeechLink link,
  ) => arrowOn(position.board, position.turn, link);

  /// O mesmo que [arrowFor], só com as peças e a vez: vale também para as
  /// posições das aulas que não são partidas (sem os dois reis).
  static (Square from, Square to)? arrowOn(
    Board board,
    Side turn,
    SpeechLink link,
  ) {
    final castle = link.castle;
    if (castle != null) {
      // O roque do lado da vez.
      final king = board.kingOf(turn);
      if (king == null) return null;
      final rank = king.rank;
      final to = Square.fromCoords(castle ? File.g : File.c, rank);
      return (king, to);
    }
    final to = link.square;
    if (!link.isMove || to == null) return null;
    final role = link.role ?? Role.pawn;
    final occupied = board.occupied;
    final candidates = <Square>[];
    for (final from in board.byRole(role).squares) {
      final piece = board.pieceAt(from)!;
      if (from == to) continue;
      if (link.fromFile != null && from.file != link.fromFile) continue;
      if (link.fromRank != null && from.rank != link.fromRank) continue;
      if (_reaches(piece, from, to, occupied)) candidates.add(from);
    }
    return candidates.length == 1 ? (candidates.single, to) : null;
  }

  // A peça em [from] chega em [to]: pelo ataque ou, o peão, andando.
  static bool _reaches(
    Piece piece,
    Square from,
    Square to,
    SquareSet occupied,
  ) {
    if (attacks(piece, from, occupied).has(to)) return true;
    if (piece.role != Role.pawn || from.file != to.file) return false;
    final step = piece.color == Side.white ? 1 : -1;
    final one = from.rank.value + step;
    if (to.rank.value == one) return !occupied.has(to);
    final start = piece.color == Side.white ? Rank.second : Rank.seventh;
    final middle = Square.fromCoords(from.file, Rank.values[one]);
    return from.rank == start &&
        to.rank.value == one + step &&
        !occupied.has(middle) &&
        !occupied.has(to);
  }
}
