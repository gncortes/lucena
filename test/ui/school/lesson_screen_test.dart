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

  Future<void> pump(
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

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final next = tester.getRect(find.byKey(LessonKeys.nextButton));
    expect(tester.getRect(speech).bottom, lessThan(next.top));
  });

  testWidgets('fala longa: ao rolar, o tabuleiro encolhe mas continua à '
      'vista, e voltando ao topo ele volta ao tamanho cheio', (tester) async {
    await pump(tester);
    final full = tester.getSize(find.byKey(LessonKeys.board));

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final small = tester.getSize(find.byKey(LessonKeys.board));
    expect(small.width, lessThan(full.width));
    expect(small.width, greaterThanOrEqualTo(full.width / 2));
    expect(find.byKey(LessonKeys.board).hitTestable(), findsOneWidget);

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(LessonKeys.board)).width, full.width);
  });

  testWidgets('lendo a fala longa, os botões saem da frente; voltam ao rolar '
      'para cima e no fim do texto', (tester) async {
    await pump(tester);
    final next = find.byKey(LessonKeys.nextButton);
    expect(next.hitTestable(), findsOneWidget);

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(next.hitTestable(), findsNothing);

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(next.hitTestable(), findsOneWidget);

    await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(next.hitTestable(), findsOneWidget);
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
}
