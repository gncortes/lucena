import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;
  late FakeHomeLayoutRepository home;

  TourCubit cubit() {
    final cubit = TourCubit(
      home: home,
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      lessons: FakeLessonRepository(
        texts: LessonTexts.fromJson({
          'tour.goal': 'Welcome, my student.',
          'tour.level': 'Choose your level.',
          'tour.level.beginner': 'Then we start from the beginning.',
          'tour.goals': 'What do you want to do here?',
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

  // Vai até o passo do nível (o penúltimo).
  Future<void> toLevel(TourCubit tour) async {
    while (tour.state.step != TourStep.level) {
      await tour.next();
    }
  }

  test('cada passo é gravado e volta ao reabrir', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.next();
    await tour.next();

    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.step, TourStep.board);
  });

  test('o nome do primeiro passo vai para o perfil na hora, já limpo, e '
      'continua ao reabrir e ao terminar', () async {
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.nickname, '');

    await tour.setNickname('  Ana   Clara ');
    expect(tour.state.nickname, 'Ana Clara');
    expect((await profile.load()).nickname, 'Ana Clara');

    // Fechou o app no meio: o tour reabre com o nome.
    final reopened = cubit();
    await reopened.load('en');
    expect(reopened.state.nickname, 'Ana Clara');

    // Terminar grava a faixa sem perder o nome; pular também não o apaga.
    reopened.setLevel(RatingLevel.intermediate);
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
    await tour.skip();

    expect((await profile.load()).nickname, '');
  });

  test('escolher 1400 no fim: perfil e degrau de início', () async {
    final tour = cubit();
    await tour.load('en');
    await toLevel(tour);
    tour.setLevel(RatingLevel.intermediate);
    expect(tour.state.startRung, '1400');
    await tour.next();
    expect(tour.state.step, TourStep.goals);
    expect(tour.state.step.isLast, isTrue);
    await tour.finish();

    expect(tour.state.finished, isTrue);
    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.startRung, '1400');
    expect((await profile.load()).level, RatingLevel.intermediate);
  });

  test('pular: o tour não aparece de novo e o degrau não muda', () async {
    final tour = cubit();
    await tour.load('en');
    await tour.skip();

    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.startRung, isNull);
  });

  test('rever o tour já visto começa do primeiro passo', () async {
    onboarding.saved = const Onboarding(done: true, step: 5);
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.step, TourStep.goal);
  });

  test('iniciante começa no Maia 1000', () async {
    final tour = cubit();
    await tour.load('en');
    tour.setLevel(RatingLevel.beginner);
    expect(tour.state.startRung, '1000');
  });

  test('o Viktor conduz: fala de cada passo e sentido da troca', () async {
    final tour = cubit();
    await tour.load('en');
    expect(tour.state.viktor!.name, 'Viktor');
    expect(tour.state.speech, 'Welcome, my student.');
    await tour.next();
    expect(tour.state.forward, isTrue);
    await tour.back();
    expect(tour.state.forward, isFalse);
  });

  test('iniciante: o Viktor convida e o tour termina nas aulas', () async {
    final tour = cubit();
    await tour.load('en');
    await toLevel(tour);
    tour.setLevel(RatingLevel.intermediate);
    expect(tour.state.toSchool, isFalse);
    expect(tour.state.speech, 'Choose your level.');
    tour.setLevel(RatingLevel.beginner);
    expect(tour.state.toSchool, isTrue);
    expect(tour.state.speech, 'Then we start from the beginning.');
    await tour.next();
    expect(tour.state.speech, 'What do you want to do here?');
    await tour.finish();
    expect(tour.state.finished, isTrue);
    expect(onboarding.saved.startRung, '1000');
    expect((await profile.load()).level, RatingLevel.beginner);
  });

  group('o que o jogador quer fazer', () {
    test('os caminhos vêm na ordem e com as marcas da sugestão do nível; '
        'trocar o nível troca a sugestão', () async {
      final tour = cubit();
      await tour.load('en');
      tour.setLevel(RatingLevel.master);
      expect(tour.state.paths.first, HomePath.speedrun);
      expect(tour.state.goals, {
        HomePath.speedrun,
        HomePath.endgames,
        HomePath.train,
      });
      tour.setLevel(RatingLevel.beginner);
      expect(tour.state.goals, {HomePath.learn, HomePath.journey});
    });

    test('o último marcado não sai', () async {
      final tour = cubit();
      await tour.load('en');
      tour.setLevel(RatingLevel.beginner);
      tour.toggleGoal(HomePath.learn);
      tour.toggleGoal(HomePath.journey);
      expect(tour.state.goals, {HomePath.journey});
    });

    test('ao terminar, a tela inicial fica com os marcados, na ordem do '
        'nível', () async {
      final tour = cubit();
      await tour.load('en');
      await toLevel(tour);
      tour.setLevel(RatingLevel.casual);
      await tour.next();
      tour.toggleGoal(HomePath.speedrun);
      await tour.finish();

      final layout = home.layout!;
      expect(layout.shown, [
        HomePath.journey,
        HomePath.endgames,
        HomePath.train,
        HomePath.speedrun,
      ]);
      expect(layout.custom, isTrue);
      // Quem acabou de fazer o tour não precisa do aviso.
      expect(home.seen, isTrue);
    });

    test('iniciante que desmarca as aulas não vai para elas', () async {
      final tour = cubit();
      await tour.load('en');
      tour.setLevel(RatingLevel.beginner);
      tour.toggleGoal(HomePath.learn);
      expect(tour.state.toSchool, isFalse);
    });

    test('pular grava a sugestão do nível, que segue o nível', () async {
      final tour = cubit();
      await tour.load('en');
      await tour.skip();
      expect(home.layout, HomeSuggestion.of(RatingLevel.casual));
      expect(home.layout!.custom, isFalse);
      expect(home.seen, isTrue);
    });
  });
}
