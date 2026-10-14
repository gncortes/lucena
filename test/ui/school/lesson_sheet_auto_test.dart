import 'dart:async';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

/// Folha automática do Viktor numa parte real da lição da oposição distante
/// (360x780). A parte `distant` virou roteiro (T70) e saiu daqui: os casos de
/// texto novo longo, passo revisto e lance jogado dependiam dos passos dela.
void main() {
  const lessonId = 'pawns.distantOpposition';
  late EndgameLesson real;
  late LessonTexts texts;

  setUpAll(() async {
    final repo = AssetEndgameLessonRepository(
      _Assets(),
      school: AssetLessonRepository(_Assets()),
    );
    real = (await repo.trail()).lessons.firstWhere((l) => l.id == lessonId);
    texts = await repo.texts('pt');
  });

  Future<LessonCubit> pump(
    WidgetTester tester, {
    Size size = const Size(360, 780),
    bool shortText = false,
    bool disableAnimations = false,
    Duration replyDelay = Duration.zero,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final lesson = shortText
        ? EndgameLesson(
            id: real.id,
            module: real.module,
            lesson: Lesson(
              id: real.id,
              steps: [
                TalkStep(id: 'curto', fen: real.lesson.steps.first.fen),
                TalkStep(id: 'fim', fen: real.lesson.steps.first.fen),
              ],
            ),
            exercises: real.exercises,
            passScore: real.passScore,
            keyPositions: real.keyPositions,
            practice: real.practice,
            references: real.references,
          )
        : real;
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          trail: EndgameTrail(
            modules: [
              EndgameModule(id: real.module, lessons: [lesson]),
            ],
          ),
          texts: texts,
        ),
        FakeEndgameProgressRepository(),
      ),
      feedback: AssetExerciseFeedbackRepository(_Assets()),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: replyDelay,
    );
    addTearDown(cubit.close);
    await cubit.load(lessonId, 'pt', part: 'diagonal');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        locale: const Locale('pt'),
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
          ),
          child: BlocProvider.value(value: cubit, child: const LessonScreen()),
        ),
      ),
    );
    return cubit;
  }

  double top(WidgetTester tester) =>
      tester.getRect(find.byKey(LessonKeys.scroll)).top;

  Future<void> frames(WidgetTester tester, int milliseconds) async {
    for (var t = 0; t < milliseconds; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  const oldText = 'Pense com calma';

  testWidgets('A: texto que cabe na folha recolhida não abre', (tester) async {
    await pump(tester, shortText: true);
    await frames(tester, 100);
    final collapsed = top(tester);
    await frames(tester, 2000);
    expect(top(tester), closeTo(collapsed, 1));
  });

  /// Anda um passo e confere, quadro a quadro, que o texto antigo só aparece
  /// com a folha na altura de antes ou na de depois.
  Future<void> expectNoIntermediate(
    WidgetTester tester,
    Future<void> Function() act,
    Finder Function() old,
  ) async {
    final initial = top(tester);
    await act();
    final tops = <double>[];
    final shownOld = <double>[];
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      // O rodapé "Pensando…" estoura 85 dp na fonte de teste (já era assim,
      // fora do escopo desta folha): só o que importa aqui é a folha.
      tester.takeException();
      final now = top(tester);
      tops.add(now);
      if (old().evaluate().isNotEmpty) {
        shownOld.add(now);
      }
    }
    final collapsed = tops.reduce((a, b) => a > b ? a : b);
    for (final t in shownOld) {
      expect(
        (t - initial).abs() < 1.5 || (t - collapsed).abs() < 1.5,
        isTrue,
        reason:
            'texto antigo com a folha em $t (antes $initial, '
            'depois $collapsed)',
      );
    }
  }

  testWidgets('C: lance com a folha aberta (apresentação) sem quadro no meio', (
    tester,
  ) async {
    final cubit = await pump(
      tester,
      size: const Size(360, 640),
      replyDelay: const Duration(milliseconds: 500),
    );
    await frames(tester, 1500);
    expect(find.byKey(LessonKeys.presentation), findsOneWidget);
    await expectNoIntermediate(
      tester,
      () async => unawaited(cubit.play(Move.parse('d3e4')!)),
      () => find.textContaining(oldText, findRichText: true),
    );
  });
}
