import '../domain/models/challenge_link.dart';
import '../domain/models/featured.dart';
import '../domain/models/clock.dart';
import '../domain/models/daily_final.dart';
import '../domain/models/game_setup.dart';
import '../domain/models/journey.dart';
import '../domain/models/survey.dart';

abstract final class Routes {
  static const home = '/';
  static const freeBoard = '/board';

  /// "Atualize o Lucena": por cima de tudo, sem voltar (E1.32).
  static const updateRequired = '/update/required';

  /// "Versão nova do Lucena", aberta só sobre a home (E1.32).
  static const updateRecommended = '/update/recommended';

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
    bool fromLink = false,
    ChallengeLink? origin,
  }) => Uri(
    path: blind,
    queryParameters: {
      'new': 'true',
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
      if (fromLink) 'link': origin == null ? '1' : origin.uri.toString(),
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
    bool fromLink = false,
    ChallengeLink? origin,
    String? featured,
    String? daily,
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
      if (fromLink) 'link': origin == null ? '1' : origin.uri.toString(),
      'featured': ?featured,
      'daily': ?daily,
    },
  ).toString();

  /// O link de desafio [link] aberto no app (`/p/<código>?...`): a tela do
  /// desafio fechado ou a Nova partida preenchida.
  static String challenge(ChallengeLink link) =>
      '${link.uri.path}?${link.uri.query}';

  /// A partida do desafio [link], com o Maia no [level] quando o link não
  /// traz o nível. Sempre no tabuleiro normal: link com `blind=1` (o app não
  /// gera mais) abre a partida normal e o resultado leva o mesmo link de origem. O relógio do link vale para os dois lados.
  static String linkGame(ChallengeLink link, {required int level}) {
    final user = link.userSide.name;
    final clock = link.clock?.code;
    final maia = link.opponent == OpponentKind.maia;
    final opponent = link.opponent.code;
    final shownLevel = maia ? '${link.level ?? level}' : null;
    return freeBoardAt(
      link.fen,
      view: user,
      white: clock,
      black: clock,
      opponent: opponent,
      level: shownLevel,
      user: user,
      goal: link.goal.code,
      position: link.positionId,
      fromLink: true,
      origin: link,
    );
  }

  /// A tela de antes do primeiro desafio (cores, peças e som).
  static String challengeSetup(ChallengeLink link) =>
      '${link.uri.path}/inicio?${link.uri.query}';

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

  /// Os finais em destaque: a lista, um torneio e um final.
  static const featured = '/featured';
  static String featuredTournament(String id) => '/featured/tournament/$id';
  static String featuredEndgame(String id) => '/featured/$id';

  /// A partida de um final em destaque: o jogador joga o lado que tem a vez na
  /// posição, contra o adversário e com o relógio de [choice]. Sem posição no
  /// catálogo: não vale nota nem entra no histórico.
  static String featuredGame(FeaturedEndgame endgame, FeaturedChoice choice) {
    final user = endgame.userSide.name;
    final clock = choice.clock;
    return freeBoardAt(
      endgame.fen,
      view: user,
      white: clock,
      black: clock,
      opponent: choice.opponent.code,
      level: choice.level?.toString(),
      user: user,
      goal: endgame.goal.code,
      featured: endgame.id,
    );
  }

  /// O final do dia: abre a partida de hoje (o toque do lembrete cai aqui).
  static const daily = '/daily';
  static const dailyResult = '/daily/result';
  static const dailyShare = '/daily/share';

  /// O resultado do final do dia [date] (`aaaa-mm-dd`).
  static String dailyResultOf(String date) =>
      Uri(path: dailyResult, queryParameters: {'date': date}).toString();
  static String dailyShareOf(String date) =>
      Uri(path: dailyShare, queryParameters: {'date': date}).toString();

  /// A partida do final do dia: sem relógio, contra o Maia no nível
  /// [level], com o lado e o objetivo do próprio final.
  static String dailyGame(DailyFinal daily, {required int level}) {
    final position = daily.position;
    final user = position.fen.split(' ')[1] == 'b' ? 'black' : 'white';
    return freeBoardAt(
      position.fen,
      view: user,
      opponent: OpponentKind.maia.code,
      level: '$level',
      user: user,
      goal: position.goal.code,
      daily: DailyRecord.dayCode(daily.date),
    );
  }

  /// A Jornada, um degrau e um desafio (pelo id da posição dentro do degrau).
  static const journey = '/journey';
  static String journeyRung(String rung) => '/journey/$rung';
  static String journeyChallenge(String rung, String position) =>
      '/journey/$rung/$position';

  /// A Corrida de problemas (E1.31) e o aquecimento que a antecede.
  static const race = '/race';
  static const raceWarmUp = '/race/warm-up';

  /// Os speedruns, um speedrun e uma tentativa dele.
  static const speedruns = '/speedruns';
  static String speedrun(String id) => '/speedruns/$id';

  /// O histórico de um speedrun: o [id] já com o ritmo
  /// (`SpeedrunPaces.idFor`).
  static String speedrunHistory(String id) => '/speedruns/$id/history';

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
  /// A conclusão de uma partida gravada (T51, frente B); sem id, a de uma
  /// partida que não se grava, com a conclusão no `extra`.
  /// [fresh]: a partida acabou agora (os avisos de conquista aparecem); sem
  /// ele (o app reaberto na conclusão), não.
  static String conclusion(int gameId, {bool fresh = false}) => Uri(
    path: '/result/$gameId',
    queryParameters: fresh ? {'fresh': '1'} : null,
  ).toString();
  static const conclusionNow = '/result';

  static const rating = '/rating';

  /// O rating com a partida [game] em destaque no gráfico e no histórico
  /// (a conclusão, T51 B).
  static String ratingAt({int? game}) => Uri(
    path: rating,
    queryParameters: {'game': ?game?.toString()},
  ).toString();

  /// Os detalhes de uma partida gravada, pelo id dela.
  static String game(int id) => '/rating/game/$id';

  /// A Escola do Viktor (as aulas do iniciante) e uma aula dela.
  static const school = '/school';

  /// A aula da escola com roteiro (curso de iniciante, T71), na etapa
  /// [stage].
  static String lessonScript(String id, {int stage = 0}) => Uri(
    path: '/school/$id/roteiro',
    queryParameters: {'etapa': '$stage'},
  ).toString();
  static const starChallenges = '/school/challenges';
  static String starChallenge(String piece, String level) =>
      '/school/challenges/$piece/$level';

  /// As aulas de finais: a trilha, uma aula, a lição dela, as informações e
  /// um exercício.
  static const endgames = '/endgames';

  /// As aulas de finais já num filtro: "Para você" ([forYou]) ou "Todos".
  static String endgamesFiltered({required bool forYou}) =>
      '/endgames?filter=${forYou ? 'forYou' : 'all'}';
  static String endgameLesson(String id) => '/endgames/$id';

  /// A lição roteirizada (T70) da parte [part] de uma aula, na etapa [stage].
  /// Sem parte, ou com uma que não abre mais, a rota cai no início da
  /// primeira parte (`resolveScriptPart`).
  static String endgameLessonScript(String id, {String? part, int stage = 0}) =>
      Uri(
        path: '/endgames/$id/roteiro',
        queryParameters: {'part': ?part, 'etapa': '$stage'},
      ).toString();
  static String endgameInfo(String id) => '/endgames/$id/info';
  static String endgameExercise(String id, String exercise) =>
      '/endgames/$id/ex/$exercise';

  /// A introdução aos exercícios da aula, antes do primeiro (ou do próximo).
  static String endgameExercisesIntro(String id) => '/endgames/$id/intro';

  /// O resultado dos exercícios da aula, depois do último.
  static String endgameExercisesDone(String id) => '/endgames/$id/done';

  /// O questionário "Sua opinião" de [kind] (`endgames` ou `school`).
  /// [fromLesson]: aberto pela aula concluída; o agradecimento então volta
  /// às aulas, não à tela anterior.
  static String survey(SurveyKind kind, {bool fromLesson = false}) => Uri(
    path: '/survey/${kind.code}',
    queryParameters: fromLesson ? {'from': 'lesson'} : null,
  ).toString();

  /// A tela "Aula concluída" da aula [id]: de [kind] `school` (Escola) ou
  /// `endgames` (aula de finais, com os capítulos todos feitos).
  /// [next] é a aula seguinte, se houver.
  static String lessonFinished(SurveyKind kind, String id, {String? next}) =>
      Uri(
        path: '/lesson-finished/${kind.code}/$id',
        queryParameters: next == null ? null : {'next': next},
      ).toString();

  /// O tour da primeira abertura (também aberto por Configurações).
  static const tour = '/tour';

  /// Depois do tour: a conta, opcional (E1.11 a E1.13 ligam o login), e o
  /// nível, que fecha a primeira abertura.
  /// A Sequência de dias (E1.22).
  static const streak = '/streak';

  /// Sua semana (E1.23), aberta pelo resumo de domingo.
  static const week = '/week';

  static const account = '/tour/conta';
  static const level = '/tour/nivel';

  /// "Seu nível" aberto por [from] (`profile`: volta para o Perfil).
  static String levelFrom(String from) =>
      Uri(path: level, queryParameters: {'from': from}).toString();

  /// As telas ligadas a "Seu nível" (E1.12). Recebem o `LevelCubit` dela
  /// como `extra`.
  static const levelLichess = '/tour/nivel/lichess';
  static const levelChess = '/tour/nivel/chess';
  static const levelRating = '/tour/nivel/rating';

  /// A conta pelo Perfil ou pelo "Já tenho conta" (E1.13). [from] diz para
  /// onde ir no fim: `tour` (a pergunta) ou `profile` (o Perfil).
  static const accountEnter = '/conta';
  static String accountEnterFrom(String from) => _from(accountEnter, from);

  /// "Criar conta" com e-mail ou, com [signIn], "Entrar". Com [reauth], só
  /// entra de novo e volta `true` (apagar a conta pede um login recente).
  static const accountEmail = '/conta/email';
  static String accountEmailFrom(
    String from, {
    bool signIn = false,
    bool reauth = false,
  }) => Uri(
    path: accountEmail,
    queryParameters: {
      'from': from,
      if (signIn || reauth) 'entrar': '1',
      if (reauth) 'reauth': '1',
    },
  ).toString();

  /// "Seu perfil", depois de entrar (e pelo lápis do Perfil). Com [welcome],
  /// o aviso de que o progresso já está na conta.
  static const accountData = '/conta/dados';
  static String accountDataFrom(String from, {bool welcome = false}) => Uri(
    path: accountData,
    queryParameters: {'from': from, if (welcome) 'novo': '1'},
  ).toString();

  /// "Bem-vindo de volta": recebe o `SyncResult` como `extra`.
  static const accountRestored = '/conta/de-volta';
  static String accountRestoredFrom(String from) =>
      _from(accountRestored, from);

  /// Para onde a conta segue no fim, vinda de [from] (`game`: o convite no
  /// fim da 1ª partida).
  static String afterAccount(String? from) => switch (from) {
    'profile' => settingsProfile,
    'game' => home,
    _ => goal,
  };

  static String _from(String path, String from) =>
      Uri(path: path, queryParameters: {'from': from}).toString();

  /// "O que você quer fazer?", entre o tour e "Seu nível" (E1.11).
  static const goal = '/tour/objetivo';

  /// O teste de nível (T52). [from] diz de onde veio (`level`, `settings`).
  static const placement = '/placement';
  static String placementFrom(String from) =>
      Uri(path: placement, queryParameters: {'from': from}).toString();

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
  static const settingsAppearance = '/settings/appearance';
  static const settingsGame = '/settings/game';
  static const settingsSound = '/settings/sound';
  static const settingsAbout = '/settings/about';
  static const alerts = '/settings/alerts';

  /// "Seu país" (E1.21): do Perfil, de Avisos e de "Seu perfil".
  static const country = '/country';
  static const settingsLanguage = '/settings/appearance/language';
  static const settingsTheme = '/settings/appearance/theme';
  static const settingsProfile = '/settings/profile';

  /// Privacidade e anúncios (E1.25), aberta do Perfil.
  static const privacy = '/settings/privacy';

  /// Enviar feedback (E1.26), aberta do Perfil.
  static const feedback = '/settings/feedback';
  static const settingsBoardAppearance = '/settings/appearance/board';
  static const settingsBoardBehavior = '/settings/game/board';
  static const settingsClock = '/settings/game/clock';
  static const settingsVoice = '/settings/sound/voice';

  /// A configuração da tela inicial: os caminhos e a ordem.
  static const homeLayout = '/settings/appearance/home';

  /// Tela de depuração do Maia (só em build de desenvolvimento e de teste).
  static const settingsMaia = '/settings/maia';
}
