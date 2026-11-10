import 'package:flutter/widgets.dart';

/// Keys do Treinador de partidas (T87): abas, partidas, exercícios e análise.
abstract final class CoachKeys {
  // Casca das abas.
  static const screen = Key('treinador.screen');
  static const back = Key('treinador.back');
  static const tabToday = Key('treinador.tab.hoje');
  static const tabGames = Key('treinador.tab.partidas');
  static const tabYourGame = Key('treinador.tab.seuJogo');
  static const today = Key('treinador.hoje');
  static const games = Key('treinador.partidas');
  static const yourGame = Key('treinador.seuJogo');

  // Hoje.
  static const lastGame = Key('treinador.hoje.ultima');
  static const seeLastGame = Key('treinador.hoje.verUltima');
  static const todayEmpty = Key('treinador.hoje.vazio');

  // Partidas.
  static const filters = Key('treinador.filtros');

  /// "Todas": limpa o ritmo e o resultado.
  static const filterAll = Key('treinador.filtro.todas');
  static Key timeControlFilter(String id) => Key('treinador.filtro.ritmo.$id');
  static Key resultFilter(String id) => Key('treinador.filtro.resultado.$id');
  static const gamesBase = Key('treinador.partidas.base');
  static const gamesEmpty = Key('treinador.partidas.vazio');
  static const clearFilters = Key('treinador.partidas.limparFiltros');
  static Key game(String id) => Key('treinador.partida.$id');

  /// A partida pronta com exercícios a fazer, na aba Hoje.
  static Key toDo(String id) => Key('treinador.paraFazer.$id');

  /// Um exercício pendente de uma partida, na aba Hoje.
  static Key toDoExercise(String id, int n) =>
      Key('treinador.paraFazer.$id.$n');

  /// A linha "3 derrotas de blitz, da mais recente" da aba Partidas.
  static const gamesCount = Key('treinador.partidas.contagem');

  // Sem plano.
  static const noPlan = Key('treinador.semPlano');
  static const discoverPlan = Key('treinador.semPlano.conhecer');

  // Ligar a conta.
  static const linkAccount = Key('treinador.conta');
  static const linkLichess = Key('treinador.conta.lichess');
  static const linkChesscom = Key('treinador.conta.chesscom');
  static const linkPrivacy = Key('treinador.conta.privacidade');
  static const username = Key('treinador.conta.usuario');
  static const confirmAccount = Key('treinador.conta.confirmar');
  static const accountError = Key('treinador.conta.erro');
  static const switchSite = Key('treinador.conta.trocarSite');
  static const lichessLoginText = Key('treinador.conta.lichessTexto');

  // Início da análise de uma partida.
  static const start = Key('treinador.inicio');
  static const gameCard = Key('treinador.inicio.partida');
  static const begin = Key('treinador.inicio.comecar');
  static const seeGames = Key('treinador.inicio.verPartidas');
  static const noGames = Key('treinador.inicio.semPartidas');

  // Carregando.
  static const loading = Key('treinador.carregando');
  static const loadingPhrase = Key('treinador.carregando.frase');
  static const loadingPercentage = Key('treinador.carregando.porcentagem');
  static const trivia = Key('treinador.carregando.curiosidade');
  static const anotherTrivia = Key('treinador.carregando.outra');
  static const notifyMe = Key('treinador.carregando.meAvise');
  static const loadingSubtitle = Key('treinador.carregando.subtitulo');
  static const loadingNote = Key('treinador.carregando.nota');
  static const loadingBar = Key('treinador.carregando.barra');
  static const loadingQueue = Key('treinador.carregando.fila');
  static const triviaDots = Key('treinador.carregando.pontos');
  static const howItWorks = Key('treinador.inicio.comoFunciona');
  static const summaryGameCard = Key('treinador.resumo.partida');
  static const summaryPositions = Key('treinador.resumo.posicoes');

  // Erros da análise.
  static const error = Key('treinador.erro');
  static const errorRetry = Key('treinador.erro.tentar');
  static const errorBack = Key('treinador.erro.voltar');

  // Exercício.
  static const exercise = Key('treinador.exercicio');
  static const exercisePage = Key('treinador.exercicio.pagina');
  static const exerciseBoard = Key('treinador.exercicio.tabuleiro');
  static const exerciseStars = Key('treinador.exercicio.estrelas');
  static const exerciseLine = Key('treinador.exercicio.fala');
  static const retry = Key('treinador.exercicio.tentar');
  static const seeSolution = Key('treinador.exercicio.solucao');
  static const hint = Key('treinador.exercicio.dica');
  static const next = Key('treinador.exercicio.proximo');

  // Fim.
  static const end = Key('treinador.fim');
  static const endNote = Key('treinador.fim.nota');
  static const analysisEnd = Key('treinador.fim.analise');
  static const endYourGame = Key('treinador.fim.seuJogo');
  static const endClose = Key('treinador.fim.fechar');
  static const endDots = Key('treinador.fim.bolinhas');
  static Key endDot(int n) => Key('treinador.fim.bolinha.$n');

  // Resumo da partida.
  static const summary = Key('treinador.resumo');
  static const summaryAccuracy = Key('treinador.resumo.precisao');
  static const summaryExercises = Key('treinador.resumo.exercicios');
  static const summaryPhases = Key('treinador.resumo.fases');
  static Key keyPosition(int n) => Key('treinador.resumo.posicao.$n');
  static const redo = Key('treinador.resumo.refazer');
  static const analysisSummary = Key('treinador.resumo.analise');

  // Análise completa.
  static const analysis = Key('treinador.analise');
  static Key comment(int chessMove) =>
      Key('treinador.analise.comentario.$chessMove');
  static Key commentAction(int chessMove) =>
      Key('treinador.analise.acao.$chessMove');
}
