import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/streak.dart';
import 'package:lucena/domain/use_cases/opening_overlay.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

/// H-INI-14: uma só coisa por cima do Início a cada abertura.
void main() {
  OpeningOverlay of({
    bool tour = false,
    bool offer = false,
    bool lost = false,
  }) => OpeningOverlay.of(
    tourPending: tour,
    offerPending: offer,
    streakLost: lost,
  );

  test('nada pendente: nada por cima', () {
    expect(of(), OpeningOverlay.none);
  });

  test('o tour vence a oferta e a sequência perdida', () {
    expect(of(tour: true, offer: true, lost: true), OpeningOverlay.tour);
    expect(of(tour: true, lost: true), OpeningOverlay.tour);
  });

  test('a oferta vence a sequência perdida', () {
    expect(of(offer: true, lost: true), OpeningOverlay.offer);
  });

  test('só a sequência perdida: o aviso sai', () {
    expect(of(lost: true), OpeningOverlay.lostStreak);
  });

  group('a vez da folha no estado do Início', () {
    const lost = Streak(current: 0, record: 5, activeToday: false, lost: 5);

    test('só ela pendente: é a vez da folha', () {
      expect(const HomeState(streak: lost).lostSheetTurn, isTrue);
    });

    test('com tour ou oferta pendente: não é', () {
      expect(
        const HomeState(streak: lost, tourPending: true).lostSheetTurn,
        isFalse,
      );
      expect(
        const HomeState(streak: lost, offerPending: true).lostSheetTurn,
        isFalse,
      );
    });

    test('sem sequência perdida: não é', () {
      expect(const HomeState().lostSheetTurn, isFalse);
    });

    test('copyWith mantém a oferta pendente', () {
      expect(
        const HomeState(offerPending: true).copyWith(streak: lost).offerPending,
        isTrue,
      );
    });
  });
}
