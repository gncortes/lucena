import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/course_preview.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/course_preview/view_models/course_preview_cubit.dart';
import 'package:lucena/ui/course_preview/widgets/course_details_screen.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';
import '../core/motion/entrada_helpers.dart';

/// A prévia que só chega quando o teste deixa (H-ANI-07).
class _Lenta implements CoursePreviewRepository {
  final pronta = Completer<CoursePreview?>();

  @override
  Future<CoursePreview?> load() => pronta.future;
}

/// Animações da venda: apresentação (`PropV2CursoApresentacao`) e Sobre o
/// Pilares (`PropV1CursoDetalhes`).
void main() {
  final preview = FakeCoursePreviewRepository.example();

  Future<GoRouter> abrir(
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
          RepositoryProvider<CoursePreviewRepository>.value(
            value: FakeCoursePreviewRepository(preview: preview),
          ),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<AccountRepository>.value(
            value: FakeAccountRepository(),
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
    return router;
  }

  Finder rolagem() => find
      .descendant(
        of: find.byKey(CoursePreviewKeys.saleScroll),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Rola até a aba (que fica fixa na barra) e a deixa visível.
  Future<Finder> aba(WidgetTester tester, int i) async {
    final tab = find.byKey(CoursePreviewKeys.tab(i));
    await tester.scrollUntilVisible(tab, 200, scrollable: rolagem());
    await tester.pumpAndSettle();
    return tab;
  }

  Finder item(int i) => find.byKey(MotionKeys.itemDaCascata(i));

  testWidgets('H-ANI-16: o topo da venda entra em cascata e o número conta', (
    tester,
  ) async {
    await abrir(tester, D2Paths.pilaresPresentation, esperar: false);
    expect(opacidade(tester, item(0)), lessThan(1));
    await tester.pumpAndSettle();
    for (var i = 0; item(i).evaluate().isNotEmpty; i++) {
      expect(opacidade(tester, item(i)), 1, reason: 'item $i');
    }
    expect(item(1), findsOneWidget);
    expect(find.text('100+'), findsOneWidget);
    expect(find.byKey(CoursePreviewKeys.benefit(0)), findsOneWidget);
  });

  testWidgets('H-ANI-05: o indicador desliza e o botão fixo não se mexe', (
    tester,
  ) async {
    await abrir(tester, D2Paths.pilaresPresentation);
    final tab1 = await aba(tester, 1);
    final botao = tester.getRect(find.byKey(CoursePreviewKeys.buy));
    final antes = tester.getRect(find.byKey(MotionKeys.indicadorDaAba)).left;
    await tester.tap(tab1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    final meio = tester.getRect(find.byKey(MotionKeys.indicadorDaAba)).left;
    expect(tester.getRect(find.byKey(CoursePreviewKeys.buy)), botao);
    await tester.pumpAndSettle();
    final depois = tester.getRect(find.byKey(MotionKeys.indicadorDaAba)).left;
    expect(meio, greaterThan(antes));
    expect(meio, lessThan(depois));
    expect(tester.getRect(find.byKey(CoursePreviewKeys.buy)), botao);
  });

  testWidgets('H-ANI-22: a dúvida abre em altura animada e a seta gira', (
    tester,
  ) async {
    await abrir(tester, D2Paths.pilaresPresentation);
    await tester.tap(await aba(tester, 2));
    await tester.pumpAndSettle();
    final faq = find.byKey(CoursePreviewKeys.faq(1));
    await tester.scrollUntilVisible(
      faq,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(CoursePreviewKeys.saleScroll),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final fechada = tester.getSize(faq).height;
    await tester.tap(faq);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final meio = tester.getSize(faq).height;
    await tester.pumpAndSettle();
    final aberta = tester.getSize(faq).height;
    expect(meio, greaterThan(fechada));
    expect(meio, lessThan(aberta));
    final seta = find.descendant(
      of: faq,
      matching: find.byKey(MotionKeys.setaDoAcordeao),
    );
    expect(tester.widget<AnimatedRotation>(seta).turns, .5);
  });

  testWidgets('H-ANI-13: as barras do comparativo enchem', (tester) async {
    await abrir(tester, D2Paths.pilaresPresentation, esperar: false);
    final barras = find.descendant(
      of: find.byKey(CoursePreviewKeys.costCompare, skipOffstage: false),
      matching: find.byType(LinearProgressIndicator, skipOffstage: false),
    );
    expect(barras, findsWidgets);
    double soma() => tester
        .widgetList<LinearProgressIndicator>(barras)
        .fold(0, (s, b) => s + (b.value ?? 0));
    final inicio = soma();
    await tester.pumpAndSettle();
    expect(soma(), greaterThan(inicio));
  });

  testWidgets('H-ANI-20: o cartão "Para quem é" afunda no toque', (
    tester,
  ) async {
    await abrir(tester, D2Paths.pilaresPresentation);
    final cartao = find.byKey(CoursePreviewKeys.audience);
    await tester.scrollUntilVisible(
      cartao,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(CoursePreviewKeys.saleScroll),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final dedo = await tester.startGesture(tester.getCenter(cartao));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final t = find.descendant(
      of: find.byKey(MotionKeys.cartaoPressionado),
      matching: find.byType(Transform),
    );
    expect(tester.widget<Transform>(t.first).transform.storage[0], lessThan(1));
    await dedo.up();
    await tester.pumpAndSettle();
  });

  group('Sobre o Pilares', () {
    testWidgets('H-ANI-17 e 16: passos com conector e cascata na visão geral', (
      tester,
    ) async {
      await abrir(tester, D2Paths.pilaresAbout, esperar: false);
      expect(opacidade(tester, item(0)), lessThan(1));
      await tester.pumpAndSettle();
      expect(opacidade(tester, item(0)), 1);
      expect(find.byKey(MotionKeys.passo(0)), findsOneWidget);
      expect(find.byKey(MotionKeys.conector(0)), findsOneWidget);
    });

    testWidgets('H-ANI-05: trocar de aba cruza o corpo em 450 ms', (
      tester,
    ) async {
      await abrir(tester, D2Paths.pilaresAbout);
      await tester.tap(find.byKey(CoursePreviewKeys.detailsTab(1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 225));
      expect(find.byKey(MotionKeys.corpoDasAbas), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byKey(MotionKeys.corpoDasAbas), findsOneWidget);
    });

    testWidgets('H-ANI-07: o esqueleto brilha até a prévia chegar', (
      tester,
    ) async {
      final repo = _Lenta();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider(
            create: (_) =>
                CoursePreviewCubit(repo, FakeCharacterRepository())..load(),
            child: const CourseDetailsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
      repo.pronta.complete(preview);
      await tester.pumpAndSettle();
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
      expect(find.byKey(MotionKeys.shimmerConteudo), findsOneWidget);
    });
  });
}
