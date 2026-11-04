import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/course_preview.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';

/// O plano como venda (H-VEN-14, `PropV2VendaPlano`).
void main() {
  late FakePurchaseRepository purchases;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    purchases = FakePurchaseRepository(
      const PurchaseState(
        pricesReady: true,
        prices: {
          PilaresPlan.lifetime: r'R$ 99,90',
          PilaresPlan.monthly: r'R$ 19,90',
        },
      ),
    );
    analytics = FakeAnalyticsRepository();
  });

  Future<GoRouter> pump(
    WidgetTester tester,
    String location, {
    CoursePreview? preview,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('inicio')),
        ),
        GoRoute(
          path: Routes.training(TrainingCourse.pilares.name),
          builder: (_, state) => Scaffold(body: Text('treino ${state.uri}')),
        ),
        ...d2Routes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(
            value: FakeAccountRepository(),
          ),
          RepositoryProvider<CampaignRepository>.value(
            value: MemoryCampaignRepository(),
          ),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<CoursePreviewRepository>.value(
            value: FakeCoursePreviewRepository(
              preview: preview ?? FakeCoursePreviewRepository.example(),
            ),
          ),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          purchaseRepository: purchases,
          analytics: analytics,
          router: router,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push(location);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('abre com o título, os números e a oferta vista do plano', (
    tester,
  ) async {
    await pump(tester, D2Paths.plan(origin: 'abertura_app'));
    expect(find.byKey(PurchaseKeys.planSaleScreen), findsOneWidget);
    expect(find.text('Seu plano para evoluir no xadrez'), findsOneWidget);
    expect(find.text('Curso de exemplo'), findsOneWidget);
    expect(find.text('capítulos'), findsOneWidget);
    expect(
      analytics.eventsNamed('pilares_oferta_vista').single.params,
      allOf(
        containsPair('origem', 'abertura_app'),
        containsPair('destaque', 'plano'),
      ),
    );
  });

  testWidgets('"Começar pelo Capítulo 1" abre o Catálogo da demonstração', (
    tester,
  ) async {
    final router = await pump(tester, D2Paths.pilaresPlan);
    await tester.tap(find.byKey(PurchaseKeys.planSaleStart));
    await tester.pumpAndSettle();
    final uri = router.routerDelegate.currentConfiguration.uri;
    expect(uri.path, Routes.training(TrainingCourse.pilares.name));
    expect(uri.queryParameters['aba'], 'catalog');
    expect(
      analytics.eventsNamed('demo_inicio').single.params,
      containsPair('capitulo_id', '1'),
    );
  });

  testWidgets('"Ver o curso completo" abre a oferta do fim da demonstração', (
    tester,
  ) async {
    await pump(tester, D2Paths.pilaresPlan);
    await tester.tap(find.byKey(PurchaseKeys.planSaleFull));
    await tester.pumpAndSettle();
    expect(find.byKey(PurchaseKeys.demoEndScreen), findsOneWidget);
  });

  testWidgets('a seta volta a quem abriu', (tester) async {
    await pump(tester, D2Paths.pilaresPlan);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('quem tem o curso vai ao Guia', (tester) async {
    purchases.state = purchases.state.copyWith(
      access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
    );
    await pump(tester, D2Paths.pilaresPlan);
    expect(find.byKey(PurchaseKeys.planSaleScreen), findsNothing);
    expect(find.textContaining('treino /training/pilares'), findsOneWidget);
  });

  // O arquivo real é privado: fora do checkout com o lucena-utils, pula.
  final real = File('assets/courses/pt/pilares_venda.json');
  testWidgets('a lista traz os 20 capítulos na ordem do currículo', (
    tester,
  ) async {
    final json = jsonDecode(real.readAsStringSync()) as Map<String, dynamic>;
    await pump(
      tester,
      D2Paths.pilaresPlan,
      preview: CoursePreview.fromJson(json),
    );
    await tester.scrollUntilVisible(
      find.byKey(PurchaseKeys.planSaleChapters),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final chips = find.descendant(
      of: find.byKey(PurchaseKeys.planSaleChapters),
      matching: find.byType(Text),
    );
    final titles = [
      for (final element in chips.evaluate()) (element.widget as Text).data,
    ];
    expect(titles, hasLength(20));
    expect(titles.first, 'Ataque duplo e peças soltas');
    expect(titles.sublist(8, 12), [
      'Fraquezas de peões',
      'Cadeias e peões passados',
      'Estruturas típicas',
      'Casas e colunas',
    ]);
    expect(titles.last, 'Cálculo de variantes');
  }, skip: !real.existsSync());
}
