abstract final class Routes {
  static const home = '/';
  static const freeBoard = '/board';

  /// Tabuleiro livre aberto numa posição preparada (FEN). Com [side], o
  /// jogador só move as peças desse lado. Com [white] e [black] (tempo de
  /// cada lado, `segundos+incremento`), a partida abre com relógio.
  static String freeBoardAt(
    String fen, {
    String? side,
    String? white,
    String? black,
  }) => Uri(
    path: freeBoard,
    queryParameters: {
      'fen': fen,
      'side': ?side,
      'white': ?white,
      'black': ?black,
    },
  ).toString();

  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsTheme = '/settings/theme';
  static const settingsProfile = '/settings/profile';
  static const settingsBoardAppearance = '/settings/board-appearance';
  static const settingsBoardBehavior = '/settings/board-behavior';
  static const settingsClock = '/settings/clock';
}
