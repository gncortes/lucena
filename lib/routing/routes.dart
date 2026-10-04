abstract final class Routes {
  static const home = '/';
  static const freeBoard = '/board';

  /// Tabuleiro livre aberto numa posição preparada (FEN).
  static String freeBoardAt(String fen) =>
      Uri(path: freeBoard, queryParameters: {'fen': fen}).toString();

  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsTheme = '/settings/theme';
  static const settingsProfile = '/settings/profile';
  static const settingsBoardAppearance = '/settings/board-appearance';
}
