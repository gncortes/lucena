import 'dart:io' as io;

import 'package:chessground/chessground.dart';
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
import 'package:lucena/ui/core/keys/viktor_sheet_keys.dart';
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

  String boardPlacement(WidgetTester tester) => tester
      .widget<Chessboard>(find.byType(Chessboard))
      .controller
      .fen
      .split(' ')
      .first;

  Finder plain(String needle) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(needle),
  );

  testWidgets('erro 1.Re3 no pensar: ramo da demo err_distantKing', (
    tester,
  ) async {
    final cubit = await pump(tester, 't_lesson', trimmed: false);
    final f = cubit.play(Move.parse('d3e3')!);
    await tester.pump(const Duration(seconds: 1));
    await f;
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    expect(plain('Re7'), findsWidgets);
    expect(plain('O rei preto ocupa a mesma coluna'), findsWidgets);
  });

  testWidgets('alternativa 1.g4: resposta das pretas, avança, mantém o ?', (
    tester,
  ) async {
    final cubit = await pump(tester, 't_lesson', trimmed: false);
    final f = cubit.play(Move.parse('d3e4')!);
    await tester.pump(const Duration(seconds: 1));
    await f;
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(cubit.state.correct, isTrue);
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.drag(
      find.byKey(ViktorSheetKeys.handle),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    final alt = find.byKey(LessonKeys.failedAlternative('g3g4'));
    await tester.ensureVisible(alt);
    await tester.pumpAndSettle();
    await tester.tap(alt);
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    expect(plain('1.g4?'), findsWidgets);
    expect(plain('Rd7'), findsWidgets);
    final next = tester.widget<IconButton>(
      find.byKey(LessonKeys.variationForward),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('demo fora do roteiro: a fala do motor, não a do roteiro', (
    tester,
  ) async {
    final cubit = await pump(tester, 'd_distant');
    cubit.demoTogglePause();
    for (var i = 0; i < 2; i++) {
      final step = cubit.demoForward();
      await tester.pump(const Duration(seconds: 1));
      await step;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final played = cubit.play(Move.parse('e4d4')!);
    await tester.pump(const Duration(seconds: 1));
    await played;
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(cubit.state.offScript, isTrue);
    expect(find.byKey(LessonKeys.demoBackToScript), findsOneWidget);
    expect(plain('1...Rf7. O rei preto'), findsNothing);
    expect(plain('também ganha'), findsWidgets);
  });

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

  testWidgets('prático: abre com a fala do passo, r<n> e fim do roteiro', (
    tester,
  ) async {
    final cubit = await pump(tester, 'convert');
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(plain('Jogue de brancas e encontre o melhor lance'), findsWidgets);
    expect(plain('O rei preto quer bloquear'), findsNothing);
    await movePractice(tester, cubit, 'd3e4');
    await movePractice(tester, cubit, 'e4e5');
    await tester.tap(find.byKey(LessonKeys.practiceBack));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(plain('O rei preto vai para a coluna e'), findsWidgets);
    expect(boardPlacement(tester), '8/4k3/8/8/4K3/6P1/8/8');
    await tester.tap(find.byKey(LessonKeys.practiceContinue));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(plain('O rei preto vai para f7'), findsWidgets);
    expect(boardPlacement(tester), '8/5k2/8/4K3/8/6P1/8/8');
    await movePractice(tester, cubit, 'e5f5');
    expect(plain('Assim se converte'), findsWidgets);
  });

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

  Future<LessonCubit> offScript(WidgetTester tester) async {
    final cubit = await pump(tester, 'd_distant');
    cubit.demoTogglePause();
    for (var i = 0; i < 2; i++) {
      final step = cubit.demoForward();
      await tester.pump(const Duration(seconds: 1));
      await step;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final played = cubit.play(Move.parse('e4d4')!);
    await tester.pump(const Duration(seconds: 1));
    await played;
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    return cubit;
  }

  testWidgets('fora do roteiro: ⏭ e ▶ desabilitados; voltar reabilita', (
    tester,
  ) async {
    final cubit = await offScript(tester);
    expect(cubit.state.offScript, isTrue);
    IconButton button(Key key) => tester.widget<IconButton>(find.byKey(key));
    expect(button(LessonKeys.demoForward).onPressed, isNull);
    expect(button(LessonKeys.demoPause).onPressed, isNull);
    expect(button(LessonKeys.demoBack).onPressed, isNotNull);
    await tester.tap(find.byKey(LessonKeys.demoBackToScript));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(cubit.state.offScript, isFalse);
    expect(button(LessonKeys.demoForward).onPressed, isNotNull);
    expect(button(LessonKeys.demoPause).onPressed, isNotNull);
  });

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
