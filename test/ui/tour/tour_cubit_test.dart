import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;

  TourCubit cubit({bool voices = true}) {
    final cubit = TourCubit(
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      voice: voices ? FakeVoiceRepository() : null,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    onboarding = FakeOnboardingRepository(const Onboarding());
    profile = FakeProfileRepository();
  });

  Future<List<TourStep>> walk(TourCubit tour) async {
    final seen = [tour.state.step];
    while (!tour.state.step.isLast) {
      await tour.next();
      seen.add(tour.state.step);
    }
    return seen;
  }

  test('são seis passos, na ordem, e a conta é o último', () async {
    expect(TourStep.values, [
      TourStep.board,
      TourStep.theme,
      TourStep.voice,
      TourStep.level,
      TourStep.region,
      TourStep.account,
    ]);
    final tour = cubit(voices: false);
    await tour.load('pt');
    expect(await walk(tour), TourStep.values);
    await tour.next();
    expect(tour.state.step, TourStep.account);
  });

  test('a barra enche 20, 30, 40, 60, 80 e 100%', () async {
    final tour = cubit();
    await tour.load('pt');
    final fractions = <double>[tour.state.progress];
    while (!tour.state.step.isLast) {
      await tour.next();
      fractions.add(tour.state.progress);
    }
    expect(fractions, [0.20, 0.30, 0.40, 0.60, 0.80, 1.0]);
  });

  test('com Aprender a jogar o nível some e a barra anda em quartos', () async {
    profile.profile = const UserProfile(goal: GoalPreference.learn);
    final tour = cubit();
    await tour.load('pt');
    expect(tour.state.steps, [
      TourStep.board,
      TourStep.theme,
      TourStep.voice,
      TourStep.region,
      TourStep.account,
    ]);
    final fractions = <double>[tour.state.progress];
    while (!tour.state.step.isLast) {
      await tour.next();
      fractions.add(tour.state.progress);
    }
    expect(fractions, [0.25, 0.25, 0.50, 0.75, 1.0]);
  });

  test('Voltar não existe no primeiro passo e volta nos outros', () async {
    final tour = cubit();
    await tour.load('pt');
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

  test('Pular pula só o passo atual, sem sair do tour', () async {
    final tour = cubit();
    await tour.load('pt');
    await tour.skip();
    expect(tour.state.step, TourStep.theme);
    await tour.skip();
    expect(tour.state.step, TourStep.voice);
    await tour.skip();
    expect(tour.state.step, TourStep.level);
    await tour.skip();
    expect(tour.state.step, TourStep.region);
    await tour.skip();
    expect(tour.state.step, TourStep.account);
    expect(tour.state.finished, isFalse);
    // Na Conta não há o que pular.
    await tour.skip();
    expect(tour.state.step, TourStep.account);
    expect(tour.state.finished, isFalse);
  });

  test('Pular a voz com Aprender vai à região', () async {
    profile.profile = const UserProfile(goal: GoalPreference.learn);
    onboarding.saved = Onboarding(step: TourStep.voice.index);
    final tour = cubit();
    await tour.load('pt');
    await tour.skip();
    expect(tour.state.step, TourStep.region);
  });

  test('o tour só termina ao sair da Conta e então conta como visto', () async {
    final tour = cubit();
    await tour.load('pt');
    await walk(tour);
    expect(tour.state.finished, isFalse);
    expect(onboarding.saved.done, isFalse);
    expect(onboarding.saved.inProgress, isTrue);
    await tour.finish();
    expect(tour.state.finished, isTrue);
    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.inProgress, isFalse);
  });

  test('fechado o app no meio, o tour volta no mesmo passo', () async {
    final tour = cubit();
    await tour.load('pt');
    await tour.next();
    await tour.next();
    await tour.next();
    await tour.next();
    final reopened = cubit();
    await reopened.load('pt');
    expect(reopened.state.step, TourStep.region);
    expect(onboarding.saved.done, isFalse);
  });

  test('vindo de um link, o tabuleiro some', () async {
    onboarding.saved = const Onboarding(linkSetupDone: true);
    final tour = cubit();
    await tour.load('pt');
    expect(tour.state.step, TourStep.theme);
    expect(tour.state.steps, [
      TourStep.theme,
      TourStep.voice,
      TourStep.level,
      TourStep.region,
      TourStep.account,
    ]);
    expect(tour.state.hasPrevious, isFalse);
    await tour.next();
    expect(tour.state.position, 1);
    await tour.back();
    expect(tour.state.step, TourStep.theme);
  });

  test('rever o tour já visto começa do primeiro passo', () async {
    onboarding.saved = const Onboarding(done: true, step: 4);
    final tour = cubit();
    await tour.load('pt');
    expect(tour.state.step, TourStep.board);
    expect(onboarding.saved.done, isTrue);
  });

  test('sem voz no idioma, o estado diz isso', () async {
    final tour = cubit(voices: false);
    await tour.load('pt');
    expect(tour.state.hasVoices, isFalse);
    expect(tour.state.viktor!.name, 'Viktor');
  });

  test('o nome vai para o perfil na hora, já limpo, e continua ao reabrir '
      'e ao terminar', () async {
    final tour = cubit();
    await tour.load('pt');
    expect(tour.state.nickname, '');
    await tour.setNickname('  Ana   Clara ');
    expect(tour.state.nickname, 'Ana Clara');
    expect((await profile.load()).nickname, 'Ana Clara');
    final reopened = cubit();
    await reopened.load('pt');
    expect(reopened.state.nickname, 'Ana Clara');
    await reopened.finish();
    expect((await profile.load()).nickname, 'Ana Clara');
  });

  test('apagar o nome volta ao apelido padrão', () async {
    final tour = cubit();
    await tour.load('pt');
    await tour.setNickname('Ana');
    await tour.setNickname('');
    expect((await profile.load()).nickname, '');
  });

  group('região', () {
    Future<TourCubit> atRegion({String? phone}) async {
      final tour = cubit();
      await tour.load('pt', phoneCountry: phone);
      while (tour.state.step != TourStep.region) {
        await tour.next();
      }
      return tour;
    }

    test('sem perfil, o país vem do celular e nada é gravado ainda', () async {
      final tour = await atRegion(phone: 'BR');
      expect(tour.state.country, 'BR');
      expect(tour.state.countryFromPhone, isTrue);
      expect(profile.profile.country, isNull);
    });

    test('trocar de país limpa estado e cidade', () async {
      final tour = await atRegion(phone: 'BR');
      tour.setRegionState('SP');
      tour.setRegionCity('Campinas');
      tour.setRegionState('RJ');
      expect(tour.state.regionCity, isNull);
      tour.setRegionCity('Niterói');
      tour.setRegionCountry('pt');
      expect(tour.state.country, 'PT');
      expect(tour.state.regionState, isNull);
      expect(tour.state.regionCity, isNull);
      expect(tour.state.countryFromPhone, isFalse);
    });

    test(
      'Continuar grava país, estado e cidade e segue para a conta',
      () async {
        final tour = await atRegion(phone: 'BR');
        tour.setRegionState('SP');
        tour.setRegionCity('Campinas');
        await tour.next();
        expect(profile.profile.country, 'BR');
        expect(profile.profile.state, 'SP');
        expect(profile.profile.city, 'Campinas');
        expect(tour.state.step, TourStep.account);
      },
    );

    test('Pular não grava a região', () async {
      final tour = await atRegion(phone: 'BR');
      tour.setRegionState('SP');
      await tour.skip();
      expect(profile.profile.state, isNull);
      expect(tour.state.step, TourStep.account);
    });

    test('finish(leave: false) grava o tour como visto sem sair', () async {
      final tour = await atRegion();
      await tour.next();
      await tour.finish(leave: false);
      expect(onboarding.saved.done, isTrue);
      expect(tour.state.finished, isFalse);
    });
  });
}
