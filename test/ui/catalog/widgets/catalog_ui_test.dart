import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/catalog/widgets/catalog_ui.dart';

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('os finais conhecidos ficam com o nome próprio', () {
    expect(endgameName(pt, 'queenVsRook'), pt.endgameQueenVsRook);
    expect(endgameName(pt, 'knightBishopVsKing'), pt.endgameKnightBishop);
  });

  test('os outros finais têm o nome montado do material', () {
    expect(endgameName(pt, 'queenVsRookPawn'), 'Dama contra torre e peão');
    expect(
      endgameName(pt, 'rookTwoPawnsVsBishopKnightPawn'),
      'Torre e dois peões contra bispo, cavalo e peão',
    );
    expect(endgameName(pt, 'twoKnightsVsPawn'), 'Dois cavalos contra peão');
    expect(endgameName(pt, 'kingVsBishopPawn'), 'Rei contra bispo e peão');
    expect(endgameName(pt, 'twoPawnsVsKing'), 'Dois peões contra rei');
    expect(
      endgameName(en, 'fourPawnsVsThreePawns'),
      'Four pawns vs three pawns',
    );
  });

  test('as categorias novas têm nome', () {
    expect(categoryName(pt, 'knight'), 'Finais de cavalo');
    expect(categoryName(pt, 'rookPieces'), 'Torre contra peças');
  });
}
