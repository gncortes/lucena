import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/review_state.dart';
import 'package:lucena/domain/use_cases/review_policy.dart';

void main() {
  final now = DateTime.utc(2026, 3, 10, 12);
  final opened = ReviewState(firstOpen: DateTime.utc(2026, 3, 7, 23));

  bool ask({
    ReviewState? state,
    ReviewSession session = const ReviewSession(),
    int lessons = 3,
    int wins = 0,
    bool available = true,
    DateTime? at,
  }) => ReviewPolicy.shouldAsk(
    now: at ?? now,
    state: state ?? opened,
    session: session,
    lessonsCompleted: lessons,
    endgamesWon: wins,
    available: available,
  );

  test('3ª aula ou 5º final ganho, o que vier primeiro', () {
    expect(ask(lessons: 2, wins: 4), isFalse);
    expect(ask(lessons: 3, wins: 0), isTrue);
    expect(ask(lessons: 0, wins: 5), isTrue);
  });

  test('pede só com 3 dias de uso, contados no calendário', () {
    expect(ask(state: const ReviewState()), isFalse);
    expect(
      ask(state: ReviewState(firstOpen: DateTime.utc(2026, 3, 8))),
      isFalse,
    );
    // Dia 7 às 23h até dia 10 ao meio-dia: 3 dias de calendário.
    expect(ask(), isTrue);
  });

  test('no máximo 3 pedidos, com 60 dias entre eles', () {
    final last = DateTime.utc(2026, 1, 20);
    final twice = ReviewState(
      firstOpen: DateTime.utc(2025, 1, 1),
      requests: 2,
      lastRequest: last,
    );
    expect(ask(state: twice), isFalse);
    expect(ask(state: twice, at: last.add(const Duration(days: 60))), isTrue);
    final thrice = ReviewState(
      firstOpen: DateTime.utc(2025, 1, 1),
      requests: 3,
      lastRequest: DateTime.utc(2025, 6, 1),
    );
    expect(ask(state: thrice), isFalse);
  });

  test('não pede na sessão do questionário nem logo depois de um revés', () {
    expect(ask(session: const ReviewSession(surveySeen: true)), isFalse);
    expect(
      ask(
        session: ReviewSession(
          lastSetback: now.subtract(const Duration(seconds: 30)),
        ),
      ),
      isFalse,
    );
    expect(
      ask(
        session: ReviewSession(
          lastSetback: now.subtract(ReviewPolicy.setbackWindow),
        ),
      ),
      isTrue,
    );
  });

  test('sem Play (F-Droid, isAvailable falso) nunca pede', () {
    expect(ask(available: false), isFalse);
  });
}
