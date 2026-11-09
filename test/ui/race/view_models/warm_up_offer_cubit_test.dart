import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/race/view_models/warm_up_offer_cubit.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_race_repository.dart';

void main() {
  late FakeRaceRepository repository;

  setUp(() {
    repository = FakeRaceRepository(now: FakeNow(DateTime(2026, 11, 9)));
  });

  test('começa ligada antes de ler a preferência', () {
    expect(WarmUpOfferCubit(repository).state, isTrue);
  });

  blocTest<WarmUpOfferCubit, bool>(
    'load traz a preferência guardada',
    build: () => WarmUpOfferCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [false],
  );

  blocTest<WarmUpOfferCubit, bool>(
    'setOffers muda o estado e guarda no repositório',
    build: () => WarmUpOfferCubit(repository),
    setUp: () => repository.offers = true,
    act: (cubit) => cubit.setOffers(value: false),
    expect: () => [false],
    verify: (_) => expect(repository.offers, isFalse),
  );

  test('sem a oferta ligada, não há problemas a oferecer', () async {
    final cubit = WarmUpOfferCubit(repository);
    expect(await cubit.problemsToOffer(), isEmpty);
  });

  test('com a oferta ligada, oferece os problemas do aquecimento', () async {
    repository.offers = true;
    final cubit = WarmUpOfferCubit(repository);
    expect(await cubit.problemsToOffer(), isNotEmpty);
  });
}
