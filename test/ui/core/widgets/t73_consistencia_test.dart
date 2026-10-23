import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';
import 'package:lucena/ui/core/widgets/round_footer_button.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  const ringKey = Key('ring');

  Future<void> pumpRow(WidgetTester tester, {Duration? time}) =>
      tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: PlayersRow(
              board: const BoardSettings(),
              players: [
                PlayerEntry(
                  side: Side.white,
                  name: 'Eu',
                  time: time,
                  running: time != null,
                  isTurn: true,
                  turnKey: ringKey,
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('D1: sem relógio, o retrato de quem joga leva o anel de 2 px; '
      'não há chip de vez', (tester) async {
    await pumpRow(tester);
    final box = tester.widget<DecoratedBox>(find.byKey(ringKey));
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.top.width, 2);
    expect(
      border.top.color,
      Theme.of(tester.element(find.byKey(ringKey))).colorScheme.primary,
    );
    expect(find.byType(GameClock), findsNothing);
    // Só o nome: nenhum texto de vez.
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('D1: com relógio, sem anel; o relógio aceso leva borda onSurface '
      'de 2 px', (tester) async {
    await pumpRow(tester, time: const Duration(minutes: 3));
    expect(find.byKey(ringKey), findsNothing);
    final clock = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(GameClock),
            matching: find.byType(Container),
          )
          .first,
    );
    final border = (clock.decoration! as BoxDecoration).border! as Border;
    expect(border.top.width, 2);
    expect(
      border.top.color,
      Theme.of(tester.element(find.byType(GameClock))).colorScheme.onSurface,
    );
  });

  Future<Rect> pumpBar(WidgetTester tester, {List<Widget>? actions}) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          appBar: LucenaAppBar(title: const Text('Título'), actions: actions),
        ),
      ),
    );
    return tester.getRect(find.text('Título'));
  }

  testWidgets('D2: título centrado sem ação e à esquerda com ação', (
    tester,
  ) async {
    final centered = await pumpBar(tester);
    expect(centered.center.dx, closeTo(200, 1));
    final left = await pumpBar(
      tester,
      actions: const [SizedBox(width: 48, height: 48)],
    );
    expect(left.left, lessThan(100));
    expect(left.center.dx, lessThan(200));
  });

  testWidgets('botão da dica: só o ícone, redondo, com tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: RoundFooterButton(
            icon: Icons.lightbulb_outline,
            tooltip: 'Dica',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byType(Text), findsNothing);
    expect(find.byTooltip('Dica'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FloatingActionButton)),
      const Size(56, 56),
    );
  });

  testWidgets('botão primário de rodapé 16/24; o do tema (cartão) fica 14/20', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final footer = AppButtonText.footer(context)!;
    expect(footer.fontSize, 16);
    expect(footer.fontSize! * footer.height!, closeTo(24, 0.001));
    final card = Theme.of(context).textTheme.labelLarge!;
    expect(card.fontSize, 14);
    expect(card.fontSize! * card.height!, closeTo(20, 0.05));
  });

  testWidgets('o nome do Viktor é w500', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: 'Olá.',
            speechContext: SpeechContext.game,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final name = tester.widget<Text>(
      find.textContaining(FakeCharacterRepository.viktor.name).first,
    );
    expect(name.style?.fontWeight, FontWeight.w500);
  });
}
