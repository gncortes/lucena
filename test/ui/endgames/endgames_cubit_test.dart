import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
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
}
