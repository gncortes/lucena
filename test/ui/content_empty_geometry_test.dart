import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';
import 'package:lucena/ui/school/widgets/school_screen.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_profile_repository.dart';
import '../../testing/fakes/fake_school_repositories.dart';
import '../../testing/test_app.dart';

void main() {
  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    for (final school in [true, false]) {
      testWidgets(
        '${school ? 'Escola' : 'Finais'} $size: grupo vazio no centro do corpo útil',
        (tester) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = size
            ..padding = const FakeViewPadding(top: 56, bottom: 24);
          addTearDown(tester.view.reset);
          late Widget screen;
          if (school) {
            final cubit = SchoolCubit(
              lessons: FakeLessonRepository(course: const Course(modules: [])),
              progress: FakeSchoolProgressRepository(),
              characters: FakeCharacterRepository(),
              profile: FakeProfileRepository(),
            );
            addTearDown(cubit.close);
            await cubit.load('pt');
            screen = BlocProvider.value(
              value: cubit,
              child: const SchoolScreen(),
            );
          } else {
            final cubit = EndgamesCubit(
              lessons: FakeEndgameLessonRepository(trail: EndgameTrail.empty),
              progress: FakeEndgameProgressRepository(),
              characters: FakeCharacterRepository(),
            );
            addTearDown(cubit.close);
            await cubit.load('pt');
            screen = BlocProvider.value(
              value: cubit,
              child: const EndgamesScreen(),
            );
          }
          await tester.pumpWidget(
            TestApp(locale: const Locale('pt'), child: screen),
          );
          await tester.pumpAndSettle();
          final group = tester.getRect(find.byKey(CoreKeys.emptyState));
          final top = 56 + kToolbarHeight;
          final bottom = size.height - 24;
          expect(group.center.dx, closeTo(size.width / 2, .5));
          expect(group.center.dy, closeTo((top + bottom) / 2, .5));
          expect(group.top, greaterThanOrEqualTo(top));
          expect(group.bottom, lessThanOrEqualTo(bottom));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
