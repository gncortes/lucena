import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/training_profile_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_progress_screen.dart';
import 'package:lucena/ui/training_profile/widgets/training_profile_screen.dart';
import 'package:lucena/ui/training_profile/widgets/training_profile_why_screen.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../course_entry/course_states_canvas_test.dart' as capture;

// Explicit authored illustration fixtures, not measurements of user progression.
TrainingResources _fixture(bool switched) {
  const slots = {
    'london': 'Sistema London',
    'caroKann': 'Caro-Kann',
    'slav': 'Eslava',
    'others': 'Outras',
    'e4White': '1.e4',
    'dragon': 'Dragão Acelerado',
    'kingsIndian': 'Índia do Rei',
    'othersAggr': 'Outras',
  };
  const aggressiveTitles = [
    'Escocesa: o peão de e5 expulsa o cavalo',
    'Alapin: a dama que chega cedo vira alvo',
    'Escandinava: espaço e tempo contra a dama',
    'Tarrasch: jogar contra o peão isolado',
    'Panov: o ataque com peças ativas',
  ];
  final lessons = <TrainingLesson>[];
  final banks = <String, List<OpeningTrecho>>{};
  for (final (slotIndex, entry) in slots.entries.indexed) {
    final profile = slotIndex < 4 ? 'solido' : 'agressivo';
    for (var part = 1; part <= 5; part++) {
      final id = 'pilares.c${part + 4}.${entry.key}$part';
      lessons.add(
        TrainingLesson(
          id: id,
          kind: TrainingLessonKind.opening,
          title: entry.key == 'e4White'
              ? aggressiveTitles[part - 1]
              : entry.value,
          partId: 'p$part',
          groupId: 'c${part + 4}',
          openingProfile: profile,
          visible: profile == (switched ? 'agressivo' : 'solido'),
          inCourseOrder: !switched || part >= 2,
        ),
      );
      banks[id] = [
        for (var i = 1; i <= 5; i++)
          OpeningTrecho(
            id: 'line$i',
            title: entry.value,
            moves: const ['d2d4'],
            openingId: entry.key,
            profile: profile,
          ),
      ];
    }
  }
  return TrainingResources(lessons: lessons, openings: banks);
}

void main() {
  setUpAll(Goldens.loadFonts);
  setUp(() async {
    capture.settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await capture.settings.load();
    capture.speech = SpeechCubit(FakeVoiceRepository());
    await capture.speech.load();
  });
  tearDown(() async {
    await capture.settings.close();
    await capture.speech.close();
  });

  for (final size in capture.sizes) {
    for (final name in [
      'PerfilMomento',
      'PerfilEscolha',
      'PerfilEscolhaAgressivo',
      'PerfilPorQue',
      'PerfilTrocar',
      'ProgressoAberturasTrocar',
      'PerfilTrocado',
      if (size == const Size(412, 917)) 'PerfilIndisponivel',
    ]) {
      testWidgets('$name $size · explicit Canvas fixture', (tester) async {
        setPhoneSize(tester, size);
        final switched = name == 'PerfilTrocado';
        final hasProgress =
            name == 'PerfilTrocar' || name == 'ProgressoAberturasTrocar';
        final progress = hasProgress || switched;
        final resources = _fixture(switched);
        final state = TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'canvas-profile-fixture',
          onboardingDone: true,
          openingProfile: switched ? 'agressivo' : 'solido',
          openingProfileStartPart: progress ? 'p2' : '',
          completedLessons: hasProgress
              ? {
                  for (final lesson in resources.lessons.where(
                    (l) => l.partId == 'p1',
                  ))
                    lesson.id: '2026-10-29',
                }
              : {},
          tab: progress ? CourseGuideTab.progress : CourseGuideTab.lesson,
          openings: hasProgress
              ? {
                  for (final id in ['london', 'caroKann', 'slav', 'others'])
                    'pilares.c5.${id}1': OpeningTrack(
                      lessonId: 'pilares.c5.${id}1',
                      startedOn: '2026-10-29',
                      doneTrechos: const {'line1': '2026-10-30'},
                      firstTry: const {
                        'line1': [true, false, true],
                      },
                    ),
                }
              : {},
        );
        final repo = FakeTrainingRepository(
          states: {TrainingCourse.pilares: state},
          content: {TrainingCourse.pilares: resources},
        );
        final cubit = CourseGuideCubit(
          repository: repo,
          config: TrainingCourseConfig.pilares,
          now: FakeNow(DateTime(2026, 10, 30)),
        );
        addTearDown(cubit.close);
        addTearDown(repo.dispose);
        await cubit.load();
        Widget child;
        if (name == 'PerfilEscolha' || name == 'PerfilEscolhaAgressivo') {
          child = TrainingProfileScreen(
            onBack: () {},
            onChosen: () {},
            onWhyLondon: () {},
          );
        } else if (name == 'PerfilIndisponivel') {
          child = TrainingProfileWhyScreen(
            onClose: () {},
            openingName: 'Caro-Kann',
          );
        } else if (name == 'PerfilPorQue') {
          child = TrainingProfileWhyScreen(onClose: () {});
        } else {
          child = CourseGuideScreen(
            onBack: () {},
            onPlan: () {},
            onHelp: () {},
            onWelcomeContinue: () {},
            onLesson: (_) {},
            onChapter: (_) {},
            goalsBuilder: (_) => const SizedBox(),
            progressBuilder: (_) => const SizedBox(),
            centerTitle: progress,
            showHeaderActions: !progress,
            titleOverride: progress ? 'Aberturas' : null,
            bodyOverride: progress
                ? TrainingOpeningProgressScreen(
                    onTrain: (_, _) {},
                    onLesson: (_) {},
                  )
                : null,
          );
        }
        await capture.mount(
          tester,
          BlocProvider.value(value: cubit, child: child),
        );
        if (name == 'PerfilEscolhaAgressivo') {
          await tester.tap(find.byKey(TrainingProfileKeys.card('agressivo')));
          await tester.pumpAndSettle();
        }
        if (name == 'PerfilTrocar') {
          await tester.tap(find.byKey(TrainingKeys.openingProfile('change')));
          await tester.pumpAndSettle();
          expect(find.text('Trocar para o Agressivo?'), findsOneWidget);
        }
        if (name == 'PerfilMomento') {
          expect(find.byKey(TrainingProfileKeys.moment), findsOneWidget);
        }
        await capture.shot(tester, name, size);
      });
    }
  }
}
