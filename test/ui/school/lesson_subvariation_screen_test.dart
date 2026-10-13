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
import 'package:lucena/ui/core/keys/viktor_sheet_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T68: as sub-variantes na faixa do modo variante, com fixtures (a lição
/// real da oposição distante é escrita por outra sessão).
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

  Future<LessonCubit> pump(
    WidgetTester tester, {
    Size size = const Size(400, 1100),
    FakeEndgameProgressRepository? progress,
    bool reduced = false,
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
      FakeSettingsRepository(const AppSettings()),
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

  String comment(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(LessonKeys.variationStrip),
          matching: find.byType(Text),
        ),
      )
      .last
      .data!;

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

  /// Faixa, tabuleiro e comentário dizem a mesma coisa.
  void expectSync(
    WidgetTester tester, {
    required String label,
    required List<String> ucis,
    required String text,
  }) {
    expect(current(tester), label);
    expect(boardFen(tester), replay(ucis));
    expect(comment(tester), text);
  }

  final d2 = LessonKeys.variationBranchMove('d2', 1);

  testWidgets('a faixa mostra a principal, as duas alternativas recuadas e '
      'o = no fim de cada uma', (tester) async {
    await pump(tester);
    await openLine(tester);
    expect(find.byKey(LessonKeys.variationBranch('d2')), findsOneWidget);
    expect(find.byKey(LessonKeys.variationBranch('d3')), findsOneWidget);
    for (final id in ['d2', 'd3']) {
      expect(
        tester.widget<Text>(find.byKey(LessonKeys.variationResult(id))).data,
        contains('='),
      );
    }
    expect(find.text('\u20662.Rd2?\u2069'), findsOneWidget);
    expect(find.text('\u20662...Ke6\u2069'), findsNothing);
    expect(find.text('\u2066Ke6\u2069'), findsOneWidget);
  });

  testWidgets('toque no lance do ramo: tabuleiro, destaque e comentário dele; '
      'o painel não abre', (tester) async {
    await pump(tester);
    await openLine(tester);
    final closed = tester.getRect(find.byKey(LessonKeys.variationSheet));
    await tapKey(tester, d2);
    expectSync(
      tester,
      label: '2.Rd2?',
      ucis: ['c1d1', 'd8e7', 'd1d2'],
      text: 'Slow.',
    );
    expect(tester.getRect(find.byKey(LessonKeys.variationSheet)), closed);
  });

  testWidgets('lance do ramo sem texto próprio mostra o da alternativa; com '
      'texto, o dele', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, LessonKeys.variationBranchMove('d2', 2));
    expectSync(
      tester,
      label: 'Ke6',
      ucis: ['c1d1', 'd8e7', 'd1d2', 'e7e6'],
      text: 'Black answers.',
    );
    await tapKey(tester, LessonKeys.variationBranchMove('d3', 2));
    expectSync(
      tester,
      label: 'Kf7',
      ucis: ['c1d1', 'd8e7', 'd1d3', 'e7f7'],
      text: 'Also slow.',
    );
  });

  testWidgets('⏭ segue o ramo e desliga no fim dele', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, d2);
    await tapKey(tester, LessonKeys.variationForward);
    expect(current(tester), 'Ke6');
    expect(
      tester
          .widget<IconButton>(find.byKey(LessonKeys.variationForward))
          .onPressed,
      isNull,
    );
  });

  testWidgets('⏮ no 1º lance do ramo volta ao ponto de partida e o ⏭ '
      'seguinte entra na principal', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, d2);
    await tapKey(tester, LessonKeys.variationBack);
    // Depois de 1.Rd1+ Ke7: lance 2 da principal em destaque.
    expect(current(tester), 'Ke7');
    expect(boardFen(tester), replay(['c1d1', 'd8e7']));
    await tapKey(tester, LessonKeys.variationForward);
    expectSync(
      tester,
      label: '2.Rd4',
      ucis: ['c1d1', 'd8e7', 'd1d4'],
      text: current(tester) == '2.Rd4' ? comment(tester) : '',
    );
  });

  testWidgets('toque num lance da principal sai do ramo', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, d2);
    await tapKey(tester, LessonKeys.variationMove(1));
    expect(current(tester), '1.Rd1+');
    expect(boardFen(tester), replay(['c1d1']));
  });

  testWidgets('X do painel aberto só recolhe: segue na variante, no mesmo '
      'lance; o X da barra sai e o tabuleiro volta ao passo', (tester) async {
    await pump(tester);
    await openLine(tester);
    await tapKey(tester, d2);
    final fen = boardFen(tester);
    final handle = find.descendant(
      of: find.byKey(LessonKeys.variationSheet),
      matching: find.byKey(ViktorSheetKeys.handle),
    );
    final collapsedTop = tester.getRect(handle).top;
    // Arrasta a alça: abre.
    await tester.drag(
      find.byKey(LessonKeys.variationStripScroll),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(handle).top, lessThan(collapsedTop));
    // O X do painel (48 dp) está inteiro na tela.
    final close = tester.getRect(find.byKey(LessonKeys.variationSheetClose));
    expect(close.size, const Size(48, 48));
    expect(close.top, greaterThanOrEqualTo(0));
    await tapKey(tester, LessonKeys.variationSheetClose);
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    expect(current(tester), '2.Rd2?');
    expect(boardFen(tester), fen);
    expect(tester.getRect(handle).top, closeTo(collapsedTop, 1));
    // O X da barra sai da variante.
    await tapKey(tester, LessonKeys.variationExit);
    expect(find.byKey(LessonKeys.variationStrip), findsNothing);
    expect(boardFen(tester), start);
  });

  testWidgets('geometria: alvos de 48 dp e recuo de 16 dp das alternativas', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, size: const Size(360, 740));
    await openLine(tester);
    final keys = [
      LessonKeys.variationMove(1),
      LessonKeys.variationMove(2),
      LessonKeys.variationMove(3),
      d2,
      LessonKeys.variationBranchMove('d2', 2),
      LessonKeys.variationBranchMove('d3', 1),
    ];
    for (final key in keys) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.width, greaterThanOrEqualTo(48), reason: '$key');
      expect(rect.height, greaterThanOrEqualTo(48), reason: '$key');
    }
    final main = tester.getRect(find.byKey(LessonKeys.variationMove(1)));
    expect(tester.getRect(find.byKey(d2)).left - main.left, closeTo(16, 1));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  for (final size in const [Size(360, 640), Size(360, 740), Size(412, 917)]) {
    testWidgets('sem overflow e com a barra à vista em $size', (tester) async {
      await pump(tester, size: size);
      await openLine(tester);
      await tapKey(tester, d2);
      expect(tester.takeException(), isNull);
      for (final key in [
        LessonKeys.variationExit,
        LessonKeys.variationBack,
        LessonKeys.variationForward,
      ]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(
        find.descendant(
          of: find.byKey(LessonKeys.variationSheet),
          matching: find.byKey(ViktorSheetKeys.header),
        ),
        findsNothing,
      );
    });
  }

  testWidgets('a transição existe: a peça anda em quadros intermediários', (
    tester,
  ) async {
    await pump(tester);
    await openLine(tester);
    await tester.tap(find.byKey(d2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    // Nos quadros do meio, faixa, tabuleiro e comentário já estão juntos.
    expectSync(
      tester,
      label: '2.Rd2?',
      ucis: ['c1d1', 'd8e7', 'd1d2'],
      text: 'Slow.',
    );
    await tester.pumpAndSettle();
  });

  testWidgets('com "remover animações" a transição é instantânea', (
    tester,
  ) async {
    await pump(tester, reduced: true);
    await openLine(tester);
    await tester.tap(find.byKey(d2));
    await tester.pump();
    expectSync(
      tester,
      label: '2.Rd2?',
      ucis: ['c1d1', 'd8e7', 'd1d2'],
      text: 'Slow.',
    );
  });

  testWidgets('fechar o app com o ramo e o painel abertos: reabre no mesmo nó '
      'e com a folha aberta', (tester) async {
    final progress = FakeEndgameProgressRepository();
    await pump(tester, progress: progress);
    await openLine(tester);
    await tapKey(tester, d2);
    await tester.drag(
      find.byKey(LessonKeys.variationStripScroll),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final saved = progress.saved.ongoing!.variation!;
    expect(saved.source, VariationCheckpoint.speech);
    expect(saved.branch, 'd2');
    expect(saved.ply, 1);
    expect(saved.open, isTrue);
    // Fecha à força e abre de novo.
    await tester.pumpWidget(const SizedBox());
    await pump(tester, progress: progress);
    expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
    expect(current(tester), '2.Rd2?');
    expect(boardFen(tester), replay(['c1d1', 'd8e7', 'd1d2']));
    expect(comment(tester), 'Slow.');
    expect(
      tester.getRect(find.byKey(LessonKeys.variationSheetClose)).top,
      greaterThanOrEqualTo(0),
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.byKey(LessonKeys.variationSheetClose),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity,
      1,
    );
  });
}
