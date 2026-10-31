import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_voice_repository.dart';

class _UnavailableLessons extends FakeLessonRepository {
  @override
  Future<LessonTexts> texts(String language) async =>
      throw const LessonContentUnavailable();
}

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;

  TourCubit cubit({bool voices = true, bool unavailable = false}) {
    final cubit = TourCubit(
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      voice: voices ? FakeVoiceRepository() : null,
      lessons: unavailable
          ? _UnavailableLessons()
          : FakeLessonRepository(
              texts: LessonTexts.fromJson({
                'tour.board': 'Welcome, my student.',
                'tour.voice': 'Pick my voice.',
                'tour.voice.link': 'Nice game!',
                'tour.voice.link.none': 'Nice game! Tell me your name.',
                'tour.voice.none': 'Tell me your name.',
              }),
            ),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    onboarding = FakeOnboardingRepository(const Onboarding());
    profile = FakeProfileRepository();
  });

  Future<void> toLast(TourCubit tour) async {
    while (!tour.state.step.isLast) {
      await tour.next();
    }
  }

  test(
    'guest without a course package can finish and resume the tour',
    () async {
      final tour = cubit(voices: false, unavailable: true);
      await tour.load('pt');
      expect(tour.state.ready, isTrue);
      expect(tour.state.speech, isNull);
      expect(tour.state.steps, TourStep.values);
      await tour.next();
      final reopened = cubit(voices: false, unavailable: true);
      await reopened.load('pt');
      expect(reopened.state.step, TourStep.voice);
      await toLast(reopened);
      await reopened.finish();
      expect(reopened.state.finished, isTrue);
      expect(onboarding.saved.done, isFalse);
      expect(onboarding.saved.inProgress, isTrue);
    },
  );

  test('são cinco passos, na ordem, e o nível não é um deles', () async {
    expect(TourStep.values, [
      TourStep.board,
      TourStep.voice,
      TourStep.school,
      TourStep.help,
      TourStep.play,
    ]);
    final tour = cubit(voices: false);
    await tour.load('en');
    final seen = [tour.state.step];
    while (!tour.state.step.isLast) {
      await tour.next();
      seen.add(tour.state.step);
    }
    expect(seen, TourStep.values);
    expect(tour.state.steps.length, 5);
    await tour.next();
    expect(tour.state.step, TourStep.play);
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

  test('Pular e Começar saem do tour sem dar o tour por visto', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.skip();
    expect(tour.state.finished, isTrue);
    expect(onboarding.saved.done, isFalse);
    expect(onboarding.saved.inProgress, isTrue);
    // Fechado o app na conta ou no nível, o tour volta no último passo.
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.step, TourStep.play);
    expect(profile.saved, isEmpty);
  });

  test(
    'vindo de um link, o tabuleiro some e a conta dos passos muda',
    () async {
      onboarding.saved = const Onboarding(linkSetupDone: true);
      final tour = cubit();
      await tour.load('en');
      expect(tour.state.step, TourStep.voice);
      expect(tour.state.steps, [
        TourStep.voice,
        TourStep.school,
        TourStep.help,
        TourStep.play,
      ]);
      expect(tour.state.position, 0);
      expect(tour.state.hasPrevious, isFalse);
      expect(tour.state.speech, 'Nice game!');
      await tour.next();
      expect(tour.state.position, 1);
      await tour.back();
      expect(tour.state.step, TourStep.voice);
      await toLast(tour);
      expect(tour.state.position, 3);
    },
  );

  test('sem voz no idioma, vindo de um link, o Viktor se apresenta e pede o '
      'nome', () async {
    onboarding.saved = const Onboarding(linkSetupDone: true);
    final tour = cubit(voices: false);
    await tour.load('en');
    expect(tour.state.speech, 'Nice game! Tell me your name.');
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

  test('cada passo é gravado e volta ao reabrir', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.next();
    await tour.next();
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.step, TourStep.school);
  });

  test('rever o tour já visto começa do primeiro passo', () async {
    onboarding.saved = const Onboarding(done: true, step: 4);
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.step, TourStep.board);
    expect(onboarding.saved.done, isTrue);
  });

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
    await reopened.finish();
    expect((await profile.load()).nickname, 'Ana Clara');
  });

  test('apagar o nome volta ao apelido padrão', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.setNickname('Ana');
    await tour.setNickname('');
    expect((await profile.load()).nickname, '');
  });
}
