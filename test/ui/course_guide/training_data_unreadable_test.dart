import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/load_failure.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';
import '../../data/repositories/training/training_repository_test.dart'
    show MemoryPreferences, MemoryContent;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  // H-TRE-17 gap 4: dado ilegível mostra erro com nova tentativa e não apaga.
  testWidgets('estado ilegível mostra erro com tentar de novo e não apaga', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    const broken = '{"version":1,"course":"pilares","tab":"nao-existe"';
    final key = TrainingRepositoryLocal.key(TrainingCourse.pilares);
    prefs.values[key] = broken;
    final repository = TrainingRepositoryLocal(
      prefs,
      LessonContentAssets(reader: MemoryContent()),
      installSeed: 'test',
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 10, 29)),
    );
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.failed, isTrue);
    expect(cubit.state.failure, LoadFailure.generic);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: CourseGuideScreen(
            onBack: () {},
            onPlan: () {},
            onHelp: () {},
            onWelcomeContinue: () {},
            onLesson: (_) {},
            onChapter: (_) {},
            goalsBuilder: (_) => const SizedBox(),
            progressBuilder: (_) => const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
    expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pump();
    await tester.pump();
    expect(prefs.values[key], broken, reason: 'nada é apagado nem regravado');
    expect(cubit.state.failed, isTrue);
  });
}
