import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/subcategory_material.dart';

void main() {
  void expectMaterial(String key, List<Role> first, List<Role> second) {
    final (a, b) = SubcategoryMaterial.of(key);
    expect(a, first, reason: '$key: primeiro lado');
    expect(b, second, reason: '$key: segundo lado');
  }

  test('dama contra torre e peão', () {
    expectMaterial('queenVsRookPawn', [Role.queen], [Role.rook, Role.pawn]);
  });

  test('números por extenso viram peças repetidas', () {
    expectMaterial('twoPawnsVsKing', [Role.pawn, Role.pawn], [Role.king]);
    expectMaterial(
      'rookTwoPawnsVsRook',
      [Role.rook, Role.pawn, Role.pawn],
      [Role.rook],
    );
  });

  test('sem "vs" (mates básicos), o outro lado é o rei sozinho', () {
    expectMaterial('twoRooks', [Role.rook, Role.rook], [Role.king]);
    expectMaterial('queen', [Role.queen], [Role.king]);
  });

  test('o rei só aparece no lado que não tem mais nada', () {
    expectMaterial('kingVsBishopPawn', [Role.king], [Role.bishop, Role.pawn]);
  });
}
