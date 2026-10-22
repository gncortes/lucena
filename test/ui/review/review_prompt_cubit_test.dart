import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/review_policy.dart';
import 'package:lucena/ui/review/view_models/review_prompt_cubit.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  late FakeReviewRepository review;

  setUp(() => review = FakeReviewRepository(ask: true));

  // A espera de verdade é a da política; aqui, curta.
  const delay = Duration(milliseconds: 20);

  ReviewPromptCubit cubit() {
    final cubit = ReviewPromptCubit(
      review: review,
      school: FakeSchoolProgressRepository(
        const SchoolProgress(completed: {'a', 'b', 'c'}),
      ),
      endgames: FakeEndgameProgressRepository(),
      progress: FakeProgressRepository(),
      delay: delay,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('a espera padrão é 1,5 s', () {
    expect(ReviewPolicy.delay, const Duration(milliseconds: 1500));
  });

  test('pede depois da espera, com as aulas e vitórias contadas', () async {
    final prompt = cubit()..ask();
    expect(review.asks, isEmpty);
    await Future<void>.delayed(delay * 3);
    expect(review.asks.single, (3, 0));
    expect(prompt.state, isTrue);
  });

  test('sair da tela antes cancela; derrota marca o revés', () async {
    await (cubit()..ask()).close();
    cubit()
      ..ask()
      ..noteSetback();
    await Future<void>.delayed(delay * 3);
    expect(review.asks, isEmpty);
    expect(review.setbacks, 1);
  });
}
