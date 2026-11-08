import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations_pt.dart';

/// No português, o 0 cai na regra `one` do plural: sem `=0`, o `=1{1 …}`
/// mostraria "1 partida" para quem não jogou nenhuma. As contagens da D2.
void main() {
  final pt = AppLocalizationsPt();

  test('zero fica no plural', () {
    expect(pt.conProgressGames(0), '0 partidas');
    expect(pt.levelGamesCount(0), '0 partidas');
    expect(pt.profileRatingGames(0), '0 partidas contadas');
    expect(pt.conVoltaJourneyValue('Coco', 0, 0), 'Coco, 0 de 0 desafios');
  });

  test('um fica no singular', () {
    expect(pt.conProgressGames(1), '1 partida');
    expect(pt.levelGamesCount(1), '1 partida');
  });
}
