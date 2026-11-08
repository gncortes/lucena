import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';

/// No português o 0 cai na regra `one`: sem `=0` explícito, "0 partidas"
/// sairia "1 partida". As contagens das telas da D3 (Nível, Sua semana,
/// formatura da Escola) dizem o zero no plural.
void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('zero no plural', () {
    expect(pt.levelGamesCount(0), '0 partidas');
    expect(pt.schoolGraduationModuleCount(0), '0 lições');
    expect(pt.weekHeadline(0, 'same', 0), contains('0 finais'));
    expect(pt.weekNotifText(0, 'same', 0), contains('0 finais'));
  });

  test('um e muitos seguem iguais', () {
    expect(pt.levelGamesCount(1), '1 partida');
    expect(pt.levelGamesCount(3), '3 partidas');
    expect(pt.weekHeadline(1, 'same', 0), contains('1 final '));
  });
}
