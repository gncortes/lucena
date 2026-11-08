import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/motion/valor_que_anima.dart';
import 'package:lucena/ui/pilares_sale/widgets/pilares_demo_catalog.dart';
import 'package:lucena/ui/pilares_sale/widgets/pilares_sale_parts.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';
import '../core/motion/entrada_helpers.dart';

/// Animações da venda do plano: `PropV2VendaPlano`, a folha antes do Início
/// e o Catálogo da demonstração.
void main() {
  Future<void> abrir(
    WidgetTester tester,
    String location, {
    bool esperar = true,
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
              preview: FakeCoursePreviewRepository.example(),
            ),
          ),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          purchaseRepository: FakePurchaseRepository(
            const PurchaseState(
              pricesReady: true,
              prices: {
                PilaresPlan.lifetime: r'R$ 99,90',
                PilaresPlan.monthly: r'R$ 19,90',
              },
            ),
          ),
          router: router,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push(location);
    if (esperar) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder item(int i) => find.byKey(MotionKeys.itemDaCascata(i));

  void expectTodosProntos(WidgetTester tester) {
    var n = 0;
    for (var i = 0; item(i).evaluate().isNotEmpty; i++, n++) {
      expect(opacidade(tester, item(i)), 1, reason: 'item $i');
    }
    expect(n, greaterThan(1));
  }

  testWidgets('H-ANI-16: a venda do plano entra em cascata, com o número '
      'contando e o botão fixo', (tester) async {
    await abrir(tester, D2Paths.pilaresPlan, esperar: false);
    expect(opacidade(tester, item(0)), lessThan(1));
    expect(find.byKey(PurchaseKeys.planSaleStart), findsOneWidget);
    await tester.pumpAndSettle();
    expectTodosProntos(tester);
    expect(find.text('100+'), findsOneWidget);
    expect(find.byKey(PurchaseKeys.planSaleChapters), findsOneWidget);
  });

  testWidgets('H-ANI-16: a folha antes do Início entra em cascata, o X já '
      'aparece e o botão é o último', (tester) async {
    await abrir(tester, D2Paths.pilaresBeforeHome, esperar: false);
    expect(find.byKey(PurchaseKeys.beforeHomeClose), findsOneWidget);
    expect(opacidade(tester, item(0)), lessThan(1));
    await tester.pumpAndSettle();
    expectTodosProntos(tester);
    expect(find.byKey(PurchaseKeys.beforeHomeLearn), findsOneWidget);
  });

  testWidgets('H-ANI-26: o plano marcado troca de contorno', (tester) async {
    Widget cartao(bool marcado) => TestApp(
      locale: const Locale('pt'),
      child: Scaffold(
        body: PilaresPlanCard(
          title: 'Vitalício',
          text: 'Para sempre',
          price: r'R$ 99,90',
          selected: marcado,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpWidget(cartao(false));
    expect(find.byKey(MotionKeys.contornoDoPlano), findsOneWidget);
    expect(find.byKey(MotionKeys.pontoDoPlano), findsOneWidget);
    Color borda() =>
        (tester.widget<Material>(find.byKey(MotionKeys.contornoDoPlano)).shape!
                as RoundedRectangleBorder)
            .side
            .color;
    final solto = borda();
    await tester.pumpWidget(cartao(true));
    await tester.pump(const Duration(milliseconds: 125));
    expect(borda(), isNot(solto));
    await tester.pumpAndSettle();
    expect(
      borda(),
      Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary,
    );
  });

  group('Catálogo da demonstração', () {
    TrainingLesson lesson(String id, String title) => TrainingLesson(
      id: id,
      kind: TrainingLessonKind.theme,
      title: title,
      groupId: 'pilares.c1',
      group: 'Ataque duplo',
      partId: 'pilares.p1',
      partTitle: 'Tática',
    );

    Future<void> catalogo(WidgetTester tester) => tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: PilaresDemoCatalog(
            lessons: [lesson('a', 'Garfo'), lesson('b', 'Cravada')],
            completed: const {'a'},
            nextLessonId: 'b',
            onLesson: (_) {},
            onChapter: (_) {},
          ),
        ),
      ),
    );

    testWidgets('H-ANI-17: os itens grátis entram em ordem', (tester) async {
      await catalogo(tester);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(MotionKeys.itemDaLista(0)), findsOneWidget);
      expect(find.byKey(MotionKeys.itemDaLista(1)), findsOneWidget);
      final primeiro = opacidade(tester, find.byKey(MotionKeys.itemDaLista(0)));
      final segundo = opacidade(tester, find.byKey(MotionKeys.itemDaLista(1)));
      expect(segundo, lessThanOrEqualTo(primeiro));
      await tester.pumpAndSettle();
      expect(opacidade(tester, find.byKey(MotionKeys.itemDaLista(1))), 1);
    });

    testWidgets('H-ANI-13: a barra do cartão do topo enche até a metade', (
      tester,
    ) async {
      await catalogo(tester);
      LinearProgressIndicator barra() => tester.widget(
        find.descendant(
          of: find.byKey(PurchaseKeys.demoCatalogBanner),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(barra().value, lessThan(.5));
      await tester.pumpAndSettle();
      expect(barra().value, .5);
    });

    testWidgets('H-ANI-18: o "1 de 2 concluídos" do topo conta até o valor', (
      tester,
    ) async {
      await catalogo(tester);
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        find.ancestor(
          of: find.text('0 de 2 concluídos'),
          matching: find.byType(ValorQueAnima),
        ),
        findsOneWidget,
      );
      expect(find.text('0 de 2 concluídos'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('1 de 2 concluídos'), findsOneWidget);
    });

    testWidgets('H-ANI-20: cada item grátis é um cartão pressionável', (
      tester,
    ) async {
      await catalogo(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(MotionKeys.cartaoPressionado), findsNWidgets(2));
      expect(find.byKey(CourseGuideKeys.chapterLesson('a')), findsOneWidget);
    });
  });
}
