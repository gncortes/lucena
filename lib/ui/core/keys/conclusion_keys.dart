import 'package:flutter/widgets.dart';

import '../../../domain/models/conclusion.dart';

/// As chaves da tela de conclusão (T51, frente B).
abstract final class ConclusionKeys {
  static const screen = Key('conclusion.screen');
  static const title = Key('conclusion.title');

  /// No speedrun: qual foi e o ritmo.
  static const mode = Key('conclusion.mode');
  static const reason = Key('conclusion.reason');
  static const goal = Key('conclusion.goal');
  static const player = Key('conclusion.player');
  static const opponent = Key('conclusion.opponent');
  static const rating = Key('conclusion.rating');
  static const ratingValue = Key('conclusion.rating.value');
  static const ratingDelta = Key('conclusion.rating.delta');
  static const comment = Key('conclusion.comment');
  static const run = Key('conclusion.run');
  static const stageTime = Key('conclusion.run.stageTime');
  static const total = Key('conclusion.run.total');
  static const runDetails = Key('conclusion.run.details');

  /// A etapa [index] (0 é a primeira) no fim do speedrun.
  static Key stage(int index) => Key('conclusion.run.stage.$index');
  static const newRecord = Key('conclusion.run.newRecord');
  static const blindMoves = Key('conclusion.blindMoves');
  static const close = Key('conclusion.close');
  static const share = Key('conclusion.share');
  static const card = Key('conclusion.card');
  static const review = Key('conclusion.review');
  static const accuracy = Key('conclusion.review.accuracy');
  static const reviewBoard = Key('conclusion.quickReview.board');
  static const quickReview = Key('conclusion.quickReview');
  static const bestLine = Key('conclusion.bestLine');
  static const bestLineToggle = Key('conclusion.bestLine.toggle');
  static const bestLineBoard = Key('conclusion.bestLine.board');
  static const bestLineBack = Key('conclusion.bestLine.back');
  static const bestLineForward = Key('conclusion.bestLine.forward');
  static const bestLineMove = Key('conclusion.bestLine.move');

  /// Quantos lances da qualidade [name] (`best`, `mistake`...).
  static Key quality(String name) => Key('conclusion.review.$name');

  /// O botão da ação [action].
  static Key action(ConclusionAction action) =>
      Key('conclusion.action.${action.name}');
}
