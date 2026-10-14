import 'dart:io' as io;

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
    Size size = const Size(412, 917),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
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

  void expectBranch(WidgetTester tester, String id) {
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    expect(find.byKey(LessonKeys.variationBranch(id)), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(LessonKeys.variationResult(id))).data,
      contains('='),
    );
  }

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

  testWidgets('LANCE CERTO (diagonal): 2.e4? abre o ramo e4 com o =', (
    tester,
  ) async {
    await thought(tester, 'diagonal', 'f3f4');
    await tapMove(tester, '2.e4?');
    expectBranch(tester, 'e4');
  });

  testWidgets('faixa (capablanca, 360x780): ao avançar, o lance da vez sobe '
      'ao alto da lista; cabeçalho e barra ficam', (tester) async {
    await pump(tester, 'capablanca', size: const Size(360, 780));
    await tapMove(tester, '2.Re3!');
    final list = find.byKey(LessonKeys.variationStripList);
    expect(list, findsOneWidget);
    final listTop = tester.getTopLeft(list).dy;
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)),
    );
    for (var i = 0; i < 8; i++) {
      final current = find.byKey(LessonKeys.variationStripCurrent);
      final rowTop = tester.getTopLeft(current).dy;
      final position = scrollable.position;
      // Com conteúdo abaixo, o lance da vez fica a menos de 48 dp do alto
      // da lista; no fim da lista, ele só não passa do que cabe.
      expect(
        rowTop < listTop ||
            rowTop - listTop < 48 ||
            position.pixels == position.maxScrollExtent,
        isTrue,
        reason:
            'passo $i: rowTop=$rowTop listTop=$listTop '
            'px=${position.pixels} max=${position.maxScrollExtent}',
      );
      // O lance da vez na linha do cabeçalho: a lista fica no começo.
      if (rowTop < listTop) expect(position.pixels, 0);
      expect(find.byKey(LessonKeys.variationHiddenToggle), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(LessonKeys.variationMove(1))).dy,
        lessThan(listTop),
      );
      final forward = tester.widget<IconButton>(
        find.byKey(LessonKeys.variationForward),
      );
      if (forward.onPressed == null) break;
      await tester.tap(find.byKey(LessonKeys.variationForward));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
