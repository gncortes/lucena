import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/script_speech_sheet.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:lucena/ui/core/widgets/speech_sheet_fade.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  testWidgets('folha da fala aberta: nome e balão de cima somem; ao fechar, '
      'voltam, e o espaço fica reservado', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viktor = (await FakeCharacterRepository().characters()).firstWhere(
      (c) => c.id == 'master',
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TeacherSpeech(
                  part: TeacherSpeechPart.header,
                  lessonV2: true,
                  headerAvatar: 40,
                  avatarHeroTag: scriptViktorHeroTag,
                  teacher: viktor,
                  text: 'Fala.',
                  speechContext: SpeechContext.teaching,
                ),
                const SpeechBalloon(child: Text('balão de cima')),
                TextButton(
                  onPressed: () => showScriptSpeechSheet(
                    context,
                    viktor: viktor,
                    title: 'Mestre Viktor',
                    texts: const ['Fala.'],
                  ),
                  child: const Text('abrir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final fades = find.descendant(
      of: find.byType(Column).first,
      matching: find.byType(SpeechSheetFade),
    );
    expect(fades, findsNWidgets(2));
    List<double> opacities() => [
      for (final fade in fades.evaluate())
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: find.byWidget(fade.widget),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
    ];
    await tester.pumpAndSettle();
    final spot = tester.getRect(find.text('balão de cima'));
    expect(opacities(), [1, 1]);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
    expect(opacities(), [0, 0]);
    // O espaço continua reservado: o balão não saiu do lugar.
    expect(tester.getRect(find.text('balão de cima')), spot);

    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
    expect(opacities(), [1, 1]);
  });
}
