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

  test('jeito de mover e notação voltam do código gravado', () {
    for (final method in MoveMethod.values) {
      expect(MoveMethod.fromCode(method.code), method);
    }
    for (final notation in MoveNotation.values) {
      expect(MoveNotation.fromCode(notation.code), notation);
    }
    expect(MoveMethod.fromCode('voz'), MoveMethod.either);
    expect(MoveNotation.fromCode(null), MoveNotation.figurine);
  });

  test('de fábrica: arrastar ou tocar, ajudas ligadas e notação figurina', () {
    const settings = BoardSettings();

    expect(settings.moveMethod, MoveMethod.either);
    expect(settings.showLegalMoves, isTrue);
    expect(settings.highlightLastMove, isTrue);
    expect(settings.animation, isTrue);
    expect(settings.premoves, isTrue);
    expect(settings.notation, MoveNotation.figurine);
  });

  test('restaurar a aparência não mexe no comportamento', () {
    const changed = BoardSettings(
      colors: BoardColors.green,
      moveMethod: MoveMethod.tap,
      showLegalMoves: false,
      notation: MoveNotation.letters,
    );

    expect(
      changed.withDefaultAppearance(),
      const BoardSettings(
        moveMethod: MoveMethod.tap,
        showLegalMoves: false,
        notation: MoveNotation.letters,
      ),
    );
  });
}
