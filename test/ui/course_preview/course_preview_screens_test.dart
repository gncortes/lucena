import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/course_preview.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/course_preview/widgets/course_sale_parts.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  final preview = FakeCoursePreviewRepository.example();
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

  /// A apresentação pelas rotas da D2, a partir de um Início de mentira.
  Future<GoRouter> pump(WidgetTester tester, String location) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('inicio')),
        ),
        GoRoute(
          path: D2Paths.pilaresAbout,
          builder: (_, _) => const Scaffold(body: Text('sobre')),
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
          settingsCubit: settings,
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

  Finder scrollable() => find
      .descendant(
        of: find.byKey(CoursePreviewKeys.saleScroll),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<Finder> show(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable());
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> openTab(WidgetTester tester, int i) async {
    final tab = find.byKey(CoursePreviewKeys.tab(i));
    await show(tester, tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  void expectTitleBar(WidgetTester tester) {
    final bars = tester.widgetList<SliverAppBar>(find.byType(SliverAppBar));
    expect(bars, hasLength(1));
    expect(bars.single.bottom, isNull);
    expect(
      find.descendant(
        of: find.byType(SliverAppBar),
        matching: find.text('Curso de exemplo'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SliverAppBar),
        matching: find.byType(BackButton),
      ),
      findsOneWidget,
    );
  }

  group('Apresentação (H-VEN-01)', () {
    testWidgets('1: título na barra, números e a fala do Viktor', (
      tester,
    ) async {
      await pump(tester, D2Paths.presentation(origin: 'home'));
      expect(find.byKey(CoursePreviewKeys.sale), findsOneWidget);
      expectTitleBar(tester);
      // O nome só na barra, nunca no corpo.
      expect(find.text('Curso de exemplo'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('100+'), findsOneWidget);
      expect(
        await show(tester, find.text('Conheça este exemplo de navegação.')),
        findsOneWidget,
      );
    });

    testWidgets('2: os 8 itens em ordem, verde nos pares', (tester) async {
      await pump(tester, D2Paths.pilaresPresentation);
      for (var i = 0; i < 8; i++) {
        final item = await show(
          tester,
          find.byKey(CoursePreviewKeys.benefit(i)),
        );
        expect(
          find.descendant(of: item, matching: find.text('Benefício ${i + 1}')),
          findsOneWidget,
        );
        expect(tester.widget<SaleIconLine>(item).green, i.isOdd);
        if (i > 0) {
          expect(
            tester.getTopLeft(item).dy,
            greaterThan(
              tester
                  .getTopLeft(find.byKey(CoursePreviewKeys.benefit(i - 1)))
                  .dy,
            ),
          );
        }
      }
    });

    testWidgets('3: preço da loja, nota e o mensal', (tester) async {
      await pump(tester, D2Paths.pilaresPresentation);
      final card = await show(tester, find.byKey(CoursePreviewKeys.priceCard));
      expect(
        find.descendant(of: card, matching: find.text(r'R$ 99,90')),
        findsOneWidget,
      );
      expect(find.text('Nota ilustrativa.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CoursePreviewKeys.planMonthly),
          matching: find.text(r'R$ 19,90/mês'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3: sem resposta da loja, os valores de referência', (
      tester,
    ) async {
      purchases = FakePurchaseRepository(const PurchaseState());
      await pump(tester, D2Paths.pilaresPresentation);
      final card = await show(tester, find.byKey(CoursePreviewKeys.priceCard));
      expect(
        find.descendant(of: card, matching: find.text(r'R$ 99,90')),
        findsOneWidget,
      );
      expect(find.text(r'R$ 19,90/mês'), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('4: o comparativo com as linhas, a soma e a fonte', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresPresentation);
      final cost = await show(
        tester,
        find.byKey(CoursePreviewKeys.costCompare),
      );
      for (final text in [
        'Custo de exemplo',
        'Opção A',
        r'R$ 100',
        r'R$ 300 a R$ 1.000',
        'Linha do curso',
        r'R$ 200',
        'Nota B.',
        'Fonte ilustrativa.',
        r'R$ 99,90',
      ]) {
        expect(
          find.descendant(of: cost, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(
        find.descendant(of: cost, matching: find.byType(FractionallySizedBox)),
        findsNWidgets(2),
      );
    });

    testWidgets('5: rolando, a barra mantém o título e as abas ficam fixas', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresPresentation);
      await openTab(tester, 1);
      await tester.drag(scrollable(), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expectTitleBar(tester);
      final tab = tester.getTopLeft(find.byKey(CoursePreviewKeys.tab(0)));
      expect(tab.dy, lessThan(200));
    });

    testWidgets('6: Ver opções de compra abre a oferta, de qualquer aba', (
      tester,
    ) async {
      for (final i in [0, 2]) {
        analytics = FakeAnalyticsRepository();
        await pump(tester, D2Paths.presentation(origin: 'home'));
        await openTab(tester, i);
        await tester.tap(find.byKey(CoursePreviewKeys.buy));
        await tester.pumpAndSettle();
        expect(find.byKey(PurchaseKeys.offerScreen), findsOneWidget);
        expect(
          analytics
              .eventsNamed('pilares_oferta_vista')
              .map((e) => (e.params['destaque'], e.params['origem'])),
          [('apresentacao', 'home'), ('oferta', 'home')],
        );
      }
    });

    testWidgets('7: o cartão abre "Para quem é" e o voltar retorna', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresPresentation);
      await tester.tap(
        await show(tester, find.byKey(CoursePreviewKeys.audience)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(CoursePreviewKeys.band), findsOneWidget);
      expect(find.text('Tema de exemplo'), findsOneWidget);
      expect(find.text('12,5 %'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(BackButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(CoursePreviewKeys.sale), findsOneWidget);
    });

    testWidgets('8: quem comprou vai ao Sobre o Pilares', (tester) async {
      purchases.state = purchases.state.copyWith(
        access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
      );
      await pump(tester, D2Paths.pilaresPresentation);
      expect(find.byKey(CoursePreviewKeys.sale), findsNothing);
      expect(find.text('sobre'), findsOneWidget);
    });

    testWidgets('conteúdo: Parte I aberta, lições numeradas, teste e '
        'aberturas', (tester) async {
      await pump(tester, D2Paths.pilaresPresentation);
      await openTab(tester, 1);
      expect(
        await show(tester, find.byKey(CoursePreviewKeys.summaryChapter(1))),
        findsOneWidget,
      );
      expect(find.text('1.1'), findsOneWidget);
      expect(find.text('Exemplo 1.1'), findsOneWidget);
      expect(find.text('1.4'), findsOneWidget);
      expect(
        find.text('Teste do capítulo · $saleChapterTestCount exercícios'),
        findsNWidgets(6),
      );
      expect(find.text('Abertura de exemplo'), findsOneWidget);
      expect(
        find.byKey(CoursePreviewKeys.summaryChapter(7), skipOffstage: false),
        findsNothing,
      );
      await tester.tap(
        await show(tester, find.byKey(CoursePreviewKeys.partHeader('II'))),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(CoursePreviewKeys.summaryChapter(7), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('dúvidas: a primeira aberta, tocar abre outra', (tester) async {
      await pump(tester, D2Paths.pilaresPresentation);
      await openTab(tester, 2);
      expect(find.text('Resposta ilustrativa 1.'), findsOneWidget);
      expect(find.text('Resposta ilustrativa 2.'), findsNothing);
      await tester.tap(
        await show(tester, find.byKey(CoursePreviewKeys.faq(1))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resposta ilustrativa 2.'), findsOneWidget);
    });

    testWidgets('abrir registra a oferta vista com o destaque apresentacao', (
      tester,
    ) async {
      await pump(tester, D2Paths.presentation(origin: 'metas'));
      final events = analytics.eventsNamed('pilares_oferta_vista');
      expect(events, hasLength(1));
      expect(events.single.params, containsPair('destaque', 'apresentacao'));
      expect(events.single.params, containsPair('origem', 'metas'));
    });
  });

  // 9: o texto real da venda só afirma e bate com o conteúdo (105, 20,
  // 850+). O arquivo é privado: fora do CI, o teste pula.
  final real = File('assets/courses/pt/pilares_venda.json');
  test('9: a venda real só afirma e traz 105 lições, 20 capítulos e 850+', () {
    final raw = real.readAsStringSync();
    final sale = CoursePreview.fromJson(jsonDecode(raw) as Map<String, dynamic>)
        .sale;
    expect(sale.title, 'Pilares do Xadrez');
    expect(sale.lessons, 105);
    expect(sale.chapters, 20);
    expect(sale.exercises, '850+');
    expect(sale.benefits, hasLength(8));
    expect(sale.faq, hasLength(8));
    final text = raw.toLowerCase();
    for (final negation in ['não é um curso', ' sem ', 'nada de']) {
      expect(text.contains(negation), isFalse, reason: negation);
    }
  }, skip: real.existsSync() ? false : 'conteúdo privado fora do CI');
}
