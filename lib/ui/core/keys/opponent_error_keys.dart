import 'package:flutter/widgets.dart';

/// Folha de erro do adversário (H-PAR-18), igual na Partida, no Final do dia
/// e em Às cegas.
abstract final class OpponentErrorKeys {
  static const sheet = Key('opponentError.sheet');
  static const retry = Key('opponentError.retry');
  static const leave = Key('opponentError.leave');
}
