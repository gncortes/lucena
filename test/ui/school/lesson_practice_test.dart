import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/ui/core/board/centered_board_layout.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/widgets/lesson_practice.dart';

import '../../../testing/test_app.dart';

const _viktor = Character(
  id: 'master',
  level: 2600,
  name: 'Viktor',
  tagline: {},
  personality: {},
  traits: [],
  avatar: 'assets/characters/master/avatar.png',
);

/// O convite e o prático da lição (T70, pg. 3.1 e 4.x).
void main() {
  var starts = 0, inviteBacks = 0, hints = 0, backs = 0, continues = 0;

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    bool invite = false,
    String? comment,
    bool back = false,
    bool next = false,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    starts = inviteBacks = hints = backs = continues = 0;
    await tester.pumpWidget(
      TestApp(
        child: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(title: const Text('Oposição distante')),
            body: BoardViewport(
              usefulHeight: size.height - 56,
              child: LessonPractice(
                viktor: _viktor,
                invite: invite,
                comment: comment,
                board: (context, side) => SizedBox.square(
                  key: const Key('test.board'),
                  dimension: side,
                ),
                onStart: () => starts++,
                onInviteBack: () => inviteBacks++,
                onHint: () => hints++,
                onBack: back ? () => backs++ : null,
                onContinue: next ? () => continues++ : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final sizes = {Size(360, 740): 344.0, Size(412, 917): 396.0};
  for (final entry in sizes.entries) {
    final size = entry.key;
    testWidgets('$size: convite com Voltar | Vamos praticar em duas colunas', (
      tester,
    ) async {
      await pump(tester, size, invite: true);
      final board = tester.getRect(find.byKey(LessonKeys.practiceBoard));
      expect(board.width, closeTo(entry.value, 1));
      expect(board.center.dx, closeTo(size.width / 2, 1));
      // O Viktor no alto, acima do tabuleiro, com o convite no balão.
      expect(find.byKey(LessonKeys.practiceInvite), findsOneWidget);
      expect(
        tester.getRect(find.byKey(LessonKeys.practiceViktor)).bottom,
        lessThanOrEqualTo(board.top),
      );
      expect(find.byKey(LessonKeys.hintButton), findsNothing);
      final back = tester.getRect(find.byKey(LessonKeys.practiceInviteBack));
      final start = tester.getRect(find.byKey(LessonKeys.practiceButton));
      expect(back.width, closeTo(start.width, 1));
      expect(back.height, 48);
      expect(start.left - back.right, closeTo(8, 1));
      expect(back.left, closeTo(16, 1));
      expect(size.width - start.right, closeTo(16, 1));
      expect(back.top, greaterThan(board.bottom));
      await tester.tap(find.byKey(LessonKeys.practiceButton));
      await tester.tap(find.byKey(LessonKeys.practiceInviteBack));
      expect([starts, inviteBacks], [1, 1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$size: prático com Dica | Voltar | Continuar iguais', (
      tester,
    ) async {
      await pump(tester, size, comment: 'Boa jogada.', back: true, next: true);
      final board = tester.getRect(find.byKey(LessonKeys.practiceBoard));
      expect(board.width, closeTo(entry.value, 1));
      final hint = tester.getRect(find.byKey(LessonKeys.hintButton));
      final back = tester.getRect(find.byKey(LessonKeys.practiceBack));
      final next = tester.getRect(find.byKey(LessonKeys.practiceContinue));
      expect(hint.height, greaterThanOrEqualTo(48));
      expect(back.width, closeTo(next.width, .5));
      expect(back.height, 48);
      expect(hint.right, lessThanOrEqualTo(back.left));
      expect(next.left - back.right, closeTo(8, 1));
      expect(size.width - next.right, closeTo(8, 1));
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      // Rodapé branco, com divisória em cima (pg. 3.1/4.7).
      final footer = find.ancestor(
        of: find.byKey(LessonKeys.hintButton),
        matching: find.byType(DecoratedBox),
      );
      final decoration = footer
          .evaluate()
          .map((e) => (e.widget as DecoratedBox).decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      final scheme = Theme.of(tester.element(find.byKey(LessonKeys.hintButton)))
          .colorScheme;
      expect(decoration.color, scheme.surfaceContainerLowest);
      expect((decoration.border! as Border).top.width, greaterThan(0));
      await tester.tap(find.byKey(LessonKeys.hintButton));
      await tester.tap(find.byKey(LessonKeys.practiceBack));
      await tester.tap(find.byKey(LessonKeys.practiceContinue));
      expect([hints, backs, continues], [1, 1, 1]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('botões só com ação: Dica | Voltar, e Dica sozinha', (
    tester,
  ) async {
    await pump(tester, const Size(360, 740), comment: 'Sua vez.', back: true);
    expect(find.byKey(LessonKeys.hintButton), findsOneWidget);
    expect(find.byKey(LessonKeys.practiceBack), findsOneWidget);
    expect(find.byKey(LessonKeys.practiceContinue), findsNothing);
    expect(
      tester.getRect(find.byKey(LessonKeys.practiceBack)).width,
      closeTo(124, .5),
    );
    await pump(tester, const Size(360, 740), comment: 'Sua vez.');
    expect(find.byKey(LessonKeys.hintButton), findsOneWidget);
    expect(find.byKey(LessonKeys.practiceBack), findsNothing);
    expect(find.byKey(LessonKeys.practiceContinue), findsNothing);
  });

  testWidgets('o balão mostra o nome da referência, sem a marcação', (
    tester,
  ) async {
    await pump(
      tester,
      const Size(360, 740),
      comment: 'Estudo de {{Nikolai Grigoriev|nikolai-grigoriev}}, de 1930.',
    );
    expect(
      find.textContaining('Nikolai Grigoriev, de 1930', findRichText: true),
      findsWidgets,
    );
    expect(find.textContaining('{{', findRichText: true), findsNothing);
  });
}
