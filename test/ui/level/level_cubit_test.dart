import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;
  late FakeHomeLayoutRepository home;

  LevelCubit cubit() {
    final cubit = LevelCubit(
      home: home,
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      lessons: FakeLessonRepository(
        texts: LessonTexts.fromJson({'tour.level': 'Choose your level.'}),
      ),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    onboarding = FakeOnboardingRepository(
      const Onboarding(inProgress: true, step: 4),
    );
    profile = FakeProfileRepository();
    home = FakeHomeLayoutRepository();
  });

  test('abre com "Fazer o teste" marcado, ainda sem teste feito', () async {
    final level = cubit();
    await level.load('en');
    expect(level.state.viktor!.name, 'Viktor');
    expect(level.state.texts.say('tour.level'), 'Choose your level.');
    expect(level.state.levelChosen, isFalse);
    expect(level.state.choice, LevelChoice.test);
    expect(level.state.testPending, isTrue);
    expect(level.state.placed, isNull);
    await level.setLevel(RatingLevel.beginner);
    expect(level.state.choice, LevelChoice.beginner);
    await level.finish();
    expect(level.state.finished, isTrue);
    expect(level.state.toSchool, isTrue);
    expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.inProgress, isFalse);
    expect(onboarding.saved.step, 0);
  });

  test(
    'o cartão marcado: começando de início, depois faixa ou teste',
    () async {
      final level = cubit();
      await level.load('en');
      await level.setLevel(RatingLevel.beginner);
      expect(level.state.choice, LevelChoice.beginner);
      await level.setLevel(RatingLevel.expert);
      expect(level.state.choice, LevelChoice.band);
      profile.profile = profile.profile.copyWith(rating: 1530);
      await level.usePlacement();
      expect(level.state.choice, LevelChoice.test);
      await level.setLevel(RatingLevel.advanced);
      expect(level.state.choice, LevelChoice.band);
    },
  );

  test('o teste usado marca o cartão e grava o degrau', () async {
    final level = cubit();
    await level.load('en');
    profile.profile = profile.profile.copyWith(rating: 1530);
    await level.usePlacement();
    expect(level.state.level, RatingLevel.intermediate);
    expect(level.state.placed, 1530);
    expect(level.state.startRung, '1600');
    await level.finish();
    expect(profile.profile.rating, 1530);
    expect(onboarding.saved.startRung, '1600');
  });

  test('começando leva às aulas; as outras faixas, à tela inicial', () async {
    final level = cubit();
    await level.load('en');
    await level.setLevel(RatingLevel.beginner);
    expect(level.state.toSchool, isTrue);
    expect(level.state.startRung, '1000');
    await level.setLevel(RatingLevel.intermediate);
    expect(level.state.toSchool, isFalse);
    await level.finish();
    expect(level.state.finished, isTrue);
    expect(level.state.toSchool, isFalse);
    expect(onboarding.saved.startRung, '1400');
    expect((await profile.load()).level, RatingLevel.intermediate);
    expect(home.layout, HomeSuggestion.of(RatingLevel.intermediate));
    expect(home.seen, isTrue);
  });

  test('a faixa escolhida sobrevive ao fechar o app', () async {
    final level = cubit();
    await level.load('en');
    await level.setLevel(RatingLevel.expert);
    final again = cubit();
    await again.load('en');
    expect(again.state.levelChosen, isTrue);
    expect(again.state.choice, LevelChoice.band);
    expect(again.state.rating, RatingLevel.expert.rating);
    await again.finish();
    expect(profile.profile.rating, RatingLevel.expert.rating);
  });

  test('o teste usado sobrevive à retomada', () async {
    final level = cubit();
    await level.load('en');
    profile.profile = profile.profile.copyWith(rating: 1530);
    await level.usePlacement();
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.placed, 1530);
    expect(reopened.state.choice, LevelChoice.test);
  });

  test(
    'gravações lentas respeitam a última seleção antes de concluir',
    () async {
      final delayed = _DelayedOnboarding();
      onboarding = delayed;
      final level = cubit();
      await level.load('en');
      delayed.gate = Completer<void>();
      final first = level.setLevel(RatingLevel.intermediate);
      final last = level.setLevel(RatingLevel.expert);
      final finish = level.finish();
      expect(level.state.finished, isFalse);
      delayed.gate!.complete();
      await Future.wait([first, last, finish]);
      expect(delayed.saved.selectedRating, RatingLevel.expert.rating);
      expect(delayed.saved.done, isTrue);
      expect(profile.profile.rating, RatingLevel.expert.rating);
    },
  );

  test(
    'resultado tardio do teste não sobrescreve a faixa escolhida depois',
    () async {
      final delayed = _DelayedProfile();
      profile = delayed;
      final level = cubit();
      await level.load('en');
      delayed.gate = Completer<UserProfile>();
      final placement = level.usePlacement();
      await level.setLevel(RatingLevel.expert);
      delayed.gate!.complete(const UserProfile(rating: 1530));
      await placement;
      expect(level.state.choice, LevelChoice.band);
      expect(level.state.rating, RatingLevel.expert.rating);
      expect(onboarding.saved.selectedRating, RatingLevel.expert.rating);
    },
  );

  test('o apelido do tour continua depois do nível', () async {
    profile.profile = profile.profile.copyWith(nickname: 'Ana');
    final level = cubit();
    await level.load('en');
    await level.setLevel(RatingLevel.intermediate);
    await level.finish();
    final saved = await profile.load();
    expect(saved.nickname, 'Ana');
    expect(saved.level, RatingLevel.intermediate);
  });
}

class _DelayedOnboarding extends FakeOnboardingRepository {
  _DelayedOnboarding() : super(const Onboarding());
  Completer<void>? gate;

  @override
  Future<void> save(Onboarding value) async {
    await gate?.future;
    await super.save(value);
  }
}

class _DelayedProfile extends FakeProfileRepository {
  Completer<UserProfile>? gate;

  @override
  Future<UserProfile> load() => gate?.future ?? super.load();
}
