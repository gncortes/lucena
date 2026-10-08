import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// O rodapé do passo de pensar ("Voltar à posição" e "Ver explicação
/// agora") cabe em celular com letra grande: os dois dividem a largura e o
/// texto encolhe, sem estourar.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lesson = Lesson.parted(
    id: 'rook.lucena',
    parts: const [
      LessonPart(
        id: 'bridge',
        steps: [
          ThinkStep(id: 'think', fen: fen, minutes: 5),
          TalkStep(id: 'end', fen: fen),
        ],
      ),
    ],
  );
  final trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: lesson,
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  );

  for (final (locale, scale) in [
    (const Locale('pt'), 1.3),
    (const Locale('de'), 1.3),
    (const Locale('pt'), 1.0),
  ]) {
    testWidgets('pensando, em ${locale.languageCode} com letra ×$scale e 360 '
        'dp: os dois botões cabem', (tester) async {
      const size = Size(360, 780);
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      final cubit = LessonCubit(
        source: EndgameLessonSource(
          FakeEndgameLessonRepository(
            trail: trail,
            texts: LessonTexts.fromJson({
              'rook.lucena.think': 'Black to move. What is the best plan?',
            }),
          ),
          FakeEndgameProgressRepository(),
        ),
        characters: FakeCharacterRepository(),
        opponent: FakeOpponentRepository(),
        now: FakeNow(DateTime.utc(2026, 10, 8, 20)),
        replyDelay: Duration.zero,
      );
      addTearDown(cubit.close);
      await cubit.load('rook.lucena', locale.languageCode);
      final settings = SettingsCubit(
        // O tempo de pensar já escolhido: a aula abre direto.
        FakeSettingsRepository(const AppSettings(thinkChosen: true)),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          locale: locale,
          settingsCubit: settings,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: BlocProvider.value(
              value: cubit,
              child: const LessonScreen(),
            ),
          ),
        ),
      );
      // O relógio de pensar anda sozinho: avança um pouco, sem esperar ele
      // acabar.
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      for (final key in [LessonKeys.thinkReset, LessonKeys.thinkSkip]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(find.byKey(key).hitTestable(), findsOneWidget);
      }
      // Os dois lado a lado, sem se cobrir.
      expect(
        tester.getRect(find.byKey(LessonKeys.thinkReset)).right,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(LessonKeys.thinkSkip)).left,
        ),
      );
    });
  }

  testWidgets('primeira aula com passo de pensar: a escolha do tempo vem '
      'antes; escolhido, a aula segue com ele e não pergunta de novo', (
    tester,
  ) async {
    const size = Size(400, 800);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: LessonTexts.empty),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 8, 20)),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final repository = FakeSettingsRepository(const AppSettings());
    final settings = SettingsCubit(
      repository,
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(LessonKeys.thinkChooser), findsOneWidget);
    expect(find.byKey(LessonKeys.thinkReset), findsNothing);

    await tester.tap(find.byKey(LessonKeys.thinkChoice(3)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(LessonKeys.thinkChooser), findsNothing);
    expect(find.byKey(LessonKeys.thinkReset), findsOneWidget);
    expect(cubit.state.thinkTime, const Duration(minutes: 3));
    expect(repository.settings.thinkMinutes, 3);
    expect(repository.settings.thinkChosen, isTrue);
  });
}
