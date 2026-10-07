import '../domain/models/clock.dart';
import '../domain/models/journey.dart';

abstract final class Routes {
  static const home = '/';
  static const freeBoard = '/board';

  /// A partida às cegas, falando os lances (experimental).
  static const blind = '/blind';

  /// A partida às cegas em [fen], com o jogador de [user] contra [opponent]
  /// (e o [level] do Maia); com [white] e [black] (`segundos+incremento`), o
  /// relógio.
  static String blindAt(
    String fen, {
    required String user,
    required String opponent,
    String? level,
    String? white,
    String? black,
    String? view,
    String? challenge,
    String? position,
    String? goal,
  }) => Uri(
    path: blind,
    queryParameters: {
      'fen': fen,
      'user': user,
      'opponent': opponent,
      'level': ?level,
      'white': ?white,
      'black': ?black,
      'view': ?view,
      'challenge': ?challenge,
      'position': ?position,
      'goal': ?goal,
    },
  ).toString();

  /// O desafio especial às cegas da Jornada.
  static String blindChallenge(Challenge challenge) {
    final fen = challenge.position.fen;
    final opponent = challenge.opponent;
    return blindAt(
      fen,
      user: fen.split(' ')[1] == 'b' ? 'black' : 'white',
      opponent: opponent.kind.code,
      level: opponent.level?.toString(),
      view: challenge.hideBoard ? 'hidden' : 'empty',
      challenge: challenge.id,
      position: challenge.position.id,
      goal: challenge.goal.code,
    );
  }

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
  /// posição, contra o adversário do desafio, com o relógio dele. Com
  /// [userTime], o relógio do jogador é outro (o banco da Maratona).
  static String challengeGame(
    Challenge challenge, {
    String? speedrunId,
    int? attemptId,
    int? stage,
    TimeControl? userTime,
  }) {
    final fen = challenge.position.fen;
    final user = fen.split(' ')[1] == 'b' ? 'black' : 'white';
    final time = challenge.time?.code;
    final mine = userTime?.code ?? time;
    final opponent = challenge.opponent;
    return freeBoardAt(
      fen,
      view: user,
      white: user == 'white' ? mine : time,
      black: user == 'black' ? mine : time,
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

  static const achievements = '/achievements';

  /// Todos os modos do app num lugar só.
  static const allModes = '/modes';

  /// Os detalhes do rating: o gráfico e o histórico das partidas.
  static const rating = '/rating';

  /// Os detalhes de uma partida gravada, pelo id dela.
  static String game(int id) => '/rating/game/$id';

  /// A Escola do Viktor (as aulas do iniciante) e uma aula dela.
  static const school = '/school';
  static String lesson(String id) => '/school/$id';
  static const starChallenges = '/school/challenges';
  static String starChallenge(String piece, String level) =>
      '/school/challenges/$piece/$level';

  /// As aulas de finais: a trilha, uma aula, a lição dela, as informações e
  /// um exercício.
  static const endgames = '/endgames';
  static String endgameLesson(String id) => '/endgames/$id';
  static String endgameLessonSteps(String id) => '/endgames/$id/lesson';
  static String endgameInfo(String id) => '/endgames/$id/info';
  static String endgameExercise(String id, String exercise) =>
      '/endgames/$id/ex/$exercise';

  /// O tour da primeira abertura (também aberto por Configurações).
  static const tour = '/tour';

  static const catalog = '/catalog';
  static String catalogCategory(String category) => '/catalog/$category';

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
  static const settingsVoice = '/settings/voice';

  /// A configuração da tela inicial: os caminhos e a ordem.
  static const homeLayout = '/settings/home';

  /// Tela de depuração do Maia (só em build de desenvolvimento e de teste).
  static const settingsMaia = '/settings/maia';
}
