import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/script_speech_sheet.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  testWidgets('fala inteira: retrato 40, nome, falas separadas por linha em '
      'branco; o link fecha a folha e faz o mesmo que o botão', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viktor = (await FakeCharacterRepository().characters()).firstWhere(
      (c) => c.id == 'master',
    );
    var answers = 0;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showScriptSpeechSheet(
                context,
                viktor: viktor,
                title: 'Professor Viktor',
                texts: const [
                  'Primeira fala.',
                  'Agora clique em {verResposta}.',
                ],
                onShowAnswer: () => answers++,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final sheet = find.byKey(LessonScriptKeys.speechSheet);
    expect(sheet, findsOneWidget);
    // A folha não passa de 70% da tela (sem o ✕).
    expect(tester.getSize(sheet).height, lessThanOrEqualTo(915 * 0.7));
    final hero = find.descendant(of: sheet, matching: find.byType(Hero));
    expect(tester.widget<Hero>(hero).tag, scriptViktorHeroTag);
    expect(tester.getSize(hero), const Size(40, 40));
    final body = tester.widget<Text>(
      find.descendant(of: sheet, matching: find.byType(Text)).last,
    );
    expect(
      body.textSpan!.toPlainText(),
      'Primeira fala.\n\nAgora clique em ver resposta',
    );
    await tester.tapOnText(find.textRange.ofSubstring('ver resposta'));
    await tester.pumpAndSettle();
    expect(answers, 1);
    expect(sheet, findsNothing);
  });

  testWidgets('arrastar para baixo fecha a folha', (tester) async {
    final viktor = (await FakeCharacterRepository().characters()).firstWhere(
      (c) => c.id == 'master',
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showScriptSpeechSheet(
                context,
                viktor: viktor,
                title: 'Professor Viktor',
                texts: const ['Uma fala.'],
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(LessonScriptKeys.speechSheet),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
  });
}
