import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/goal/view_models/goal_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;
  late FakeHomeLayoutRepository home;

  setUp(() {
    onboarding = FakeOnboardingRepository(const Onboarding(inProgress: true));
    profile = FakeProfileRepository(const UserProfile(nickname: 'Ana'));
    home = FakeHomeLayoutRepository();
  });

  Future<GoalCubit> loaded({bool fromLink = false}) async {
    final cubit = GoalCubit(
      fromLink: fromLink,
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      home: home,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('abre com "Aprender finais" marcado e o Viktor', () async {
    final cubit = await loaded();

    expect(cubit.state.ready, isTrue);
    expect(cubit.state.goal, GoalPreference.train);
    expect(cubit.state.viktor?.id, 'master');
  });

  test('o app fechado na pergunta volta nela', () async {
    await loaded();

    expect(onboarding.saved.stage, OnboardingStage.goal);
    expect(onboarding.saved.done, isFalse);
  });

  test('reaberta, marca o objetivo já gravado', () async {
    profile.profile = const UserProfile(goal: GoalPreference.train);
    final cubit = await loaded();

    expect(cubit.state.goal, GoalPreference.train);
  });

  test('treinar finais grava o objetivo e segue para o tour', () async {
    final cubit = await loaded();
    cubit.select(GoalPreference.train);
    await cubit.finish();

    expect(cubit.state.exit, GoalExit.tour);
    expect(profile.profile.goal, GoalPreference.train);
    expect(profile.profile.nickname, 'Ana');
    // O tour começa no primeiro passo; a primeira abertura não acabou.
    expect(onboarding.saved.stage, OnboardingStage.tour);
    expect(onboarding.saved.step, 0);
    expect(onboarding.saved.done, isFalse);
    expect(home.layout, isNull);
  });

  test('aprender a jogar segue para o tour já como iniciante', () async {
    final cubit = await loaded();
    cubit.select(GoalPreference.learn);
    await cubit.finish();

    expect(cubit.state.exit, GoalExit.tour);
    expect(profile.profile.goal, GoalPreference.learn);
    expect(profile.profile.level, RatingLevel.beginner);
    // O nível sai do tour: a faixa já vai gravada, mas só o fim do tour
    // conclui a primeira abertura.
    expect(onboarding.saved.done, isFalse);
    expect(onboarding.saved.startRung, '1000');
    expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
    // A sugestão de iniciante, sem ajuste da pessoa.
    expect(home.layout?.custom, isFalse);
    expect(home.layout?.shown.first, isNot(HomePath.race));
    expect(home.seen, isTrue);
  });

  test(
    'erro ao gravar: tela de erro e Tentar novamente reabre a pergunta',
    () async {
      final cubit = await loaded();
      profile.failNextSave = true;
      await cubit.finish();

      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.exit, isNull);
      await cubit.load();
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.failure, isNull);
    },
  );

  test('depois de gravar, não troca mais', () async {
    final cubit = await loaded();
    await cubit.finish();
    cubit.select(GoalPreference.learn);

    expect(cubit.state.goal, GoalPreference.train);
  });

  test('vindo de um link: "Aprender a jogar" não vale', () async {
    profile = FakeProfileRepository(
      const UserProfile(nickname: 'Ana', goal: GoalPreference.learn),
    );
    final cubit = await loaded(fromLink: true);

    expect(cubit.state.goal, GoalPreference.train);
    cubit.select(GoalPreference.learn);
    expect(cubit.state.goal, GoalPreference.train);
    cubit.select(GoalPreference.train);
    await cubit.finish();
    expect(cubit.state.exit, GoalExit.tour);
    expect((await profile.load()).goal, GoalPreference.train);
  });
}
