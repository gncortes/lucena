import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/engine_fallback.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';
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

/// T70: a lição REAL da oposição distante (asset e falas em PT-BR): tocar na
/// citação da fala abre o modo variante com o ramo recuado e o `=`.
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
    WidgetTester tester,
    String stepId, {
    bool trimmed = true,
    String part = 'distant',
    Size size = const Size(412, 917),
    int cp = 900,
    bool withEngine = true,
    LessonStep? custom,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final step = trimmed
        ? custom ?? real.lesson.steps.firstWhere((s) => s.id == stepId)
        : null;
    final trail = !trimmed
        ? EndgameTrail(
            modules: [
              EndgameModule(id: real.module, lessons: [real]),
            ],
          )
        : EndgameTrail(
            modules: [
              EndgameModule(
                id: real.module,
                lessons: [
                  EndgameLesson(
                    id: real.id,
                    module: real.module,
                    lesson: Lesson(
                      id: real.id,
                      steps: [
                        step!,
                        TalkStep(id: 'fim', fen: step.fen),
                      ],
                    ),
                    exercises: real.exercises,
                    passScore: real.passScore,
                    keyPositions: real.keyPositions,
                    practice: real.practice,
                    references: real.references,
                  ),
                ],
              ),
            ],
          );
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: texts),
        FakeEndgameProgressRepository(),
      ),
      feedback: AssetExerciseFeedbackRepository(_Assets()),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
      typingDelay: Duration.zero,
      practiceV2: true,
      engine: !withEngine
          ? null
          : EngineFallback(
              evaluate: (position, pov) async => Evaluation(centipawns: cp),
              bestMove: (position) async => position.legalMoves.entries
                  .map(
                    (e) => NormalMove(from: e.key, to: e.value.squares.first),
                  )
                  .first,
            ),
    );
    addTearDown(cubit.close);
    await cubit.load(lessonId, 'pt', part: trimmed ? null : part);
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
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Finder plain(String needle) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(needle),
  );

  Future<void> movePractice(
    WidgetTester tester,
    LessonCubit cubit,
    String uci,
  ) async {
    final f = cubit.play(Move.parse(uci)!);
    await tester.pump(const Duration(seconds: 1));
    await f;
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final c in [
    ('t_carlsenSo', 'defend', 'f6e5', 'Com 55...Re5? você deixa escapar'),
    ('t_euwe', 'lateral', 'c4d5', 'Com 49.Rd5? você deixa escapar'),
    ('t_useReserve', 'useReserve', 'h5h6', 'Com 4.h6? você deixa escapar'),
    ('t_fixedTarget', 'fixedTarget', 'd7c6', 'Com 1.Rc6? você deixa escapar'),
    ('t_synchronize', 'synchronize', 'f5e4', 'Com 4.Re4? você deixa escapar'),
  ]) {
    testWidgets('erro no pensar da ${c.$1}: textos da variante do feedback', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        c.$1,
        trimmed: false,
        part: c.$2,
        withEngine: false,
      );
      final f = cubit.play(Move.parse(c.$3)!);
      await tester.pump(const Duration(seconds: 1));
      await f;
      await settle(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
      expect(plain(c.$4), findsWidgets);
      expect(plain('o adversário encontra um recurso'), findsNothing);
    });
  }

  for (final c in [
    ('grigorievMove', 'waiting', 'a8b8', 'Com 1.Rb8? você deixa escapar'),
    ('fixedTargetMove', 'fixedTarget', 'd7c6', 'Com 1.Rc6? você deixa escapar'),
  ]) {
    testWidgets('prático errado ${c.$1}: texto escrito do feedback', (
      tester,
    ) async {
      final cubit = await pump(tester, c.$1, cp: 0);
      await settle(tester);
      await movePractice(tester, cubit, c.$3);
      expect(plain(c.$4), findsWidgets);
      expect(plain('encontram um recurso contra o seu plano'), findsNothing);
    });
  }

  testWidgets(
    'fora do roteiro, o afogamento encerra: frase e tabuleiro travado',
    (tester) async {
      const fen = '7k/5Q2/8/8/8/8/8/K7 w - - 0 1';
      final cubit = await pump(
        tester,
        'x',
        custom: const DemoStep(
          id: 'x',
          fen: fen,
          line: [DemoMove(uci: 'f7f1')],
        ),
      );
      cubit.demoTogglePause();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final played = cubit.play(Move.parse('f7g6')!);
      await tester.pump(const Duration(seconds: 1));
      await played;
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(cubit.state.note, LessonNote.gameStalemate);
      expect(plain('Afogamento: empate.'), findsWidgets);
      expect(find.byKey(LessonKeys.demoBackToScript), findsOneWidget);
      // Nenhum lance novo entra.
      final fenAfter = cubit.state.fen;
      await cubit.play(Move.parse('h8g8')!);
      expect(cubit.state.fen, fenAfter);
    },
  );
}
