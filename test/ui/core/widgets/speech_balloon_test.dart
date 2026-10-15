import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/character_speech.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/character_bar.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

const _avatar = Key('avatar');

CharacterLine _line(String id, String text) => CharacterLine(
  id: id,
  category: LineCategory.gameStart,
  intensity: 1,
  emotion: Emotion.calm,
  text: text,
);

/// O que pinta o balão (corpo e ponta num contorno só).
final _shaped = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is BalloonPainter,
  description: 'pintura do balão',
);

SpeechBalloonShape _shapeOf(WidgetTester tester) =>
    (tester.widget<CustomPaint>(_shaped).painter! as BalloonPainter).shape;

void main() {
  for (final tail in [BalloonTail.up, BalloonTail.down]) {
    testWidgets('ponta ${tail.name} centrada no retrato (±2 px)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 740)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const avatar = 44.0;
      final balloon = SpeechBalloon(
        tail: tail,
        tailX: SpeechBalloon.tailXFor(avatar),
        child: const Text('Olá'),
      );
      const portrait = SizedBox.square(key: _avatar, dimension: avatar);
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tail == BalloonTail.up) portrait else balloon,
                  if (tail == BalloonTail.up) balloon else portrait,
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(_shaped);
      final shape = _shapeOf(tester);
      final tip = shape.tipOf(rect);
      expect(tip.dx, closeTo(tester.getCenter(find.byKey(_avatar)).dx, 2));
    });
  }

  for (final tail in [BalloonTail.up, BalloonTail.down, BalloonTail.start]) {
    testWidgets('ponta ${tail.name}: a pontinha fica a 6 do retrato '
        '(canvas CompBalao 3f3938b)', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 740)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const avatar = 44.0;
      final balloon = SpeechBalloon(
        tail: tail,
        tailX: SpeechBalloon.tailXFor(avatar),
        tailY: avatar / 2,
        child: const Text('Olá'),
      );
      const portrait = SizedBox.square(key: _avatar, dimension: avatar);
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (tail) {
                BalloonTail.start => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    portrait,
                    Expanded(child: balloon),
                  ],
                ),
                BalloonTail.up => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [portrait, balloon],
                ),
                _ => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [balloon, portrait],
                ),
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(_shaped);
      final shape = _shapeOf(tester);
      final tip = shape.tipOf(rect);
      final face = tester.getRect(find.byKey(_avatar));
      final gap = switch (tail) {
        BalloonTail.up => tip.dy - face.bottom,
        BalloonTail.down => face.top - tip.dy,
        _ => tip.dx - face.right,
      };
      expect(gap, SpeechBalloon.tailGap);
      expect(SpeechBalloon.tailGap, 6);
    });
  }

  for (final tail in [BalloonTail.up, BalloonTail.down, BalloonTail.start]) {
    test('ponta ${tail.name}: um contorno só, com a ponta presa ao corpo', () {
      final shape = SpeechBalloonShape(
        tail: tail,
        tailX: SpeechBalloon.tailXFor(44),
        tailY: 22,
        textDirection: TextDirection.ltr,
      );
      const rect = Rect.fromLTWH(0, 0, 300, 100);
      final path = shape.getOuterPath(rect);
      final tip = shape.tipOf(rect);
      final body = shape.bodyOf(rect, TextDirection.ltr);
      // A pontinha e o meio do caminho até o corpo estão dentro do contorno.
      final inward = switch (tail) {
        BalloonTail.up => const Offset(0, 1),
        BalloonTail.down => const Offset(0, -1),
        _ => const Offset(1, 0),
      };
      // Da pontinha até dentro do corpo, sem buraco na emenda.
      for (var d = 1.0; d <= 14; d++) {
        expect(path.contains(tip + inward * d), isTrue, reason: '$d');
      }
      expect(path.contains(body.center), isTrue);
      // A base fica no trecho reto, fora do raio do canto (16).
      if (tail != BalloonTail.start) {
        final y = tail == BalloonTail.up ? body.top + 0.5 : body.bottom - 0.5;
        expect(path.contains(Offset(body.left + 16.5, y)), isTrue);
        expect(path.contains(Offset(body.left + 16 + 17.5, y)), isTrue);
        // A pontinha mira o centro do retrato de 44.
        expect(tip.dx, closeTo(22, 0.01));
      }
    });
  }

  testWidgets('os 3 usos têm o mesmo fundo e sombra, e nenhum tem X', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ScriptSpeech(
                  texts: const ['Lição'],
                  metrics: ScriptSpeechMetrics.of(context),
                ),
                const CharacterSpeech(
                  character: FakeCharacterRepository.viktor,
                  text: 'Partida',
                ),
                const CharacterBar(
                  talk: TalkState(
                    character: FakeCharacterRepository.viktor,
                    line: CharacterLine(
                      id: 'a',
                      category: LineCategory.gameStart,
                      intensity: 1,
                      emotion: Emotion.calm,
                      text: 'Adversário',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    // Sem Material nem elevação: o fundo e a sombra vêm pintados no contorno.
    expect(
      find.descendant(
        of: find.byType(SpeechBalloon),
        matching: find.byType(PhysicalShape),
      ),
      findsNothing,
    );
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<BalloonPainter>()
        .toList();
    expect(painters, hasLength(3));
    for (final painter in painters) {
      expect(painter.color, scheme.surfaceContainerLowest);
      expect(painter.shadow, scheme.shadow.withValues(alpha: 0.25));
    }
    expect(BalloonPainter.offset, const Offset(0, 1));
    expect(BalloonPainter.sigma, 0.75);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byKey(LessonScriptKeys.speech), findsOneWidget);
  });

  testWidgets('CharacterBar: ao mudar a fala o mesmo balão faz crossfade', (
    tester,
  ) async {
    Widget bar(CharacterLine line) => TestApp(
      child: Scaffold(
        body: CharacterBar(
          talk: TalkState(
            character: FakeCharacterRepository.viktor,
            line: line,
          ),
        ),
      ),
    );
    await tester.pumpWidget(bar(_line('a', 'Primeira fala')));
    await tester.pumpAndSettle();
    final first = tester.element(find.byKey(FreeBoardKeys.speechBubble));
    await tester.pumpWidget(bar(_line('b', 'Segunda fala')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.textContaining('Primeira'), findsOneWidget);
    expect(find.textContaining('Segunda'), findsOneWidget);
    expect(tester.element(find.byKey(FreeBoardKeys.speechBubble)), same(first));
    await tester.pumpAndSettle();
    expect(find.textContaining('Primeira'), findsNothing);
  });
}
