import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/motion/rota_que_abre.dart';
import 'package:lucena/ui/pilares_sale/widgets/pilares_demo_tabs.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';

/// H-ANI-04 por rota na Venda: a apresentação do Pilares (`/pilares`) cresce
/// do cartão "Conhecer o Pilares" da demo (a [OrigemQueAbre] "venda").
void main() {
  Future<void> abrir(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: PilaresDemoCallout(
                text: 'Pilares',
                buttonKey: PurchaseKeys.demoCatalogLearnMore,
                origin: 'catalogo',
              ),
            ),
          ),
        ),
        ...d2Routes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CoursePreviewRepository>.value(
            value: FakeCoursePreviewRepository(
              preview: FakeCoursePreviewRepository.example(),
            ),
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
  }

  testWidgets('a chamada da demo é a origem "venda" da apresentação', (
    tester,
  ) async {
    await abrir(tester);
    final origem = find.ancestor(
      of: find.byKey(PurchaseKeys.demoCatalogLearnMore),
      matching: find.byType(OrigemQueAbre),
    );
    expect(origem, findsOneWidget);
    expect(tester.widget<OrigemQueAbre>(origem).id, pilaresSaleOrigin);
  });

  testWidgets('"Conhecer o Pilares": a apresentação cresce do cartão', (
    tester,
  ) async {
    await abrir(tester);
    final cartao = tester.getRect(
      find.ancestor(
        of: find.byKey(PurchaseKeys.demoCatalogLearnMore),
        matching: find.byType(OrigemQueAbre),
      ),
    );
    await tester.tap(find.byKey(PurchaseKeys.demoCatalogLearnMore));
    await tester.pump();
    await tester.pump();
    final quadro = find.byKey(MotionKeys.rotaQueAbre);
    expect(quadro, findsOneWidget);
    expect(tester.getRect(quadro).top, closeTo(cartao.top, 2));
    // Venda: 560 ms até a tela inteira.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
    expect(find.byKey(CoursePreviewKeys.sale), findsOneWidget);
  });
}
