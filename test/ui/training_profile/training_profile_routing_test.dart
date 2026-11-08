import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/placement/placement_repository.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/training_history_source.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_profile_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/domain/models/app_language.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

class _Downloads extends CourseDownloadRepository {
  _Downloads(this.repository) : super.unconfigured();
  final FakeTrainingRepository repository;
  final calls = <(String, String?)>[];
  @override
  Future<bool> isDownloaded(
    TrainingCourseConfig config, {
    String? chapterId,
  }) async => true;
  @override
  Future<void> prepare(TrainingCourseConfig config, {String? chapterId}) async {
    final profile = (await repository.load(config.course)).openingProfile;
    calls.add((profile, chapterId));
    repository.content[config.course] = TrainingResources(
      lessons: [
        for (final lesson in repository.content[config.course]!.lessons)
          TrainingLesson.fromJson({
            ...lesson.toJson(),
            'visible': lesson.openingProfile == profile,
          }),
      ],
    );
  }
}

void main() {
  for (final catalog in [false, true]) {
    testWidgets(
      'choose from ${catalog ? 'direct catalog chapter' : 'guide'} downloads and launches selected first lesson',
      (tester) async {
        setPhoneSize(tester, const Size(412, 917));
        final now = FakeNow(DateTime(2026, 10, 30));
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        final repository = FakeTrainingRepository(
          states: {
            TrainingCourse.pilares: TrainingState(
              course: TrainingCourse.pilares,
              installSeed: 'routing-profile',
              onboardingDone: true,
            ),
          },
          content: {
            TrainingCourse.pilares: TrainingResources(
              lessons: [
                if (catalog)
                  const TrainingLesson(
                    id: 'pilares.c4.london',
                    kind: TrainingLessonKind.opening,
                    title: 'Earlier opening',
                    groupId: 'pilares.c4',
                    partId: 'p1',
                    openingProfile: 'solido',
                  ),
                TrainingLesson(
                  id: 'pilares.c5.london',
                  kind: TrainingLessonKind.opening,
                  title: 'London',
                  groupId: 'pilares.c5',
                  partId: catalog ? 'p2' : 'p1',
                  openingProfile: 'solido',
                ),
                TrainingLesson(
                  id: 'pilares.c5.e4White',
                  kind: TrainingLessonKind.opening,
                  title: '1.e4',
                  groupId: 'pilares.c5',
                  partId: catalog ? 'p2' : 'p1',
                  openingProfile: 'agressivo',
                  visible: false,
                ),
              ],
            ),
          },
        );
        final downloads = _Downloads(repository);
        String? destinationPart;
        final router = GoRouter(
          initialLocation: catalog
              ? '/training/pilares/chapter/pilares.c5'
              : '/training/pilares',
          routes: [
            trainingRoute(),
            GoRoute(
              path: '/endgames/:chapter/roteiro',
              builder: (_, state) {
                destinationPart = state.uri.queryParameters['part'];
                return const Scaffold(body: Text('selected-lesson'));
              },
            ),
          ],
        );
        addTearDown(repository.dispose);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(
                value: FakeAccountRepository(
                  account: FakeAccountRepository.google,
                ),
              ),
              RepositoryProvider<TrainingRepository>.value(value: repository),
              RepositoryProvider<CourseDownloadRepository>.value(
                value: downloads,
              ),
              RepositoryProvider<TrainingHistorySource>.value(
                value: TrainingHistorySource(
                  repository,
                  learning: null,
                  now: now,
                ),
              ),
              RepositoryProvider<EndgameLessonRepository>.value(
                value: FakeEndgameLessonRepository(),
              ),
              RepositoryProvider<EndgameProgressRepository>.value(
                value: FakeEndgameProgressRepository(),
              ),
              RepositoryProvider<PlacementRepository>.value(
                value: FakePlacementRepository(),
              ),
              RepositoryProvider<CharacterRepository>.value(
                value: FakeCharacterRepository(),
              ),
              RepositoryProvider<Now>.value(value: now),
            ],
            child: TestApp(
              settingsCubit: settings,
              locale: const Locale('pt'),
              router: router,
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            catalog
                ? CourseGuideKeys.chapterContinue
                : CourseGuideKeys.continueButton,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(TrainingProfileKeys.screen), findsOneWidget);
        expect(find.text('selected-lesson'), findsNothing);
        if (catalog) {
          await tester.tap(find.byKey(TrainingProfileKeys.card('agressivo')));
          await tester.pump();
          await tester.tap(find.byKey(TrainingProfileKeys.chip('solido', 1)));
          await tester.pumpAndSettle();
          expect(find.text('Por que Caro-Kann?'), findsOneWidget);
          expect(
            find.text('Esta apresentação ainda não está disponível.'),
            findsOneWidget,
          );
          expect(find.byKey(TrainingProfileKeys.whyBoard), findsNothing);
          await tester.tap(find.byKey(TrainingProfileKeys.whyClose));
          await tester.pumpAndSettle();
          expect(find.text('Escolher o Agressivo'), findsOneWidget);
          expect(
            (await repository.load(TrainingCourse.pilares))
                .openingProfileStartPart,
            isEmpty,
          );
          expect(
            (await repository.load(TrainingCourse.pilares)).openingProfile,
            'solido',
          );
          await tester.tap(find.byKey(TrainingProfileKeys.chip('solido', 0)));
          await tester.pumpAndSettle();
          expect(find.byKey(TrainingProfileKeys.why), findsOneWidget);
          await tester.tap(find.byKey(TrainingProfileKeys.whyClose));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(TrainingProfileKeys.card('agressivo')));
        await tester.pump();
        await tester.tap(find.byKey(TrainingProfileKeys.choose));
        await tester.pumpAndSettle();
        expect(find.text('selected-lesson'), findsOneWidget);
        expect(destinationPart, 'e4White');
        expect(downloads.calls, contains(('agressivo', null)));
        expect(
          (await repository.load(TrainingCourse.pilares))
              .openingProfileStartPart,
          catalog ? 'p2' : 'p1',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
