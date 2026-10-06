/// A partida e a posição para fora do app: PGN e os endereços da análise no
/// Lichess e no chess.com, já na posição.
abstract final class GameExport {
  /// O PGN da partida que começa em [startFen] com os lances [sans]
  /// (notação algébrica) e terminou em [result] (`1-0`, `0-1`, `1/2-1/2`,
  /// `*`).
  static String pgn({
    required String startFen,
    required List<String> sans,
    String result = '*',
    String white = '?',
    String black = '?',
    DateTime? date,
  }) {
    final parts = startFen.split(' ');
    final blackStarts = parts.length > 1 && parts[1] == 'b';
    var number = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    final day = date == null
        ? '????.??.??'
        : '${date.year}.${_two(date.month)}.${_two(date.day)}';
    final moves = StringBuffer();
    for (final (index, san) in sans.indexed) {
      final whiteMove = (index.isEven) != blackStarts;
      if (whiteMove) {
        moves.write('$number. ');
      } else if (index == 0) {
        moves.write('$number... ');
      }
      moves.write('$san ');
      if (!whiteMove) number++;
    }
    moves.write(result);
    return [
      '[Event "Lucena"]',
      '[Site "Lucena"]',
      '[Date "$day"]',
      '[White "$white"]',
      '[Black "$black"]',
      '[Result "$result"]',
      '[SetUp "1"]',
      '[FEN "$startFen"]',
      '',
      moves.toString(),
    ].join('\n');
  }

  /// A posição [fen] no tabuleiro de análise do Lichess.
  static Uri lichess(String fen) => Uri.parse(
    'https://lichess.org/analysis/standard/${fen.replaceAll(' ', '_')}',
  );

  /// A posição [fen] na análise do chess.com.
  static Uri chessCom(String fen) =>
      Uri.https('www.chess.com', '/analysis', {'fen': fen});

  static String _two(int value) => value.toString().padLeft(2, '0');
}
