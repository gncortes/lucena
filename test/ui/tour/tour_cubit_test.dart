import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_voice_repository.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;
  late FakeHomeLayoutRepository home;

  TourCubit cubit({bool voices = true}) {
    final cubit = TourCubit(
      home: home,
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      voice: voices ? FakeVoiceRepository() : null,
      lessons: FakeLessonRepository(
        texts: LessonTexts.fromJson({
          'tour.board': 'Welcome, my student.',
          'tour.voice': 'Pick my voice.',
          'tour.voice.none': 'Tell me your name.',
          'tour.level': 'Choose your level.',
        }),
      ),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    onboarding = FakeOnboardingRepository(const Onboarding());
    profile = FakeProfileRepository();
    home = FakeHomeLayoutRepository();
  });

  Future<void> toLevel(TourCubit tour) async {
    while (tour.state.step != TourStep.level) {
      await tour.next();
    }
  }

  test('são seis passos, na ordem, e nenhum some', () async {
    expect(TourStep.values, [
      TourStep.board,
      TourStep.voice,
      TourStep.school,
      TourStep.help,
      TourStep.play,
      TourStep.level,
    ]);
    final tour = cubit(voices: false);
    await tour.load('en');
    final seen = [tour.state.step];
    while (tour.state.step != TourStep.level) {
      await tour.next();
      seen.add(tour.state.step);
    }
    expect(seen, TourStep.values);
    expect(TourStep.level.isLast, isTrue);
  });

  test('Voltar não existe no primeiro passo e volta nos outros', () async {
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.hasPrevious, isFalse);
    await tour.back();
    expect(tour.state.step, TourStep.board);
    await tour.next();
    expect(tour.state.hasPrevious, isTrue);
    expect(tour.state.forward, isTrue);
    await tour.back();
    expect(tour.state.step, TourStep.board);
    expect(tour.state.forward, isFalse);
  });

  test('Pular sem nível leva ao último passo; não é escolha', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.skip();
    expect(tour.state.step, TourStep.level);
    await tour.skip();
    expect(tour.state.step, TourStep.level);
    expect(tour.state.levelChosen, isFalse);
    expect(onboarding.saved.selectedRating, isNull);
    expect(onboarding.saved.done, isFalse);
    expect(profile.saved, isEmpty);
    expect(home.layout, isNull);
  });

  test('Pular com nível termina e grava o degrau', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.skip();
    await tour.setLevel(RatingLevel.intermediate);
    await tour.skip();
    expect(tour.state.finished, isTrue);
    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.startRung, '1400');
    expect(home.layout, HomeSuggestion.of(RatingLevel.intermediate));
    expect(home.seen, isTrue);
  });

  test(
    'abre com começando marcado; Começar grava beginner e vai às aulas',
    () async {
      final tour = cubit();
      await tour.load('en');
      await toLevel(tour);
      expect(tour.state.levelChosen, isFalse);
      expect(tour.state.choice, TourLevelChoice.beginner);
      await tour.finish();
      expect(tour.state.finished, isTrue);
      expect(tour.state.toSchool, isTrue);
      expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
      expect(onboarding.saved.done, isTrue);
    },
  );

  test(
    'o cartão marcado: começando de início, depois faixa ou teste',
    () async {
      final tour = cubit();
      await tour.load('en');
      expect(tour.state.choice, TourLevelChoice.beginner);
      await tour.setLevel(RatingLevel.beginner);
      expect(tour.state.choice, TourLevelChoice.beginner);
      await tour.setLevel(RatingLevel.expert);
      expect(tour.state.choice, TourLevelChoice.band);
      profile.profile = profile.profile.copyWith(rating: 1530);
      await tour.usePlacement();
      expect(tour.state.choice, TourLevelChoice.test);
      await tour.setLevel(RatingLevel.advanced);
      expect(tour.state.choice, TourLevelChoice.band);
    },
  );

  test('o teste usado marca o cartão e não avança o passo', () async {
    final tour = cubit();
    await tour.load('en');
    await toLevel(tour);
    profile.profile = profile.profile.copyWith(rating: 1530);
    await tour.usePlacement();
    expect(tour.state.step, TourStep.level);
    expect(tour.state.level, RatingLevel.intermediate);
    expect(tour.state.placed, 1530);
    expect(tour.state.startRung, '1600');
    await tour.finish();
    expect(profile.profile.rating, 1530);
    expect(onboarding.saved.startRung, '1600');
  });

  test('começando leva às aulas; as outras faixas, à tela inicial', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.setLevel(RatingLevel.beginner);
    expect(tour.state.toSchool, isTrue);
    expect(tour.state.startRung, '1000');
    await tour.setLevel(RatingLevel.intermediate);
    expect(tour.state.toSchool, isFalse);
    await tour.setLevel(RatingLevel.beginner);
    await tour.finish();
    expect(tour.state.finished, isTrue);
    expect(tour.state.toSchool, isTrue);
    expect(onboarding.saved.startRung, '1000');
    expect((await profile.load()).level, RatingLevel.beginner);
    expect(home.layout, HomeSuggestion.of(RatingLevel.beginner));
    expect(home.seen, isTrue);
  });

  test('a fala é a do passo; sem voz no idioma, a do nome', () async {
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.viktor!.name, 'Viktor');
    expect(tour.state.speech, 'Welcome, my student.');
    await tour.next();
    expect(tour.state.speech, 'Pick my voice.');
    onboarding.saved = const Onboarding();
    final mute = cubit(voices: false);
    await mute.load('en');
    expect(mute.state.hasVoices, isFalse);
    await mute.next();
    expect(mute.state.speech, 'Tell me your name.');
    await mute.next();
    expect(mute.state.speech, isNull);
  });

  test(
    'cada passo é gravado e volta ao reabrir, com a faixa marcada',
    () async {
      final tour = cubit();
      await tour.load('en');
      await tour.next();
      await tour.next();
      final reopened = cubit();
      await reopened.load('en');
      expect(reopened.state.step, TourStep.school);

      await toLevel(reopened);
      await reopened.setLevel(RatingLevel.expert);
      final again = cubit();
      await again.load('en');
      expect(again.state.step, TourStep.level);
      expect(again.state.levelChosen, isTrue);
      expect(again.state.choice, TourLevelChoice.band);
      expect(again.state.rating, RatingLevel.expert.rating);
      await again.finish();
      expect(profile.profile.rating, RatingLevel.expert.rating);
    },
  );

  test('o teste usado sobrevive à retomada', () async {
    final tour = cubit();
    await tour.load('en');
    await toLevel(tour);
    profile.profile = profile.profile.copyWith(rating: 1530);
    await tour.usePlacement();
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.step, TourStep.level);
    expect(reopened.state.placed, 1530);
    expect(reopened.state.choice, TourLevelChoice.test);
  });

  test('replay exige nova escolha e não apaga o done legado', () async {
    onboarding.saved = const Onboarding(done: true, selectedRating: 1530);
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.levelChosen, isFalse);
    expect(tour.state.step, TourStep.board);
    expect(onboarding.saved.done, isTrue);
    await tour.skip();
    await tour.setLevel(RatingLevel.advanced);
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.step, TourStep.level);
    expect(reopened.state.rating, RatingLevel.advanced.rating);
    expect(onboarding.saved.done, isTrue);
  });

  test('rever o tour já visto começa do primeiro passo', () async {
    onboarding.saved = const Onboarding(done: true, step: 4);
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.step, TourStep.board);
  });

  test(
    'gravações lentas respeitam a última seleção antes de concluir',
    () async {
      final delayed = _DelayedOnboarding();
      onboarding = delayed;
      final tour = cubit();
      await tour.load('en');
      await toLevel(tour);
      delayed.gate = Completer<void>();
      final first = tour.setLevel(RatingLevel.intermediate);
      final last = tour.setLevel(RatingLevel.expert);
      final finish = tour.finish();
      expect(tour.state.finished, isFalse);
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
      final tour = cubit();
      await tour.load('en');
      await toLevel(tour);
      delayed.gate = Completer<UserProfile>();
      final placement = tour.usePlacement();
      await tour.setLevel(RatingLevel.expert);
      delayed.gate!.complete(const UserProfile(rating: 1530));
      await placement;
      expect(tour.state.step, TourStep.level);
      expect(tour.state.choice, TourLevelChoice.band);
      expect(tour.state.rating, RatingLevel.expert.rating);
      expect(onboarding.saved.selectedRating, RatingLevel.expert.rating);
    },
  );

  test('o nome vai para o perfil na hora, já limpo, e continua ao reabrir '
      'e ao terminar', () async {
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.nickname, '');
    await tour.setNickname('  Ana   Clara ');
    expect(tour.state.nickname, 'Ana Clara');
    expect((await profile.load()).nickname, 'Ana Clara');
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.nickname, 'Ana Clara');
    await reopened.setLevel(RatingLevel.intermediate);
    await reopened.finish();
    final saved = await profile.load();
    expect(saved.nickname, 'Ana Clara');
    expect(saved.level, RatingLevel.intermediate);
  });

  test('apagar o nome volta ao apelido padrão', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.setNickname('Ana');
    await tour.setNickname('');
    expect((await profile.load()).nickname, '');
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
