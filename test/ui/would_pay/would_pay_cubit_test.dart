import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/would_pay.dart';
import 'package:lucena/ui/would_pay/view_models/would_pay_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  late FakeWouldPayRepository wouldPay;
  late FakeFeedbackRepository feedback;
  late FakeReviewRepository review;

  setUp(() {
    wouldPay = FakeWouldPayRepository();
    feedback = FakeFeedbackRepository();
    review = FakeReviewRepository();
  });

  WouldPayCubit cubit({UserProfile profile = const UserProfile()}) {
    final cubit = WouldPayCubit(
      wouldPay: wouldPay,
      feedback: feedback,
      profile: FakeProfileRepository(profile),
      characters: FakeCharacterRepository(),
      review: review,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> answerAll(WouldPayCubit cubit) async {
    await cubit.pickCourse(WouldPayAnswer.yes);
    await cubit.pickCoursePrice(CoursePrice.from60To99);
    await cubit.next();
    await cubit.pickCoach(WouldPayAnswer.maybe);
    await cubit.pickCoachPrice(MonthPrice.upTo9);
    await cubit.next();
    await cubit.pickLearn(LearnAnswer.yes);
  }

  test('abrir conta como questionário visto na sessão', () async {
    await cubit().load();
    expect(review.surveysSeen, 1);
  });

  test('cada passo só segue com as duas respostas', () async {
    final pay = cubit();
    await pay.load();
    expect(pay.state.canAdvance, isFalse);
    await pay.pickCourse(WouldPayAnswer.no);
    await pay.next();
    expect(pay.state.step, 0);
    await pay.pickCoursePrice(CoursePrice.none);
    await pay.next();
    expect(pay.state.step, 1);
    expect(pay.state.canAdvance, isFalse);
  });

  test('o rascunho guarda o passo e as respostas e volta onde parou', () async {
    final first = cubit();
    await first.load();
    await first.pickCourse(WouldPayAnswer.yes);
    await first.pickCoursePrice(CoursePrice.upTo29);
    await first.next();
    expect(wouldPay.draft?.step, 1);

    final again = cubit();
    await again.load();
    expect(again.state.step, 1);
    expect(again.state.answers.coursePrice, CoursePrice.upTo29);
  });

  test('a rota não pula passo obrigatório', () async {
    final pay = cubit();
    await pay.load(step: 3);
    expect(pay.state.step, 0);
  });

  test('enviar manda as respostas, marca respondido e agradece', () async {
    final pay = cubit();
    await pay.load();
    await answerAll(pay);
    await pay.toggleWhy('teach');
    await pay.toggleLevel('middle');
    await pay.send();
    final sent = feedback.sent.single;
    expect(sent.kind, 'pagaria');
    expect(sent.answers?.level, 'middle');
    expect(sent.answers?.why, {'teach'});
    expect(feedback.levels.single, isNull);
    expect(wouldPay.isAnswered, isTrue);
    expect(pay.state.sent, isTrue);
  });

  test('com nível no perfil o passo 3 não pergunta e vai o rating', () async {
    final pay = cubit(
      profile: const UserProfile(rating: 1700, levelSource: LevelSource.test),
    );
    await pay.load();
    expect(pay.state.levelDefined, isTrue);
    await answerAll(pay);
    await pay.send();
    expect(feedback.sent.single.answers?.level, isNull);
    expect(feedback.levels.single, '1700');
    expect(
      feedback.sent.single.toJson(level: feedback.levels.single)['level'],
      '1700',
    );
  });

  test('sem a "estrutura ensina?" não envia', () async {
    final pay = cubit();
    await pay.load();
    await pay.pickCourse(WouldPayAnswer.yes);
    await pay.pickCoursePrice(CoursePrice.upTo29);
    await pay.next();
    await pay.pickCoach(WouldPayAnswer.no);
    await pay.pickCoachPrice(MonthPrice.none);
    await pay.next();
    expect(pay.state.isLast, isTrue);
    await pay.send();
    expect(feedback.sent, isEmpty);
    expect(pay.state.sent, isFalse);
  });

  group('o convite', () {
    WouldPayInviteCubit invite({int lessons = 2}) {
      final cubit = WouldPayInviteCubit(
        wouldPay: wouldPay,
        school: FakeSchoolProgressRepository(
          SchoolProgress(completed: {for (var i = 0; i < lessons; i++) '$i'}),
        ),
        endgames: FakeEndgameProgressRepository(),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('aparece a partir da 2ª aula concluída', () async {
      final one = invite(lessons: 1);
      await one.load();
      expect(one.state, isFalse);
      final two = invite();
      await two.load();
      expect(two.state, isTrue);
    });

    test('"Agora não" esconde para sempre', () async {
      final card = invite();
      await card.load();
      await card.dismiss();
      expect(card.state, isFalse);
      final later = invite(lessons: 9);
      await later.load();
      expect(later.state, isFalse);
    });

    test('respondido não volta', () async {
      wouldPay.isAnswered = true;
      final card = invite();
      await card.load();
      expect(card.state, isFalse);
    });
  });
}
