import 'package:flutter/widgets.dart';

/// Keys da aba Seu jogo do Treinador de partidas e das telas que saem dela
/// (tema, estilo, teoria, partidas-modelo, abertura no Pilares, destaque nas
/// metas).
abstract final class SeuJogoKeys {
  // Aba.
  static const screen = ValueKey('seuJogo.screen');
  static const aba = ValueKey('seuJogo.aba');
  static const carregando = ValueKey('seuJogo.carregando');
  static const erro = ValueKey('seuJogo.erro');
  static const vazio = ValueKey('seuJogo.vazio');
  static const base = ValueKey('seuJogo.base');
  static ValueKey<String> ritmo(String ritmo) =>
      ValueKey('seuJogo.ritmo.$ritmo');
  static const numeros = ValueKey('seuJogo.numeros');
  static const precisao = ValueKey('seuJogo.numeros.precisao');
  static const aproveitamento = ValueKey('seuJogo.numeros.aproveitamento');
  static const errosFase = ValueKey('seuJogo.numeros.errosFase');
  static const poucas = ValueKey('seuJogo.poucas');
  static const poucasAviso = ValueKey('seuJogo.poucas.aviso');
  static const foco = ValueKey('seuJogo.foco');
  static const focoVer = ValueKey('seuJogo.foco.ver');
  static const focoCurso = ValueKey('seuJogo.foco.curso');
  static const fases = ValueKey('seuJogo.fases');
  static ValueKey<String> fase(String fase) => ValueKey('seuJogo.fase.$fase');
  static const semanas = ValueKey('seuJogo.semanas');
  static const estilo = ValueKey('seuJogo.estilo');
  static const estiloTexto = ValueKey('seuJogo.estilo.texto');
  static const temas = ValueKey('seuJogo.temas');
  static ValueKey<String> tema(String tema) => ValueKey('seuJogo.tema.$tema');
  static const ritmos = ValueKey('seuJogo.ritmos');
  static const cores = ValueKey('seuJogo.cores');
  static const aberturas = ValueKey('seuJogo.aberturas');
  static ValueKey<String> abertura(int i) => ValueKey('seuJogo.abertura.$i');
  static ValueKey<String> aberturaSaida(int i) =>
      ValueKey('seuJogo.abertura.$i.saida');
  static const modelosLink = ValueKey('seuJogo.modelosLink');

  // Tema.
  static const temaScreen = ValueKey('seuJogo.temaScreen');
  static ValueKey<String> temaPosicao(int i) =>
      ValueKey('seuJogo.temaScreen.posicao.$i');

  // Estilo.
  static const estiloScreen = ValueKey('seuJogo.estiloScreen');
  static const estiloConfianca = ValueKey('seuJogo.estiloScreen.confianca');
  static ValueKey<String> estiloForte(int i) =>
      ValueKey('seuJogo.estiloScreen.forte.$i');
  static ValueKey<String> estiloAcertar(int i) =>
      ValueKey('seuJogo.estiloScreen.acertar.$i');
  static ValueKey<String> estiloVerPosicoes(int i) =>
      ValueKey('seuJogo.estiloScreen.acertar.$i.ver');

  // Teoria.
  static const teoriaScreen = ValueKey('seuJogo.teoriaScreen');
  static const teoriaComentario = ValueKey('seuJogo.teoriaScreen.comentario');
  static const teoriaTabuleiro = ValueKey('seuJogo.teoriaScreen.tabuleiro');
  static const teoriaLinha = ValueKey('seuJogo.teoriaScreen.linha');
  static ValueKey<String> teoriaCandidato(String san) =>
      ValueKey('seuJogo.teoriaScreen.candidato.$san');
  static const teoriaModelos = ValueKey('seuJogo.teoriaScreen.modelos');
  static const teoriaLances = ValueKey('seuJogo.teoriaScreen.lances');
  static const teoriaJogou = ValueKey('seuJogo.teoriaScreen.jogou');
  static const teoriaInicio = ValueKey('seuJogo.teoriaScreen.inicio');
  static const teoriaAnterior = ValueKey('seuJogo.teoriaScreen.anterior');
  static const teoriaProximo = ValueKey('seuJogo.teoriaScreen.proximo');
  static const teoriaFim = ValueKey('seuJogo.teoriaScreen.fim');

  // Partidas-modelo.
  static const modelosScreen = ValueKey('seuJogo.modelosScreen');
  static const modelosAviso = ValueKey('seuJogo.modelosScreen.aviso');
  static const modelosVazio = ValueKey('seuJogo.modelosScreen.vazio');
  static ValueKey<String> modelo(int i) =>
      ValueKey('seuJogo.modelosScreen.modelo.$i');
  static ValueKey<String> modeloAbrir(int i) =>
      ValueKey('seuJogo.modelosScreen.modelo.$i.abrir');

  // Abertura no Pilares (sem o curso).
  static const pilaresScreen = ValueKey('seuJogo.pilaresScreen');
  static ValueKey<String> pilaresParte(String id) =>
      ValueKey('seuJogo.pilaresScreen.parte.$id');
  static const pilaresDestaque = ValueKey('seuJogo.pilaresScreen.destaque');
  static const pilaresOferta = ValueKey('seuJogo.pilaresScreen.oferta');
  static const pilaresConhecer = ValueKey('seuJogo.pilaresScreen.conhecer');

  // Destaque nas metas de hoje (com o curso).
  static const metasDestaque = ValueKey('seuJogo.metasDestaque');
  static const metasDestaqueParte = ValueKey('seuJogo.metasDestaque.parte');
  static const metasDestaqueAviso = ValueKey('seuJogo.metasDestaque.aviso');
}
