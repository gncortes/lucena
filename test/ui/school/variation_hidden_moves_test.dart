import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/variation_tree.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T69: os lances ocultos da faixa do modo variante (fixtures da T68: a
/// principal 1.Rd1+ Ke7 2.Rd4 e as alternativas d2 e d3 no lance 2).
void main() {
  const said = 'Play 1.Rd1+ Ke7 2.Rd4 and the rook shields the king.';
  const start = FakeEndgameLessonRepository.lucenaFen;

  String replay(List<String> ucis) {
    var position = Chess.fromSetup(Setup.parseFen(start)) as Position;
    for (final uci in ucis) {
      position = position.play(Move.parse(uci)!);
    }
    return position.fen;
  }

  final texts = LessonTexts.fromJson({
    ...FakeEndgameLessonRepository.sampleTexts.toJson(),
    'rook.lucena.intro': said,
    'rook.lucena.intro.alt.d2': 'Slow.',
    'rook.lucena.intro.alt.d2.m2': 'Black answers.',
    'rook.lucena.intro.alt.d3': 'Also slow.',
  });

  final sample = FakeEndgameLessonRepository.sample;
  final lucena = sample.modules.first.lessons.first;
  final trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: lucena.id,
            module: lucena.module,
            lesson: Lesson(
              id: lucena.id,
              steps: [
                TalkStep(
                  id: 'intro',
                  fen: start,
                  lines: const [
                    CitedLine(
                      uci: ['c1d1', 'd8e7', 'd1d4'],
                      branches: [
                        CitedBranch(
                          id: 'd2',
                          at: 2,
                          uci: ['d1d2', 'e7e6'],
                          glyphs: ['?', null],
                          result: VariationResult.draw,
                        ),
                        CitedBranch(
                          id: 'd3',
                          at: 2,
                          uci: ['d1d3', 'e7f7'],
                          glyphs: ['?'],
                          result: VariationResult.draw,
                        ),
                      ],
                    ),
                  ],
                ),
                lucena.lesson.steps.last,
              ],
            ),
            exercises: lucena.exercises,
            passScore: lucena.passScore,
            keyPositions: lucena.keyPositions,
            practice: lucena.practice,
            references: lucena.references,
          ),
        ],
      ),
    ],
  );

  late SettingsCubit settingsOf;

  Future<LessonCubit> pump(
    WidgetTester tester, {
    Size size = const Size(400, 1100),
    FakeEndgameProgressRepository? progress,
    bool reduced = false,
    bool hidden = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (reduced) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: texts),
        progress ?? FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(AppSettings(lessonHiddenMoves: hidden)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    settingsOf = settings;
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  String boardFen(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(LessonKeys.board))
      .controller
      .game
      .fen;

  String current(WidgetTester tester) => tester
      .widget<Text>(find.byKey(LessonKeys.variationStripCurrent))
      .data!
      .replaceAll(RegExp('[\u2066\u2069]'), '');

  Future<void> openLine(WidgetTester tester) async {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(LessonKeys.speech),
        matching: find.byType(RichText),
      ),
    );
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: said.indexOf('Rd1+') + 1),
      Rect.zero,
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 8)));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Rect textOf(WidgetTester tester, Key move) => tester.getRect(
    find.descendant(of: find.byKey(move), matching: find.byType(Text)),
  );

  Rect block(WidgetTester tester, int row) =>
      tester.getRect(find.byKey(LessonKeys.variationHiddenBlock(row)));

  /// O lance está fora do leitor de tela (coberto pelo bloco).
  bool covered(WidgetTester tester, Key move) => tester
      .widget<ExcludeSemantics>(
        find
            .descendant(
              of: find.byKey(move),
              matching: find.byType(ExcludeSemantics),
            )
            .first,
      )
      .excluding;

  Finder blockFinder(int row) =>
      find.byKey(LessonKeys.variationHiddenBlock(row));

  bool contains(Rect outer, Rect inner) =>
      outer.left <= inner.left + .5 &&
      inner.right <= outer.right + .5 &&
      outer.top <= inner.top + .5 &&
      inner.bottom <= outer.bottom + .5;

  final m1 = LessonKeys.variationMove(1);
  final m2 = LessonKeys.variationMove(2);
  final m3 = LessonKeys.variationMove(3);
  final d2a = LessonKeys.variationBranchMove('d2', 1);
  final d2b = LessonKeys.variationBranchMove('d2', 2);
  final d3a = LessonKeys.variationBranchMove('d3', 1);
  final d3b = LessonKeys.variationBranchMove('d3', 2);
  final hiddenNotation = RegExp(r'^(Ke7|2\.Rd4|2\.Rd2\?|Ke6|2\.Rd3\?|Kf7)$');

  for (final size in [
    const Size(360, 640),
    const Size(360, 740),
    const Size(412, 917),
  ]) {
    testWidgets('estado 1 em ${size.width.toInt()}×${size.height.toInt()}: '
        'um bloco por linha cobre os lances, sem overflow', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, size: size);
      await openLine(tester);
      expect(tester.takeException(), isNull);
      // Só o caminho até o lance de entrada fica à vista.
      expect(find.bySemanticsLabel(hiddenNotation), findsNothing);
      expect(find.bySemanticsLabel('Draw'), findsNothing);
      expect(find.bySemanticsLabel('1.Rd1+'), findsOneWidget);
      final line = tester.getRect(find.byKey(m1));
      final shown = textOf(tester, m1);
      final covered = {
        0: [m2, m3],
        1: [d2a, d2b],
        2: [d3a, d3b],
      };
      for (final MapEntry(key: row, value: moves) in covered.entries) {
        final b = block(tester, row);
        expect(b.height, closeTo(28, .5));
        for (final move in moves) {
          expect(contains(b, textOf(tester, move)), isTrue, reason: '$move');
        }
        // O alvo de toque do bloco tem 48 dp.
        final node = tester.getSemantics(
          find
              .ancestor(of: blockFinder(row), matching: find.byType(Semantics))
              .first,
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      }
      // Os "=" também ficam sob o bloco.
      for (final id in ['d2', 'd3']) {
        final result = tester.getRect(
          find.byKey(LessonKeys.variationResult(id)),
        );
        final row = id == 'd2' ? 1 : 2;
        expect(contains(block(tester, row), result), isTrue);
      }
      // Centrado na linha de 48 e a 12 dp do fim do último revelado.
      expect(block(tester, 0).center.dy, closeTo(line.center.dy, .5));
      expect(block(tester, 0).left - shown.right, greaterThanOrEqualTo(11.5));
      // Espaço entre textos vizinhos da linha: pelo menos 12 dp.
      expect(
        textOf(tester, m3).left - textOf(tester, m2).right,
        greaterThanOrEqualTo(11.5),
      );
      // Os 3 botões e o alvo de 48 dp do botão do canto.
      final toggle = tester.getRect(
        find.byKey(LessonKeys.variationHiddenToggle),
      );
      expect(toggle.width, closeTo(48, .01));
      expect(toggle.height, closeTo(48, .01));
      expect(toggle.right, lessThanOrEqualTo(size.width));
      expect(
        toggle.left,
        greaterThanOrEqualTo(tester.getRect(find.byKey(m3)).right - .5),
      );
      handle.dispose();
    });
  }

  testWidgets('revelar não move nenhum lance', (tester) async {
    await pump(tester);
    await openLine(tester);
    List<Rect> rects() => [
      for (final key in [m1, m2, m3, d2a, d2b, d3a, d3b]) textOf(tester, key),
    ];
    final before = rects();
    await tapKey(tester, LessonKeys.variationForward);
    expect(rects(), before);
    await tapKey(tester, LessonKeys.variationForward);
    expect(rects(), before);
  });

  testWidgets('⏭ revela: lance da vez, tabuleiro e o bloco desliza em 240 ms', (
    tester,
  ) async {
    await pump(tester);
    await openLine(tester);
    final l1 = textOf(tester, m2).left;
    final l2 = textOf(tester, m3).left;
    expect(block(tester, 0).left, closeTo(l1, .5));
    await tester.tap(find.byKey(LessonKeys.variationForward));
    await tester.pump();
    // O destaque e o tabuleiro trocam no início.
    expect(current(tester), 'Ke7');
    expect(boardFen(tester), replay(['c1d1', 'd8e7']));
    await tester.pump(const Duration(milliseconds: 120));
    final mid = block(tester, 0).left;
    expect(mid, greaterThan(l1 + .5));
    expect(mid, lessThan(l2 - .5));
    await tester.pumpAndSettle();
    expect(block(tester, 0).left, closeTo(l2, .5));
    expect(current(tester), 'Ke7');
  });

  testWidgets('⏮ não cobre de novo: o lance revelado fica e o bloco não '
      'cresce em nenhum quadro', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, LessonKeys.variationForward);
    final width = block(tester, 0).width;
    await tester.tap(find.byKey(LessonKeys.variationBack));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(block(tester, 0).width, closeTo(width, .5));
    }
    await tester.pumpAndSettle();
    expect(current(tester), '1.Rd1+');
    expect(boardFen(tester), replay(['c1d1']));
    expect(covered(tester, m2), isFalse);
    handle.dispose();
  });

  testWidgets('⏮ até o início: posição inicial, nada em destaque, ⏮ '
      'desativado e o conjunto igual', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, LessonKeys.variationForward);
    final left = block(tester, 0).left;
    await tapKey(tester, LessonKeys.variationBack);
    await tapKey(tester, LessonKeys.variationBack);
    expect(find.byKey(LessonKeys.variationStripCurrent), findsNothing);
    expect(boardFen(tester), start);
    expect(
      tester.widget<IconButton>(find.byKey(LessonKeys.variationBack)).onPressed,
      isNull,
    );
    expect(block(tester, 0).left, closeTo(left, .5));
  });

  testWidgets('toque no bloco do ramo revela um lance por vez, do caminho '
      'até o ramo, e não abre o painel', (tester) async {
    await pump(tester);
    await openLine(tester);
    final closed = tester.getRect(find.byKey(LessonKeys.variationSheet));
    await tapKey(tester, LessonKeys.variationHiddenBlock(1));
    expect(current(tester), 'Ke7');
    expect(boardFen(tester), replay(['c1d1', 'd8e7']));
    expect(block(tester, 0).left, closeTo(textOf(tester, m3).left, .5));
    expect(block(tester, 1).left, closeTo(textOf(tester, d2a).left, .5));
    await tapKey(tester, LessonKeys.variationHiddenBlock(1));
    expect(current(tester), '2.Rd4');
    expect(blockFinder(0), findsNothing);
    await tapKey(tester, LessonKeys.variationHiddenBlock(1));
    expect(current(tester), '2.Rd2?');
    expect(block(tester, 1).left, closeTo(textOf(tester, d2b).left, .5));
    expect(tester.getRect(find.byKey(LessonKeys.variationSheet)), closed);
  });

  testWidgets('fim do ramo: = à vista, sem bloco, ⏭ desativado com a dica '
      'da alternativa', (tester) async {
    await pump(tester);
    await openLine(tester);
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, LessonKeys.variationHiddenBlock(1));
    }
    await tapKey(tester, LessonKeys.variationForward);
    expect(current(tester), 'Ke6');
    expect(blockFinder(1), findsNothing);
    final result = find.byKey(LessonKeys.variationResult('d2'));
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: result, matching: find.byType(Opacity)).first,
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(LessonKeys.variationForward))
          .onPressed,
      isNull,
    );
    expect(find.byTooltip('End of the alternative'), findsOneWidget);
    // A outra alternativa segue coberta.
    expect(blockFinder(2), findsOneWidget);
  });

  testWidgets('na principal, o ⏭ desativado diz que a linha acabou', (
    tester,
  ) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, LessonKeys.variationForward);
    await tapKey(tester, LessonKeys.variationForward);
    expect(current(tester), '2.Rd4');
    expect(find.byTooltip('End of the line'), findsOneWidget);
    // Tudo revelado na principal: sem bloco na linha 0, botão ainda ligado.
    expect(blockFinder(0), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(LessonKeys.variationHiddenToggle))
          .isSelected,
      isTrue,
    );
  });

  testWidgets('desligar no meio da linha e religar: o visto continua à '
      'vista, o resto volta coberto, e grava', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, LessonKeys.variationForward);
    final toggle = find.byKey(LessonKeys.variationHiddenToggle);
    expect(tester.widget<IconButton>(toggle).tooltip, 'Show all moves');
    expect(
      find.descendant(of: toggle, matching: find.byIcon(Icons.blur_on)),
      findsOneWidget,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settingsOf.state!.lessonHiddenMoves, isFalse);
    for (var row = 0; row < 3; row++) {
      expect(blockFinder(row), findsNothing);
    }
    expect(covered(tester, m3), isFalse);
    expect(tester.widget<IconButton>(toggle).tooltip, 'Hide the next moves');
    expect(
      find.descendant(of: toggle, matching: find.byIcon(Icons.blur_off)),
      findsOneWidget,
    );
    // O lance que vira o da vez com o botão desligado entra no conjunto.
    await tapKey(tester, d2a);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settingsOf.state!.lessonHiddenMoves, isTrue);
    expect(blockFinder(0), findsNothing);
    expect(covered(tester, m3), isFalse);
    expect(covered(tester, d2a), isFalse);
    expect(covered(tester, d2b), isTrue);
    expect(block(tester, 1).left, closeTo(textOf(tester, d2b).left, .5));
    expect(blockFinder(2), findsOneWidget);
    handle.dispose();
  });

  testWidgets('com a preferência desligada de início, nada fica coberto', (
    tester,
  ) async {
    await pump(tester, hidden: false);
    await openLine(tester);
    expect(blockFinder(0), findsNothing);
    expect(blockFinder(1), findsNothing);
    await tapKey(tester, d3b);
    expect(current(tester), 'Kf7');
  });

  testWidgets('remover animações: após um quadro o estado final já está '
      'desenhado', (tester) async {
    await pump(tester, reduced: true);
    await openLine(tester);
    final l2 = textOf(tester, m3).left;
    await tester.tap(find.byKey(LessonKeys.variationForward));
    await tester.pump();
    expect(block(tester, 0).left, closeTo(l2, .5));
    expect(current(tester), 'Ke7');
  });

  testWidgets('comentário: o lance citado e coberto vira granulado e some '
      'ao ser revelado', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await openLine(tester);
    final grain = find.byKey(LessonKeys.variationHiddenComment);
    expect(grain, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LessonKeys.variationStrip),
        matching: find.bySemanticsLabel(RegExp('Ke7')),
      ),
      findsNothing,
    );
    expect(tester.getSize(grain).width, greaterThan(40));
    final full = tester.getSize(grain).width;
    await tapKey(tester, LessonKeys.variationForward);
    expect(grain, findsOneWidget);
    expect(tester.getSize(grain).width, lessThan(full));
    await tapKey(tester, LessonKeys.variationForward);
    expect(grain, findsNothing);
    handle.dispose();
  });

  testWidgets('sair da linha e voltar, e o segundo plano, mantêm os lances '
      'vistos', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, LessonKeys.variationForward);
    final left = block(tester, 0).left;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(block(tester, 0).left, closeTo(left, .5));
    await tapKey(tester, LessonKeys.variationExit);
    expect(find.byKey(LessonKeys.variationStrip), findsNothing);
    await openLine(tester);
    expect(block(tester, 0).left, closeTo(textOf(tester, m3).left, .5));
  });

  testWidgets('cabeçalho: o botão dos ocultos fica antes das marcações, '
      'com 48 dp, e grava', (tester) async {
    await pump(tester, size: const Size(360, 740));
    // Abre a folha do Viktor para o cabeçalho aparecer.
    await tester.tapAt(
      tester.getTopLeft(find.byKey(LessonKeys.scroll)) + const Offset(40, 12),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final hidden = tester.getRect(find.byKey(LessonKeys.hiddenMovesToggle));
    final marks = tester.getRect(find.byKey(LessonKeys.marksToggle));
    expect(hidden.size, const Size(48, 48));
    expect(hidden.right, lessThanOrEqualTo(marks.left + .5));
    expect(marks.right, lessThanOrEqualTo(360));
    await tester.tap(find.byKey(LessonKeys.hiddenMovesToggle));
    await tester.pumpAndSettle();
    expect(settingsOf.state!.lessonHiddenMoves, isFalse);
  });
}
