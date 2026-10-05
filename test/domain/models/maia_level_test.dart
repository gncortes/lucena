import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/domain/models/rating_level.dart';

void main() {
  test('os níveis vão de 1000 a 2600, de 200 em 200', () {
    expect(MaiaLevels.all.first, 1000);
    expect(MaiaLevels.all.last, 2600);
    expect(MaiaLevels.all, hasLength(9));
    for (var i = 1; i < MaiaLevels.all.length; i++) {
      expect(MaiaLevels.all[i] - MaiaLevels.all[i - 1], 200);
    }
  });

  test('o nível sugerido é o mais próximo do rating', () {
    expect(MaiaLevels.nearest(1800), 1800);
    expect(MaiaLevels.nearest(1750), 1800);
    expect(MaiaLevels.nearest(1450), 1400);
    expect(MaiaLevels.nearest(1290), 1200);
  });

  test('rating fora da faixa cai no primeiro ou no último nível', () {
    expect(MaiaLevels.nearest(400), 1000);
    expect(MaiaLevels.nearest(3200), 2600);
  });

  test('toda faixa do perfil tem um nível sugerido', () {
    expect(
      [
        for (final level in RatingLevel.values)
          MaiaLevels.nearest(level.rating),
      ],
      [1000, 1200, 1400, 1800, 2000, 2400],
    );
  });

  test('o Maia varia os lances, mas puxa para os mais prováveis', () {
    // Entre o lance fixo (0), que repete a partida, e o sorteio puro (1), que
    // erra mais do que as pessoas do nível (docs/calibracao.md).
    expect(MaiaLevels.temperature, greaterThan(0));
    expect(MaiaLevels.temperature, lessThan(1));
  });
}
