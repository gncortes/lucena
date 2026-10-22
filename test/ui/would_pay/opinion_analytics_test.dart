import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/would_pay.dart';
import 'package:lucena/ui/feedback/view_models/feedback_cubit.dart';
import 'package:lucena/ui/review/view_models/review_prompt_cubit.dart';
import 'package:lucena/ui/would_pay/view_models/would_pay_cubit.dart';

import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

/// Os eventos da E1.03 no "Você pagaria?", no feedback e no pedido de
/// avaliação (E1.26).
void main() {
  late FakeAnalyticsRepository analytics;
  late FakeFeedbackRepository feedback;
  late FakeReviewRepository review;

  setUp(() {
    analytics = FakeAnalyticsRepository();
    feedback = FakeFeedbackRepository();
    review = FakeReviewRepository(ask: true);
  });

  group('"Você pagaria?"', () {
    WouldPayCubit cubit() {
      final cubit = WouldPayCubit(
        wouldPay: FakeWouldPayRepository(),
        feedback: feedback,
        profile: FakeProfileRepository(),
        characters: FakeCharacterRepository(),
        review: review,
        analytics: analytics,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('abrir, passar e enviar, sem o texto', () async {
      final pay = cubit();
      await pay.load();
      await pay.load();
      await pay.pickCourse(WouldPayAnswer.maybe);
      await pay.pickCoursePrice(CoursePrice.from30To59);
      await pay.next();
      await pay.pickCoach(WouldPayAnswer.no);
      await pay.pickCoachPrice(MonthPrice.none);
      await pay.next();
      await pay.pickLearn(LearnAnswer.yes);
      await pay.setNext('Finais de torre');
      await pay.send();
      pay.leave();

      expect(analytics.names, [
        'questionario_aberto',
        'questionario_passo',
        'questionario_passo',
        'questionario_enviado',
      ]);
      expect(analytics.events.first.params, {
        'tipo': 'pagaria',
        'origem': 'cartao_aulas',
      });
      final steps = analytics.eventsNamed('questionario_passo');
      expect([for (final step in steps) step.params['passo']], [2, 3]);
      expect(steps.first.params['passos_total'], 3);
      final sent = analytics.eventsNamed('questionario_enviado').single.params;
      expect(sent['interesse'], 'talvez');
      expect(sent['curso_faixa'], CoursePrice.from30To59.code);
      expect(sent['mensal_faixa'], MonthPrice.none.code);
      expect(sent['tem_texto'], 'sim');
      expect(sent.values, isNot(contains('Finais de torre')));
    });

    test('fechar antes de enviar conta como dispensado', () async {
      final pay = cubit();
      await pay.load();
      pay.leave();
      expect(analytics.eventsNamed('questionario_dispensado').single.params, {
        'tipo': 'pagaria',
        'passo': 1,
        'como': 'fechou',
      });
    });

    test('"Agora não" no convite', () async {
      final invite = WouldPayInviteCubit(
        wouldPay: FakeWouldPayRepository(),
        school: FakeSchoolProgressRepository(),
        endgames: FakeEndgameProgressRepository(),
        analytics: analytics,
      );
      addTearDown(invite.close);
      await invite.dismiss();
      expect(analytics.eventsNamed('questionario_dispensado').single.params, {
        'tipo': 'pagaria',
        'passo': 0,
        'como': 'agora_nao',
      });
    });
  });

  test('feedback enviado leva o assunto e a faixa, nunca o texto', () async {
    final cubit = FeedbackCubit(
      feedback: feedback,
      characters: FakeCharacterRepository(),
      analytics: analytics,
    );
    addTearDown(cubit.close);
    cubit
      ..pickType(FeedbackType.idea)
      ..setText('Mais finais de torre');
    await cubit.send();
    expect(analytics.eventsNamed('feedback_enviado').single.params, {
      'tipo': FeedbackType.idea.code,
      'tamanho_faixa': 'ate_50',
    });
  });

  group('avaliação', () {
    const delay = Duration(milliseconds: 20);

    ReviewPromptCubit cubit({String trigger = 'aula'}) {
      final cubit = ReviewPromptCubit(
        review: review,
        school: FakeSchoolProgressRepository(
          const SchoolProgress(completed: {'a', 'b', 'c'}),
        ),
        endgames: FakeEndgameProgressRepository(),
        progress: FakeProgressRepository(),
        trigger: trigger,
        analytics: analytics,
        delay: delay,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('o pedido feito conta com o número e o gatilho', () async {
      cubit().ask();
      await Future<void>.delayed(delay * 3);
      cubit(trigger: 'final').ask();
      await Future<void>.delayed(delay * 3);
      final asked = analytics.eventsNamed('avaliacao_pedida');
      expect(
        [for (final event in asked) event.params],
        [
          {'numero': 1, 'gatilho': 'aula'},
          {'numero': 2, 'gatilho': 'final'},
        ],
      );
    });

    test('a política não deixou: nada sai', () async {
      review.ask = false;
      cubit().ask();
      await Future<void>.delayed(delay * 3);
      expect(analytics.eventsNamed('avaliacao_pedida'), isEmpty);
    });
  });
}
