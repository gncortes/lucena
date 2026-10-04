import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/main.dart';
import 'package:patrol/patrol.dart';

import '../../testing/e2e_dependencies.dart';

/// Ações do app inteiro e do aparelho: abrir, reiniciar, segundo plano, rede,
/// tema e idioma do sistema.
class AppRobot {
  const AppRobot(this.$);

  final PatrolIntegrationTester $;

  /// Abre o app com a composição E2E, sem nenhum dado gravado.
  ///
  /// [systemLocale] faz o app enxergar o aparelho nesse idioma.
  Future<void> open({Locale? systemLocale}) async {
    expect(isE2E, isTrue, reason: 'Rode o Patrol com --dart-define=E2E=true');
    await resetE2EData();
    if (systemLocale != null) {
      $.tester.platformDispatcher.localesTestValue = [systemLocale];
      addTearDown($.tester.platformDispatcher.clearLocalesTestValue);
    }
    await _pumpApp();
  }

  /// Fecha e abre o app de novo, mantendo o que foi gravado no aparelho. Como
  /// ao fechar à força: nenhuma tela é avisada de que o app vai fechar.
  Future<void> restart() async {
    await $.pumpWidgetAndSettle(const SizedBox());
    await _pumpApp();
  }

  // A key nova a cada abertura garante um app do zero, sem estado em memória.
  // A leitura das preferências vem do aparelho e não agenda quadros: só o
  // pumpAndSettle não basta, é preciso esperar a primeira tela aparecer.
  Future<void> _pumpApp() async {
    await $.pumpWidgetAndSettle(
      LucenaApp(key: UniqueKey(), dependencies: await e2eDependencies()),
    );
    // O app abre na tela inicial ou, com partida em andamento, no tabuleiro.
    await $(Scaffold).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Faz o relógio do app andar [duration] de uma vez. O relógio dos cenários
  /// não anda sozinho: o tempo só passa aqui.
  Future<void> advanceTime(Duration duration) async {
    e2eNow.advance(duration);
    // A tela refaz os tempos no tique seguinte.
    await $.pump(const Duration(milliseconds: 300));
  }

  /// Vai para a tela inicial do celular, deixa passar [duration] no relógio
  /// do app e volta.
  Future<void> sendToBackgroundFor(Duration duration) async {
    await $.platform.mobile.pressHome();
    e2eNow.advance(duration);
    await $.platform.mobile.openApp();
    await $.pumpAndSettle();
  }

  /// O que o app recebe quando a tela é bloqueada e desbloqueada [duration]
  /// depois. O Patrol não bloqueia a tela de verdade: aqui o app passa pelos
  /// mesmos estados (pausado e retomado) que o bloqueio provoca.
  Future<void> lockScreenFor(Duration duration) async {
    final binding = $.tester.binding;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    e2eNow.advance(duration);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndSettle();
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

  /// O tema que a tela atual está usando de fato.
  void expectBrightness(Brightness brightness) {
    final context = $.tester.element(find.byType(Scaffold).last);
    expect(Theme.of(context).brightness, brightness);
  }

  void expectDirection(TextDirection direction) {
    final context = $.tester.element(find.byType(Navigator).first);
    expect(Directionality.of(context), direction);
  }

  /// Nenhum texto da tela atual foi cortado nem encurtado com reticências.
  void expectNoClippedText() {
    final paragraphs = find.byType(RichText).evaluate();
    expect(paragraphs, isNotEmpty);
    for (final element in paragraphs) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'texto cortado: "${paragraph.text.toPlainText()}"',
      );
    }
  }
}
