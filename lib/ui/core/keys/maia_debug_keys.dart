import 'package:flutter/widgets.dart';

abstract final class MaiaDebugKeys {
  static const screen = Key('maiaDebug.screen');
  static const fen = Key('maiaDebug.fen');
  static const evaluate = Key('maiaDebug.evaluate');

  /// Mede a velocidade do modelo no aparelho, e o resultado da medição.
  static const measure = Key('maiaDebug.measure');
  static const timing = Key('maiaDebug.timing');
  static const invalid = Key('maiaDebug.invalid');
  static const failed = Key('maiaDebug.failed');

  /// O nível avaliado (`maiaDebug.level.1400`).
  static Key level(int level) => Key('maiaDebug.level.$level');

  /// O resultado: tempo da conta, previsão de resultado e os lances, do mais
  /// provável (0) para o menos.
  static const result = Key('maiaDebug.result');
  static const elapsed = Key('maiaDebug.elapsed');
  static const outcome = Key('maiaDebug.outcome');
  static Key move(int index) => Key('maiaDebug.move.$index');
  static Key probability(int index) => Key('maiaDebug.probability.$index');
}
