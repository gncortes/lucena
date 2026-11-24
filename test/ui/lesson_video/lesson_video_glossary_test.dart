import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/glossary_term.dart';
import 'package:lucena/ui/core/keys/lesson_video_keys.dart';
import 'package:lucena/ui/glossary/widgets/glossary_text.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';
import 'package:lucena/ui/lesson_video/widgets/lesson_video_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

void main() {
  const opposition = GlossaryTerm(
    id: 'oposicao',
    name: 'oposição',
    definition: 'Reis frente a frente com uma casa entre eles.',
  );

  Future<(LessonVideoCubit, List<GlossaryTerm>, List<String>)> pump(
    WidgetTester tester,
  ) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final texts = {...scriptTexts(), 'e1': 'Aqui a oposição decide.'};
    final cubit = LessonVideoCubit(
      scripts: FakeLessonScriptRepository(scriptFixture(), texts),
      videos: FakeLessonVideoRepository(),
      interruptions: FakeVideoInterruptionsRepository(),
      now: FakeNow(DateTime(2026, 11, 23, 10)),
      lessonId: 'pawns.test',
      partId: 'distant',
      scriptPath: 'roteiro.json',
      ticker: (_, _) => null,
    );
    addTearDown(cubit.close);
    final opened = <GlossaryTerm>[];
    final events = <String>[];
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => LessonVideoScreen(
              title: 'Oposição distante',
              terms: const [opposition],
              onGlossary: () {
                events.add(cubit.state.playing ? 'tocando' : 'pausado');
                cubit.pause();
                events.add('livro');
              },
              onTerm: (term) {
                cubit.pause();
                opened.add(term);
              },
            ),
          ),
        ),
      ),
    );
    await cubit.start();
    await tester.pump(const Duration(milliseconds: 300));
    return (cubit, opened, events);
  }

  testWidgets('termo sublinhado na fala pausa o vídeo e abre o termo', (
    tester,
  ) async {
    final (cubit, opened, _) = await pump(tester);
    expect(cubit.state.playing, isTrue);
    final caption = tester.widget<GlossaryText>(
      find.byKey(LessonVideoKeys.caption),
    );
    expect(caption.terms.single.id, 'oposicao');
    caption.onOpen!(opposition);
    await tester.pump();
    expect(opened.single.id, 'oposicao');
    expect(cubit.state.playing, isFalse);
  });

  group('Vídeo 17 / E8: voltar do Glossário', () {
    testWidgets('tocava → pausa enquanto aberto e volta a tocar', (
      tester,
    ) async {
      final (cubit, _, _) = await pump(tester);
      final glossary = Completer<void>();
      expect(cubit.state.playing, isTrue);
      final away = cubit.pauseWhile(() => glossary.future);
      await tester.pump();
      expect(cubit.state.playing, isFalse);
      final at = cubit.state.position;
      glossary.complete();
      await away;
      expect(cubit.state.playing, isTrue);
      expect(cubit.state.position, at, reason: 'no mesmo instante');
    });

    testWidgets('pausado → continua pausado na volta', (tester) async {
      final (cubit, _, _) = await pump(tester);
      cubit.pause();
      await cubit.pauseWhile(() async {});
      expect(cubit.state.playing, isFalse);
    });
  });

  testWidgets('o livro do topo abre o Glossário', (tester) async {
    final (cubit, _, events) = await pump(tester);
    await tester.tap(find.byKey(LessonVideoKeys.glossaryButton));
    await tester.pump();
    expect(events, ['tocando', 'livro']);
    expect(cubit.state.playing, isFalse);
  });
}
