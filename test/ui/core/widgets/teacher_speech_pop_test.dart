import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/balao_viktor.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

/// H-ANI-09 no `TeacherSpeech`: o balão entra pelo bico na primeira
/// aparição; a fala nova não repete a entrada (a troca é a digitação).
void main() {
  Widget fala(String texto, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: TestApp(
      locale: const Locale('pt'),
      child: Scaffold(
        body: TeacherSpeech(
          teacher: FakeCharacterRepository.viktor,
          text: texto,
          speechContext: SpeechContext.teaching,
        ),
      ),
    ),
  );

  double opacidadeDoPop(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .descendant(
              of: find.byType(SpeechPop),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  testWidgets('a primeira aparição entra pelo bico em 280 ms', (tester) async {
    await tester.pumpWidget(fala('Olá.'));
    expect(find.byType(SpeechPop), findsOneWidget);
    expect(opacidadeDoPop(tester), 0);
    await tester.pump(const Duration(milliseconds: 140));
    expect(opacidadeDoPop(tester), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 160));
    expect(opacidadeDoPop(tester), 1);
    await tester.pumpAndSettle();
  });

  testWidgets('fala nova: o balão não entra de novo', (tester) async {
    await tester.pumpWidget(fala('Olá.'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(fala('Agora o rei vai à frente.'));
    await tester.pump();
    expect(opacidadeDoPop(tester), 1);
    await tester.pumpAndSettle();
  });

  testWidgets('movimento reduzido: só o fade curto, sem escala', (
    tester,
  ) async {
    await tester.pumpWidget(fala('Olá.', reduzir: true));
    expect(
      find.descendant(
        of: find.byType(SpeechPop),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacidadeDoPop(tester), 1);
  });
}
