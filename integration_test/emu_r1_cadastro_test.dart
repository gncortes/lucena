import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/emulator_robot.dart';

// Roteiro do QA da R5, item 1 (lado app), no Emulator Suite: cadastro com
// e-mail, verificação, login e sair. Ao sair, o token do push sai da conta
// (H-R5-64) e o painel deixa de contar o aparelho nas notificações.
void main() {
  patrolTest('R5 roteiro 1: cadastro, verificação, login e sair', ($) async {
    final app = EmulatorRobot($);
    final admin = app.admin;
    // E-mail novo a cada rodada: o emulador guarda as contas até reiniciar.
    final email = 'cadastro-${Random().nextInt(1 << 30)}@teste.lucena';
    const password = 'cadastro-teste-123';

    await app.open();
    await app.openProfile();
    await app.createAccount(email, password);
    await $(ProfileKeys.syncCard).waitUntilVisible();

    // A conta existe no Auth com o e-mail ainda sem verificar; o link do
    // e-mail (aplicado pelo emulador) a verifica.
    final account = await admin.signIn(email, password);
    expect(await admin.emailVerified(account), isFalse);
    await admin.verifyEmail(account, email);
    expect(await admin.emailVerified(account), isTrue);

    // O app gravou a conta e o aparelho do push.
    await admin.waitFor('users/${account.uid}', (doc) => doc != null);
    final device = 'users/${account.uid}/push/device';
    await admin.waitFor(device, (doc) => doc?['token'] is String);

    // Sair: o token do push sai da conta (H-R5-64).
    await app.signOut();
    await admin.waitFor(device, (doc) => doc == null);

    // Entrar de novo na mesma conta: o aparelho volta.
    await app.signIn(email, password);
    await $(ProfileKeys.syncCard).waitUntilVisible();
    await admin.waitFor(device, (doc) => doc?['token'] is String);
    await app.signOut();
    await admin.waitFor(device, (doc) => doc == null);
  });
}
