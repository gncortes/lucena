abstract final class Routes {
  static const home = '/';
  static const freeBoard = '/board';

  /// Tabuleiro livre aberto numa posição preparada (FEN). Com [side], o
  /// jogador só move as peças desse lado; [view] é o lado que fica embaixo.
  /// Com [white] e [black] (tempo de cada lado, `segundos+incremento`), a
  /// partida abre com relógio.
  ///
  /// No treino, [opponent] (`stockfish`, `twoPlayers`), [user] (o lado do
  /// jogador), [goal] e [position] (id no catálogo) dizem de que partida se
  /// trata.
  static String freeBoardAt(
    String fen, {
    String? side,
    String? view,
    String? white,
    String? black,
    String? opponent,
    String? user,
    String? goal,
    String? position,
  }) => Uri(
    path: freeBoard,
    queryParameters: {
      'fen': fen,
      'side': ?side,
      'view': ?view,
      'white': ?white,
      'black': ?black,
      'opponent': ?opponent,
      'user': ?user,
      'goal': ?goal,
      'position': ?position,
    },
  ).toString();

  static const catalog = '/catalog';
  static String catalogCategory(String category) => '/catalog/$category';
  static String catalogSubcategory(String category, String subcategory) =>
      '/catalog/$category/$subcategory';

  /// Configuração da partida numa posição, com o objetivo e, se ela vier do
  /// catálogo, o id dela (para o histórico).
  static String setup(String fen, {required String goal, String? position}) =>
      Uri(
        path: '/setup',
        queryParameters: {'fen': fen, 'goal': goal, 'position': ?position},
      ).toString();

  static const customPosition = '/custom';

  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsTheme = '/settings/theme';
  static const settingsProfile = '/settings/profile';
  static const settingsBoardAppearance = '/settings/board-appearance';
  static const settingsBoardBehavior = '/settings/board-behavior';
  static const settingsClock = '/settings/clock';
}
