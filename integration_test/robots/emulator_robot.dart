import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/e2e_dependencies.dart';
import '../../testing/emulator_admin.dart';
import '../../testing/emulator_dependencies.dart';
import '../../testing/fakes/fake_push_repository.dart';
import 'lifecycle.dart';
import 'home_robot.dart';
import 'profile_robot.dart';

/// O app de verdade no Emulator Suite (roteiro do QA da R5,
/// `docs/tasks/E1.19-qa-r5.md`), com o [admin] do outro lado.
///
/// Rodar com `--dart-define=E2E=true --dart-define=FIREBASE_EMULADOR=true`,
/// o emulador do Firebase ligado no computador (Auth 9099, Firestore 8085,
/// Functions 5001, projeto do `google-services.json` do flavor dev) e as
/// contas de `tools/emulador_contas_qa.py`.
class EmulatorRobot {
  EmulatorRobot(this.$, {this.realPush = false});

  final PatrolIntegrationTester $;
  final admin = EmulatorAdmin();

  /// O push de verdade (FCM real do flavor dev) em vez do [push] falso.
  final bool realPush;

  /// O toque no push: o FCM não é emulado.
  final push = FakePushRepository(allowed: true);
  late Dependencies dependencies;

  /// Abre o app sem conta e sem nada gravado. [beforeApp] grava no aparelho
  /// o que o app deve encontrar ao abrir.
  Future<void> open({Future<void> Function()? beforeApp}) async {
    expect(isE2E, isTrue, reason: 'Rode o Patrol com --dart-define=E2E=true');
    addTearDown(admin.close);
    await $.pumpWidgetAndSettle(const SizedBox());
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await resetE2EData();
    await beforeApp?.call();
    final dispatcher = $.tester.platformDispatcher;
    dispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(dispatcher.clearLocalesTestValue);
    await _pumpApp();
  }

  /// Fecha e abre o app de novo, como ao fechar à força: o que está no
  /// aparelho e a conta do Firebase ficam; a memória do app, não.
  Future<void> restart() async {
    await $.pumpWidgetAndSettle(const SizedBox());
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _pumpApp(keepAccount: true);
  }

  Future<void> _pumpApp({bool keepAccount = false}) async {
    dependencies = await emulatorDependencies(
      push: realPush ? null : push,
      keepAccount: keepAccount,
    );
    resumed($);
    await $.pumpWidgetAndSettle(
      LucenaApp(key: UniqueKey(), dependencies: dependencies),
    );
    await $(Scaffold).waitUntilVisible();
    await $.pumpAndSettle();
    // Sem compra, a oferta do Pilares sai por cima do Início uma vez por
    // abertura (H-INI-14): o roteiro do painel começa com ela fechada.
    await pumpUntil(
      () =>
          find.byKey(PurchaseKeys.beforeHomeSheet).evaluate().isNotEmpty ||
          find
              .byKey(HomeKeys.settingsButton)
              .hitTestable()
              .evaluate()
              .isNotEmpty,
    );
    if (find.byKey(PurchaseKeys.beforeHomeSheet).evaluate().isNotEmpty) {
      await $(PurchaseKeys.beforeHomeClose).tap();
    }
    await $(HomeKeys.settingsButton).waitUntilVisible();
  }

  /// Da tela inicial ao Perfil.
  Future<void> openProfile() async {
    await HomeRobot($).openSettings();
    await ProfileRobot($).open();
  }

  /// No Perfil sem conta: cria a conta com e-mail e senha.
  Future<void> createAccount(String email, String password) async {
    await _openEmail();
    await _fill(email, password);
  }

  /// No Perfil sem conta: entra numa conta que já existe.
  Future<void> signIn(String email, String password) async {
    await _openEmail();
    await $(AccountKeys.toSignIn).scrollTo().tap();
    await $(AccountKeys.signInScreen).waitUntilVisible();
    await _fill(email, password);
  }

  /// No Perfil com conta: sai e volta ao Perfil sem conta.
  Future<void> signOut() async {
    await $(ProfileKeys.signOut).scrollTo().tap();
    await $(ProfileKeys.createAccount)
        .waitUntilVisible(timeout: const Duration(seconds: 20));
  }

  /// Vai direto à rota [location] (atalho para telas fora do caminho do
  /// cenário).
  Future<void> go(String location) async {
    GoRouter.of($.tester.element(find.byType(Scaffold).first)).go(location);
    await $.pumpAndSettle();
  }

  /// O caminho da tela de cima agora. O `push` não muda a `uri` da
  /// configuração (ela fica na base): vale o último casamento de rota.
  String get location =>
      GoRouter.of($.tester.element(find.byType(Scaffold).last))
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation;

  /// As rotas na tela agora (diagnóstico de falha): o caminho do roteador e,
  /// para cada Scaffold, o nome da rota, se é a de cima e se está ativa.
  String get routes {
    final scaffolds = find.byType(Scaffold, skipOffstage: false).evaluate();
    final described = [
      for (final e in scaffolds)
        if (ModalRoute.of(e) case final route?)
          '${route.settings.name}'
              '${route.isCurrent ? ' (em cima)' : ''}'
              '${route.isActive ? '' : ' (saindo)'}',
    ];
    return '$location; rotas: ${described.toSet().join(' | ')}';
  }

  /// As keys de texto na tela agora (diagnóstico de falha).
  String get keys => {
    for (final e
        in find.byWidgetPredicate((w) => w.key is ValueKey<String>).evaluate())
      (e.widget.key! as ValueKey<String>).value,
  }.join(', ');

  /// Os textos na tela agora (diagnóstico de falha).
  String get textos =>
      [for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data]
          .join(' | ');

  /// Deixa o app trabalhar (rede do emulador) até [done] ou [timeout].
  Future<void> pumpUntil(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final watch = Stopwatch()..start();
    while (!done()) {
      if (watch.elapsed > timeout) {
        fail(
          'O app não chegou ao esperado em $timeout; tela $routes; '
          'keys: $keys; textos: $textos',
        );
      }
      await $.tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await $.pump(const Duration(milliseconds: 100));
    }
    await $.pumpAndSettle();
  }

  Future<void> _openEmail() async {
    await $(ProfileKeys.createAccount).scrollTo().tap();
    await $(AccountKeys.enterScreen).waitUntilVisible();
    await $(AccountKeys.email).tap();
    await $(AccountKeys.createScreen).waitUntilVisible();
  }

  Future<void> _fill(String email, String password) async {
    await $(AccountKeys.emailField).enterText(email);
    await $(AccountKeys.passwordField).enterText(password);
    await $(AccountKeys.emailSubmit).tap();
    await $.pumpAndSettle();
    // A conta nova passa pelo aceite e pelos dados; a que já existe não.
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 30)) {
      if (find.byKey(AccountKeys.acceptScreen).evaluate().isNotEmpty) {
        await $(AccountKeys.acceptCheck).tap();
        await $(AccountKeys.acceptContinue).tap();
        await $.pumpAndSettle();
      } else if (find.byKey(AccountKeys.restoredScreen).evaluate().isNotEmpty) {
        // Conta com progresso no servidor (de uma rodada anterior no mesmo
        // emulador): o "Bem-vindo de volta" vem antes do Perfil.
        await $(AccountKeys.restoredContinue).scrollTo().tap();
        await $.pumpAndSettle();
      } else if (find.byKey(AccountKeys.dataScreen).evaluate().isNotEmpty) {
        await $(AccountKeys.dataSave).tap();
        await $.pumpAndSettle();
      } else if (find.byKey(ProfileKeys.syncCard).evaluate().isNotEmpty ||
          find.byKey(CourseUnlockedKeys.screen).evaluate().isNotEmpty) {
        break;
      } else {
        await $.tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await $.pump(const Duration(milliseconds: 100));
      }
    }
    // Com curso dado e não visto, o "Curso liberado" abre por cima do Perfil
    // logo depois de entrar: quem chamou decide o que fazer com ele.
    await pumpUntil(
      () =>
          find.byKey(CourseUnlockedKeys.screen).evaluate().isNotEmpty ||
          find.byKey(ProfileKeys.screen).hitTestable().evaluate().isNotEmpty,
    );
  }
}
