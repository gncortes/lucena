import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';

import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';

void main() {
  late FakeTrainingRepository training;

  CatalogCubit build() => CatalogCubit(
    FakePositionsRepository(),
    training,
    FakeProgressRepository(),
  );

  setUp(() => training = FakeTrainingRepository());

  test('carrega as categorias com o filtro gravado', () async {
    training.filter = const CatalogFilter(goal: GoalFilter.draw);
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.filter, const CatalogFilter(goal: GoalFilter.draw));
    expect(cubit.state.categories?.map((c) => c.key), ['basic', 'rookPawn']);
    expect(cubit.state.positions, isNull);
    expect(cubit.state.sections, isNull);
  });

  test(
    'com a categoria, carrega as posições de todos os finais dela',
    () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load(category: 'basic');

      expect(cubit.state.positions?.map((p) => p.id), [
        'basic.queen.0001',
        'basic.rook.0001',
      ]);
      expect(cubit.state.sections?.map((s) => s.subcategory), [
        'queen',
        'rook',
      ]);
      expect(cubit.state.sections?.every((s) => s.expanded), isTrue);
    },
  );

  test('filtrar "defender" deixa só as posições de empate e grava', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(category: 'rookPawn');

    await cubit.setGoal(GoalFilter.draw);

    expect(cubit.state.visiblePositions?.map((p) => p.goal), [
      PositionGoal.draw,
    ]);
    expect(training.filter, const CatalogFilter(goal: GoalFilter.draw));
  });

  test('final sem posição para o filtro sai das seções', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(category: 'basic');

    await cubit.setGoal(GoalFilter.draw);

    expect(cubit.state.sections, isEmpty);
  });

  test('fechar uma seção e abrir de novo', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(category: 'basic');

    cubit.toggleSection('queen');

    expect(cubit.state.sections?.map((s) => s.expanded), [false, true]);

    cubit.toggleSection('queen');

    expect(cubit.state.sections?.map((s) => s.expanded), [true, true]);
  });

  test('a contagem da categoria segue o filtro', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    final basic = cubit.state.categories!.first;
    expect(basic.count(GoalFilter.all), 2);
    expect(basic.count(GoalFilter.win), 2);
    expect(basic.count(GoalFilter.draw), 0);
  });

  group('filtro de lição', () {
    const p1 = 'pawns.distantOpposition';
    const p2 = 'pawns.waitingMoves';
    EndgamePosition pawn(
      int n,
      PositionGoal goal,
      List<LessonLink> links, {
      String sub = 'pawnVsKing',
    }) => EndgamePosition(
      id: 'pawn.$sub.${n.toString().padLeft(4, '0')}',
      category: 'pawn',
      subcategory: sub,
      fen: '8/8/8/8/8/4k3/4P3/4K3 w - - 0 1',
      goal: goal,
      verified: true,
      links: links,
    );
    final positions = [
      ...samplePositions,
      pawn(1, PositionGoal.win, const [
        LessonLink(lessonId: p1, relation: LessonRelation.base),
      ]),
      pawn(2, PositionGoal.draw, const [
        LessonLink(lessonId: p2, relation: LessonRelation.base),
      ]),
      pawn(3, PositionGoal.win, const [
        LessonLink(lessonId: p1, relation: LessonRelation.transposes, ply: 4),
        LessonLink(lessonId: p2, relation: LessonRelation.base),
      ]),
      pawn(4, PositionGoal.draw, const [
        LessonLink(lessonId: p1, relation: LessonRelation.transposes, ply: 2),
      ], sub: 'pawnVsPawn'),
      pawn(5, PositionGoal.win, const []),
    ];

    CatalogCubit withLinks() => CatalogCubit(
      FakePositionsRepository(positions),
      training,
      FakeProgressRepository(),
    );

    List<String>? ids(CatalogCubit cubit) =>
        cubit.state.visiblePositions?.map((p) => p.id.split('.').last).toList();

    test('as opções são as lições com posição ligada', () async {
      final cubit = withLinks();
      addTearDown(cubit.close);
      await cubit.load(category: 'pawn');

      expect(cubit.state.lessons, [p1, p2]);
    });

    test('lições em OU entre si e em E com o objetivo', () async {
      final cubit = withLinks();
      addTearDown(cubit.close);
      await cubit.load(category: 'pawn');

      await cubit.setLessons({p1});
      expect(ids(cubit), ['0001', '0003', '0004']);

      await cubit.setLessons({p1, p2});
      expect(ids(cubit), ['0001', '0002', '0003', '0004']);

      await cubit.setGoal(GoalFilter.draw);
      expect(ids(cubit), ['0002', '0004']);
      expect(cubit.state.filter.lessons, {p1, p2});

      await cubit.clearLessons();
      expect(ids(cubit), ['0002', '0004']);
      expect(cubit.state.filter, const CatalogFilter(goal: GoalFilter.draw));
    });

    test('o filtro de lição grava e volta ao reabrir', () async {
      final cubit = withLinks();
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.setLessons({p2});
      expect(training.filter, const CatalogFilter(lessons: {p2}));

      final again = withLinks();
      addTearDown(again.close);
      await again.load(category: 'pawn');
      expect(again.state.filter.lessons, {p2});
      expect(ids(again), ['0002', '0003']);
    });

    test('lição que deixou de existir é ignorada', () async {
      training.filter = const CatalogFilter(
        goal: GoalFilter.win,
        lessons: {p1, 'pawns.removida'},
      );
      final cubit = withLinks();
      addTearDown(cubit.close);
      await cubit.load(category: 'pawn');

      expect(
        cubit.state.filter,
        const CatalogFilter(goal: GoalFilter.win, lessons: {p1}),
      );

      await cubit.setLessons({'pawns.removida'});
      expect(cubit.state.filter.lessons, isEmpty);
    });

    test('só a lição removida: o filtro de lição fica vazio', () async {
      training.filter = const CatalogFilter(lessons: {'pawns.removida'});
      final cubit = withLinks();
      addTearDown(cubit.close);
      await cubit.load(category: 'pawn');

      expect(cubit.state.filter.byLesson, isFalse);
      expect(ids(cubit), hasLength(5));
    });

    test('as contagens e as seções seguem o filtro inteiro', () async {
      final cubit = withLinks();
      addTearDown(cubit.close);
      await cubit.load(category: 'pawn');
      await cubit.setLessons({p2});

      final pawnCategory = cubit.state.categories!.firstWhere(
        (c) => c.key == 'pawn',
      );
      final basic = cubit.state.categories!.first;
      expect(pawnCategory.countFor(cubit.state.filter), 2);
      expect(basic.countFor(cubit.state.filter), 0);
      expect(cubit.state.sections?.map((s) => s.subcategory), ['pawnVsKing']);

      await cubit.setGoal(GoalFilter.win);
      expect(pawnCategory.countFor(cubit.state.filter), 1);
    });

    test('selo "Transpõe": só a que não é base de nenhuma lição marcada', () {
      final three = positions[6];
      final four = positions[7];
      expect(const CatalogFilter(lessons: {p1}).onlyTransposes(three), isTrue);
      expect(
        const CatalogFilter(lessons: {p1, p2}).onlyTransposes(three),
        isFalse,
      );
      expect(const CatalogFilter(lessons: {p1}).onlyTransposes(four), isTrue);
      expect(const CatalogFilter().onlyTransposes(four), isFalse);
      expect(
        const CatalogFilter(lessons: {p2}).onlyTransposes(positions[4]),
        isFalse,
      );
    });
  });
}
