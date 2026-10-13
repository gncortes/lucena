import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Square;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/board/speech_flash.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/viktor_sheet_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  // Uma fala bem longa, que não cabe sob o tabuleiro.
  final long = List.filled(
    30,
    'The rook moves in straight lines, as far as it likes.',
  ).join(' ');

  late LessonCubit lessonCubit;

  Future<SettingsCubit> pump(
    WidgetTester tester, {
    String? intro,
    Size size = const Size(400, 800),
    bool endgame = false,
    Course? course,
    bool systemBars = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (systemBars) {
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 32);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 32);
    }
    final texts = LessonTexts.fromJson({
      'module.pieces': 'The pieces',
      'pieces.rook.title': 'The rook',
      'pieces.rook.intro': intro ?? long,
      'pieces.rook.stars': 'Take the rook to the stars.',
      'coach.illegal.rook': 'The rook does not move like that.',
    });
    final cubit = LessonCubit(
      source: endgame
          ? EndgameLessonSource(
              FakeEndgameLessonRepository(
                texts: LessonTexts.fromJson({
                  ...FakeEndgameLessonRepository.sampleTexts.toJson(),
                  'rook.lucena.intro': intro ?? long,
                }),
              ),
              FakeEndgameProgressRepository(),
            )
          : null,
      lessons: endgame
          ? null
          : FakeLessonRepository(texts: texts, course: course),
      progress: endgame ? null : FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load(endgame ? 'rook.lucena' : 'pieces.rook', 'en');
    lessonCubit = cubit;
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
    return settings;
  }

  testWidgets('a fala longa fica inteira no balão e a tela rola até o fim '
      'dela, acima das ações', (tester) async {
    await pump(tester);
    final speech = find.byKey(LessonKeys.speech);
    final words = tester.widget<Text>(speech);
    expect(words.data ?? words.textSpan?.toPlainText(), long);
    // Só a tela rola: nada rola dentro do balão.
    expect(
      find.descendant(
        of: find.byType(TeacherSpeech),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );

    // O primeiro puxão abre a folha; o seguinte rola o texto até o fim.
    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    // Parada, aberta: as ações voltam e o fim da fala fica acima delas.
    final next = find.byKey(LessonKeys.nextButton);
    expect(next.hitTestable(), findsOneWidget);
    expect(
      tester.getRect(speech).bottom,
      lessThanOrEqualTo(tester.getRect(next).top),
    );
  });

  testWidgets(
    'a fala passa sob os botões recolhida e fica acessível no modal',
    (tester) async {
      // Uma fala que passa um pouco da folha fechada.
      final medium = List.filled(
        7,
        'The rook moves in straight lines, as far as it likes.',
      ).join(' ');
      await pump(tester, intro: medium);
      final scroll = find.byKey(LessonKeys.scroll);
      final speech = find.byKey(LessonKeys.speech);
      final buttons = tester.getRect(find.byKey(LessonKeys.nextButton));
      expect(tester.getRect(scroll).bottom, greaterThan(buttons.bottom));

      for (var i = 0; i < 3; i++) {
        await tester.drag(scroll, const Offset(0, -3000));
        await tester.pumpAndSettle();
      }
      final end = tester.getRect(speech).bottom;
      final next = find.byKey(LessonKeys.nextButton);
      expect(next.hitTestable(), findsOneWidget);
      expect(end, lessThanOrEqualTo(tester.getRect(next).top));

      // Fala curta: cabe, sem rolagem.
      await pump(tester, intro: 'Short.');
      await tester.tap(find.byKey(LessonKeys.speech));
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
      );
      expect(position.position.maxScrollExtent, 0);
    },
  );

  testWidgets('fala longa: puxando a folha, ela sobe por cima do tabuleiro '
      'inteiro; puxando de volta, desce e o tabuleiro reaparece', (
    tester,
  ) async {
    await pump(tester);
    final board = find.byKey(LessonKeys.board);
    // A alça da folha: o balão rola dentro dela (teleprompter).
    final speech = find.byKey(ViktorSheetKeys.handle);
    final full = tester.getRect(board);
    // Fechada: a folha começa abaixo do tabuleiro.
    expect(tester.getRect(speech).top, greaterThan(full.bottom));

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    // Aberta: o tabuleiro não encolhe, a folha é que cobre.
    expect(tester.getRect(board), full);
    expect(tester.getRect(speech).top, lessThan(full.bottom));
    // Aberta e parada: as ações voltam por cima dela, com o ✕.
    expect(find.byKey(LessonKeys.nextButton).hitTestable(), findsOneWidget);
    expect(find.byKey(LessonKeys.closeSheet).hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(LessonKeys.closeSheet));
    await tester.pumpAndSettle();
    expect(tester.getRect(speech).top, greaterThan(full.bottom));
    expect(board.hitTestable(), findsOneWidget);
    expect(find.byKey(LessonKeys.nextButton).hitTestable(), findsOneWidget);
  });

  testWidgets('aula de final: a folha do Viktor nasce sob o tabuleiro e o '
      'modal volta ao compacto pelo X', (tester) async {
    await pump(tester, endgame: true);
    final board = tester.getRect(find.byKey(LessonKeys.board));
    expect(find.byKey(LessonKeys.viktorSheet), findsOneWidget);
    expect(
      tester.getRect(find.byKey(ViktorSheetKeys.handle)).top,
      greaterThan(board.bottom),
    );

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(ViktorSheetKeys.handle)).top,
      lessThan(board.bottom),
    );
    expect(find.byKey(LessonKeys.closeSheet).hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(LessonKeys.closeSheet));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(ViktorSheetKeys.handle)).top,
      greaterThan(board.bottom),
    );
  });

  testWidgets('marcações: o botão na folha esconde e mostra, e grava', (
    tester,
  ) async {
    final settings = await pump(tester);
    expect(settings.state!.lessonMarks, isTrue);
    await tester.tapAt(
      tester.getTopLeft(find.byKey(LessonKeys.scroll)) + const Offset(40, 12),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LessonKeys.marksToggle));
    await tester.pumpAndSettle();
    expect(settings.state!.lessonMarks, isFalse);
    await tester.tap(find.byKey(LessonKeys.marksToggle));
    await tester.pumpAndSettle();
    expect(settings.state!.lessonMarks, isTrue);
  });

  testWidgets('fala curta: toque abre o modal sem mover o tabuleiro', (
    tester,
  ) async {
    await pump(tester, intro: 'Short.');
    final board = tester.getRect(find.byKey(LessonKeys.board));
    await tester.tap(find.byKey(LessonKeys.speech));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(LessonKeys.board)), board);
    expect(
      tester.getRect(find.byKey(LessonKeys.speech)).top,
      lessThan(board.bottom),
    );
    expect(find.byKey(LessonKeys.closeSheet).hitTestable(), findsOneWidget);
  });

  testWidgets('o botão de voltar aparece do segundo passo em diante e volta '
      'um passo', (tester) async {
    await pump(tester);
    expect(find.byKey(LessonKeys.backButton), findsNothing);
    await tester.tap(find.byKey(LessonKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.step('pieces.rook', 'stars')), findsOneWidget);

    await tester.tap(find.byKey(LessonKeys.backButton));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.step('pieces.rook', 'intro')), findsOneWidget);
    expect(find.byKey(LessonKeys.backButton), findsNothing);
  });

  testWidgets('tocar num lance da fala marca a casa no tabuleiro por um '
      'instante', (tester) async {
    const said = 'The rook goes all the way: Rd8.';
    // Alta o bastante para a fala ficar acima dos botões que flutuam.
    await pump(tester, intro: said, size: const Size(400, 1100));
    Set<Shape> shapes() =>
        tester.widget<Chessboard>(find.byKey(LessonKeys.board)).shapes;
    expect(shapes().whereType<CustomShape>(), isEmpty);

    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(LessonKeys.speech),
        matching: find.byType(RichText),
      ),
    );
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: said.indexOf('Rd8') + 1),
      Rect.zero,
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 8)));
    await tester.pump();
    // A torre de d4 chega em d8: a seta do lance.
    expect(
      shapes().whereType<Arrow>().map((arrow) => (arrow.orig, arrow.dest)),
      contains((Square.d4, Square.d8)),
    );
    // Fica até tocar de novo no mesmo lance, que desmarca.
    await tester.pump(const Duration(seconds: 3));
    expect(
      shapes().whereType<Arrow>().map((arrow) => (arrow.orig, arrow.dest)),
      contains((Square.d4, Square.d8)),
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 8)));
    await tester.pump();
    expect(
      shapes().whereType<Arrow>().where((arrow) => arrow.dest == Square.d8),
      isEmpty,
    );
  });

  testWidgets('tocar numa casa da fala põe o anel nela', (tester) async {
    const said = 'Look at the square d4 now.';
    await pump(tester, intro: said, size: const Size(400, 1100));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(LessonKeys.speech),
        matching: find.byType(RichText),
      ),
    );
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: said.indexOf('d4') + 1),
      Rect.zero,
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 8)));
    await tester.pump();
    final ring = find.byType(SpeechRing);
    expect(ring, findsOneWidget);
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final rect = tester.getRect(ring);
    // ignore: avoid_print
    print('RING $rect BOARD $board');
    expect(rect.width, greaterThan(10));
    expect(board.contains(rect.center), isTrue);
  });

  /// O centro da casa [square] no tabuleiro (brancas embaixo).
  Offset centerOf(WidgetTester tester, Square square) {
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final cell = board.width / 8;
    return Offset(
      board.left + (square.file + 0.5) * cell,
      board.bottom - (square.rank + 0.5) * cell,
    );
  }

  Future<void> toStars(WidgetTester tester) async {
    await tester.tap(find.byKey(LessonKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.step('pieces.rook', 'stars')), findsOneWidget);
  }

  Future<void> dragPiece(WidgetTester tester, Square from, Square to) async {
    final gesture = await tester.startGesture(centerOf(tester, from));
    await tester.pump();
    final target = centerOf(tester, to);
    final start = centerOf(tester, from);
    for (var i = 1; i <= 5; i++) {
      await gesture.moveTo(Offset.lerp(start, target, i / 5)!);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('escola: o passo de estrelas sem cronômetro e sem a contagem '
      'de aulas na barra', (tester) async {
    await pump(tester, intro: 'Short.');
    expect(find.byKey(LessonKeys.place), findsNothing);
    await toStars(tester);
    expect(find.byKey(LessonKeys.prompt), findsNothing);
    expect(find.byKey(LessonKeys.stepTimer), findsNothing);
    expect(find.byKey(LessonKeys.place), findsNothing);
    // A barra de passos da aula fica.
    expect(find.byKey(LessonKeys.progress), findsOneWidget);
  });

  testWidgets('estrelas: arrastar a torre na diagonal não anda, ela volta e '
      'o Viktor diz como a torre anda', (tester) async {
    await pump(tester, intro: 'Short.');
    await toStars(tester);
    final fen = lessonCubit.state.fen;
    await dragPiece(tester, Square.a1, Square.b2);
    expect(lessonCubit.state.fen, fen);
    expect(find.text('The rook does not move like that.'), findsOneWidget);
    expect(
      tester
          .widget<Chessboard>(find.byKey(LessonKeys.board))
          .controller
          .game
          .fen,
      fen,
    );
  });

  testWidgets('estrelas: tocar a torre e depois uma casa aonde ela não anda '
      'também tem a fala; o lance certo não', (tester) async {
    await pump(tester, intro: 'Short.');
    await toStars(tester);
    await tester.tapAt(centerOf(tester, Square.a1));
    await tester.pumpAndSettle();
    await tester.tapAt(centerOf(tester, Square.c3));
    await tester.pumpAndSettle();
    expect(find.text('The rook does not move like that.'), findsOneWidget);

    // Lance que vale, sem estrela: a torre anda e a fala volta ao pedido.
    await dragPiece(tester, Square.a1, Square.a3);
    expect(lessonCubit.state.fen, startsWith('8/8/8/8/8/R7/8/8'));
    expect(find.text('The rook does not move like that.'), findsNothing);
    expect(find.text('Take the rook to the stars.'), findsOneWidget);
  });

  testWidgets(
    'D16 erro: grade 2x2 preserva disponibilidade e tentar novamente',
    (tester) async {
      // Exercise the authored-mistake path: generic wrong moves stay active.
      const course = Course(
        modules: [
          CourseModule(
            id: 'pieces',
            lessons: [
              Lesson(
                id: 'pieces.rook',
                steps: [
                  TalkStep(
                    id: 'intro',
                    fen: FakeEndgameLessonRepository.lucenaFen,
                  ),
                  MoveStep(
                    id: 'bridge',
                    fen: FakeEndgameLessonRepository.lucenaFen,
                    line: [
                      MoveTurn(accept: {'c1c4'}),
                    ],
                    mistakes: {'c1c3': StepMistake(say: 'coach.illegal.rook')},
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pump(tester, intro: 'Short.', course: course);
      await tester.tap(find.byKey(LessonKeys.nextButton));
      await tester.pumpAndSettle();
      await dragPiece(tester, Square.c1, Square.c3);
      expect(lessonCubit.state.phase, StepPhase.failed);
      final back = find.byKey(LessonKeys.backButton);
      final review = find.byKey(LessonKeys.reviewPoint);
      final solution = find.byKey(LessonKeys.seeSolution);
      final retry = find.byKey(LessonKeys.retryButton);
      expect(tester.getRect(back).top, closeTo(tester.getRect(review).top, 1));
      expect(
        tester.getRect(solution).top,
        closeTo(tester.getRect(retry).top, 1),
      );
      expect(
        tester.getRect(solution).top,
        greaterThan(tester.getRect(back).bottom),
      );
      expect(tester.widget<OutlinedButton>(review).onPressed, isNull);
      expect(tester.widget<FilledButton>(solution).onPressed, isNull);
      expect(find.byKey(LessonKeys.variationShow), findsNothing);
      final board = tester.getRect(find.byKey(LessonKeys.board));
      final teacher = find.byWidgetPredicate(
        (widget) =>
            widget is TeacherSpeech && widget.part == TeacherSpeechPart.all,
      );
      expect(tester.getTopLeft(teacher).dy, greaterThan(board.bottom));
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(lessonCubit.state.phase, StepPhase.active);
      expect(lessonCubit.state.fen, FakeEndgameLessonRepository.lucenaFen);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(360, 640),
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets('D15 $size: tabuleiro no topo com enunciado e Viktor embaixo', (
      tester,
    ) async {
      await pump(tester, intro: 'Short.', size: size, systemBars: true);
      final explaining = tester.getRect(find.byKey(LessonKeys.board));
      await toStars(tester);
      final board = tester.getRect(find.byKey(LessonKeys.board));
      expect(board.top, closeTo(explaining.top, 1));
      final teacher = find.byWidgetPredicate(
        (widget) =>
            widget is TeacherSpeech && widget.part == TeacherSpeechPart.all,
      );
      expect(tester.getTopLeft(teacher).dy, greaterThan(board.bottom));
      expect(board.width, greaterThanOrEqualTo(200));
      // Explicando, o tabuleiro fica no alto; jogando, desce ao centro.
      expect(explaining.size, board.size);
      expect(explaining.top, closeTo(board.top, 1));
      expect(
        tester.getTopLeft(find.byKey(LessonKeys.scroll)).dy,
        greaterThan(board.bottom),
      );
      expect(
        tester.getTopLeft(find.byKey(LessonKeys.footer)).dy,
        greaterThanOrEqualTo(board.bottom),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'D15 escola: explicação e enunciado mantêm tabuleiro no alto e fala abaixo',
    (tester) async {
      await pump(tester, intro: 'Short.', size: const Size(412, 860));
      final talk = tester.getRect(find.byKey(LessonKeys.board));
      // A folha fechada começa abaixo do tabuleiro, com um vão.
      expect(
        tester.getRect(find.byKey(LessonKeys.scroll)).top,
        greaterThanOrEqualTo(talk.bottom + 8 - 0.5),
      );
      await toStars(tester);
      final stars = tester.getRect(find.byKey(LessonKeys.board));
      expect(find.byKey(LessonKeys.prompt), findsNothing);
      final footer = tester.getRect(find.byKey(LessonKeys.footer));
      expect(stars.size, talk.size);
      // No centro do espaço útil (T64): entre a barra do app e o rodapé, sem
      // cobrir o enunciado.
      expect(stars.top, closeTo(talk.top, 1));
      expect(stars.bottom, lessThanOrEqualTo(footer.top));
      expect(
        tester.getRect(find.byKey(LessonKeys.scroll)).top,
        greaterThan(stars.bottom),
      );
      // Explicando (pedido do Gabriel, 2026-10-11), ele sobe para o alto e a
      // folha da fala fica com o resto da tela.
      expect(talk.top, closeTo(stars.top, 1));
    },
  );
}
