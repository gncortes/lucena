import 'package:flutter/widgets.dart';

/// O final do dia (E1.22): a faixa da home, o fim da partida, o resultado e
/// a imagem para compartilhar.
abstract final class DailyKeys {
  static const homeStrip = Key('daily.homeStrip');
  static const streakPill = Key('daily.streakPill');
  static const badge = Key('daily.badge');
  static const playAgain = Key('daily.playAgain');
  static const openResult = Key('daily.openResult');
  static const resultScreen = Key('daily.resultScreen');
  static const resultTitle = Key('daily.resultTitle');
  static const squares = Key('daily.squares');

  /// O quadradinho do lance [index] (a partir de 0).
  static Key square(int index) => Key('daily.square.$index');

  static const streakCard = Key('daily.streakCard');
  static const crowdCard = Key('daily.crowdCard');
  static const share = Key('daily.share');
  static const shareScreen = Key('daily.shareScreen');
  static const shareImage = Key('daily.shareImage');
  static const shareButton = Key('daily.shareButton');
  static const continueButton = Key('daily.continueButton');
}
