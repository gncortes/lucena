import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/load_failure.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_now.dart';

class _School extends FakeLessonRepository {
  bool fails = true;
  @override
  Future<LessonTexts> texts(String language) async {
    if (fails) throw const LessonContentUnavailable();
    return super.texts(language);
  }
}

void main() {
  test('fim da aula com pacote ausente permite repetir', () async {
    final school = _School();
    final cubit = LessonFinishedCubit(
      kind: SurveyKind.school,
      lessonId: 'pieces.rook',
      nextId: null,
      school: school,
      endgames: FakeEndgameLessonRepository(),
      race: FakeRaceRepository(now: FakeNow(DateTime(2026, 11, 2))),
    );
    addTearDown(cubit.close);
    await cubit.load('pt');
    expect((cubit.state as dynamic).failure, LoadFailure.unavailable);
    school.fails = false;
    await cubit.load('pt');
    expect(cubit.state.ready, isTrue);
  });
}
