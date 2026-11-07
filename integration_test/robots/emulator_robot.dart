import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/e2e_dependencies.dart';
import '../../testing/emulator_admin.dart';
import '../../testing/emulator_dependencies.dart';
import '../../testing/fakes/fake_push_repository.dart';
import 'home_robot.dart';
import 'profile_robot.dart';

/// O app de verdade no Emulator Suite (roteiro do QA da R5,
/// `docs/tasks/E1.19-qa-r5.md`), com o [admin] do outro lado.
///
/// Rodar com `--dart-define=E2E=true --dart-define=FIREBASE_EMULADOR=true`,
/// o emulador do Firebase ligado no computador (Auth 9099, Firestore 8080,
/// Functions 5001, projeto do `google-services.json` do flavor dev) e as
/// contas de `tools/emulador_contas_qa.py`.
class EmulatorRobot {
  EmulatorRobot(this.$);

  final PatrolIntegrationTester $;
  final admin = EmulatorAdmin();

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
    dependencies = await emulatorDependencies(push: push);
    await $.pumpWidgetAndSettle(
      LucenaApp(key: UniqueKey(), dependencies: dependencies),
    );
    await $(Scaffold).waitUntilVisible();
    await $.pumpAndSettle();
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

  /// O caminho da tela de cima agora.
  String get location =>
      GoRouter.of($.tester.element(find.byType(Scaffold).last))
          .routeInformationProvider
          .value
          .uri
          .path;

  /// Deixa o app trabalhar (rede do emulador) até [done] ou [timeout].
  Future<void> pumpUntil(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final watch = Stopwatch()..start();
    while (!done()) {
      if (watch.elapsed > timeout) {
        fail('O app não chegou ao esperado em $timeout');
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
      } else if (find.byKey(AccountKeys.dataScreen).evaluate().isNotEmpty) {
        await $(AccountKeys.dataSave).tap();
        await $.pumpAndSettle();
      } else if (find.byKey(ProfileKeys.syncCard).evaluate().isNotEmpty) {
        break;
      } else {
        await $.tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await $.pump(const Duration(milliseconds: 100));
      }
    }
    await $(ProfileKeys.screen).waitUntilVisible();
  }
}
