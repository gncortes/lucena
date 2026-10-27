import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_profile_repository.dart';
import '../../testing/fakes/fake_school_repositories.dart';

class _School extends FakeLessonRepository {
  bool offline = true;
  @override
  Future<Course> course() async {
    if (offline) throw const LessonContentUnavailable();
    return super.course();
  }
}

class _Endgames extends FakeEndgameLessonRepository {
  bool offline = true;
  @override
  Future<EndgameTrail> trail() async {
    if (offline) throw const LessonContentUnavailable();
    return super.trail();
  }
}

void main() {
  test(
    'school unavailable remains usable and retries without deleting progress',
    () async {
      final lessons = _School();
      const saved = SchoolProgress(completed: {'pieces.rook'});
      final progress = FakeSchoolProgressRepository(saved);
      final cubit = SchoolCubit(
        lessons: lessons,
        progress: progress,
        characters: FakeCharacterRepository(),
        profile: FakeProfileRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('pt');
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.course.lessons, isEmpty);
      expect(await progress.load(), saved);
      lessons.offline = false;
      await cubit.load('pt');
      expect(cubit.state.course.lessons, isNotEmpty);
      expect(cubit.state.completed, saved.completed);
    },
  );

  test(
    'endgames unavailable remains usable and retries without deleting progress',
    () async {
      final lessons = _Endgames();
      const saved = EndgameProgress(
        ongoing: LessonCheckpoint(lessonId: 'rook.lucena', step: 2),
      );
      final progress = FakeEndgameProgressRepository(saved);
      final cubit = EndgamesCubit(
        lessons: lessons,
        progress: progress,
        characters: FakeCharacterRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('pt');
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.trail.lessons, isEmpty);
      expect(await progress.load(), saved);
      lessons.offline = false;
      await cubit.load('pt');
      expect(cubit.state.trail.lessons, isNotEmpty);
      expect(cubit.state.progress, saved);
    },
  );
}
