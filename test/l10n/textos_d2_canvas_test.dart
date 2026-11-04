import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations_pt.dart';

/// Textos da D2 que o canvas fixou (lista de bugs do orquestrador, 04/11).
void main() {
  final pt = AppLocalizationsPt();

  test('item 13: conquistas "Mate de dama/torre contra todos"', () {
    expect(pt.achievementAllLevelsQueenTitle, 'Mate de dama contra todos');
    expect(pt.achievementAllLevelsRookTitle, 'Mate de torre contra todos');
  });

  // Um conceito, um nome: "Notificações" no Perfil, nas Configurações e na
  // tela (decisão do orquestrador, 04/11; o quadro RetencaoPerfil foi corrigido).
  test('item 7: o grupo se chama "Notificações" em todo lugar', () {
    expect(pt.alertsTitle, 'Notificações');
  });
}
