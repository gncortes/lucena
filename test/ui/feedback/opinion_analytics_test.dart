import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/feedback/view_models/feedback_cubit.dart';
import 'package:lucena/ui/review/view_models/review_prompt_cubit.dart';

import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

/// Os eventos da E1.03 no feedback e no pedido de avaliação (E1.26).
void main() {
  late FakeAnalyticsRepository analytics;
  late FakeFeedbackRepository feedback;
  late FakeReviewRepository review;

  setUp(() {
    analytics = FakeAnalyticsRepository();
    feedback = FakeFeedbackRepository();
    review = FakeReviewRepository(ask: true);
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
