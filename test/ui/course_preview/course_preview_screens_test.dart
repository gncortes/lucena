import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_preview_keys.dart';
import 'package:lucena/ui/course_preview/view_models/course_preview_cubit.dart';
import 'package:lucena/ui/course_preview/widgets/course_band_preview_screen.dart';
import 'package:lucena/ui/course_preview/widgets/course_chapter_preview_screen.dart';
import 'package:lucena/ui/course_preview/widgets/course_map_preview_screen.dart';
import 'package:lucena/ui/course_preview/widgets/course_sale_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  final preview = FakeCoursePreviewRepository.real();

  /// As três telas da prévia nas mesmas rotas do app, em PT.
  Future<GoRouter> pump(
    WidgetTester tester, {
    String at = Routes.pilaresSale,
  }) async {
    final cubit = CoursePreviewCubit(
      FakeCoursePreviewRepository(preview: preview),
      FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    Widget provide(Widget child) =>
        BlocProvider.value(value: cubit, child: child);
    final router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(
          path: Routes.pilaresSale,
          builder: (context, state) => provide(const CourseSaleScreen()),
          routes: [
            GoRoute(
              path: 'faixa',
              builder: (context, state) =>
                  provide(const CourseBandPreviewScreen()),
            ),
            GoRoute(
              path: 'mapa',
              builder: (context, state) =>
                  provide(const CourseMapPreviewScreen()),
              routes: [
                GoRoute(
                  path: 'capitulo',
                  builder: (context, state) =>
                      provide(const CourseChapterPreviewScreen()),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        router: router,
        locale: const Locale('pt'),
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder saleScrollable() => find
      .descendant(
        of: find.byKey(CoursePreviewKeys.saleScroll),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Rola a venda até a aba [i] aparecer e toca nela.
  Future<void> openTab(WidgetTester tester, int i) async {
    final tab = find.byKey(CoursePreviewKeys.tab(i));
    await tester.scrollUntilVisible(tab, 200, scrollable: saleScrollable());
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  test('o asset exportado do canvas tem as três telas', () {
    expect(preview.sale.title, 'Pilares do Xadrez');
    expect(preview.sale.price, 'R\$ 59,90');
    expect(preview.sale.parts, isNotEmpty);
    expect(preview.sale.faq, isNotEmpty);
    expect(preview.map.chapters, hasLength(preview.map.total));
    expect(preview.chapter.lessons, isNotEmpty);
  });

  testWidgets('o cartão da faixa abre "Para quem é" com o gráfico e o '
      'aviso', (tester) async {
    setPhoneSize(tester, phoneSizes.first);
    await pump(tester);
    final card = find.byKey(CoursePreviewKeys.audience);
    await tester.scrollUntilVisible(card, 200, scrollable: saleScrollable());
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byKey(CoursePreviewKeys.band), findsOneWidget);
    expect(find.text('De 1000 a 2200 no Lichess'), findsOneWidget);
    expect(find.text('Garfo'), findsOneWidget);
    expect(find.text('14,6 %'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sem promessa de rating'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sem promessa de rating'), findsOneWidget);
  });

  for (final size in phoneSizes) {
    final w = size.width;
    final h = size.height;
    testWidgets('H4 venda ${w.toInt()}×${h.toInt()}: topo, preço, abas e o '
        'botão de comprar fixo', (tester) async {
      setPhoneSize(tester, size);
      await pump(tester);
      expect(find.text('Comprar · R\$ 59,90'), findsOneWidget);
      // Expandida: o nome só no topo, a barra ainda sem título visível.
      final bar = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Pilares do Xadrez').first,
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(bar.opacity, 0);

      final price = rectOf(tester, CoursePreviewKeys.priceCard);
      expect(price.left, closeToDp(16));
      expect(price.right, closeToDp(w - 16));

      final buy = rectOf(tester, CoursePreviewKeys.buy);
      expect(buy.height, closeToDp(52));
      expect(buy.left, closeToDp(16));
      expect(buy.right, closeToDp(w - 16));
      expect(buy.bottom, closeToDp(h - 24));

      // Rolada: as abas grudam embaixo da barra e o nome aparece nela.
      await tester.drag(
        find.byKey(CoursePreviewKeys.saleScroll),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      final collapsed = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.text('Pilares do Xadrez'),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(collapsed.opacity, 1);
      final appBar = tester.getRect(find.byType(AppBar));
      final tabs = tester.getRect(find.byType(TabBar));
      expect(tabs.top, closeToDp(appBar.bottom));
      expect(tabs.height, closeToDp(48));
    });

    testWidgets('H4 Conteúdo ${w.toInt()}×${h.toInt()}: a Parte I aberta com '
        'todos os capítulos, a parte abre e fecha num toque e o capítulo '
        'abre o mapa; Continuar abre o capítulo', (tester) async {
      setPhoneSize(tester, size);
      final router = await pump(tester);
      await openTab(tester, 1);
      expect(
        find.text('Toque numa parte para ver os capítulos e as lições.'),
        findsOneWidget,
      );
      final part = find.byKey(CoursePreviewKeys.part(0));
      await tester.scrollUntilVisible(part, 200, scrollable: saleScrollable());
      await tester.pumpAndSettle();
      final rect = tester.getRect(part);
      expect(rect.left, closeToDp(16));
      expect(rect.right, closeToDp(w - 16));
      expect(find.text('Parte I · 20 lições'), findsOneWidget);
      // A Parte I aberta: os seis capítulos, o último das aberturas sem
      // exercícios; as outras partes fechadas.
      for (var n = 1; n <= 6; n++) {
        expect(find.byKey(CoursePreviewKeys.summaryChapter(n)), findsOneWidget);
      }
      expect(find.text('1 · Ataque duplo e peças soltas'), findsOneWidget);
      expect(find.text('1.4'), findsOneWidget);
      expect(find.text('Exercícios'), findsNWidgets(5));
      expect(find.text('6 · Aberturas'), findsOneWidget);
      expect(find.text('6.5'), findsNothing);
      expect(find.byKey(CoursePreviewKeys.summaryChapter(7)), findsNothing);

      final header = find.byKey(CoursePreviewKeys.partHeader('I'));
      expect(tester.getRect(header).height, greaterThanOrEqualTo(48));
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(find.byKey(CoursePreviewKeys.summaryChapter(1)), findsNothing);
      final second = find.byKey(CoursePreviewKeys.partHeader('II'));
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(find.text('7 · Contra o defensor'), findsOneWidget);
      expect(find.text('10 · Aberturas'), findsOneWidget);

      final chapter = find.byKey(CoursePreviewKeys.summaryChapter(7));
      await tester.ensureVisible(chapter);
      await tester.pumpAndSettle();
      await tester.tap(chapter);
      await tester.pumpAndSettle();
      expect(find.byKey(CoursePreviewKeys.map), findsOneWidget);
      expect(router.state.uri.toString(), Routes.pilaresMap);

      // H5 mapa: Continuar, o teste de nível e os seis capítulos.
      // O botão do cartão: 16 de margem da tela e 16 de dentro do cartão.
      final next = rectOf(tester, CoursePreviewKeys.mapContinue);
      expect(next.left, closeToDp(32));
      expect(next.right, closeToDp(w - 32));
      expect(next.height, closeToDp(48));
      expect(find.byKey(CoursePreviewKeys.mapTest), findsOneWidget);
      final first = rectOf(
        tester,
        CoursePreviewKeys.mapChapter(preview.map.chapters.first.id),
      );
      expect(first.left, closeToDp(16));
      expect(first.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byKey(CoursePreviewKeys.mapContinue));
      await tester.pumpAndSettle();
      expect(find.byKey(CoursePreviewKeys.chapter), findsOneWidget);
      expect(router.state.uri.toString(), Routes.pilaresChapter);
    });

    testWidgets('H5 capítulo ${w.toInt()}×${h.toInt()}: lições, exercícios e '
        '"Começar a lição 5.1"', (tester) async {
      setPhoneSize(tester, size);
      await pump(tester, at: Routes.pilaresChapter);
      expect(find.text('Parte I · capítulo 5 de 6'), findsOneWidget);
      expect(find.text('Princípios da abertura'), findsOneWidget);
      for (final lesson in preview.chapter.lessons) {
        final row = rectOf(tester, CoursePreviewKeys.chapterLesson(lesson.id));
        expect(row.height, greaterThanOrEqualTo(48));
      }
      final exercises = rectOf(tester, CoursePreviewKeys.chapterExercises);
      expect(exercises.height, greaterThanOrEqualTo(48));
      expect(
        find.descendant(
          of: find.byKey(CoursePreviewKeys.chapterExercises),
          matching: find.text('Exercícios'),
        ),
        findsOneWidget,
      );
      final start = rectOf(tester, CoursePreviewKeys.chapterStart);
      expect(start.height, closeToDp(52));
      expect(start.left, closeToDp(16));
      expect(start.right, closeToDp(w - 16));
      expect(start.bottom, closeToDp(h - 8));
      expect(find.text('Começar a lição 5.1'), findsOneWidget);
    });
  }

  testWidgets('H4 Dúvidas: a primeira pergunta aberta; tocar abre outra', (
    tester,
  ) async {
    setPhoneSize(tester, phoneSizes.first);
    await pump(tester);
    await openTab(tester, 2);
    final faq = preview.sale.faq;
    expect(find.text(faq[0].answer), findsOneWidget);
    expect(find.text(faq[1].answer), findsNothing);
    final tile = rectOf(tester, CoursePreviewKeys.faq(1));
    expect(tile.height, greaterThanOrEqualTo(56));
    await tester.ensureVisible(find.text(faq[1].question));
    await tester.pumpAndSettle();
    await tester.tap(find.text(faq[1].question));
    await tester.pumpAndSettle();
    expect(find.text(faq[1].answer), findsOneWidget);
    expect(find.text(faq[0].answer), findsOneWidget);
  });
}
