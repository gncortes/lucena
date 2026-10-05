import 'package:flutter/widgets.dart';

import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/rating_level.dart';
import '../../tour/view_models/tour_cubit.dart';

abstract final class TourKeys {
  static const screen = Key('tour.screen');
  static const skipButton = Key('tour.skip');
  static const nextButton = Key('tour.next');
  static const backButton = Key('tour.back');
  static const startButton = Key('tour.start');
  static const startRung = Key('tour.startRung');
  static const progress = Key('tour.progress');
  static const stepCounter = Key('tour.stepCounter');
  static const viktor = Key('tour.viktor');
  static const speech = Key('tour.speech');

  /// O passo aberto.
  static Key step(TourStep step) => Key('tour.step.${step.name}');

  /// No passo do tema: claro, escuro ou o do aparelho, e a cor do app.
  static Key themeMode(AppThemeMode mode) =>
      Key('tour.theme.mode.${mode.code}');
  static Key accent(AppAccent accent) =>
      Key('tour.theme.accent.${accent.code}');
  static const accentValue = Key('tour.theme.accent.value');

  /// No passo do tabuleiro: a amostra, as cores e as peças.
  static const boardPreview = Key('tour.board.preview');
  static Key boardColors(BoardColors colors) =>
      Key('tour.board.colors.${colors.code}');
  static Key boardPieces(PieceStyle pieces) =>
      Key('tour.board.pieces.${pieces.code}');

  /// Uma faixa no passo do nível.
  static Key level(RatingLevel level) => Key('tour.level.${level.name}');
}
