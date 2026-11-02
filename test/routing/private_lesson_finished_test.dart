@Tags(['private-content'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/progress/progress_repository.dart';
import 'package:lucena/data/repositories/race/race_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository.dart';
import 'package:lucena/data/repositories/training/training_endgame_content.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';
import 'package:lucena/ui/lesson_finished/widgets/lesson_finished_screen.dart';

import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_progress_repository.dart';
import '../../testing/fakes/fake_race_repository.dart';
import '../../testing/fakes/fake_school_repositories.dart';
import '../../testing/phone_size.dart';
import '../../testing/test_app.dart';

class _ChapterFiles extends AssetService {
  @override
  Future<String> loadString(String path) async {
    final file = File(path);
    if (!await file.exists()) throw const LessonContentNotFound();
    final text = await file.readAsString();
    if (path != TrainingCourseConfig.pilares.indexSource) return text;
    final original = jsonDecode(text) as Map;
    return jsonEncode({
      ...original,
      'partes': [
        for (final part in original['partes'] as List)
          {
            ...part as Map,
            'capitulos': [
              for (final chapter in part['capitulos'] as List)
                if ((chapter as Map)['id'] == 'pilares.c1') chapter,
            ],
          },
      ],
    });
  }
}

void main() {
  for (final kind in [SurveyKind.endgames, SurveyKind.school]) {
    testWidgets(
      'actual finished route scopes only private endgames: ${kind.code}',
      (tester) async {
        setPhoneSize(tester, const Size(412, 915));
        final public = FakeEndgameLessonRepository();
        final school = FakeLessonRepository();
        final private = TrainingEndgameContent.fromConfigs(
          _ChapterFiles(),
          school: school,
          configs: [TrainingCourseConfig.pilares],
        );
        if (kind == SurveyKind.endgames) {
          // Real File I/O runs outside the widget fake clock. Source cold loads
          // are covered separately; this case verifies the actual route scope.
          await tester.runAsync(() async {
            final source = private.forId('pilares.c1')!;
            await source.trail();
            await source.texts('pt');
          });
        }
        final router = buildRouter(
          initialLocation: Routes.lessonFinished(kind, 'pilares.c1'),
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EndgameLessonRepository>.value(value: public),
              RepositoryProvider<TrainingEndgameContent?>.value(value: private),
              RepositoryProvider<LessonRepository>.value(value: school),
              RepositoryProvider<RaceRepository>.value(
                value: FakeRaceRepository(now: FakeNow(DateTime(2026, 10, 29))),
              ),
              RepositoryProvider<ProgressRepository>.value(
                value: FakeProgressRepository(),
              ),
            ],
            child: TestApp(
              locale: const Locale('pt'),
              router: router,
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(LessonFinishedScreen));
        final cubit = context.read<LessonFinishedCubit>();
        final expectedSource = kind == SurveyKind.endgames
            ? private.forId('pilares.c1')!
            : public;
        expect(context.read<EndgameLessonRepository>(), same(expectedSource));
        expect(cubit.endgames, same(expectedSource));
        // Await real file-backed loading outside the widget fake clock;
        // production source and Cubit above are still constructed by buildRouter.
        if (!cubit.state.ready) {
          await tester.runAsync(() => cubit.load('pt'));
          await tester.pumpAndSettle();
        }
        final state = cubit.state;
        expect(state.ready, isTrue);
        expect(state.practice, isNull);
        if (kind == SurveyKind.endgames) {
          final index = jsonDecode(
            File(TrainingCourseConfig.pilares.indexSource).readAsStringSync(),
          ) as Map;
          final title = [
            for (final part in index['partes'] as List)
              for (final chapter in (part as Map)['capitulos'] as List)
                if ((chapter as Map)['id'] == 'pilares.c1') chapter['titulo'],
          ].single;
          expect(state.title, title);
          expect(state.title, isNot('pilares.c1'));
          expect(state.hasExercises, isTrue);
          expect(
            context.read<EndgameLessonRepository>(),
            same(private.forId('pilares.c1')),
          );
          expect(find.byKey(NextStepsKeys.option('exercises')), findsOneWidget);
          expect(find.byKey(NextStepsKeys.option('train')), findsNothing);
        } else {
          expect(context.read<EndgameLessonRepository>(), same(public));
          expect(state.hasExercises, isFalse);
          expect(find.byKey(NextStepsKeys.block), findsNothing);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
