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

  // Consultor de texto, aprovado pelo orquestrador (04/11): "tudo salvo" com
  // "ainda não" se contradiziam; "exercício" e a contagem com o substantivo
  // seguem o padrão do app. "Salvo", nunca "guardado" (H-LIC-16).
  test('cartão da conta: "Progresso na conta" e "salvo"', () {
    expect(pt.profileSyncedTitle, 'Progresso na conta');
    expect(pt.profileSyncedAt('hoje, 21:40'), 'Salvo hoje, 21:40');
    expect(pt.profileSyncedNever, 'Ainda não salvo');
    expect(
      pt.profileSyncOffline,
      'Sem internet, o que você faz fica no celular e é salvo na conta '
      'quando a conexão voltar.',
    );
  });

  test('aquecimento: "alguns exercícios rápidos"', () {
    expect(
      pt.settingsWarmUpHint,
      'Antes de uma partida, alguns exercícios rápidos do mesmo final.',
    );
  });

  test('notificações: "3 de 4 notificações ligadas"', () {
    expect(pt.alertsCount(3, 4), '3 de 4 notificações ligadas');
  });

  test('cartão do curso na demonstração', () {
    expect(
      pt.venDemoText,
      'Na demonstração você faz o Capítulo 1. O curso completo tem 20 '
      'capítulos.',
    );
  });
}
