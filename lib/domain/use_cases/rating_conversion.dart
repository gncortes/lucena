import '../models/level_source.dart';
import '../models/maia_level.dart';

/// Converte o rating de outro lugar para a escala do Lucena (a do Maia, que
/// imita os jogadores do Lichess).
///
/// Tabela aproximada, ponto de partida pelos exemplos do canvas (FIDE 1450 ->
/// 1650, Chess.com 1405 -> 1650, Lichess igual). Entre dois pontos, a conta é
/// uma reta. O nível se ajusta depois com as partidas.
abstract final class RatingConversion {
  static const min = 400;
  static const max = 3000;

  // (rating de lá, rating no Lucena), em ordem.
  static const _chesscom = [
    (400, 750),
    (1000, 1300),
    (1405, 1650),
    (2000, 2150),
    (3000, 3000),
  ];
  static const _fide = [
    (400, 750),
    (1000, 1300),
    (1450, 1650),
    (2000, 2100),
    (2500, 2500),
    (3000, 3000),
  ];

  /// Um número dentro do que a tela aceita.
  static bool isValid(int rating) => rating >= min && rating <= max;

  static int toLucena(RatingOrigin origin, int rating) {
    final value = rating.clamp(min, max);
    return switch (origin) {
      RatingOrigin.lichess || RatingOrigin.unknown => value,
      RatingOrigin.chesscom => _along(_chesscom, value),
      RatingOrigin.fide || RatingOrigin.cbx => _along(_fide, value),
    };
  }

  /// O adversário em que a Jornada começa: o nível do Maia igual ou abaixo do
  /// rating (1712 começa no 1600).
  static int startRung(int rating) => MaiaLevels.atOrBelow(rating);

  static int _along(List<(int, int)> table, int value) {
    for (var i = 1; i < table.length; i++) {
      final (x0, y0) = table[i - 1];
      final (x1, y1) = table[i];
      if (value <= x1) {
        return (y0 + (value - x0) * (y1 - y0) / (x1 - x0)).round();
      }
    }
    return table.last.$2;
  }
}
