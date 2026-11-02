import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/featured_rules.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../course_entry/course_states_canvas_test.dart' as capture;

class _SnapshotHome extends HomeCubit {
  _SnapshotHome(HomeState snapshot)
    : super(
        journey: FakeJourneyRepository(),
        progress: FakeProgressRepository(),
        onboarding: FakeOnboardingRepository(),
        characters: FakeCharacterRepository(),
        rating: FakeRatingRepository(),
        lessons: FakeLessonRepository(),
        school: FakeSchoolProgressRepository(),
        profile: FakeProfileRepository(),
        endgameLessons: FakeEndgameLessonRepository(),
        endgameProgress: FakeEndgameProgressRepository(),
      ) {
    emit(snapshot);
  }
}

void main() {
  final source = io.File('docs/qa/T85-integral/artboard-snapshots.json');
  if (!source.existsSync()) {
    test(
      'Canvas Home snapshots are local evidence fixtures',
      () {},
      skip: true,
    );
    return;
  }
  final samples = (jsonDecode(source.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>()
      .where(
        (entry) => const {
          'Home',
          'HomeMeta',
          'HomeAbertura',
          'HomeFeito',
          'HomeFolga',
        }.contains(entry['id']),
      );
  setUpAll(Goldens.loadFonts);
  for (final sample in samples) {
    for (final size in [const Size(412, 917), const Size(360, 740)]) {
      testWidgets('Canvas ${sample['id']} $size', (tester) async {
        setPhoneSize(tester, size);
        capture.settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await capture.settings.load();
        capture.speech = SpeechCubit(
          FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
        );
        await capture.speech.load();
        addTearDown(capture.settings.close);
        addTearDown(capture.speech.close);
        final hero = (sample['imports'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((p) => p['name'] == 'CompHeroContinuar');
        final status = switch (sample['id']) {
          'HomeMeta' => HomeCourseStatus.exercise,
          'HomeAbertura' => HomeCourseStatus.opening,
          'HomeFeito' => HomeCourseStatus.done,
          'HomeFolga' => HomeCourseStatus.dayOff,
          _ => HomeCourseStatus.lesson,
        };
        final training = HomeTraining(
          config: TrainingCourseConfig.pilares,
          state: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'canvas',
          ),
          resources: TrainingResources(
            lessons: [
              TrainingLesson(
                id: 'visual',
                kind: status == HomeCourseStatus.opening
                    ? TrainingLessonKind.opening
                    : TrainingLessonKind.theme,
                title: hero['titulo'] as String,
              ),
            ],
          ),
          card: HomeCourseCard(status, switch (status) {
            HomeCourseStatus.done ||
            HomeCourseStatus.dayOff => HomeCourseDestination.lessonTab,
            HomeCourseStatus.exercise => HomeCourseDestination.exercise,
            HomeCourseStatus.opening => HomeCourseDestination.trecho,
            _ => HomeCourseDestination.lesson,
          }, 'visual'),
          lessonPreview: LessonScriptState(
            ready: true,
            fen: hero['fen'] as String? ?? '',
            orientation: hero['lado'] == 'pretas' ? Side.black : Side.white,
          ),
        );
        final base = sampleFeaturedCatalog().finals.first;
        // The featured panel is static surrounding context, not a chess verdict.
        final featured = FeaturedItem(
          played: false,
          isNew: false,
          endgame: FeaturedEndgame(
            id: 'canvas',
            kind: base.kind,
            origin: base.origin,
            goal: base.goal,
            suggested: base.suggested,
            fen: '8/8/8/2k5/8/1PK5/8/1r6 w - - 0 1',
            white: const FeaturedPlayer(name: 'Magnus Carlsen'),
            black: const FeaturedPlayer(name: 'Wesley So'),
          ),
          tournament: const FeaturedTournament(
            id: 'canvas',
            name: 'Norway Chess',
            year: 2017,
            country: 'NO',
            summary: LocalizedText({}),
          ),
        );
        final cubit = _SnapshotHome(
          HomeState(
            ready: true,
            boardControlsDone: true,
            training: training,
            teacher: FakeCharacterRepository.viktor,
            rating: 1310,
            ratingChange: 9,
            featured: featured,
            layout: const HomeLayout(
              order: [
                HomePath.journey,
                HomePath.endgames,
                HomePath.train,
                HomePath.race,
                HomePath.stars,
              ],
              visible: {
                HomePath.journey,
                HomePath.endgames,
                HomePath.train,
                HomePath.race,
                HomePath.stars,
              },
            ),
          ),
        );
        addTearDown(cubit.close);
        await capture.mount(
          tester,
          BlocProvider<HomeCubit>.value(
            value: cubit,
            child: const HomeScreen(),
          ),
        );
        await capture.shot(tester, sample['id'] as String, size);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}
