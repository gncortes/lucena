// Synthetic native harness for Canvas/transition evidence. Never a release target.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:lucena/ui/course_entry/widgets/course_content_states.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../fakes/fake_character_repository.dart';
import '../fakes/fake_course_training_repository.dart';
import '../fakes/fake_now.dart';
import '../fakes/fake_settings_repository.dart';
import '../fakes/fake_voice_repository.dart';
import '../test_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final clock = FakeNow(DateTime(2026, 10, 30, 12));
  final settings = SettingsCubit(
    FakeSettingsRepository(const AppSettings(languageCode: 'pt')),
    languages: AppLanguage.selectable,
  );
  final speech = SpeechCubit(
    FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
  );
  await settings.load();
  await speech.load();
  final repository = FakeTrainingRepository(
    states: {
      TrainingCourse.pilares: TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'synthetic-native',
        day: DayGoals(
          date: '2026-10-30',
          studyDay: true,
          goals: [
            TrainingGoal(
              kind: GoalKind.openings,
              ref: 'openings',
              items: {'london': 'london.part-2'},
            ),
          ],
        ),
        openings: {
          'london': OpeningTrack(
            lessonId: 'london',
            startedOn: '2026-10-29',
            doneTrechos: {'london.part-1': '2026-10-29'},
            firstTry: {
              'london.part-1': [true],
            },
          ),
        },
      ),
    },
    content: {
      TrainingCourse.pilares: TrainingResources(
        openings: {
          'london': [
            for (var i = 1; i <= 5; i++)
              OpeningTrecho(
                id: 'london.part-$i',
                title: 'Sistema London',
                lines: [
                  ['d2d4', 'd7d5', 'c1f4'],
                  ['d2d4', 'g8f6', 'c1f4'],
                ],
              ),
          ],
        },
      ),
    },
  );
  final finalRepository = FakeTrainingRepository(
    states: {
      TrainingCourse.pilares: (await repository.load(TrainingCourse.pilares))
          .copyWith(
            openings: {
              'london': OpeningTrack(
                lessonId: 'london',
                startedOn: '2026-10-29',
                doneTrechos: {
                  for (var i = 1; i <= 4; i++) 'london.part-$i': '2026-10-29',
                },
              ),
            },
          ),
    },
    content: repository.content,
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('T85 · evidência sintética')),
          body: ListView(
            children: [
              ListTile(
                title: const Text('Abertura ramificada'),
                onTap: () => context.push('/opening'),
              ),
              ListTile(
                title: const Text('Sem espaço'),
                onTap: () => context.push('/storage'),
              ),
              ListTile(
                title: const Text('Última parte'),
                onTap: () => context.push('/last-part'),
              ),
            ],
          ),
        ),
        routes: [
          GoRoute(
            path: 'last-part',
            builder: (context, state) => TrainingOpeningScreen(
              repository: finalRepository,
              config: TrainingCourseConfig.pilares,
              now: clock,
              lessonId: 'london',
              partId: 'london.part-5',
              teacher: FakeCharacterRepository.viktor,
              onNextGoal: () => context.pop(),
              onProgress: () => context.pop(),
            ),
          ),
          GoRoute(
            path: 'opening',
            builder: (context, state) => TrainingOpeningScreen(
              repository: repository,
              config: TrainingCourseConfig.pilares,
              now: clock,
              lessonId: 'london',
              teacher: FakeCharacterRepository.viktor,
              onNextGoal: () => context.pop(),
              onProgress: () => context.pop(),
            ),
          ),
          GoRoute(
            path: 'storage',
            builder: (context, state) => Scaffold(
              appBar: LucenaAppBar(
                toolbarHeight: 64,
                title: const Text('Espeto'),
              ),
              body: CourseDownloadFailure(
                failure: const LessonContentStorageUnavailable(2 * 1024 * 1024),
                chapter: true,
                onRetry: () {},
              ),
            ),
          ),
        ],
      ),
    ],
  );
  runApp(
    TestApp(
      locale: const Locale('pt'),
      settingsCubit: settings,
      speechCubit: speech,
      router: router,
      child: const SizedBox(),
    ),
  );
}
