import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

void main() {
  Future<EndgamesState> load([
    EndgameProgress progress = const EndgameProgress(),
  ]) async {
    final cubit = EndgamesCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(progress),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    return cubit.state;
  }

  test(
    'a trilha abre com todas as aulas abertas e a primeira como próxima',
    () async {
      final state = await load();
      expect(state.viktor!.name, 'Viktor');
      expect(state.total, 2);
      expect(state.passed, 0);
      expect(state.next, 'rook.lucena');
      expect(state.status('rook.lucena'), EndgameLessonStatus.open);
      expect(state.status('rook.philidor'), EndgameLessonStatus.open);
      expect(state.score('rook.lucena'), (0, 6));
    },
  );

  test('aula começada, aprovada e a próxima', () async {
    final state = await load(
      const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1, 'e02': 2, 'e03': 1},
          ),
          'rook.philidor': EndgameLessonProgress(stars: {}),
        },
      ),
    );
    expect(state.status('rook.lucena'), EndgameLessonStatus.passed);
    expect(state.score('rook.lucena'), (4, 6));
    expect(state.passed, 1);
    expect(state.next, 'rook.philidor');

    final started = await load(
      const EndgameProgress(
        lessons: {'rook.lucena': EndgameLessonProgress(lessonDone: true)},
      ),
    );
    expect(started.status('rook.lucena'), EndgameLessonStatus.started);
    expect(started.next, 'rook.lucena');
  });

  test('tudo aprovado: sem próxima', () async {
    final state = await load(
      const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1, 'e02': 2, 'e03': 3},
          ),
          'rook.philidor': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1},
          ),
        },
      ),
    );
    expect(state.next, isNull);
    expect(state.passed, 2);
  });

  test('o filtro da rota vale na visita e não muda o gravado', () async {
    final settings = FakeSettingsRepository(
      const AppSettings(endgamesAll: true),
    );
    final cubit = EndgamesCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      settings: settings,
    );
    addTearDown(cubit.close);
    await cubit.load('en', showAll: false);
    expect(cubit.state.showAll, isFalse);
    expect((await settings.load()).endgamesAll, isTrue);
    await cubit.load('en');
    expect(cubit.state.showAll, isTrue);
  });

  group('filtros', () {
    // A Lucena é intermediária; a Philidor, avançada (só para o teste).
    final skills = SkillMap([
      const SkillNode(
        id: 'rook.lucena',
        group: SkillGroup.queenRook,
        band: RatingLevel.intermediate,
        lessons: [
          SkillLesson(id: 'rook.lucena', kind: SkillLessonKind.endgame),
        ],
      ),
      const SkillNode(
        id: 'rook.philidor',
        group: SkillGroup.queenRook,
        band: RatingLevel.advanced,
        lessons: [
          SkillLesson(id: 'rook.philidor', kind: SkillLessonKind.endgame),
        ],
      ),
    ]);

    Future<(EndgamesCubit, FakeSettingsRepository)> build([
      AppSettings saved = const AppSettings(),
    ]) async {
      final settings = FakeSettingsRepository(saved);
      final cubit = EndgamesCubit(
        lessons: FakeEndgameLessonRepository(),
        progress: FakeEndgameProgressRepository(
          const EndgameProgress(
            lessons: {
              'rook.lucena': EndgameLessonProgress(
                lessonDone: true,
                stars: {'e01': 1, 'e02': 2, 'e03': 1},
              ),
            },
          ),
        ),
        characters: FakeCharacterRepository(),
        placement: FakePlacementRepository(skills: skills),
        settings: settings,
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      return (cubit, settings);
    }

    test('tipos e faixas que têm aula; sem filtro, os módulos', () async {
      final (cubit, _) = await build();
      final state = cubit.state;
      expect(state.availableKinds, [EndgameKind.rook]);
      expect(state.availableLevels, [
        RatingLevel.intermediate,
        RatingLevel.advanced,
      ]);
      expect(state.level('rook.lucena'), RatingLevel.intermediate);
      expect(state.sections.map((section) => section.id), ['rook']);
      expect(state.filteredLessons, hasLength(2));
    });

    test('filtrar por situação e por faixa, e gravar', () async {
      final (cubit, settings) = await build();
      await cubit.toggleStatus(EndgameLessonStatus.passed);
      expect(cubit.state.filteredLessons.map((lesson) => lesson.id), [
        'rook.lucena',
      ]);
      await cubit.toggleLevel(RatingLevel.advanced);
      expect(cubit.state.filteredLessons, isEmpty);
      expect(cubit.state.sections, isEmpty);
      expect(
        settings.settings.endgamesFilter,
        const EndgameFilter(
          levels: {RatingLevel.advanced},
          statuses: {EndgameLessonStatus.passed},
        ),
      );
      await cubit.clearFilter();
      expect(cubit.state.filter.isEmpty, isTrue);
      expect(settings.settings.endgamesFilter, const EndgameFilter());
    });

    test('tipo sem aula esvazia a lista', () async {
      final (cubit, _) = await build();
      await cubit.toggleKind(EndgameKind.pawn);
      expect(cubit.state.filteredLessons, isEmpty);
      await cubit.toggleKind(EndgameKind.rook);
      expect(cubit.state.filteredLessons, hasLength(2));
    });

    test('das mais fáceis às mais difíceis: seções por faixa', () async {
      final (cubit, _) = await build();
      await cubit.setSort(EndgameSort.easiest);
      expect(cubit.state.sections.map((section) => section.level), [
        RatingLevel.intermediate,
        RatingLevel.advanced,
      ]);
    });

    test('o filtro gravado volta ao abrir', () async {
      final (cubit, _) = await build(
        const AppSettings(
          endgamesFilter: EndgameFilter(kinds: {EndgameKind.queen}),
        ),
      );
      expect(cubit.state.filter.kinds, {EndgameKind.queen});
      expect(cubit.state.filteredLessons, isEmpty);
    });
  });
}
