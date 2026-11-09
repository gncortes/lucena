import 'package:flutter/widgets.dart';

/// Keys do Treinador de partidas (T87): abas, partidas, exercícios e análise.
abstract final class TreinadorKeys {
  // Casca das abas.
  static const screen = Key('treinador.screen');
  static const back = Key('treinador.back');
  static const tabHoje = Key('treinador.tab.hoje');
  static const tabPartidas = Key('treinador.tab.partidas');
  static const tabSeuJogo = Key('treinador.tab.seuJogo');
  static const hoje = Key('treinador.hoje');
  static const partidas = Key('treinador.partidas');
  static const seuJogo = Key('treinador.seuJogo');

  // Hoje.
  static const ultimaPartida = Key('treinador.hoje.ultima');
  static const verUltimaPartida = Key('treinador.hoje.verUltima');
  static const hojeVazio = Key('treinador.hoje.vazio');

  // Partidas.
  static Key filtroRitmo(String id) => Key('treinador.filtro.ritmo.$id');
  static Key filtroResultado(String id) =>
      Key('treinador.filtro.resultado.$id');
  static const partidasBase = Key('treinador.partidas.base');
  static const partidasVazio = Key('treinador.partidas.vazio');
  static const limparFiltros = Key('treinador.partidas.limparFiltros');
  static Key partida(String id) => Key('treinador.partida.$id');

  // Sem plano.
  static const semPlano = Key('treinador.semPlano');
  static const conhecerPlano = Key('treinador.semPlano.conhecer');

  // Ligar a conta.
  static const ligarConta = Key('treinador.conta');
  static const ligarLichess = Key('treinador.conta.lichess');
  static const ligarChesscom = Key('treinador.conta.chesscom');
  static const usuario = Key('treinador.conta.usuario');
  static const confirmarConta = Key('treinador.conta.confirmar');
  static const contaErro = Key('treinador.conta.erro');
  static const trocarSite = Key('treinador.conta.trocarSite');

  // Início da análise de uma partida.
  static const inicio = Key('treinador.inicio');
  static const cartaoPartida = Key('treinador.inicio.partida');
  static const comecar = Key('treinador.inicio.comecar');
  static const verPartidas = Key('treinador.inicio.verPartidas');
  static const semPartidas = Key('treinador.inicio.semPartidas');

  // Carregando.
  static const carregando = Key('treinador.carregando');
  static const carregandoFrase = Key('treinador.carregando.frase');
  static const carregandoPorcentagem = Key('treinador.carregando.porcentagem');
  static const curiosidade = Key('treinador.carregando.curiosidade');
  static const outraCuriosidade = Key('treinador.carregando.outra');
  static const meAvise = Key('treinador.carregando.meAvise');

  // Erros da análise.
  static const erro = Key('treinador.erro');
  static const erroTentar = Key('treinador.erro.tentar');
  static const erroVoltar = Key('treinador.erro.voltar');

  // Exercício.
  static const exercicio = Key('treinador.exercicio');
  static const exercicioPagina = Key('treinador.exercicio.pagina');
  static const exercicioTabuleiro = Key('treinador.exercicio.tabuleiro');
  static const exercicioEstrelas = Key('treinador.exercicio.estrelas');
  static const exercicioFala = Key('treinador.exercicio.fala');
  static const tentarDeNovo = Key('treinador.exercicio.tentar');
  static const verSolucao = Key('treinador.exercicio.solucao');
  static const proximo = Key('treinador.exercicio.proximo');

  // Fim.
  static const fim = Key('treinador.fim');
  static const fimNota = Key('treinador.fim.nota');
  static const fimAnalise = Key('treinador.fim.analise');
  static const fimSeuJogo = Key('treinador.fim.seuJogo');
  static const fimFechar = Key('treinador.fim.fechar');

  // Resumo da partida.
  static const resumo = Key('treinador.resumo');
  static const resumoPrecisao = Key('treinador.resumo.precisao');
  static const resumoExercicios = Key('treinador.resumo.exercicios');
  static const resumoFases = Key('treinador.resumo.fases');
  static Key posicaoChave(int n) => Key('treinador.resumo.posicao.$n');
  static const refazer = Key('treinador.resumo.refazer');
  static const resumoAnalise = Key('treinador.resumo.analise');

  // Análise completa.
  static const analise = Key('treinador.analise');
  static Key comentario(int lance) =>
      Key('treinador.analise.comentario.$lance');
  static Key acaoComentario(int lance) => Key('treinador.analise.acao.$lance');
}
