import 'package:flutter/widgets.dart';

/// Keys da aba Seu jogo do Treinador de partidas e das telas que saem dela
/// (tema, estilo, teoria, partidas-modelo, abertura no Pilares, destaque nas
/// metas).
abstract final class YourGameKeys {
  // Aba.
  static const screen = ValueKey('seuJogo.screen');
  static const tab = ValueKey('seuJogo.aba');
  static const loading = ValueKey('seuJogo.carregando');
  static const error = ValueKey('seuJogo.erro');
  static const empty = ValueKey('seuJogo.vazio');
  static const base = ValueKey('seuJogo.base');
  static ValueKey<String> timeControl(String timeControl) =>
      ValueKey('seuJogo.ritmo.$timeControl');
  static const numbers = ValueKey('seuJogo.numeros');
  static const accuracy = ValueKey('seuJogo.numeros.precisao');
  static const scoreRate = ValueKey('seuJogo.numeros.aproveitamento');
  static const phaseErrors = ValueKey('seuJogo.numeros.errosFase');
  static const few = ValueKey('seuJogo.poucas');
  static const fewNotice = ValueKey('seuJogo.poucas.aviso');
  static const focus = ValueKey('seuJogo.foco');
  static const focusSee = ValueKey('seuJogo.foco.ver');
  static const focusCourse = ValueKey('seuJogo.foco.curso');
  static const phases = ValueKey('seuJogo.fases');
  static ValueKey<String> phase(String phase) =>
      ValueKey('seuJogo.fase.$phase');
  static const weeks = ValueKey('seuJogo.semanas');
  static const style = ValueKey('seuJogo.estilo');
  static const styleText = ValueKey('seuJogo.estilo.texto');
  static const motifs = ValueKey('seuJogo.temas');
  static ValueKey<String> motif(String motif) =>
      ValueKey('seuJogo.tema.$motif');
  static const timeControls = ValueKey('seuJogo.ritmos');
  static const colors = ValueKey('seuJogo.cores');
  static const openings = ValueKey('seuJogo.aberturas');
  static ValueKey<String> opening(int i) => ValueKey('seuJogo.abertura.$i');
  static ValueKey<String> openingExit(int i) =>
      ValueKey('seuJogo.abertura.$i.saida');
  static const modelGamesLink = ValueKey('seuJogo.modelosLink');

  // Tema.
  static const motifScreen = ValueKey('seuJogo.temaScreen');
  static ValueKey<String> motifPosition(int i) =>
      ValueKey('seuJogo.temaScreen.posicao.$i');

  // Estilo.
  static const styleScreen = ValueKey('seuJogo.estiloScreen');
  static const styleConfidence = ValueKey('seuJogo.estiloScreen.confianca');
  static ValueKey<String> styleStrong(int i) =>
      ValueKey('seuJogo.estiloScreen.forte.$i');
  static ValueKey<String> styleSolve(int i) =>
      ValueKey('seuJogo.estiloScreen.acertar.$i');
  static ValueKey<String> styleSeePositions(int i) =>
      ValueKey('seuJogo.estiloScreen.acertar.$i.ver');

  // Teoria.
  static const theoryScreen = ValueKey('seuJogo.teoriaScreen');
  static const theoryComment = ValueKey('seuJogo.teoriaScreen.comentario');
  static const theoryBoard = ValueKey('seuJogo.teoriaScreen.tabuleiro');
  static const theoryLine = ValueKey('seuJogo.teoriaScreen.linha');
  static ValueKey<String> theoryCandidate(String san) =>
      ValueKey('seuJogo.teoriaScreen.candidato.$san');
  static const theoryModelGames = ValueKey('seuJogo.teoriaScreen.modelos');
  static const theoryMoves = ValueKey('seuJogo.teoriaScreen.lances');
  static const theoryPlayed = ValueKey('seuJogo.teoriaScreen.jogou');
  static const theoryStart = ValueKey('seuJogo.teoriaScreen.inicio');
  static const theoryPrevious = ValueKey('seuJogo.teoriaScreen.anterior');
  static const theoryNext = ValueKey('seuJogo.teoriaScreen.proximo');
  static const theoryEnd = ValueKey('seuJogo.teoriaScreen.fim');

  // Partidas-modelo.
  static const modelGamesScreen = ValueKey('seuJogo.modelosScreen');
  static const modelGamesNoticeKey = ValueKey('seuJogo.modelosScreen.aviso');
  static const modelGamesEmpty = ValueKey('seuJogo.modelosScreen.vazio');
  static ValueKey<String> modelGame(int i) =>
      ValueKey('seuJogo.modelosScreen.modelo.$i');
  static ValueKey<String> modelGameOpen(int i) =>
      ValueKey('seuJogo.modelosScreen.modelo.$i.abrir');

  // Abertura no Pilares (sem o curso).
  static const pilaresScreen = ValueKey('seuJogo.pilaresScreen');
  static ValueKey<String> pilaresPart(String id) =>
      ValueKey('seuJogo.pilaresScreen.parte.$id');
  static const pilaresHighlight = ValueKey('seuJogo.pilaresScreen.destaque');
  static const pilaresOffer = ValueKey('seuJogo.pilaresScreen.oferta');
  static const pilaresDiscover = ValueKey('seuJogo.pilaresScreen.conhecer');

  // Destaque nas metas de hoje (com o curso).
  static const goalsHighlight = ValueKey('seuJogo.metasDestaque');
  static const goalsHighlightPart = ValueKey('seuJogo.metasDestaque.parte');
  static const goalsHighlightNotice = ValueKey('seuJogo.metasDestaque.aviso');
}
