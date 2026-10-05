import 'package:flutter/widgets.dart';

/// Os detalhes de uma partida.
abstract final class GameDetailsKeys {
  static const screen = Key('gameDetails.screen');
  static const board = Key('gameDetails.board');
  static const opponent = Key('gameDetails.opponent');
  static const result = Key('gameDetails.result');
  static const notFound = Key('gameDetails.notFound');

  /// O lance [index] na tabela e o tempo dele.
  static Key move(int index) => Key('gameDetails.move.$index');
  static Key moveTime(int index) => Key('gameDetails.move.$index.time');
}
