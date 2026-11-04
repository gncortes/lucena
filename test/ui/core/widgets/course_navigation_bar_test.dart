import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_navigation_bar.dart';

import '../../../../testing/test_app.dart';

/// H-TRE-18: cinco abas só com ícone, ordem fixa, selo vermelho nas Metas.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    int remaining = 0,
    int selected = 0,
    ValueChanged<int>? onSelected,
  }) => tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      child: Scaffold(
        bottomNavigationBar: CourseNavigationBar(
          selectedIndex: selected,
          remaining: remaining,
          onDestinationSelected: onSelected,
        ),
      ),
    ),
  );

  test('o enum tem as cinco abas na ordem do canvas', () {
    expect(CourseGuideTab.values.map((t) => t.name), [
      'lesson',
      'goals',
      'guide',
      'stats',
      'catalog',
    ]);
  });

  testWidgets('cinco ícones na ordem, sem rótulo visível', (tester) async {
    await pump(tester);
    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();
    expect(destinations, hasLength(5));
    final icons = [
      for (final tab in CourseGuideTab.values)
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(CourseGuideKeys.tab(tab.name)),
                matching: find.byType(Icon),
              ),
            )
            .icon,
    ];
    expect(icons[2], Icons.explore_outlined);
    expect(icons[4], Icons.menu_book_outlined);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
    for (final label in ['Lição', 'Metas', 'Guia', 'Estatísticas', 'Catálogo']) {
      final visible = find.text(label).evaluate().where((e) {
        final render = e.renderObject;
        return render != null && render.paintBounds.height > 0;
      });
      expect(
        tester
            .widgetList<Opacity>(
              find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
            )
            .every((o) => o.opacity == 0),
        isTrue,
        reason: 'rótulo $label deve estar oculto (visíveis: ${visible.length})',
      );
    }
  });

  testWidgets('cada ícone anuncia o nome para o leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final (tab, name) in [
      (CourseGuideTab.lesson, 'Lição'),
      (CourseGuideTab.goals, 'Metas'),
      (CourseGuideTab.guide, 'Guia'),
      (CourseGuideTab.stats, 'Estatísticas'),
      (CourseGuideTab.catalog, 'Catálogo'),
    ]) {
      expect(
        tester.getSemantics(find.byKey(CourseGuideKeys.tab(tab.name))).label,
        contains(name),
      );
    }
    handle.dispose();
  });

  testWidgets('selo vermelho com as metas que faltam', (tester) async {
    await pump(tester, remaining: 3);
    final badge = tester.widget<Badge>(find.byKey(CourseGuideKeys.goalsBadge));
    expect(badge.isLabelVisible, isTrue);
    expect(badge.backgroundColor, const Color(0xFFB3261E));
    expect(find.descendant(of: find.byKey(CourseGuideKeys.goalsBadge), matching: find.text('3')), findsOneWidget);
  });

  testWidgets('acima de 9 mostra 9+', (tester) async {
    await pump(tester, remaining: 12);
    expect(find.text('9+'), findsOneWidget);
    await pump(tester, remaining: 9);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('sem metas faltando não há selo', (tester) async {
    await pump(tester);
    final badge = tester.widget<Badge>(find.byKey(CourseGuideKeys.goalsBadge));
    expect(badge.isLabelVisible, isFalse);
  });

  testWidgets('toque devolve o índice da aba', (tester) async {
    int? tapped;
    await pump(tester, onSelected: (i) => tapped = i);
    await tester.tap(find.byKey(CourseGuideKeys.tab('guide')));
    expect(tapped, 2);
    await tester.tap(find.byKey(CourseGuideKeys.tab('stats')));
    expect(tapped, 3);
  });
}
