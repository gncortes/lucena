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
import 'package:lucena/ui/lesson_ad/widgets/lesson_entry.dart';

import '../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../testing/fakes/fake_now.dart';

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
          builder: (_, _) => const Scaffold(body: Text('apresentação')),
        ),
        GoRoute(
          name: RouteNames.pilaresOffer,
          path: '/oferta',
          builder: (_, _) => const Scaffold(body: Text('oferta')),
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
    expect(find.text('apresentação'), findsOneWidget);
    final nav = Navigator.of(t.element(find.text('apresentação')));
    nav.pop();
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.screen), findsOneWidget);
  });

  testWidgets('anúncio que não carrega: tentar de novo e voltar', (t) async {
    final h = _Harness(seen: true);
    h.ads.loads = [false, false, true];
    await h.pump(t);
    await t.tap(find.byKey(_openKey));
    await t.pumpAndSettle();
    expect(find.text('Não foi possível carregar o anúncio'), findsOneWidget);
    expect(
      find.text(
        'Sem o anúncio, não é possível abrir a lição. Verifique sua conexão com a internet.',
      ),
      findsOneWidget,
    );
    await t.tap(find.byKey(AdsKeys.adFailedRetry));
    await t.pumpAndSettle();
    expect(h.ads.loadCalls, 2);
    expect(find.byKey(AdsKeys.failed), findsOneWidget);
    await t.tap(find.byKey(AdsKeys.adFailedBack));
    await t.pumpAndSettle();
    expect(find.byKey(_lessonKey), findsNothing);
    expect(find.byKey(_openKey), findsOneWidget);
  });

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
    expect(find.text('oferta'), findsOneWidget);
  });

  testWidgets('capítulo trancado: Agora não só fecha a folha', (t) async {
    final h = _Harness();
    await h.pump(t);
    await t.tap(find.byKey(_chapterKey));
    await t.pumpAndSettle();
    await t.tap(find.byKey(AdsKeys.demoLockedSheetLater));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.lockedSheet), findsNothing);
    expect(find.text('oferta'), findsNothing);
  });

  testWidgets('comprador toca o capítulo 2 sem folha', (t) async {
    final h = _Harness(access: CourseAccess.owned);
    await h.pump(t);
    await t.tap(find.byKey(_chapterKey));
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.lockedSheet), findsNothing);
  });

  testWidgets('rota do anúncio sem a lição volta ao início', (t) async {
    final h = _Harness(seen: true);
    await h.pump(t);
    GoRouter.of(t.element(find.byKey(_openKey))).go(D1Paths.lessonAd);
    await t.pumpAndSettle();
    expect(find.byKey(AdsKeys.screen), findsNothing);
  });
}
