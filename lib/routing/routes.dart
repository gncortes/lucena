import '../domain/models/journey.dart';

abstract final class Routes {
  static const home = '/';
  static const freeBoard = '/board';

  /// Tabuleiro livre aberto numa posição preparada (FEN). Com [side], o
  /// jogador só move as peças desse lado; [view] é o lado que fica embaixo.
  /// Com [white] e [black] (tempo de cada lado, `segundos+incremento`), a
  /// partida abre com relógio.
  ///
  /// No treino, [opponent] (`maia`, `stockfish`, `twoPlayers`), [level] (o
  /// nível do Maia), [user] (o lado do jogador), [goal] e [position] (id no
  /// catálogo) dizem de que partida se trata.
  static String freeBoardAt(
    String fen, {
    String? side,
    String? view,
    String? white,
    String? black,
    String? opponent,
    String? level,
    String? user,
    String? goal,
    String? position,
    String? challenge,
    String? speedrun,
    String? attempt,
    String? stage,
  }) => Uri(
    path: freeBoard,
    queryParameters: {
      'fen': fen,
      'side': ?side,
      'view': ?view,
      'white': ?white,
      'black': ?black,
      'opponent': ?opponent,
      'level': ?level,
      'user': ?user,
      'goal': ?goal,
      'position': ?position,
      'challenge': ?challenge,
      'speedrun': ?speedrun,
      'attempt': ?attempt,
      'stage': ?stage,
    },
  ).toString();

  /// A partida de um desafio da Jornada (ou de uma etapa de speedrun, com
  /// [speedrunId], [attemptId] e [stage]): o jogador joga o lado que move na
  /// posição, contra o adversário do desafio, com o relógio dele.
  static String challengeGame(
    Challenge challenge, {
    String? speedrunId,
    int? attemptId,
    int? stage,
  }) {
    final fen = challenge.position.fen;
    final user = fen.split(' ')[1] == 'b' ? 'black' : 'white';
    final time = challenge.time?.code;
    final opponent = challenge.opponent;
    return freeBoardAt(
      fen,
      view: user,
      white: time,
      black: time,
      opponent: opponent.kind.code,
      level: opponent.level?.toString(),
      user: user,
      goal: challenge.goal.code,
      position: challenge.position.id,
      challenge: speedrunId == null ? challenge.id : null,
      speedrun: speedrunId,
      attempt: attemptId?.toString(),
      stage: stage?.toString(),
    );
  }

  /// A Jornada, um degrau e um desafio (pelo id da posição dentro do degrau).
  static const journey = '/journey';
  static String journeyRung(String rung) => '/journey/$rung';
  static String journeyChallenge(String rung, String position) =>
      '/journey/$rung/$position';

  /// Os speedruns, um speedrun e uma tentativa dele.
  static const speedruns = '/speedruns';
  static String speedrun(String id) => '/speedruns/$id';

  ///
  /// [game] (o instante em que uma etapa terminou) faz a tentativa ser lida de
  /// novo ao voltar do tabuleiro, mesmo que a tela dela já esteja aberta.
  static String speedrunAttempt(String id, int attempt, {int? game}) => Uri(
    path: '/speedruns/$id/$attempt',
    queryParameters: {'game': ?game?.toString()},
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

  /// Tela de depuração do Maia (só em build de desenvolvimento e de teste).
  static const settingsMaia = '/settings/maia';
}
