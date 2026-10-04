import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';

void main() {
  test('cada cor e cada conjunto de peças voltam do código gravado', () {
    for (final colors in BoardColors.values) {
      expect(BoardColors.fromCode(colors.code), colors);
    }
    for (final pieces in PieceStyle.values) {
      expect(PieceStyle.fromCode(pieces.code), pieces);
    }
  });

  test('código desconhecido ou ausente cai no padrão', () {
    expect(BoardColors.fromCode(null), BoardColors.blue);
    expect(BoardColors.fromCode('neon'), BoardColors.blue);
    expect(PieceStyle.fromCode(null), PieceStyle.cburnett);
    expect(PieceStyle.fromCode('alpha'), PieceStyle.cburnett);
  });

  test('de fábrica: tabuleiro azul, peças Cburnett e coordenadas ligadas', () {
    const settings = BoardSettings();

    expect(settings.colors, BoardColors.blue);
    expect(settings.pieces, PieceStyle.cburnett);
    expect(settings.coordinates, isTrue);
  });

  test('restaurar a aparência volta cores, peças e coordenadas', () {
    const changed = BoardSettings(
      colors: BoardColors.purple,
      pieces: PieceStyle.merida,
      coordinates: false,
    );

    expect(changed.withDefaultAppearance(), const BoardSettings());
  });
}
