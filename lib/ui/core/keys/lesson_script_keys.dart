import 'package:flutter/widgets.dart';

/// A tela da lição roteirizada (T70).
abstract final class LessonScriptKeys {
  static const screen = Key('lessonScript.screen');
  static const board = Key('lessonScript.board');

  /// O tabuleiro de antes, enquanto se dissolve no novo (crossfade).
  static const crossfade = Key('lessonScript.crossfade');

  /// As coordenadas desenhadas por cima das marcações do tabuleiro.
  static const coordinates = Key('lessonScript.coordinates');
  static const speech = Key('lessonScript.speech');
  static const characterBar = Key('lessonScript.characterBar');
  static const soundButton = Key('lessonScript.soundButton');

  /// Ao lado do som: mostrar ou esconder as setas e os círculos.
  static const marksToggle = Key('lessonScript.marksToggle');
  static const bookButton = Key('lessonScript.bookButton');
  static const moveList = Key('lessonScript.moveList');
  static const page = Key('lessonScript.page');

  /// A fala inteira do Viktor (o clique no balão) e o ✕ dela.
  static const speechSheet = Key('lessonScript.speechSheet');
  static const speechSheetClose = Key('lessonScript.speechSheetClose');

  /// O rodapé da demonstração (etapa 2): repetir, lance anterior, tocar ou
  /// pausar, e o anel do botão principal.
  static const demoRepeat = Key('lessonScript.demoRepeat');
  static const demoStepBack = Key('lessonScript.demoStepBack');
  static const demoToggle = Key('lessonScript.demoToggle');
  static const demoRing = Key('lessonScript.demoRing');
  static const back = Key('lessonScript.back');

  /// Continuar, Próxima etapa, Voltar ao início.
  static const primary = Key('lessonScript.primary');
  static const showAnswer = Key('lessonScript.showAnswer');
  static const reviewIdea = Key('lessonScript.reviewIdea');
  static const mainLine = Key('lessonScript.mainLine');
  static const typing = Key('lessonScript.typing');
  static const nextPart = Key('lessonScript.nextPart');

  /// Um lance da lista (o id do nó da árvore de lances).
  static Key move(String nodeId) => Key('lessonScript.move.$nodeId');

  /// O resultado depois do lance que acabou a partida.
  static Key moveResult(String nodeId) =>
      Key('lessonScript.moveResult.$nodeId');
}
