import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';
import 'package:lucena/ui/catalog/widgets/catalog_screen.dart';
import 'package:lucena/ui/catalog/widgets/category_screen.dart';
import 'package:lucena/ui/catalog/widgets/subcategory_screen.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeTrainingRepository training;

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    String? subcategory,
    Locale locale = const Locale('en'),
    Set<String> fulfilled = const {},
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    training = FakeTrainingRepository();
    final cubit = CatalogCubit(
      FakePositionsRepository(),
      training,
      FakeProgressRepository([
        for (final id in fulfilled)
          Attempt(
            positionId: id,
            playedAt: DateTime.utc(2026),
            outcome: AttemptOutcome.win,
            fulfilled: true,
            opponent: OpponentKind.stockfish,
          ),
      ]),
    );
    addTearDown(cubit.close);
    await cubit.load(subcategory: subcategory);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('as categorias aparecem com o nome traduzido e a contagem', (
    tester,
  ) async {
    await pump(tester, const CatalogScreen(), locale: const Locale('es'));

    expect(textOf(tester, CatalogKeys.categoryName('basic')), 'Mates básicos');
    expect(
      textOf(tester, CatalogKeys.categoryName('rookPawn')),
      'Finales de torre',
    );
    expect(find.text('2 posiciones'), findsNWidgets(2));
  });

  testWidgets('filtrar "defender" esconde a categoria sem empates e grava', (
    tester,
  ) async {
    await pump(tester, const CatalogScreen());

    await tester.tap(find.byKey(CatalogKeys.filter(GoalFilter.draw)));
    await tester.pumpAndSettle();

    expect(find.byKey(CatalogKeys.category('basic')), findsNothing);
    expect(find.byKey(CatalogKeys.category('rookPawn')), findsOneWidget);
    expect(find.text('1 position'), findsOneWidget);
    expect(training.filter, GoalFilter.draw);
  });

  testWidgets('a categoria lista as subcategorias com o material em figurino', (
    tester,
  ) async {
    await pump(tester, const CategoryScreen(category: 'basic'));

    expect(find.byKey(CatalogKeys.subcategory('queen')), findsOneWidget);
    expect(find.byKey(CatalogKeys.subcategory('rook')), findsOneWidget);
    expect(find.text('♕  –  ♚'), findsOneWidget);
  });

  testWidgets('a lista de posições mostra o objetivo, sem o mate', (
    tester,
  ) async {
    await pump(
      tester,
      const SubcategoryScreen(category: 'basic', subcategory: 'queen'),
      subcategory: 'queen',
    );

    final tile = find.byKey(CatalogKeys.position('basic.queen.0001'));
    expect(tile, findsOneWidget);
    expect(find.textContaining('Mate'), findsNothing);
    expect(
      find.descendant(of: tile, matching: find.text('Win')),
      findsOneWidget,
    );
  });

  testWidgets('sem posições para o filtro, aparece o aviso', (tester) async {
    await pump(
      tester,
      const SubcategoryScreen(category: 'basic', subcategory: 'queen'),
      subcategory: 'queen',
    );

    await tester.tap(find.byKey(CatalogKeys.filter(GoalFilter.draw)));
    await tester.pumpAndSettle();

    expect(find.byKey(CatalogKeys.empty), findsOneWidget);
  });

  testWidgets('posição com o objetivo já cumprido ganha a marca', (
    tester,
  ) async {
    await pump(
      tester,
      const SubcategoryScreen(category: 'basic', subcategory: 'queen'),
      subcategory: 'queen',
      fulfilled: {'basic.queen.0001'},
    );

    expect(
      find.byKey(CatalogKeys.fulfilled('basic.queen.0001')),
      findsOneWidget,
    );
  });
}
