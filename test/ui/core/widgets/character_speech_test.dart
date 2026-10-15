import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/character_speech.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';

import '../../../../testing/test_app.dart';

const _viktor = Character(
  id: 'master',
  level: 2600,
  name: 'Viktor',
  tagline: {},
  personality: {},
  traits: [],
  avatar: 'assets/characters/master/avatar.png',
);

final _long = List.filled(
  14,
  'Procure uma casa do rei que deixe um número ímpar.',
).join(' ');

/// O balão do personagem (T72): o balão único, sem X; o toque abre a fala.
void main() {
  var opened = 0;

  Future<void> pump(
    WidgetTester tester, {
    required String text,
    bool typing = false,
    String? lead,
    Size size = const Size(360, 740),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    opened = 0;
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          appBar: AppBar(title: const Text('Lição')),
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: SizedBox(
                height: 160,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CharacterSpeech(
                    character: _viktor,
                    text: text,
                    typing: typing,
                    lead: lead,
                    onOpen: () => opened++,
                    bubbleKey: LessonKeys.practiceSpeech,
                    typingKey: LessonKeys.practiceTyping,
                    avatarKey: LessonKeys.practiceViktor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Os pontinhos giram sem parar: não há como assentar.
    await (typing
        ? tester.pump(const Duration(milliseconds: 100))
        : tester.pumpAndSettle());
  }

  for (final size in const [Size(360, 740), Size(412, 917)]) {
    testWidgets(
      '$size: texto longo: corta com reticências, toque abre, sem X',
      (tester) async {
        await pump(tester, text: _long, size: size);
        final bubble = find.byKey(LessonKeys.practiceSpeech);
        final rect = tester.getRect(bubble);
        expect(rect.left, 12);
        expect(rect.width, size.width - 24);
        final text = tester.widget<RichText>(
          find.descendant(of: bubble, matching: find.byType(RichText)).first,
        );
        expect(text.maxLines, lessThanOrEqualTo(3));
        expect(text.overflow, TextOverflow.ellipsis);
        expect(find.byIcon(Icons.close), findsNothing);

        await tester.tap(bubble);
        expect(opened, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$size: a ponta cai no centro do retrato (±2 dp)', (
      tester,
    ) async {
      await pump(tester, text: 'Sua vez.', size: size);
      // A ponta é medida na pintura do balão; o vão de 6 fica fora dele.
      final rect = tester.getRect(
        find.descendant(
          of: find.byKey(LessonKeys.practiceSpeech),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is BalloonPainter,
          ),
        ),
      );
      final avatar = tester.getRect(find.byKey(LessonKeys.practiceViktor));
      final shape =
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byKey(LessonKeys.practiceSpeech),
                          matching: find.byWidgetPredicate(
                            (w) =>
                                w is CustomPaint && w.painter is BalloonPainter,
                          ),
                        ),
                      )
                      .painter!
                  as BalloonPainter)
              .shape;
      final tip = shape.tipOf(rect);
      expect(tip.dx, closeTo(avatar.center.dx, 2));
      // A pontinha fica a 6 dp do retrato.
      expect(avatar.top - tip.dy, closeTo(6, 0.5));
    });
  }

  testWidgets('toque no Viktor também abre a fala', (tester) async {
    await pump(tester, text: _long);
    await tester.tap(find.byKey(LessonKeys.practiceViktor));
    expect(opened, 1);
  });

  testWidgets('balão com a largura toda e peso regular', (tester) async {
    await pump(tester, text: 'Sua vez.');
    final rect = tester.getRect(find.byKey(LessonKeys.practiceSpeech));
    expect(rect.left, 12);
    expect(rect.width, 360 - 24);
    final text = tester.widget<RichText>(
      find
          .descendant(
            of: find.byKey(LessonKeys.practiceSpeech),
            matching: find.byType(RichText),
          )
          .first,
    );
    expect(text.text.style?.fontWeight, FontWeight.w400);
  });

  testWidgets('a Dica leva o selo; digitando mostra os pontos', (tester) async {
    await pump(tester, text: 'Pense no rei.', lead: 'Dica');
    expect(find.text('Dica'), findsOneWidget);
    await pump(tester, text: '', typing: true);
    expect(find.byKey(LessonKeys.practiceTyping), findsOneWidget);
  });
}
