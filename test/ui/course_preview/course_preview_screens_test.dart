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
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/course_preview/widgets/course_details_screen.dart';
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
          path: '${Routes.training('pilares')}/help',
          builder: (context, _) => const Scaffold(
            body: Column(children: [Text('como funciona'), CourseAboutTile()]),
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
        find.descendant(
          of: cost,
          matching: find.byKey(MotionKeys.barraQueEnche),
        ),
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
      expect(find.byKey(CoursePreviewKeys.details), findsOneWidget);
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

  group('Sobre o Pilares (H-VEN-02)', () {
    Finder detailsScrollable() => find
        .descendant(
          of: find.byKey(CoursePreviewKeys.details),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<Finder> reveal(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: detailsScrollable(),
      );
      await tester.pumpAndSettle();
      return finder;
    }

    Future<void> openDetailsTab(WidgetTester tester, int i) async {
      await tester.tap(find.byKey(CoursePreviewKeys.detailsTab(i)));
      await tester.pumpAndSettle();
    }

    /// Abre "Como funciona" e toca no cartão "Sobre o Pilares".
    Future<GoRouter> openFromHelp(WidgetTester tester) async {
      final router = await pump(tester, '${Routes.training('pilares')}/help');
      await tester.tap(find.byKey(CoursePreviewKeys.aboutTile));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('1: o cartão da Ajuda abre a barra, 3 abas e Visão geral', (
      tester,
    ) async {
      await pump(tester, '${Routes.training('pilares')}/help');
      expect(find.text('Sobre o Pilares'), findsOneWidget);
      expect(
        find.text('Conteúdo, plano e dúvidas do Pilares do Xadrez.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CoursePreviewKeys.aboutTile));
      await tester.pumpAndSettle();
      expect(find.byKey(CoursePreviewKeys.details), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sobre o Pilares'),
        ),
        findsOneWidget,
      );
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(CoursePreviewKeys.detailsTab(i)), findsOneWidget);
      }
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(find.text('Como o curso funciona'), findsOneWidget);
      for (var i = 1; i <= 5; i++) {
        expect(find.text('Passo $i'), findsOneWidget);
      }
      expect(
        await reveal(tester, find.byKey(CoursePreviewKeys.detailsAudience)),
        findsOneWidget,
      );
    });

    testWidgets('2: Conteúdo com as partes e a Parte I aberta', (tester) async {
      await openFromHelp(tester);
      await openDetailsTab(tester, 1);
      expect(find.text('Resultado de exemplo'), findsOneWidget);
      expect(find.text('Sumário de exemplo.'), findsOneWidget);
      expect(find.byKey(CoursePreviewKeys.detailsPart(0)), findsOneWidget);
      expect(
        find.byKey(CoursePreviewKeys.summaryChapter(1), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(CoursePreviewKeys.summaryChapter(7), skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('3: Dúvidas com a primeira aberta; tocar abre outra', (
      tester,
    ) async {
      await openFromHelp(tester);
      await openDetailsTab(tester, 2);
      expect(find.text('Resposta de exemplo 1.'), findsOneWidget);
      expect(find.text('Resposta de exemplo 2.'), findsNothing);
      await tester.tap(
        await reveal(tester, find.byKey(CoursePreviewKeys.detailsFaq(1))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resposta de exemplo 2.'), findsOneWidget);
      // O Acordeão gira a mesma seta em meia volta (H-ANI-22).
      final seta = find.descendant(
        of: find.byKey(CoursePreviewKeys.detailsFaq(1)),
        matching: find.byKey(MotionKeys.setaDoAcordeao),
      );
      expect(tester.widget<AnimatedRotation>(seta).turns, .5);
    });

    testWidgets('5: a seta volta a "Como funciona", de qualquer aba', (
      tester,
    ) async {
      for (var i = 0; i < 3; i++) {
        await openFromHelp(tester);
        await openDetailsTab(tester, i);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byKey(CoursePreviewKeys.details), findsNothing);
        expect(find.text('como funciona'), findsOneWidget);
      }
    });

    testWidgets('5: aberta direto (comprador), a seta vai a "Como funciona"', (
      tester,
    ) async {
      await pump(tester, D2Paths.pilaresAbout);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('como funciona'), findsOneWidget);
    });
  });

  // 9: o texto real da venda só afirma e bate com o conteúdo (105, 20,
  // 850+). O arquivo é privado: fora do CI, o teste pula.
  final real = File('assets/courses/pt/pilares_venda.json');
  test('9: a venda real só afirma e traz 105 lições, 20 capítulos e 850+', () {
    final json = jsonDecode(real.readAsStringSync()) as Map<String, dynamic>;
    final sale = CoursePreview.fromJson(json).sale;
    expect(sale.title, 'Pilares do Xadrez');
    expect(sale.lessons, 105);
    expect(sale.chapters, 20);
    expect(sale.exercises, '850+');
    expect(sale.benefits, hasLength(8));
    expect(sale.faq, hasLength(8));
    // Sobre o Pilares (H-VEN-02): 5 partes que somam 105 e as 9 dúvidas.
    final details = CoursePreview.fromJson(json).details;
    expect(details.steps, hasLength(5));
    expect(details.faq, hasLength(9));
    expect(details.faq.first.question, 'Serve para o meu nível?');
    expect(sale.parts.map((p) => p.lessons), [24, 17, 25, 21, 18]);
    // 4 e 6: o fim da assinatura e o tempo de acesso, sem valores.
    final ended = details.faq.singleWhere(
      (f) => f.question == 'O que acontece quando a assinatura termina?',
    );
    for (final part in ['progresso', 'Capítulo 1', 'anúncio', '2 a 20']) {
      expect(ended.answer, contains(part));
    }
    final access = details.faq.singleWhere(
      (f) => f.question == 'Por quanto tempo tenho acesso?',
    );
    expect(access.answer, contains('Acesso vitalício ao Pilares'));
    expect(access.answer, contains('assinatura mensal'));
    expect(access.answer.contains(r'R$'), isFalse);
    // Só a venda: o "Sobre o Pilares" explica regras ("sem dica").
    final text = jsonEncode(json['sale']).toLowerCase();
    for (final negation in ['não é um curso', ' sem ', 'nada de']) {
      expect(text.contains(negation), isFalse, reason: negation);
    }
  }, skip: real.existsSync() ? false : 'conteúdo privado fora do CI');
}
