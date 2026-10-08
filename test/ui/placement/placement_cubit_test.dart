import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/placement/view_models/placement_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../tools/placement/synthetic.dart';

void main() {
  final skills = SkillMap.fromJson(syntheticSkillsJson());
  final bank = PlacementBank.fromJson(syntheticItemsJson());

  late FakePlacementRepository repository;
  late FakeProfileRepository profile;
  late FakeOnboardingRepository onboarding;

  PlacementCubit cubit() {
    final cubit = PlacementCubit(
      placement: repository,
      profile: profile,
      now: FakeNow(DateTime.utc(2026, 10, 8, 20)),
      onboarding: onboarding,
      seed: 7,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    repository = FakePlacementRepository(skills: skills, bank: bank);
    profile = FakeProfileRepository();
    onboarding = FakeOnboardingRepository(const Onboarding());
  });

  test('abre na abertura, sem teste começado', () async {
    final placement = cubit();
    await placement.load();
    expect(placement.state.view, PlacementView.intro);
    expect(placement.state.resuming, isFalse);
  });

  test('começar mostra a pergunta 1 e já grava o teste', () async {
    final placement = cubit();
    await placement.load();
    await placement.start();
    expect(placement.state.view, PlacementView.question);
    expect(placement.state.number, 1);
    expect(placement.state.item, isNotNull);
    expect(repository.saved, isNotNull);
  });

  test('cada resposta grava: fechar e abrir de novo continua na mesma '
      'pergunta', () async {
    final first = cubit();
    await first.load();
    await first.start();
    for (var i = 0; i < 3; i++) {
      await first.answer(PlacementOutcome.dontKnow);
    }
    expect(first.state.number, 4);
    final item = first.state.item!.id;

    final again = cubit();
    await again.load();
    expect(again.state.resuming, isTrue);
    expect(again.state.number, 4);
    await again.start();
    expect(again.state.number, 4);
    expect(again.state.item!.id, item);
  });

  test('recomeçar apaga o teste pela metade', () async {
    final first = cubit();
    await first.load();
    await first.start();
    await first.answer(PlacementOutcome.wrong);

    final again = cubit();
    await again.load();
    await again.restart();
    expect(again.state.view, PlacementView.question);
    expect(again.state.number, 1);
  });

  test('a pergunta de casas marca e desmarca; a nova pergunta vem limpa', () {
    final state = PlacementViewState(
      view: PlacementView.question,
      item: PlacementItem.fromJson({
        'id': 'sq',
        'node': 'rules.bishop',
        'type': 'squares',
        'difficulty': 500,
        'fen': '8/8/8/8/3B4/8/8/8 w - - 0 1',
        'prompt': 'placementSquares',
        'squares': ['c3'],
      }),
    );
    expect(state.copyWith(selected: {'c3'}).selected, {'c3'});
    expect(const PlacementViewState().selected, isEmpty);
  });

  test('20 respostas: o resultado é gravado, o teste pela metade some e '
      'a tela vai ao resultado', () async {
    final placement = cubit();
    await placement.load();
    await placement.start();
    for (var i = 0; i < PlacementState.questionCount; i++) {
      expect(placement.state.view, PlacementView.question);
      final item = placement.state.item!;
      // Acerta as fáceis, erra as difíceis.
      await placement.answer(
        item.difficulty < 1300
            ? PlacementOutcome.correct
            : PlacementOutcome.wrong,
      );
    }
    expect(placement.state.view, PlacementView.result);
    expect(placement.state.result, isNotNull);
    expect(repository.saveResultValue, placement.state.result);
    expect(repository.saved, isNull);
  });

  test('usar o nível leva o θ ao perfil e o degrau da Jornada', () async {
    final placement = cubit();
    await placement.load();
    await placement.start();
    for (var i = 0; i < PlacementState.questionCount; i++) {
      await placement.answer(PlacementOutcome.correct);
    }
    final result = placement.state.result!;
    await placement.apply();
    expect(profile.profile.rating, result.theta);
    expect(onboarding.saved.startRung, isNotNull);
    expect(placement.state.applied, isTrue);
  });

  test('intervalo entre duas faixas: a escolhida vale o rating dela', () async {
    final placement = cubit();
    await placement.load();
    await placement.start();
    for (var i = 0; i < PlacementState.questionCount; i++) {
      await placement.answer(PlacementOutcome.dontKnow);
    }
    final other = placement.state.result!.levels.firstWhere(
      (level) => level != placement.state.result!.level,
      orElse: () => placement.state.result!.level,
    );
    await placement.apply(level: other);
    expect(
      profile.profile.rating,
      other == placement.state.result!.level
          ? placement.state.result!.theta
          : other.rating,
    );
  });

  test('quem já tem faixa começa do meio dela', () async {
    profile = FakeProfileRepository(const UserProfile(rating: 2000));
    final placement = cubit();
    await placement.load();
    await placement.start();
    expect(placement.state.test!.initialTheta, greaterThan(1500));
  });
}
