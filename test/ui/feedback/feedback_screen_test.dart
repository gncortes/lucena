import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/ui/core/keys/feedback_keys.dart';
import 'package:lucena/ui/feedback/view_models/feedback_cubit.dart';
import 'package:lucena/ui/feedback/widgets/feedback_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeFeedbackRepository feedback;

  setUp(() => feedback = FakeFeedbackRepository());

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = FeedbackCubit(
      feedback: feedback,
      characters: FakeCharacterRepository(),
      language: 'pt',
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const FeedbackScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool canSend(WidgetTester tester) =>
      tester
          .widget<ButtonStyleButton>(find.byKey(FeedbackKeys.send))
          .onPressed !=
      null;

  testWidgets('Enviar só com assunto e texto; depois o agradecimento', (
    tester,
  ) async {
    await pump(tester);
    expect(canSend(tester), isFalse);
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.problem)));
    await tester.pumpAndSettle();
    expect(canSend(tester), isFalse);
    await tester.enterText(find.byKey(FeedbackKeys.text), '   ');
    await tester.pumpAndSettle();
    expect(canSend(tester), isFalse);
    await tester.enterText(find.byKey(FeedbackKeys.text), 'O som some');
    await tester.pumpAndSettle();
    expect(find.text('10/500'), findsOneWidget);
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();

    final sent = feedback.sent.single;
    expect(sent.type, FeedbackType.problem);
    expect(sent.text, 'O som some');
    expect(sent.language, 'pt');
    expect(find.byKey(FeedbackKeys.thanks), findsOneWidget);
    expect(find.text('Voltar ao perfil'), findsOneWidget);
  });

  testWidgets('o texto para em 500 letras', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(FeedbackKeys.text), 'a' * 600);
    await tester.pumpAndSettle();
    expect(find.byKey(FeedbackKeys.counter), findsOneWidget);
    expect(find.text('500/500'), findsOneWidget);
  });

  testWidgets('um assunto por vez', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.idea)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.praise)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FeedbackKeys.text), 'Gostei');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();
    expect(feedback.sent.single.type, FeedbackType.praise);
  });
}
