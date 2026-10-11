import 'dart:math';
import 'dart:ui';

import 'centered_board_layout.dart';

/// A geometria do modo exercício da lição (T60), em contas puras: o
/// tabuleiro centralizado no espaço que sobra enquanto o aluno resolve, e no
/// alto, com a folha da fala embaixo, depois da resposta.
abstract final class ExerciseLayout {
  /// A margem de cada lado do tabuleiro.
  static const gutter = 8.0;

  /// O menor tabuleiro que ainda se joga.
  static const minBoard = 120.0;

  /// O espaço garantido para o enunciado acima do tabuleiro: o retrato
  /// pequeno do Viktor e uma linha do balão. Fala maior rola.
  static const promptReserve = 56.0;

  /// O maior tabuleiro que cabe em [area], descontados o cabeçalho (o
  /// enunciado) e o rodapé (o cronômetro e as ações), com a margem em volta.
  static double boardSize(Size area, {double header = 0, double footer = 0}) {
    final width = area.width - 2 * gutter;
    final height = area.height - header - footer - 2 * gutter;
    return max(min(width, height), minBoard);
  }

  /// A conta do tabuleiro centralizado enquanto o aluno resolve (T64): o
  /// centro em [centerY] (por padrão, o centro do espaço útil, entre o topo
  /// da área e o rodapé), com o espaço do enunciado [header] reservado em
  /// cima. O enunciado não empurra o tabuleiro: se for alto, o tabuleiro
  /// diminui (até um mínimo) e o enunciado rola no espaço que sobra.
  static BoardCentering centering(
    Size area, {
    double header = 0,
    double footer = 0,
    double? centerY,
  }) => BoardCentering(
    area,
    footer: footer,
    centerY: centerY,
    gap: gutter,
    gutter: gutter,
    reserveTop: header,
  );

  /// A maior altura que o enunciado pode ocupar acima do tabuleiro.
  static double headerRoom(Size area, {double footer = 0, double? centerY}) =>
      centering(area, footer: footer, centerY: centerY).maxRoomAbove;

  /// Onde o tabuleiro fica enquanto o aluno resolve: centralizado na
  /// horizontal e, na vertical, com o centro em [centerY] (ver [centering]).
  static Rect solvingRect(
    Size area, {
    double header = 0,
    double footer = 0,
    double? centerY,
  }) {
    final rect = centering(
      area,
      header: header,
      footer: footer,
      centerY: centerY,
    ).board;
    if (rect.width >= minBoard) return rect;
    return Rect.fromCenter(
      center: rect.center,
      width: minBoard,
      height: minBoard,
    );
  }

  /// O lado do tabuleiro depois da resposta, com [sheetRoom] para a folha.
  static double _explainingSize(Size area, double sheetRoom) =>
      max(min(area.width - 2 * gutter, area.height - sheetRoom), minBoard);

  /// Onde começa a folha da fala depois da resposta: logo abaixo do
  /// tabuleiro, no alto; com [lowered] (a escola), no mesmo lugar de antes,
  /// deixando [sheetRoom] para ela.
  static double sheetTop(
    Size area, {
    required double sheetRoom,
    bool lowered = false,
  }) {
    final size = _explainingSize(area, sheetRoom);
    final high = 2 * gutter + size;
    return lowered ? max(high, area.height - sheetRoom + gutter) : high;
  }

  /// Onde ele fica depois da resposta: centralizado no espaço entre o topo
  /// da área e a folha da fala ([sheetTop]), encolhendo se precisar para
  /// deixar [sheetRoom] para a folha.
  static Rect explainingRect(
    Size area, {
    required double sheetRoom,
    bool lowered = false,
  }) {
    final size = _explainingSize(area, sheetRoom);
    final sheet = sheetTop(area, sheetRoom: sheetRoom, lowered: lowered);
    final top = max(gutter, (sheet - size) / 2);
    return Rect.fromLTWH((area.width - size) / 2, top, size, size);
  }
}
