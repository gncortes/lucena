import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/would_pay_keys.dart';
import 'package:lucena/ui/would_pay/view_models/would_pay_cubit.dart';
import 'package:lucena/ui/would_pay/widgets/would_pay_invite_card.dart';
import 'package:lucena/ui/would_pay/widgets/would_pay_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeWouldPayRepository wouldPay;
  late FakeFeedbackRepository feedback;

  setUp(() {
    wouldPay = FakeWouldPayRepository();
    feedback = FakeFeedbackRepository();
  });

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

  Future<void> pumpScreen(WidgetTester tester) async {
    phone(tester);
    final cubit = WouldPayCubit(
      wouldPay: wouldPay,
      feedback: feedback,
      profile: FakeProfileRepository(),
      characters: FakeCharacterRepository(),
      review: FakeReviewRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const WouldPayScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('3 passos: Continuar só com as respostas, depois Enviar', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(enabled(tester, WouldPayKeys.next), isFalse);
    await tap(tester, WouldPayKeys.courseAnswer('yes'));
    await tap(tester, WouldPayKeys.coursePrice('30to59'));
    expect(enabled(tester, WouldPayKeys.next), isTrue);
    await tap(tester, WouldPayKeys.next);

    expect(find.text('2 de 3'), findsOneWidget);
    await tap(tester, WouldPayKeys.coachAnswer('no'));
    await tap(tester, WouldPayKeys.coachPrice('none'));
    await tap(tester, WouldPayKeys.next);

    expect(find.text('3 de 3'), findsOneWidget);
    expect(enabled(tester, WouldPayKeys.send), isFalse);
    await tap(tester, WouldPayKeys.learnAnswer('some'));
    await tap(tester, WouldPayKeys.whyChip('rating'));
    await tap(tester, WouldPayKeys.levelChip('beginner'));
    await tap(tester, WouldPayKeys.send);

    expect(find.byKey(WouldPayKeys.thanks), findsOneWidget);
    expect(feedback.sent.single.answers?.why, {'rating'});
    expect(feedback.sent.single.answers?.level, 'beginner');
    expect(wouldPay.isAnswered, isTrue);
  });

  testWidgets('o voltar do passo 2 volta ao 1 com as respostas', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tap(tester, WouldPayKeys.courseAnswer('maybe'));
    await tap(tester, WouldPayKeys.coursePrice('none'));
    await tap(tester, WouldPayKeys.next);
    await tap(tester, WouldPayKeys.back);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(enabled(tester, WouldPayKeys.next), isTrue);
  });

  group('o convite', () {
    Future<void> pumpCard(WidgetTester tester, {int lessons = 2}) async {
      phone(tester);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          wouldPayRepository: wouldPay,
          schoolProgressRepository: FakeSchoolProgressRepository(
            SchoolProgress(completed: {for (var i = 0; i < lessons; i++) '$i'}),
          ),
          child: const Scaffold(body: WouldPayInviteCard()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('não aparece antes da 2ª aula', (tester) async {
      await pumpCard(tester, lessons: 1);
      expect(find.byKey(WouldPayKeys.invite), findsNothing);
    });

    testWidgets('"Agora não" some e grava', (tester) async {
      await pumpCard(tester);
      expect(find.byKey(WouldPayKeys.invite), findsOneWidget);
      await tap(tester, WouldPayKeys.inviteNo);
      expect(find.byKey(WouldPayKeys.invite), findsNothing);
      expect(wouldPay.isDismissed, isTrue);
    });
  });
}
