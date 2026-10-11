import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/placement_roadmap.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

/// O roteiro do teste de nível (T52) nas telas da escola e da trilha de
/// finais, com o curso e a trilha pequenos dos fakes.
void main() {
  // Um mapa pequeno, ligado às aulas dos fakes.
  final skills = SkillMap.fromJson({
    'nodes': [
      {
        'id': 'rules.rook',
        'group': 'rules',
        'band': 'beginner',
        'lessons': [
          {'id': 'pieces.rook', 'kind': 'school'},
        ],
      },
      {
        'id': 'mate.inOne',
        'group': 'mates',
        'band': 'beginner',
        'requires': ['rules.rook'],
        'lessons': [
          {'id': 'pieces.mate', 'kind': 'school'},
        ],
      },
      {
        'id': 'mate.queen',
        'group': 'mates',
        'band': 'casual',
        'requires': ['mate.inOne'],
        'lessons': [
          {'id': 'mates.queen', 'kind': 'school'},
        ],
      },
      {
        'id': 'rook.lucena',
        'group': 'queenRook',
        'band': 'intermediate',
        'lessons': [
          {'id': 'rook.lucena', 'kind': 'endgame'},
        ],
      },
    ],
  });

  PlacementResult result(Map<String, NodeStatus> nodes) => PlacementResult(
    theta: 1200,
    low: 1050,
    high: 1350,
    takenAt: DateTime.utc(2026, 10, 8),
    nodes: nodes,
  );

  Future<SchoolState> school({
    PlacementResult? placed,
    SchoolProgress progress = const SchoolProgress(),
  }) async {
    final cubit = SchoolCubit(
      lessons: FakeLessonRepository(),
      progress: FakeSchoolProgressRepository(progress),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(const UserProfile(rating: 800)),
      placement: FakePlacementRepository(
        skills: skills,
        saveResultValue: placed,
      ),
      endgames: FakeEndgameLessonRepository(),
      endgameProgress: FakeEndgameProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    return cubit.state;
  }

  group('escola', () {
    test('sem teste: nada dispensado, o convite aparece', () async {
      final state = await school();
      expect(state.tested, isFalse);
      expect(state.skipped, isEmpty);
      expect(state.next, 'pieces.rook');
    });

    test(
      'o que o teste dispensa sai da frente e destrava a seguinte',
      () async {
        final state = await school(
          placed: result(const {
            'rules.rook': NodeStatus(NodeState.mastered, confirmed: true),
            'mate.inOne': NodeStatus(NodeState.likely),
            'mate.queen': NodeStatus(NodeState.gap, confirmed: true),
          }),
        );
        expect(state.tested, isTrue);
        expect(state.skipped, {
          'pieces.rook': SkipReason.confirmed,
          'pieces.mate': SkipReason.likely,
        });
        expect(state.status('pieces.rook'), LessonStatus.skippedByTest);
        // Iniciante, mas a anterior foi dispensada: a lacuna fica aberta.
        expect(state.status('mates.queen'), LessonStatus.open);
        expect(state.next, 'mates.queen');
        // Dispensa não é conclusão: nem conta aula feita nem forma.
        expect(state.done, 0);
        expect(state.graduated, isFalse);
      },
    );

    test(
      'aula feita depois do teste conta como feita, não dispensada',
      () async {
        final state = await school(
          placed: result(const {
            'rules.rook': NodeStatus(NodeState.mastered, confirmed: true),
          }),
          progress: const SchoolProgress(completed: {'pieces.rook'}),
        );
        expect(state.status('pieces.rook'), LessonStatus.completed);
        expect(state.skipped, isEmpty);
      },
    );

    test('rever as aulas anteriores abre e fecha o grupo', () async {
      final cubit = SchoolCubit(
        lessons: FakeLessonRepository(),
        progress: FakeSchoolProgressRepository(),
        characters: FakeCharacterRepository(),
        profile: FakeProfileRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      cubit.toggleSkipped();
      expect(cubit.state.showSkipped, isTrue);
      cubit.toggleSkipped();
      expect(cubit.state.showSkipped, isFalse);
    });
  });

  group('trilha de finais', () {
    Future<EndgamesState> endgames({
      PlacementResult? placed,
      EndgameProgress progress = const EndgameProgress(),
    }) async {
      final cubit = EndgamesCubit(
        lessons: FakeEndgameLessonRepository(),
        progress: FakeEndgameProgressRepository(progress),
        characters: FakeCharacterRepository(),
        placement: FakePlacementRepository(
          skills: skills,
          saveResultValue: placed,
        ),
        school: FakeLessonRepository(),
        schoolProgress: FakeSchoolProgressRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      return cubit.state;
    }

    test('sem teste: sem selos nem roteiro', () async {
      final state = await endgames();
      expect(state.tested, isFalse);
      expect(state.badge('rook.lucena'), isNull);
    });

    test('lacuna: a aula vira a recomendada e o próximo final', () async {
      final state = await endgames(
        placed: result(const {
          'rook.lucena': NodeStatus(NodeState.gap, confirmed: true),
        }),
      );
      expect(state.badge('rook.lucena'), EndgameBadge.recommended);
      expect(state.roadmap!.nextEndgame!.lessonId, 'rook.lucena');
      expect(state.next, 'rook.lucena');
    });

    test('dominado: selo "já domina"', () async {
      final state = await endgames(
        placed: result(const {
          'rook.lucena': NodeStatus(NodeState.mastered, confirmed: true),
        }),
      );
      expect(state.badge('rook.lucena'), EndgameBadge.mastered);
    });

    test(
      'aula concluída segue em "Para você"; esconder fica gravado',
      () async {
        final settings = FakeSettingsRepository(const AppSettings());
        EndgamesCubit cubit() {
          final cubit = EndgamesCubit(
            lessons: FakeEndgameLessonRepository(),
            progress: FakeEndgameProgressRepository(
              const EndgameProgress(
                lessons: {
                  'rook.lucena': EndgameLessonProgress(
                    lessonDone: true,
                    stars: {'e01': 2, 'e02': 2, 'e03': 2},
                  ),
                },
              ),
            ),
            characters: FakeCharacterRepository(),
            placement: FakePlacementRepository(
              skills: skills,
              saveResultValue: result(const {
                'rook.lucena': NodeStatus(NodeState.gap, confirmed: true),
              }),
            ),
            school: FakeLessonRepository(),
            schoolProgress: FakeSchoolProgressRepository(),
            settings: settings,
          );
          addTearDown(cubit.close);
          return cubit;
        }

        final first = cubit();
        await first.load('en');
        expect(first.state.doneLessons.map((lesson) => lesson.id), [
          'rook.lucena',
        ]);
        expect(first.state.hideDone, isFalse);
        await first.setHideDone(true);
        expect(first.state.hideDone, isTrue);
        expect(settings.settings.endgamesHideDone, isTrue);

        final again = cubit();
        await again.load('en');
        expect(again.state.hideDone, isTrue);
      },
    );

    test('"Para você" e "Todos": sem teste, sempre todos; a escolha fica '
        'gravada', () async {
      final settings = FakeSettingsRepository(const AppSettings());
      EndgamesCubit cubit({PlacementResult? placed}) {
        final cubit = EndgamesCubit(
          lessons: FakeEndgameLessonRepository(),
          progress: FakeEndgameProgressRepository(),
          characters: FakeCharacterRepository(),
          placement: FakePlacementRepository(
            skills: skills,
            saveResultValue: placed,
          ),
          school: FakeLessonRepository(),
          schoolProgress: FakeSchoolProgressRepository(),
          settings: settings,
        );
        addTearDown(cubit.close);
        return cubit;
      }

      final untested = cubit();
      await untested.load('en');
      expect(untested.state.forYou, isFalse);

      final tested = cubit(
        placed: result(const {
          'rook.lucena': NodeStatus(NodeState.gap, confirmed: true),
        }),
      );
      await tested.load('en');
      expect(tested.state.forYou, isTrue);
      await tested.setShowAll(true);
      expect(tested.state.forYou, isFalse);
      expect(settings.settings.endgamesAll, isTrue);

      final again = cubit(
        placed: result(const {
          'rook.lucena': NodeStatus(NodeState.gap, confirmed: true),
        }),
      );
      await again.load('en');
      expect(again.state.showAll, isTrue);
    });
  });
}
