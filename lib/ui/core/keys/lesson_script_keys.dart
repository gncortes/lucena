import 'package:flutter/widgets.dart';

/// A tela da lição roteirizada (T70).
abstract final class LessonScriptKeys {
  static const screen = Key('lessonScript.screen');
  static const board = Key('lessonScript.board');
  static const speech = Key('lessonScript.speech');
  static const characterBar = Key('lessonScript.characterBar');
  static const soundButton = Key('lessonScript.soundButton');
  static const bookButton = Key('lessonScript.bookButton');
  static const moveList = Key('lessonScript.moveList');
  static const back = Key('lessonScript.back');

  /// Continuar, Próxima etapa, Voltar ao início.
  static const primary = Key('lessonScript.primary');
  static const showAnswer = Key('lessonScript.showAnswer');
  static const reviewIdea = Key('lessonScript.reviewIdea');
  static const nextPart = Key('lessonScript.nextPart');

  /// Um lance da lista (o id do nó da árvore de lances).
  static Key move(String nodeId) => Key('lessonScript.move.$nodeId');
}
