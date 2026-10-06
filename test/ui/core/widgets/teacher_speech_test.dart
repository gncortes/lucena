import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  const speech = Key('speech');
  const long =
      'Queen against rook is a win, but the queen cannot do it alone: a rook '
      'glued to its king defends everything.';

  Future<void> pump(
    WidgetTester tester, {
    bool stacked = false,
    bool typed = false,
    bool noAnimations = false,
  }) => tester.pumpWidget(
    TestApp(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: noAnimations),
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: long,
            bubbleKey: speech,
            stacked: stacked,
            typed: typed,
          ),
        ),
      ),
    ),
  );

  String shown(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(speech)).data!;

  testWidgets('ao lado: o balão começa à direita do retrato', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final avatar = tester.getRect(find.byType(CharacterAvatar));
    final text = tester.getRect(find.byKey(speech));
    expect(text.left, greaterThan(avatar.right));
  });

  testWidgets('embaixo: o balão fica abaixo do retrato e usa a largura toda', (
    tester,
  ) async {
    await pump(tester, stacked: true);
    await tester.pumpAndSettle();
    final avatar = tester.getRect(find.byType(CharacterAvatar));
    final text = tester.getRect(find.byKey(speech));
    expect(text.top, greaterThan(avatar.bottom));
    expect(text.left, lessThan(avatar.right));
  });

  testWidgets('a fala aparece aos poucos e o texto está inteiro desde o '
      'começo', (tester) async {
    await pump(tester, stacked: true, typed: true);
    await tester.pump(const Duration(milliseconds: 100));
    // O texto inteiro já está lá (quem lê a tela ouve tudo); só a vista é
    // recortada enquanto a fala anda.
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsOneWidget);

    await tester.pumpAndSettle();
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('um toque no balão mostra a fala inteira', (tester) async {
    await pump(tester, stacked: true, typed: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ClipPath), findsOneWidget);

    // O texto ainda está recortado: quem recebe o toque é a área da fala.
    await tester.tap(find.byKey(speech), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('com as animações desligadas a fala aparece de uma vez', (
    tester,
  ) async {
    await pump(tester, stacked: true, typed: true, noAnimations: true);
    await tester.pump();
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsNothing);
  });
}
