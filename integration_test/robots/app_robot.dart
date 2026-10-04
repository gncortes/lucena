import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/main.dart';
import 'package:patrol/patrol.dart';

import '../../testing/e2e_dependencies.dart';

/// Ações do app inteiro e do aparelho: abrir, segundo plano, rede, tema do sistema.
class AppRobot {
  const AppRobot(this.$);

  final PatrolIntegrationTester $;

  /// Abre o app com a composição E2E (fakes de `testing/`).
  Future<void> open({Locale? locale}) async {
    expect(isE2E, isTrue, reason: 'Rode o Patrol com --dart-define=E2E=true');
    await $.pumpWidgetAndSettle(
      LucenaApp(dependencies: e2eDependencies(), locale: locale),
    );
  }

  Future<void> sendToBackgroundAndReturn() async {
    await $.platform.mobile.pressHome();
    await $.platform.mobile.openApp();
    await $.pumpAndSettle();
  }

  /// Desliga Wi-Fi e dados móveis. O botão de modo avião do Patrol depende do
  /// idioma do aparelho (não cobre português nem árabe); este caminho, não.
  Future<void> goOffline() async {
    await $.platform.mobile.disableWifi();
    await $.platform.mobile.disableCellular();
  }

  Future<void> goOnline() async {
    await $.platform.mobile.enableWifi();
    await $.platform.mobile.enableCellular();
  }

  Future<void> enableSystemDarkMode() async {
    await $.platform.mobile.enableDarkMode();
    await $.pumpAndSettle();
  }

  Future<void> disableSystemDarkMode() async {
    await $.platform.mobile.disableDarkMode();
    await $.pumpAndSettle();
  }

  /// O app fica em retrato mesmo com o aparelho deitado.
  void expectPortrait() {
    final size = $.tester.view.physicalSize;
    expect(
      size.height,
      greaterThan(size.width),
      reason: 'a tela do app deveria estar em retrato, mas mede $size',
    );
  }
}
