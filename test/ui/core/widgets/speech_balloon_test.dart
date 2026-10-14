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

/// O Material que desenha o balão (corpo e ponta num contorno só).
final _shaped = find.byWidgetPredicate(
  (w) => w is Material && w.shape is SpeechBalloonShape,
  description: 'Material do balão',
);

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
      final shape =
          tester.widget<Material>(_shaped).shape! as SpeechBalloonShape;
      final tip = shape.tipOf(rect);
      expect(tip.dx, closeTo(tester.getCenter(find.byKey(_avatar)).dx, 2));
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
    final materials = tester.widgetList<Material>(_shaped).toList();
    expect(materials, hasLength(3));
    final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    for (final m in materials) {
      expect(m.color, scheme.surfaceContainerLowest);
      expect(m.elevation, 1);
    }
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
