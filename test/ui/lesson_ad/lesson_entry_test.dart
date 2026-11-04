import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/lesson_ad/course_access_repository.dart';
import 'package:lucena/data/repositories/lesson_ad/demo_ad_repository.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/use_cases/ad_policy.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/routing/frentes/d1_routes.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/ui/core/keys/ads_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/lesson_ad/widgets/lesson_entry.dart';

import '../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/motion_expectations.dart';

const _lessonKey = Key('test.lesson');
const _openKey = Key('test.open');
const _chapterKey = Key('test.chapter');

class _Harness {
  _Harness({CourseAccess access = CourseAccess.demo, bool seen = false})
    : access = FakeCourseAccessRepository(access),
      ads = FakeDemoAdRepository(seen: seen);

  final FakeCourseAccessRepository access;
  final FakeDemoAdRepository ads;
  final now = FakeNow(DateTime(2026, 11, 4, 9));
  final vistas = EntradasVistas();
  DemoAdEntry entry = DemoAdEntry.lesson;

  Future<void> pump(WidgetTester t) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: _openKey,
                  onPressed: () => LessonEntry.open(
                    context,
                    lessonId: 'pilares.c1.garfo',
                    lessonTitle: 'Garfo de cavalo',
                    entry: entry,
                    open: () => context.go('/lesson'),
                  ),
                  child: const Text('abrir'),
                ),
                TextButton(
                  key: _chapterKey,
                  onPressed: () => LessonEntry.openChapter(
                    context,
                    chapterId: 'pilares.c2',
                    chapterTitle: 'Capítulo 2 · Golpes em linha',
                  ),
                  child: const Text('capitulo'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/lesson',
          builder: (_, _) => const Scaffold(key: _lessonKey),
        ),
        GoRoute(
          name: RouteNames.pilaresPresentation,
          path: '/apresentacao',
          builder: (_, state) => Scaffold(
            body: Text('apresentação ${state.uri.queryParameters['origem']}'),
          ),
        ),
        GoRoute(
          name: RouteNames.pilaresOffer,
          path: '/oferta',
          builder: (_, state) => Scaffold(
            body: Text('oferta ${state.uri.queryParameters['origem']}'),
          ),
        ),
        ...d1Routes,
      ],
    );
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CourseAccessRepository>.value(value: access),
          RepositoryProvider<DemoAdRepository>.value(value: ads),
          RepositoryProvider<Now>.value(value: now),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          // Como no app: as entradas vistas valem acima do Navigator.
          builder: (_, child) => EntradasVistasEscopo(
            vistas: vistas,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  /// Anda o relógio e a tela juntos.
  Future<void> wait(WidgetTester t, Duration total) async {
    for (
      var d = Duration.zero;
      d < total;
      d += const Duration(milliseconds: 100)
    ) {
      now.advance(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  testWidgets('comprador abre a lição sem aviso nem anúncio', (t) async {
    final h = _Harness(access: CourseAccess.owned);
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    expect(find.byKey(_lessonKey), findsOneWidget);
    expect(find.byKey(AdsKeys.noticeSheet), findsNothing);
  });

  testWidgets('demo vê o aviso uma vez, depois o anúncio com contagem', (
    t,
  ) async {
    final h = _Harness();
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    expect(find.text('Antes da lição, um anúncio'), findsOneWidget);
    expect(h.ads.marks, 1);
    await t.tap(find.byKey(AdsKeys.demoAdNoticeSee));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.screen), findsOneWidget);
    expect(find.text('Anúncio'), findsOneWidget);
    expect(find.text('Depois do anúncio: Garfo de cavalo'), findsOneWidget);
    expect(find.text('Fechar em 3'), findsOneWidget);
    // Tocar antes de zerar não fecha.
    await t.tap(find.byKey(AdsKeys.adCloseButton));
    await t.pump();
    expect(find.byKey(AdsKeys.screen), findsOneWidget);
    await h.wait(t, const Duration(milliseconds: 1100));
    expect(find.text('Fechar em 2'), findsOneWidget);
    await h.wait(t, const Duration(seconds: 1));
    expect(find.text('Fechar em 1'), findsOneWidget);
    await h.wait(t, const Duration(seconds: 1));
    expect(find.text('Fechar'), findsOneWidget);
    await t.tap(find.byKey(AdsKeys.adCloseButton));
    await t.pumpAndSettle();
    expect(find.byKey(_lessonKey), findsOneWidget);
  });

  testWidgets(
    'H-ANI-31: a barra do anúncio usa o kit e conta 3, 2, 1, Fechar',
    (t) async {
      final h = _Harness(seen: true);
      await h.pump(t);
      await t.tap(find.byKey(_openKey));
      await t.pumpAndSettle();
      // "Conhecer o Pilares" entra com ConhecerQueEntra; o fechar é a contagem.
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.conhecerDoAnuncio),
          matching: find.byKey(AdsKeys.learnMore),
        ),
        findsOneWidget,
      );
      final contagem = find.byKey(MotionKeys.contagemParaFechar);
      expect(
        find.descendant(of: contagem, matching: find.text('Fechar em 3')),
        findsOneWidget,
      );
      final vistos = <String>[];
      for (var i = 0; i < 40; i++) {
        final texto = t
            .widgetList<Text>(
              find.descendant(of: contagem, matching: find.byType(Text)),
            )
            .last
            .data!;
        if (vistos.isEmpty || vistos.last != texto) vistos.add(texto);
        if (texto != 'Fechar') {
          // Antes de "Fechar", tocar não fecha.
          await t.tap(contagem, warnIfMissed: false);
          await t.pump();
          expect(find.byKey(AdsKeys.screen), findsOneWidget);
        }
        await h.wait(t, const Duration(milliseconds: 100));
      }
      expect(vistos, ['Fechar em 3', 'Fechar em 2', 'Fechar em 1', 'Fechar']);
      await t.pumpAndSettle();
      await t.tap(contagem);
      await t.pumpAndSettle();
      expect(find.byKey(_lessonKey), findsOneWidget);
    },
  );

  testWidgets(
    'H-ANI-31: movimento reduzido, tudo no lugar no primeiro quadro',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final h = _Harness(seen: true);
      await h.pump(t);
      await t.tap(find.byKey(_openKey));
      await t.pumpAndSettle();
      final conhecer = find.byKey(MotionKeys.conhecerDoAnuncio);
      expect(conhecer, findsOneWidget);
      expect(opacidadeDaParte(t, find.byKey(AdsKeys.learnMore)), 1);
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.contagemParaFechar),
          matching: find.text('Fechar em 3'),
        ),
        findsOneWidget,
      );
      await h.wait(t, const Duration(milliseconds: 1100));
      expect(find.text('Fechar em 2'), findsOneWidget);
    },
  );

  testWidgets('segunda entrada vai direto ao anúncio, sem aviso', (t) async {
    final h = _Harness(seen: true);
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.noticeSheet), findsNothing);
    expect(find.byKey(AdsKeys.screen), findsOneWidget);
  });

  testWidgets('Agora não no aviso volta sem abrir a lição', (t) async {
    final h = _Harness();
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    await t.tap(find.byKey(AdsKeys.demoAdNoticeLater));
    await t.pumpAndSettle();
    expect(find.byKey(_lessonKey), findsNothing);
    expect(find.byKey(AdsKeys.screen), findsNothing);
    expect(find.byKey(_openKey), findsOneWidget);
  });

  testWidgets('assinatura vencida conta como demo', (t) async {
    final h = _Harness(access: CourseAccess.subscriptionEnded, seen: true);
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.screen), findsOneWidget);
  });

  testWidgets('dentro da lição e no teste não há anúncio', (t) async {
    for (final entry in [DemoAdEntry.insideLesson, DemoAdEntry.test]) {
      final h = _Harness(seen: true)..entry = entry;
      await h.pump(t);
      await t.tap(find.byKey(_openKey));
      await t.pumpAndSettle();
      expect(find.byKey(_lessonKey), findsOneWidget, reason: '$entry');
    }
  });

  testWidgets('Conhecer o Pilares abre a apresentação e volta ao anúncio', (
    t,
  ) async {
    final h = _Harness(seen: true);
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    await t.tap(find.byKey(AdsKeys.learnMore));
    await t.pumpAndSettle();
    // H-LIC-12: pilares_oferta_vista com origem=anuncio.
    expect(find.text('apresentação anuncio'), findsOneWidget);
    final nav = Navigator.of(t.element(find.text('apresentação anuncio')));
    nav.pop();
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.screen), findsOneWidget);
  });

  testWidgets(
    'anúncio que não carrega: tentar de novo e Conhecer o Pilares (H-VEN-13)',
    (t) async {
      final h = _Harness(seen: true);
      h.ads.loads = [false, false, true];
      await h.pump(t);
      await t.tap(find.byKey(_openKey));
      await t.pumpAndSettle();
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(
        find.text(
          'A lição abre depois do anúncio. Confira a internet e tente de novo, ou abra direto com o Pilares.',
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(AdsKeys.adFailedRetry));
      await t.pumpAndSettle();
      expect(h.ads.loadCalls, 2);
      expect(find.byKey(AdsKeys.failed), findsOneWidget);
      expect(find.text('Conhecer o Pilares'), findsOneWidget);
      await t.tap(find.byKey(AdsKeys.adFailedLearnMore));
      await t.pumpAndSettle();
      expect(find.text('apresentação anuncio'), findsOneWidget);
      // Voltar da apresentação reabre a falha, sem perder a lição escolhida.
      Navigator.of(t.element(find.text('apresentação anuncio'))).pop();
      await t.pumpAndSettle();
      expect(find.byKey(AdsKeys.failed), findsOneWidget);
      await t.tap(find.byKey(AdsKeys.adFailedRetry));
      await t.pumpAndSettle();
      expect(find.byKey(AdsKeys.screen), findsOneWidget);
      expect(find.byKey(_lessonKey), findsNothing);
    },
  );

  testWidgets(
    'H-ANI-24: a falha do anúncio entra com calma só na primeira vez',
    (t) async {
      final h = _Harness(seen: true);
      h.ads.loads = [false, false, true];
      await h.pump(t);
      await t.tap(find.byKey(_openKey));
      for (
        var i = 0;
        i < 20 && find.byKey(AdsKeys.failed).evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.textoDoEstado),
          matching: find.text('Ocorreu um erro inesperado'),
        ),
        findsOneWidget,
      );
      expect(opacidadeDaParte(t, find.byKey(MotionKeys.textoDoEstado)), 0);
      await t.pumpAndSettle();
      expect(opacidadeDaParte(t, find.byKey(MotionKeys.textoDoEstado)), 1);
      // Os botões ficam no rodapé, fora da entrada.
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.acaoDoEstado),
          matching: find.byKey(AdsKeys.adFailedRetry),
        ),
        findsNothing,
      );
      // Falhou de novo: o estado volta pronto.
      await t.tap(find.byKey(AdsKeys.adFailedRetry));
      await t.pump();
      await t.pump();
      expect(find.byKey(AdsKeys.failed), findsOneWidget);
      expect(opacidadeDaParte(t, find.byKey(MotionKeys.textoDoEstado)), 1);
      await t.pumpAndSettle();
    },
  );

  testWidgets('capítulo trancado mostra a folha; Comprar abre a oferta', (
    t,
  ) async {
    final h = _Harness();
    await h.pump(t);
    await t.tap(find.byKey(_chapterKey));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.lockedSheet), findsOneWidget);
    expect(find.text('Capítulo 2 · Golpes em linha'), findsOneWidget);
    await t.tap(find.byKey(AdsKeys.demoLockedSheetBuy));
    await t.pumpAndSettle();
    // H-LIC-06: o cadeado do capítulo abre a oferta com origem=catalogo.
    expect(find.text('oferta catalogo'), findsOneWidget);
  });

  testWidgets('capítulo trancado: Agora não só fecha a folha', (t) async {
    final h = _Harness();
    await h.pump(t);
    await t.tap(find.byKey(_chapterKey));
    await t.pumpAndSettle();
    await t.tap(find.byKey(AdsKeys.demoLockedSheetLater));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.lockedSheet), findsNothing);
    expect(find.textContaining('oferta'), findsNothing);
  });

  testWidgets('comprador toca o capítulo 2 sem folha', (t) async {
    final h = _Harness(access: CourseAccess.owned);
    await h.pump(t);
    await t.tap(find.byKey(_chapterKey));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.lockedSheet), findsNothing);
  });

  group('H-ANI-16 nas folhas da demonstração', () {
    for (final reduced in [false, true]) {
      testWidgets(
        'aviso: a cascata espera a folha parar (reduzido: $reduced)',
        (t) async {
          t.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: reduced);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
          final h = _Harness();
          await h.pump(t);
          await t.tap(find.byKey(_openKey));
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
          // Título, texto e os dois botões, o principal antes do "Agora não".
          expectEntradaEmCascata(t, itens: 4, animando: !reduced);
          expect(
            find.descendant(
              of: find.byKey(MotionKeys.itemDaCascata(2)),
              matching: find.byKey(AdsKeys.demoAdNoticeSee),
            ),
            findsOneWidget,
          );
          // A folha ainda sobe: nem o título começou.
          expect(
            opacidadeDaParte(t, find.byKey(MotionKeys.itemDaCascata(0))),
            reduced ? 1 : 0,
          );
          await t.pumpAndSettle();
          expect(
            opacidadeDaParte(t, find.byKey(MotionKeys.itemDaCascata(3))),
            1,
          );
          await t.tap(find.byKey(AdsKeys.demoAdNoticeLater));
          await t.pumpAndSettle();
        },
      );
    }

    testWidgets('capítulo trancado: na segunda vez a folha já vem pronta', (
      t,
    ) async {
      final h = _Harness();
      await h.pump(t);
      await t.tap(find.byKey(_chapterKey));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expectEntradaEmCascata(t, itens: 4, animando: true);
      await t.pumpAndSettle();
      await t.tap(find.byKey(AdsKeys.demoLockedSheetLater));
      await t.pumpAndSettle();
      await t.tap(find.byKey(_chapterKey));
      await t.pump();
      expectEntradaEmCascata(t, itens: 4, animando: false);
      await t.pumpAndSettle();
    });
  });

  testWidgets('rota do anúncio sem a lição volta ao início', (t) async {
    final h = _Harness(seen: true);
    await h.pump(t);
    GoRouter.of(t.element(find.byKey(_openKey))).go(D1Paths.lessonAd);
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.screen), findsNothing);
  });
}
