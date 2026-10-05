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
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

/// Três posições do mesmo final, para a grade ter mais de uma linha.
const _threeQueenPositions = [
  EndgamePosition(
    id: 'basic.queen.0001',
    category: 'basic',
    subcategory: 'queen',
    fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
    goal: PositionGoal.win,
  ),
  EndgamePosition(
    id: 'basic.queen.0002',
    category: 'basic',
    subcategory: 'queen',
    fen: '8/8/3k4/8/8/4K3/8/7Q w - - 0 1',
    goal: PositionGoal.win,
  ),
  EndgamePosition(
    id: 'basic.queen.0003',
    category: 'basic',
    subcategory: 'queen',
    fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
    goal: PositionGoal.win,
  ),
];

void main() {
  late FakeTrainingRepository training;

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    String? category,
    List<EndgamePosition>? positions,
    Locale locale = const Locale('en'),
    Set<String> fulfilled = const {},
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    training = FakeTrainingRepository();
    final cubit = CatalogCubit(
      FakePositionsRepository(positions),
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
    await cubit.load(category: category);
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

  testWidgets('a categoria mostra cada final já aberto, com as posições', (
    tester,
  ) async {
    await pump(
      tester,
      const CategoryScreen(category: 'basic'),
      category: 'basic',
    );

    expect(find.byKey(CatalogKeys.subcategory('queen')), findsOneWidget);
    expect(find.byKey(CatalogKeys.subcategory('rook')), findsOneWidget);
    expect(find.text('♕  –  ♚'), findsOneWidget);
    expect(find.text('Queen mate'), findsOneWidget);
    expect(
      find.byKey(CatalogKeys.position('basic.queen.0001')),
      findsOneWidget,
    );
    expect(find.byKey(CatalogKeys.position('basic.rook.0001')), findsOneWidget);
  });

  testWidgets('a posição mostra o objetivo, sem o mate', (tester) async {
    await pump(
      tester,
      const CategoryScreen(category: 'basic'),
      category: 'basic',
    );

    final tile = find.byKey(CatalogKeys.position('basic.queen.0001'));
    expect(find.textContaining('Mate'), findsNothing);
    expect(
      find.descendant(of: tile, matching: find.text('Win')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.text('Position 1')),
      findsOneWidget,
    );
  });

  testWidgets('fechar uma seção esconde as posições dela; abrir de novo '
      'mostra', (tester) async {
    await pump(
      tester,
      const CategoryScreen(category: 'basic'),
      category: 'basic',
    );

    await tester.tap(find.byKey(CatalogKeys.subcategory('queen')));
    await tester.pumpAndSettle();

    expect(find.byKey(CatalogKeys.position('basic.queen.0001')), findsNothing);
    // A outra seção continua aberta.
    expect(find.byKey(CatalogKeys.position('basic.rook.0001')), findsOneWidget);

    await tester.tap(find.byKey(CatalogKeys.subcategory('queen')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(CatalogKeys.position('basic.queen.0001')),
      findsOneWidget,
    );
  });

  testWidgets('as posições ficam duas por linha', (tester) async {
    await pump(
      tester,
      const CategoryScreen(category: 'basic'),
      category: 'basic',
      positions: _threeQueenPositions,
    );

    final first = tester.getTopLeft(
      find.byKey(CatalogKeys.position('basic.queen.0001')),
    );
    final second = tester.getTopLeft(
      find.byKey(CatalogKeys.position('basic.queen.0002')),
    );
    final third = tester.getTopLeft(
      find.byKey(CatalogKeys.position('basic.queen.0003')),
    );
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(third.dy, greaterThan(first.dy));
    expect(third.dx, first.dx);
  });

  testWidgets('em árabe, a grade começa pela direita', (tester) async {
    await pump(
      tester,
      const CategoryScreen(category: 'basic'),
      category: 'basic',
      positions: _threeQueenPositions,
      locale: const Locale('ar'),
    );

    final first = tester.getTopLeft(
      find.byKey(CatalogKeys.position('basic.queen.0001')),
    );
    final second = tester.getTopLeft(
      find.byKey(CatalogKeys.position('basic.queen.0002')),
    );
    expect(second.dy, first.dy);
    expect(second.dx, lessThan(first.dx));
  });

  testWidgets('o filtro deixa só as posições do objetivo e esconde o final '
      'sem nenhuma', (tester) async {
    await pump(
      tester,
      const CategoryScreen(category: 'rookPawn'),
      category: 'rookPawn',
      positions: [
        ...samplePositions,
        const EndgamePosition(
          id: 'rookPawn.rookVsPawn.0001',
          category: 'rookPawn',
          subcategory: 'rookVsPawn',
          fen: '8/8/8/8/8/2k5/2p5/2K3R1 w - - 0 1',
          goal: PositionGoal.win,
        ),
      ],
    );

    await tester.tap(find.byKey(CatalogKeys.filter(GoalFilter.draw)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(CatalogKeys.position('rookPawn.rookPawnVsRook.0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(CatalogKeys.position('rookPawn.rookPawnVsRook.0002')),
      findsNothing,
    );
    expect(find.byKey(CatalogKeys.subcategory('rookVsPawn')), findsNothing);
    expect(find.text('1 position'), findsOneWidget);
  });

  testWidgets('sem posições para o filtro, aparece o aviso', (tester) async {
    await pump(
      tester,
      const CategoryScreen(category: 'basic'),
      category: 'basic',
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
      const CategoryScreen(category: 'basic'),
      category: 'basic',
      fulfilled: {'basic.queen.0001'},
    );

    expect(
      find.byKey(CatalogKeys.fulfilled('basic.queen.0001')),
      findsOneWidget,
    );
    expect(find.byKey(CatalogKeys.fulfilled('basic.rook.0001')), findsNothing);
  });
}
