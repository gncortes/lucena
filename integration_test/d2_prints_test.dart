import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/config/dependencies.dart' show hideDevToolsForPrints;
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/repositories/sync/sync_repository.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/keys/alerts_keys.dart';
import 'package:lucena/ui/core/keys/board_settings_keys.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/my_progress_keys.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_purchase_service.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// Os prints da D2 (venda, conta e ajustes) ao lado dos quadros do canvas:
/// lista em `docs/tasks/T85-D2-prints.md`. O app dev não tem loja, então os
/// estados de demonstração e de compra saem daqui, com o fake da compra.
/// Coletor: `tools/capture/t85_capture_server.py` (porta 8792).
void main() {
  // O quadro não tem as ferramentas de desenvolvimento.
  hideDevToolsForPrints = true;
  const prices = {
    PilaresPlan.lifetime: r'R$ 99,90',
    PilaresPlan.monthly: r'R$ 19,90',
  };
  const demo = PurchaseState(pricesReady: true, prices: prices);

  PurchaseState owning(PilaresAccessKind kind, {bool endedSeen = false}) =>
      PurchaseState(
        pricesReady: true,
        prices: prices,
        access: PilaresAccess(kind: kind, endedSeen: endedSeen),
      );

  /// [settle] falso: a tela tem animação sem fim (o indicador da compra
  /// processando), e o `pumpAndSettle` nunca terminaria.
  Future<void> go(
    PatrolIntegrationTester $,
    String route, {
    Object? extra,
    bool settle = true,
  }) async {
    final router = GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)));
    unawaited(router.push<void>(route, extra: extra));
    if (settle) {
      await $.pumpAndSettle();
    } else {
      await $.pump(const Duration(milliseconds: 600));
    }
  }

  Future<void> shots(
    PatrolIntegrationTester $,
    List<(String, String, Key)> screens, {
    Map<String, Object> extras = const {},
    bool settle = true,
  }) async {
    final capture = TrainingCaptureRobot($);
    for (final (name, route, ready) in screens) {
      await go($, route, extra: extras[name], settle: settle);
      // O conteúdo de algumas telas vem de leitura assíncrona e entra em
      // cascata depois da rota: sem esta espera, o print sai em branco.
      for (var i = 0; i < 20; i++) {
        await $.pump(const Duration(milliseconds: 100));
      }
      await capture.shot(name, ready: ready);
      final navigator = Navigator.of($.tester.element(find.byKey(ready)));
      navigator.pop();
      if (settle) {
        await $.pumpAndSettle();
      } else {
        await $.pump(const Duration(milliseconds: 600));
      }
    }
  }

  patrolTest('D2 prints: venda na demonstração', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      demo: true,
      purchases: FakePurchaseRepository(demo),
    );
    await shots($, [
      (
        'PropV2CursoApresentacao',
        D2Paths.pilaresPresentation,
        CoursePreviewKeys.sale,
      ),
      ('PropV1CursoDetalhes', D2Paths.pilaresAbout, CoursePreviewKeys.details),
      ('PropV2CompraA', D2Paths.offer(), PurchaseKeys.offerScreen),
      (
        'PropV2CompraAMensal',
        D2Paths.offer(plan: PilaresPlan.monthly),
        PurchaseKeys.offerScreen,
      ),
      ('PropV2VendaPlano', D2Paths.plan(), PurchaseKeys.planSaleScreen),
      (
        'PropV2OfertaAntesInicio',
        D2Paths.pilaresBeforeHome,
        // A folha (SafeArea) não recebe toque no centro; o X, sim.
        PurchaseKeys.beforeHomeClose,
      ),
      (
        'PropV2CompraPendente',
        D2Paths.pilaresPurchasePending,
        PurchaseKeys.pendingScreen,
      ),
      (
        'PropV2CompraConcluida',
        D2Paths.pilaresPurchaseDone,
        CourseUnlockedKeys.screen,
      ),
    ]);
  }, tags: ['d2-venda']);

  // Restaurar pede conta (sem ela, a rota leva à entrada): o print com a conta
  // Google do E2E, como no quadro.
  patrolTest('D2 prints: restaurar com conta', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      demo: true,
      signedIn: true,
      purchases: FakePurchaseRepository(demo),
    );
    await shots($, [
      (
        'PropV2CompraRestaurar',
        D2Paths.pilaresRestore,
        PurchaseKeys.restoreScreen,
      ),
    ]);
  }, tags: ['d2-venda']);

  for (final outcome in [
    PurchaseOutcome.canceled,
    PurchaseOutcome.error,
    PurchaseOutcome.offline,
  ]) {
    patrolTest('D2 prints: oferta com a compra ${outcome.name}', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        demo: true,
        purchases: FakePurchaseRepository(demo.copyWith(outcome: outcome)),
      );
      await shots($, [
        ('compra-${outcome.name}', D2Paths.offer(), PurchaseKeys.offerScreen),
      ]);
    }, tags: ['d2-compra']);
  }

  patrolTest('D2 prints: compra processando', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      demo: true,
      purchases: FakePurchaseRepository(demo.copyWith(processing: true)),
    );
    await shots($, [
      ('PropV2CompraProcessando', D2Paths.offer(), PurchaseKeys.offerScreen),
    ], settle: false);
  }, tags: ['d2-compra']);

  for (final (name, kind) in [
    ('PropV2CompraJaTem', PilaresAccessKind.lifetime),
    ('PropV2CompraJaTemMensal', PilaresAccessKind.monthlyActive),
  ]) {
    patrolTest('D2 prints: $name', ($) async {
      await AppRobot($).open(
        systemLocale: const Locale('pt', 'BR'),
        lightDevice: true,
        purchases: FakePurchaseRepository(owning(kind)),
      );
      // O quadro é o Perfil do dono, com o cartão do Pilares.
      await shots($, [(name, Routes.settingsProfile, ProfileKeys.screen)]);
    }, tags: ['d2-compra']);
  }

  patrolTest('D2 prints: assinatura encerrada', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      purchases: FakePurchaseRepository(owning(PilaresAccessKind.monthlyEnded)),
    );
    await shots($, [
      (
        'PropV2AssinaturaEncerrada',
        D2Paths.pilaresSubscriptionEnded,
        PurchaseKeys.endedScreen,
      ),
    ]);
  }, tags: ['d2-compra']);

  patrolTest('D2 prints: conta do visitante', ($) async {
    await AppRobot($)
        .open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    await shots($, [
      (
        'PropV1ContaEntrada',
        Routes.accountEnterFrom('perfil'),
        AccountKeys.enterScreen,
      ),
      (
        'PropV1ContaCriar',
        Routes.accountEmailFrom('perfil'),
        AccountKeys.createScreen,
      ),
      (
        'PropV1ContaEntrar',
        Routes.accountEmailFrom('perfil', signIn: true),
        AccountKeys.signInScreen,
      ),
      (
        'PropV1ContaAceite',
        Routes.accountConsentFrom('perfil'),
        AccountKeys.acceptScreen,
      ),
      ('PropV1PerfilSemConta', Routes.settingsProfile, ProfileKeys.screen),
    ]);
  }, tags: ['d2-conta']);

  // O quadro do Progresso tem o convite da conta pendente.
  patrolTest('D2 prints: progresso com o convite', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      accountInvite: true,
    );
    await shots($, [
      ('PropV2UxProgresso', D2Paths.progress, MyProgressKeys.screen),
    ]);
  }, tags: ['d2-conta']);

  patrolTest('D2 prints: conta Google', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      signedIn: true,
    );
    await shots(
      $,
      [
        ('PropV1PerfilConta', Routes.settingsProfile, ProfileKeys.screen),
        (
          'PropV1ContaPerfil',
          Routes.accountDataFrom('perfil', welcome: true),
          AccountKeys.dataScreen,
        ),
        (
          'PropV1PerfilRecuperar',
          Routes.accountRestoredFrom('perfil'),
          AccountKeys.restoredScreen,
        ),
        ('PropV1ContaPrivacidade', Routes.privacy, PrivacyKeys.screen),
        ('TelaConquistas', Routes.achievements, AchievementsKeys.screen),
      ],
      extras: {
        // A tela "de volta" só abre com o resultado da sincronização.
        'PropV1PerfilRecuperar': const SyncResult(
          summary: ProgressSummary(
            profile: UserProfile(nickname: 'Ana', rating: 1400),
          ),
          hadRemote: true,
        ),
      },
    );
  }, tags: ['d2-conta']);

  patrolTest('D2 prints: ajustes', ($) async {
    await AppRobot($)
        .open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    // PropV1ConfigB: "Sem conta · Melhorar o jogo · 1712".
    final profile = $.tester
        .element(find.byKey(HomeKeys.screen))
        .read<ProfileCubit>();
    await $.tester.runAsync(() => profile.setGoal(GoalPreference.improve));
    await $.pumpAndSettle();
    await shots($, [
      ('PropV1ConfigB', Routes.settings, SettingsKeys.screen),
      (
        'TelaAparencia',
        Routes.settingsAppearance,
        SettingsKeys.appearanceScreen,
      ),
      ('TelaIdioma', Routes.settingsLanguage, SettingsKeys.languageScreen),
      (
        'TelaAparenciaTabuleiro',
        Routes.settingsBoardAppearance,
        BoardSettingsKeys.appearanceScreen,
      ),
      (
        'PropV1ConfigPartidaAquecimento',
        Routes.settingsGame,
        SettingsKeys.gameScreen,
      ),
      (
        'TelaConfigRelogio',
        Routes.settingsClock,
        BoardSettingsKeys.clockScreen,
      ),
      ('TelaSom', Routes.settingsSound, SettingsKeys.soundScreen),
      ('PropV1RetencaoAvisos', Routes.alerts, AlertsKeys.screen),
      ('PropV1LegalSobre', Routes.settingsAbout, SettingsKeys.aboutScreen),
    ]);
  }, tags: ['d2-ajustes']);
}
