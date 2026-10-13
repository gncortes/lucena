import 'dart:async';
import 'dart:io' as io;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:lucena/domain/models/variation_tree.dart';
import 'package:lucena/domain/use_cases/variation_tree_builder.dart';
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

/// T68: a lição REAL da oposição distante (asset e falas em PT-BR): tocar na
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
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    final step = trimmed
        ? real.lesson.steps.firstWhere((s) => s.id == stepId)
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

  /// Toca na [occurrence]-ésima ocorrência de [needle] (o ponto [shift]
  /// caracteres depois do começo dele) no primeiro parágrafo que a tem: a
  /// folha abre e rola até o trecho ficar à vista.
  Future<void> tapMove(
    WidgetTester tester,
    String needle, {
    int occurrence = 0,
    int shift = 0,
  }) async {
    final finder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(needle),
    );
    expect(finder, findsWidgets, reason: needle);
    Offset point() {
      final paragraph = tester.renderObject<RenderParagraph>(finder.first);
      final plain = paragraph.text.toPlainText();
      var index = -1;
      for (var i = 0; i <= occurrence; i++) {
        index = plain.indexOf(needle, index + 1);
      }
      return paragraph.localToGlobal(
        paragraph.getOffsetForCaret(
              TextPosition(offset: index + shift + 1),
              Rect.zero,
            ) +
            const Offset(3, 8),
      );
    }

    await tester.drag(
      find.byKey(ViktorSheetKeys.handle),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 14 && (point().dy > 760 || point().dy < 120); i++) {
      await tester.dragFrom(
        const Offset(200, 600),
        Offset(0, point().dy > 760 ? -150 : 150),
      );
      await tester.pumpAndSettle();
    }
    await tester.tapAt(point());
    await tester.pumpAndSettle();
  }

  /// As casas do tabuleiro da lição (1º campo do FEN).
  String boardPlacement(WidgetTester tester) => tester
      .widget<Chessboard>(find.byType(Chessboard))
      .controller
      .fen
      .split(' ')
      .first;

  void expectBranch(WidgetTester tester, String id) {
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    expect(find.byKey(LessonKeys.variationBranch(id)), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(LessonKeys.variationResult(id))).data,
      contains('='),
    );
  }

  testWidgets('intro: 1.Re4 abre o ramo 2.g4? com o =', (tester) async {
    await pump(tester, 'intro');
    await tapMove(tester, '1.Re4');
    expectBranch(tester, 'g4');
  });

  testWidgets('intro: 1.Re4 Rf8 2.Rf5! abre o ramo 2.g4? Rg7 com o =', (
    tester,
  ) async {
    await pump(tester, 'intro');
    await tapMove(tester, 'Rf8');
    expectBranch(tester, 'g4f8');
  });

  testWidgets('diagonal: 2.Re4! abre o ramo 2.e4? Rf6! com o =', (
    tester,
  ) async {
    await pump(tester, 'diagonal');
    await tapMove(tester, '2.Re4!');
    expectBranch(tester, 'e4');
  });

  testWidgets('capablanca: 2.Re3! abre os ramos 2.Rd3? e 2.Rf3? com o =', (
    tester,
  ) async {
    await pump(tester, 'capablanca');
    await tapMove(tester, '2.Re3!');
    expectBranch(tester, 'kd3');
    expectBranch(tester, 'kf3');
  });

  testWidgets('convert (feito): 1.Re4 ... 3.Rf5 abre o ramo 3.g4? com o =', (
    tester,
  ) async {
    final cubit = await pump(tester, 'convert');
    await tester.runAsync(() async {
      for (final move in ['d3e4', 'e4e5', 'e5f5']) {
        await cubit.play(Move.parse(move)!);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    });
    await tester.pumpAndSettle();
    await tapMove(tester, '1.Re4');
    expectBranch(tester, 'g4');
  });

  /// O passo de pensar da [part] respondido com [uci]: a explicação abre.
  Future<LessonCubit> thought(
    WidgetTester tester,
    String part,
    String uci,
  ) async {
    final cubit = await pump(tester, '', trimmed: false, part: part);
    await tester.runAsync(() async {
      await cubit.play(Move.parse(uci)!);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(cubit.state.explanation, isNotNull);
    return cubit;
  }

  testWidgets('LANCE CERTO: a variante 1...Rf8 2.Rf5 tem o ramo 2.g4? Rg7 =', (
    tester,
  ) async {
    final cubit = await thought(tester, 'distant', 'd3e4');
    final payload = cubit.state.explanation!;
    final retreat = [
      for (final block in payload.explanations) ...block.variations,
    ].firstWhere((v) => v.id == 'human_retreat');
    final tree = VariationTreeBuilder.fromExplanation(
      payload: payload,
      cursor: payload.openVariation(retreat)!,
      cited: VariationTreeBuilder.citedSources(cubit.state.lesson!.steps),
      letters: const {'K': 'R'},
    );
    final branch = tree.branches.singleWhere((b) => b.id == 'g4f8');
    expect(branch.at, 1);
    expect(branch.moves.map((m) => m.label), ['2.g4?', '2...Rg7']);
    expect(branch.result, VariationResult.draw);
  });

  testWidgets('LANCE CERTO (diagonal): 2.e4? abre o ramo e4 com o =', (
    tester,
  ) async {
    await thought(tester, 'diagonal', 'f3f4');
    await tapMove(tester, '2.e4?');
    expectBranch(tester, 'e4');
  });

  testWidgets('LANCE CERTO: tocar em 2.g4? abre o ramo g4 com o =', (
    tester,
  ) async {
    final cubit = await pump(tester, 'intro', trimmed: false);
    await tester.runAsync(() async {
      await cubit.play(Move.parse('d3e4')!);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(cubit.state.explanation, isNotNull);
    await tapMove(tester, '2.g4?');
    expectBranch(tester, 'g4');
    expect(
      boardPlacement(tester),
      '8/5k2/8/8/4K1P1/8/8/8',
      reason: 'depois de 2.g4',
    );
  });

  testWidgets('depois do LANCE CERTO, a fala do intro: 1.Re4 abre o ramo', (
    tester,
  ) async {
    final cubit = await pump(tester, 'intro', trimmed: false);
    await tester.runAsync(() async {
      await cubit.play(Move.parse('d3e4')!);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    // Continuar e Voltar: o intro de novo, com a explicação de revisão.
    await tester.runAsync(cubit.next);
    await tester.runAsync(cubit.back);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(cubit.state.current?.id, 'intro');
    expect(cubit.state.explanation, isNotNull);
    await tapMove(
      tester,
      'Nesta posição, 1.Re4',
      shift: 'Nesta posição, '.length,
    );
    expectBranch(tester, 'g4');
  });

  testWidgets(
    'convert (erro): tocar em 3.g4? abre o ramo g4, recuado, com ? e =',
    (tester) async {
      final cubit = await pump(tester, 'convert');
      await tester.runAsync(() async {
        for (final move in ['d3e4', 'e4e5']) {
          await cubit.play(Move.parse(move)!);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      });
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      unawaited(cubit.play(Move.parse('g3g4')!));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tapMove(tester, '3.g4?');
      expectBranch(tester, 'g4');
      // Recuado e com o glifo: o ramo da aula, não a linha solta da fala.
      expect(
        find.descendant(
          of: find.byKey(LessonKeys.variationBranchMove('g4', 1)),
          matching: find.textContaining('3.g4?'),
        ),
        findsOneWidget,
      );
      // O tabuleiro mostra a posição DEPOIS do lance destacado.
      expect(
        boardPlacement(tester),
        '8/5k2/8/4K3/6P1/8/8/8',
        reason: 'depois de 3.g4',
      );
    },
  );
}
