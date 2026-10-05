import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  Future<SchoolState> load({
    SchoolProgress progress = const SchoolProgress(),
    int rating = 800,
  }) async {
    final cubit = SchoolCubit(
      lessons: FakeLessonRepository(),
      progress: FakeSchoolProgressRepository(progress),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(UserProfile(rating: rating)),
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    return cubit.state;
  }

  test('iniciante: só a primeira aula liberada', () async {
    final state = await load();
    expect(state.status('pieces.rook'), LessonStatus.open);
    expect(state.status('pieces.mate'), LessonStatus.locked);
    expect(state.blockedBy('pieces.mate'), 'pieces.rook');
    expect(state.next, 'pieces.rook');
    expect(state.viktor!.name, 'Viktor');
  });

  test('concluir uma aula libera a seguinte', () async {
    final state = await load(
      progress: const SchoolProgress(completed: {'pieces.rook'}),
    );
    expect(state.status('pieces.rook'), LessonStatus.completed);
    expect(state.status('pieces.mate'), LessonStatus.open);
    expect(state.status('mates.queen'), LessonStatus.locked);
    expect(state.done, 1);
    expect(state.next, 'pieces.mate');
  });

  test('a aula começada é a próxima', () async {
    final state = await load(
      progress: const SchoolProgress(
        ongoing: LessonCheckpoint(lessonId: 'pieces.mate', step: 0),
      ),
    );
    expect(state.next, 'pieces.mate');
  });

  test('quem não é iniciante abre qualquer aula', () async {
    final state = await load(rating: 1500);
    expect(state.status('mates.queen'), LessonStatus.open);
  });

  test('todas concluídas: formado', () async {
    final state = await load(
      progress: const SchoolProgress(
        completed: {'pieces.rook', 'pieces.mate', 'mates.queen'},
      ),
    );
    expect(state.graduated, isTrue);
    expect(state.next, isNull);
  });
}
