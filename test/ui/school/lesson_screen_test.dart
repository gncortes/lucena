import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Square;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/board/speech_flash.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
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
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final texts = LessonTexts.fromJson({
      'module.pieces': 'The pieces',
      'pieces.rook.title': 'The rook',
      'pieces.rook.intro': intro ?? long,
      'pieces.rook.stars': 'Take the rook to the stars.',
      'coach.illegal.rook': 'The rook does not move like that.',
    });
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(texts: texts),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('pieces.rook', 'en');
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
      'dela, acima dos botões', (tester) async {
    await pump(tester);
    final speech = find.byKey(LessonKeys.speech);
    expect(tester.widget<Text>(speech).data, long);
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
    final next = tester.getRect(find.byKey(LessonKeys.nextButton));
    expect(tester.getRect(speech).bottom, lessThan(next.top));
  });

  testWidgets(
    'os botões flutuantes não cobrem a fala: a área que rola '
    'termina acima deles e o fim do texto fica à vista; fala curta não rola',
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
      // Fechada: nada da fala passa por baixo dos botões.
      expect(tester.getRect(scroll).bottom, lessThanOrEqualTo(buttons.top));

      for (var i = 0; i < 3; i++) {
        await tester.drag(scroll, const Offset(0, -3000));
        await tester.pumpAndSettle();
      }
      final end = tester.getRect(speech).bottom;
      expect(end, lessThan(buttons.top));
      expect(end, lessThanOrEqualTo(tester.getRect(scroll).bottom));

      // Fala curta: cabe, sem rolagem.
      await pump(tester, intro: 'Short.');
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
    final speech = find.byKey(LessonKeys.speech);
    final full = tester.getRect(board);
    // Fechada: a folha começa abaixo do tabuleiro.
    expect(tester.getRect(speech).top, greaterThan(full.bottom));

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    // Aberta: o tabuleiro não encolhe, a folha é que cobre.
    expect(tester.getRect(board), full);
    expect(tester.getRect(speech).top, lessThan(full.bottom));
    // Os botões continuam à vista, por cima da folha.
    expect(find.byKey(LessonKeys.nextButton).hitTestable(), findsOneWidget);

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(speech).top, greaterThan(full.bottom));
    expect(board.hitTestable(), findsOneWidget);
  });

  testWidgets('marcações: o botão na folha esconde e mostra, e grava', (
    tester,
  ) async {
    final settings = await pump(tester);
    expect(settings.state!.lessonMarks, isTrue);
    await tester.tap(find.byKey(LessonKeys.marksToggle));
    await tester.pumpAndSettle();
    expect(settings.state!.lessonMarks, isFalse);
    await tester.tap(find.byKey(LessonKeys.marksToggle));
    await tester.pumpAndSettle();
    expect(settings.state!.lessonMarks, isTrue);
  });

  testWidgets('fala curta: a folha não abre e o x não aparece', (tester) async {
    await pump(tester, intro: 'Short.');
    final board = tester.getRect(find.byKey(LessonKeys.board));
    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(LessonKeys.board)), board);
    expect(
      tester.getRect(find.byKey(LessonKeys.speech)).top,
      greaterThan(board.bottom),
    );
    expect(find.byKey(LessonKeys.closeSheet).hitTestable(), findsNothing);
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
    expect(find.byKey(LessonKeys.prompt), findsOneWidget);
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

  testWidgets('escola: o tabuleiro no meio do espaço livre resolvendo e, '
      'explicando, perto dali, com a folha abaixo da fileira 1', (
    tester,
  ) async {
    await pump(tester, intro: 'Short.', size: const Size(412, 860));
    final talk = tester.getRect(find.byKey(LessonKeys.board));
    // A folha fechada começa abaixo do tabuleiro, com um vão.
    expect(
      tester.getRect(find.byKey(LessonKeys.scroll)).top,
      greaterThanOrEqualTo(talk.bottom + 8 - 0.5),
    );
    await toStars(tester);
    final stars = tester.getRect(find.byKey(LessonKeys.board));
    final prompt = tester.getRect(find.byKey(LessonKeys.prompt));
    final footer = tester.getRect(find.byKey(LessonKeys.footer));
    expect(stars.size, talk.size);
    // No meio entre o enunciado e o rodapé.
    expect(stars.top - prompt.bottom, closeTo(footer.top - stars.bottom, 1));
    // Explicando, ele não vai para o alto: fica a menos de meio tabuleiro
    // de onde estava resolvendo.
    expect((stars.top - talk.top).abs(), lessThan(stars.height / 2));
  });
}
