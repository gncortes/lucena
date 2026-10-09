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

  /// O brilho em volta do retrato de quem venceu (nunca no empate).
  static const winnerGlow = Key('conclusion.winnerGlow');
  static const rating = Key('conclusion.rating');
  static const ratingValue = Key('conclusion.rating.value');
  static const ratingDelta = Key('conclusion.rating.delta');
  static const comment = Key('conclusion.comment');

  /// O ✕ que esconde a fala do adversário (e cala a voz).
  static const commentClose = Key('conclusion.comment.close');
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

  /// O cartão da análise rápida como entra na imagem de compartilhar.
  static const analysisShared = Key('conclusion.review.shared');

  /// No resumo pronto da análise rápida: a revisão completa da partida.
  static const reviewDeeper = Key('conclusion.review.deeper');
  static const accuracy = Key('conclusion.review.accuracy');
  static const reviewBoard = Key('conclusion.quickReview.board');
  static const quickReview = Key('conclusion.quickReview');

  static const bestLine = Key('conclusion.bestLine');
  static const bestLineToggle = Key('conclusion.bestLine.toggle');
  static const bestLineBoard = Key('conclusion.bestLine.board');
  static const bestLineBack = Key('conclusion.bestLine.back');
  static const bestLineForward = Key('conclusion.bestLine.forward');
  static const bestLineMove = Key('conclusion.bestLine.move');

  /// A barra enquanto a melhor linha é jogada.
  static const bestLineRunning = Key('conclusion.bestLine.running');

  /// O aviso de que o Stockfish jogou rápido (1 s por lance).
  static const bestLineDisclaimer = Key('conclusion.bestLine.disclaimer');

  /// "Ver a análise detalhada", embaixo da melhor linha.
  static const bestLineDeeper = Key('conclusion.bestLine.deeper');

  /// Quantos lances da qualidade [name] (`best`, `mistake`...).
  static Key quality(String name) => Key('conclusion.review.$name');

  /// O botão da ação [action].
  static Key action(ConclusionAction action) =>
      Key('conclusion.action.${action.name}');
}
