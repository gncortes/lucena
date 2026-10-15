/// O lance descrito em palavras, sem notação: que peça anda, para que casa,
/// se captura e se promove. O balão do Viktor usa isto nos lances sem
/// comentário escrito.
class MoveWords {
  const MoveWords({
    required this.piece,
    required this.to,
    required this.capture,
    this.promotion,
  });

  /// king, queen, rook, bishop, knight ou pawn.
  final String piece;

  /// A casa de chegada, como `c6`.
  final String to;
  final bool capture;

  /// queen, rook, bishop ou knight; nulo sem promoção.
  final String? promotion;

  static const _names = {
    'k': 'king',
    'q': 'queen',
    'r': 'rook',
    'b': 'bishop',
    'n': 'knight',
    'p': 'pawn',
  };

  /// O lance [uci] na posição [fenBefore]; nulo se a FEN ou o lance não
  /// servem.
  static MoveWords? of(String fenBefore, String uci) {
    if (uci.length < 4) return null;
    final rows = fenBefore.split(' ').first.split('/');
    if (rows.length != 8) return null;
    String? at(String square) {
      final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final rank = int.tryParse(square[1]);
      if (file < 0 || file > 7 || rank == null || rank < 1 || rank > 8) {
        return null;
      }
      var column = 0;
      for (final char in rows[8 - rank].split('')) {
        final empty = int.tryParse(char);
        if (empty != null) {
          column += empty;
        } else {
          if (column == file) return char;
          column++;
        }
      }
      return '';
    }

    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final moved = at(from);
    final target = at(to);
    if (moved == null || moved.isEmpty || target == null) return null;
    final piece = _names[moved.toLowerCase()];
    if (piece == null) return null;
    // Peão que muda de coluna captura, mesmo na casa vazia (en passant).
    final capture = target.isNotEmpty || (piece == 'pawn' && from[0] != to[0]);
    final promotion = uci.length > 4 ? _names[uci[4].toLowerCase()] : null;
    return MoveWords(
      piece: piece,
      to: to,
      capture: capture,
      promotion: promotion,
    );
  }
}
