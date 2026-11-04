import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/test_canvas_keys.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/test_app.dart';

/// H-LIC-47 a 49: medalhas e telas de resultado do teste do capítulo.
void main() {
  Future<void> open(
    WidgetTester tester, {
    required int correct,
    List<String?>? themes,
    VoidCallback? onContinue,
    VoidCallback? onRetry,
    VoidCallback? onReviewLessons,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: TestCanvasResultPage(
          chapter: 2,
          answers: [for (var i = 0; i < 12; i++) i < correct],
          themes: themes ?? List.filled(12, 'Garfo de cavalo'),
          teacher: FakeCharacterRepository.viktor,
          onContinue: onContinue ?? () {},
          onRetry: onRetry ?? () {},
          onReviewLessons: onReviewLessons ?? () {},
          onReview: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ExercisesDoneKeys.current)).data!;

  for (final (correct, name) in [
    (12, 'Perfeito'),
    (11, 'Excelente'),
    (10, 'Ótimo'),
    (9, 'Você passou'),
  ]) {
    testWidgets('$correct de 12 mostra a medalha $name', (tester) async {
      await open(tester, correct: correct);
      expect(title(tester), name);
      expect(find.text('Teste do capítulo 2 · $correct de 12'), findsOneWidget);
      expect(find.text('Continuar o curso'), findsOneWidget);
      expect(find.text('Refazer o teste'), findsOneWidget);
    });
  }

  for (final correct in [4, 7, 8]) {
    testWidgets('$correct de 12 mostra Quase lá com os temas dos erros', (
      tester,
    ) async {
      var reviewed = 0, retried = 0;
      await open(
        tester,
        correct: correct,
        themes: [
          for (var i = 0; i < 12; i++) i.isEven ? 'Garfo de cavalo' : 'Cravada',
        ],
        onReviewLessons: () => reviewed++,
        onRetry: () => retried++,
      );
      expect(title(tester), 'Quase lá');
      expect(find.text('Teste do capítulo 2 · $correct de 12'), findsOneWidget);
      final first = correct.isEven ? 'Garfo de cavalo' : 'Cravada';
      final second = correct.isEven ? 'Cravada' : 'Garfo de cavalo';
      expect(
        find.textContaining(
          'Recomendo rever as lições deste capítulo antes de seguir. '
          'Os erros foram em $first e $second.',
        ),
        findsOneWidget,
      );
      expect(find.text('Rever as lições'), findsOneWidget);
      expect(find.text('Refazer o teste'), findsOneWidget);
      expect(find.text('Continuar o curso'), findsNothing);
      await tester.tap(find.byKey(TestCanvasKeys.reviewLessons));
      await tester.tap(find.byKey(ExercisesDoneKeys.redo));
      expect(reviewed, 1);
      expect(retried, 1);
    });
  }

  for (final correct in [3, 0]) {
    testWidgets('$correct de 12 mostra Vamos recomeçar', (tester) async {
      await open(
        tester,
        correct: correct,
        themes: [
          for (var i = 0; i < 12; i++)
            ['Garfo de cavalo', 'Cravada', 'Ataque duplo'][i % 3],
        ],
      );
      expect(title(tester), 'Vamos recomeçar');
      expect(find.text('Teste do capítulo 2 · $correct de 12'), findsOneWidget);
      expect(
        find.textContaining(
          'Recomendo fortemente rever as lições deste capítulo antes de '
          'seguir. Os erros foram em Garfo de cavalo, Cravada e Ataque duplo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Rever as lições'), findsOneWidget);
      expect(find.text('Refazer o teste'), findsOneWidget);
    });
  }

  testWidgets('um tema só na fala', (tester) async {
    await open(tester, correct: 7);
    expect(
      find.textContaining('Os erros foram em Garfo de cavalo.'),
      findsOneWidget,
    );
  });

  testWidgets('sem tema conhecido a fala não cita erros', (tester) async {
    await open(tester, correct: 7, themes: List.filled(12, null));
    expect(
      find.textContaining('Recomendo rever as lições deste capítulo antes de'),
      findsOneWidget,
    );
    expect(find.textContaining('Os erros foram'), findsNothing);
  });

  testWidgets('reprovar não mostra cadeado nem aviso de bloqueio', (
    tester,
  ) async {
    await open(tester, correct: 3);
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.textContaining('liberar'), findsNothing);
    expect(find.textContaining('bloque'), findsNothing);
  });
}
