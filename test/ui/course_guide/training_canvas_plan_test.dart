import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_plan_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../course_entry/course_states_canvas_test.dart' as capture;

void main() {
  setUpAll(Goldens.loadFonts);
  for (final name in [
    'Plano',
    'PlanoEditar',
    'PlanoHorario',
    'PlanoNotificacaoNegada',
    'PlanoPermissao',
    'EscolaPlano',
    'EscolaPlanoEditar',
    'EscolaPlanoHorario',
  ]) {
    for (final size in [const Size(412, 917), const Size(360, 740)]) {
      testWidgets('Canvas $name $size', (tester) async {
        final originalShadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
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
          final config = name.startsWith('Escola')
              ? TrainingCourseConfig.escola
              : TrainingCourseConfig.pilares;
          final editing =
              name.endsWith('Editar') ||
              name.endsWith('Horario') ||
              name.endsWith('Negada');
          final push = FakePushRepository(
            allowed:
                name != 'PlanoNotificacaoNegada' && name != 'PlanoPermissao',
          );
          final repository = FakeTrainingRepository(
            content: {config.course: TrainingResources()},
            states: {
              config.course: TrainingState(
                course: config.course,
                installSeed: 'canvas-plan',
                onboardingDone: editing,
                plan: const TrainingPlan(weekdays: 127),
              ),
            },
          );
          addTearDown(repository.dispose);
          final cubit = TrainingPlanCubit(
            repository: repository,
            config: config,
            now: FakeNow(DateTime(2026, 10, 26, 12)),
            push: push,
          );
          addTearDown(cubit.close);
          await cubit.load();
          await capture.mount(
            tester,
            BlocProvider.value(
              value: cubit,
              child: TrainingPlanScreen(onBack: () {}, onSaved: () {}),
            ),
          );
          if (name.endsWith('Horario') || name == 'PlanoPermissao') {
            final target = find.byKey(
              name.endsWith('Horario')
                  ? TrainingKeys.reminderTime
                  : TrainingKeys.planSave,
            );
            await tester.scrollUntilVisible(
              target,
              120,
              scrollable: find
                  .descendant(
                    of: find.byKey(TrainingKeys.planScroll),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(
              name.endsWith('Horario')
                  ? find.byType(TimePickerDialog)
                  : find.byKey(TrainingKeys.permissionDialog),
              findsOneWidget,
            );
          }
          await capture.shot(tester, name, size);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        } finally {
          debugDisableShadows = originalShadows;
        }
      });
    }
  }
}
