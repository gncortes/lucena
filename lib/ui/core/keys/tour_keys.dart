import 'package:flutter/widgets.dart';

import '../../../domain/models/board_settings.dart';
import '../../tour/view_models/tour_cubit.dart';

abstract final class TourKeys {
  static const screen = Key('tour.screen');
  static const skipButton = Key('tour.skip');
  static const nextButton = Key('tour.next');
  static const backButton = Key('tour.back');
  static const startButton = Key('tour.start');

  /// No primeiro passo, o vazio de 56 dp no lugar de "Voltar" (o "Pular" fica
  /// no mesmo lugar nos dois primeiros passos).
  static const backSlot = Key('tour.backSlot');

  /// A barra de progresso colada na base da barra do app.
  static const progress = Key('tour.progress');

  /// O retrato do Viktor com o nome e o som (o cabeçalho).
  static const viktor = Key('tour.viktor');

  /// O balão da fala; o clique abre a fala inteira.
  static const speech = Key('tour.speech');

  /// A tela do tour, que rola inteira.
  static const scroll = Key('tour.scroll');

  /// No passo da voz: o nome do jogador e a nota embaixo.
  static const nameField = Key('tour.name');
  static const voiceHint = Key('tour.voiceHint');

  /// O passo aberto.
  static Key step(TourStep step) => Key('tour.step.${step.name}');

  /// No passo do tabuleiro: a amostra, as cores e as peças.
  static const boardPreview = Key('tour.board.preview');
  static Key boardColors(BoardColors colors) =>
      Key('tour.board.colors.${colors.code}');
  static Key boardPieces(PieceStyle pieces) =>
      Key('tour.board.pieces.${pieces.code}');

  /// No passo das aulas: as três etapas.
  static const stages = Key('tour.stages');

  /// No passo da ajuda: a lâmpada e "Ver resposta".
  static const helpButtons = Key('tour.helpButtons');

  /// No passo das partidas: os cinco adversários e o chip do rating.
  static const opponents = Key('tour.opponents');
  static const ratingChip = Key('tour.ratingChip');

  /// Um dos três cartões do último passo.
  static Key levelOption(TourLevelChoice choice) =>
      Key('tour.levelOption.${choice.name}');
}
