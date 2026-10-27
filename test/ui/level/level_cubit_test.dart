import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_chesscom_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';

final _readAt = DateTime(2026, 10, 22, 21, 40);

final _lichess = PlatformRating(
  user: 'gabriel_finais',
  readAt: _readAt,
  bullet: const ModeRating(rating: 1588, games: 312),
  blitz: const ModeRating(rating: 1712, games: 940),
  rapid: const ModeRating(rating: 1805, games: 121),
);

final _provisional = PlatformRating(
  user: 'gabi_novata',
  readAt: _readAt,
  blitz: const ModeRating(rating: 1500, games: 4, provisional: true),
);

final _chess = PlatformRating(
  user: 'gabriel_finais',
  readAt: _readAt,
  blitz: const ModeRating(rating: 1405, games: 512),
);

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;
  late FakeHomeLayoutRepository home;
  late FakeLichessRepository lichess;
  late FakeChessComRepository chessCom;

  LevelCubit cubit({bool fromProfile = false}) {
    final cubit = LevelCubit(
      home: home,
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      lichess: lichess,
      chessCom: chessCom,
      fromProfile: fromProfile,
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
    lichess = FakeLichessRepository(rating: _lichess);
    chessCom = FakeChessComRepository(users: {'gabriel_finais': _chess});
  });

  test('abre com "Fazer o teste" marcado, ainda sem teste feito', () async {
    final level = cubit();
    await level.load();
    expect(level.state.viktor!.name, 'Viktor');
    expect(level.state.choice, LevelChoice.test);
    expect(level.state.testPending, isTrue);
    expect(level.state.placed, isNull);
    expect(onboarding.saved.stage, OnboardingStage.level);
    // Sem o teste feito, "Continuar" não termina nada.
    await level.finish();
    expect(level.state.finished, isFalse);
  });

  test('"Já sei o meu rating" abre os caminhos e voltar fecha', () async {
    final level = cubit();
    await level.load();
    level.select(LevelChoice.known);
    expect(level.state.knowsRating, isFalse);
    level.openKnown();
    expect(level.state.knowsRating, isTrue);
    expect(level.state.choice, LevelChoice.lichess);
    level.closeKnown();
    expect(level.state.knowsRating, isFalse);
    expect(level.state.choice, LevelChoice.known);
    // Sem caminho escolhido, "Continuar" não termina nada.
    await level.finish();
    expect(level.state.finished, isFalse);
  });

  group('teste', () {
    test('o teste usado marca o cartão e grava o degrau abaixo', () async {
      final level = cubit();
      await level.load();
      profile.profile = profile.profile.copyWith(rating: 1530);
      await level.usePlacement();
      expect(level.state.choice, LevelChoice.test);
      expect(level.state.placed, 1530);
      expect(level.state.testPending, isFalse);
      await level.finish();
      expect(level.state.finished, isTrue);
      expect(profile.profile.rating, 1530);
      expect(profile.profile.levelSource, LevelSource.test);
      expect(onboarding.saved.startRung, '1400');
      expect(onboarding.saved.done, isTrue);
      expect(onboarding.saved.inProgress, isFalse);
      expect(onboarding.saved.step, 0);
      expect(onboarding.saved.byHand, isFalse);
    });

    test('o teste usado sobrevive à retomada', () async {
      final level = cubit();
      await level.load();
      profile.profile = profile.profile.copyWith(rating: 1530);
      await level.usePlacement();
      final reopened = cubit();
      await reopened.load();
      expect(reopened.state.placed, 1530);
      expect(reopened.state.choice, LevelChoice.test);
    });

    test(
      'resultado tardio do teste não muda nada depois de terminar',
      () async {
        final delayed = _DelayedProfile();
        profile = delayed;
        final level = cubit();
        await level.load();
        final gate = delayed.gate = Completer<UserProfile>();
        final placement = level.usePlacement();
        delayed.gate = null;
        level.select(LevelChoice.zero);
        await level.finish();
        gate.complete(const UserProfile(rating: 1530));
        await placement;
        expect(level.state.choice, LevelChoice.zero);
        expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
      },
    );
  });

  group('Lichess', () {
    test('conecta, mostra os ratings e usa o blitz', () async {
      final level = cubit();
      await level.load();
      level.select(LevelChoice.lichess);
      await level.connectLichess();
      expect(lichess.connects, 1);
      expect(level.state.lichess, _lichess);
      expect(level.state.lichessBusy, isFalse);
      expect(level.state.lichessRating, 1712);
      await level.useLichess();
      expect(level.state.finished, isTrue);
      expect(level.state.toSchool, isFalse);
      expect(profile.profile.rating, 1712);
      expect(profile.profile.levelSource, LevelSource.lichess);
      expect(profile.profile.lichessUser, 'gabriel_finais');
      expect(onboarding.saved.startRung, '1600');
      expect(onboarding.saved.byHand, isTrue);
      expect(home.layout, HomeSuggestion.of(RatingLevel.of(1712)));
    });

    test('cancelado na página do Lichess volta sem erro', () async {
      lichess.hold = true;
      final level = cubit();
      await level.load();
      final connecting = level.connectLichess();
      expect(level.state.lichessBusy, isTrue);
      level.cancelLichess();
      await connecting;
      expect(level.state.lichessBusy, isFalse);
      expect(level.state.lichess, isNull);
      expect(level.state.error, isNull);
      expect(level.state.choice, LevelChoice.lichess);
    });

    test('sem rede mostra o erro e não grava', () async {
      lichess.failure = LichessFailure.network;
      final level = cubit();
      await level.load();
      await level.connectLichess();
      expect(level.state.error, LevelError.lichessOffline);
      expect(level.state.errorCount, 1);
      await level.connectLichess();
      expect(level.state.errorCount, 2);
      expect(level.state.lichess, isNull);
      expect(onboarding.saved.done, isFalse);
    });

    test('rating provisório: usar mesmo assim grava o 1500', () async {
      lichess.rating = _provisional;
      final level = cubit();
      await level.load();
      await level.connectLichess();
      expect(level.state.lichess!.main!.provisional, isTrue);
      await level.useLichess();
      expect(profile.profile.rating, 1500);
      expect(profile.profile.levelSource, LevelSource.lichess);
    });

    test('a volta do Lichess com o app fechado reabre conectada', () async {
      lichess.pending = _lichess;
      final level = cubit();
      await level.load();
      expect(level.state.choice, LevelChoice.lichess);
      expect(level.state.lichess, _lichess);
    });
  });

  group('Chess.com', () {
    test('acha o usuário e converte o rating', () async {
      final level = cubit();
      await level.load();
      await level.lookUpChess(' Gabriel_Finais ');
      expect(level.state.chess, _chess);
      expect(level.state.chessNotFound, isFalse);
      expect(level.state.chessRating, 1650);
      await level.useChess();
      expect(profile.profile.rating, 1650);
      expect(profile.profile.levelSource, LevelSource.chesscom);
      expect(profile.profile.chessComUser, 'gabriel_finais');
      expect(onboarding.saved.startRung, '1600');
    });

    test('usuário não achado: erro no campo, sem salvar', () async {
      final level = cubit();
      await level.lookUpChess('ninguem');
      await level.load();
      await level.lookUpChess('ninguem');
      expect(level.state.chessNotFound, isTrue);
      expect(level.state.chess, isNull);
      expect(level.state.error, isNull);
      await level.useChess();
      expect(level.state.finished, isFalse);
      await level.lookUpChess('');
      expect(level.state.chessNotFound, isFalse);
    });

    test('sem rede mostra o erro', () async {
      chessCom.offline = true;
      final level = cubit();
      await level.load();
      await level.lookUpChess('gabriel_finais');
      expect(level.state.error, LevelError.chessOffline);
      expect(level.state.chessNotFound, isFalse);
    });

    test('a resposta de uma busca antiga não ganha da nova', () async {
      final slow = _SlowChessCom({'gabriel_finais': _chess});
      chessCom = slow;
      final level = cubit();
      await level.load();
      final old = level.lookUpChess('gabriel_finais');
      await level.lookUpChess('');
      slow.gate.complete();
      await old;
      expect(level.state.chess, isNull);
    });
  });

  group('rating informado', () {
    test('válido: FIDE 1450 vira 1650', () async {
      final level = cubit();
      await level.load();
      level.setManual(1450);
      expect(level.state.manualOrigin, RatingOrigin.fide);
      expect(level.state.manualValid, isTrue);
      expect(level.state.manualLucena, 1650);
      level.setManualOrigin(RatingOrigin.lichess);
      expect(level.state.manualLucena, 1450);
      await level.useManual();
      expect(profile.profile.rating, 1450);
      expect(profile.profile.levelSource, LevelSource.manual);
      expect(onboarding.saved.startRung, '1400');
    });

    test('fora de 400 a 3000 não grava', () async {
      final level = cubit();
      await level.load();
      for (final rating in [399, 3001, null]) {
        level.setManual(rating);
        expect(level.state.manualValid, isFalse);
        expect(level.state.manualLucena, isNull);
        await level.useManual();
        expect(level.state.finished, isFalse);
      }
      level.setManual(400);
      expect(level.state.manualValid, isTrue);
      level.setManual(3000);
      expect(level.state.manualValid, isTrue);
    });
  });

  test('"Não sei jogar" grava learn e o rating de quem começa', () async {
    final level = cubit();
    await level.load();
    level.select(LevelChoice.zero);
    await level.finish();
    expect(level.state.finished, isTrue);
    expect(level.state.toSchool, VisibleLessons.school);
    expect(profile.profile.goal, GoalPreference.learn);
    expect(profile.profile.levelSource, LevelSource.zero);
    expect(profile.profile.rating, RatingLevel.beginner.rating);
    expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
    expect(onboarding.saved.done, isTrue);
  });

  test('o Personalizar da pessoa ganha da sugestão do nível', () async {
    final custom = HomeSuggestion.of(RatingLevel.master).copyWith(custom: true);
    await home.save(custom);
    final level = cubit();
    await level.load();
    level.setManual(1000);
    await level.useManual();
    expect(home.layout, custom);
    expect(home.seen, isTrue);
  });

  test('pelo Perfil: não marca o teste antigo nem volta o passo', () async {
    onboarding = FakeOnboardingRepository(
      const Onboarding(done: true, selectedRating: 1530),
    );
    final level = cubit(fromProfile: true);
    await level.load();
    expect(level.fromProfile, isTrue);
    expect(level.state.placed, isNull);
    expect(onboarding.saved.stage, isNot(OnboardingStage.level));
    level.setManual(1800);
    level.setManualOrigin(RatingOrigin.lichess);
    await level.useManual();
    expect(profile.profile.rating, 1800);
    expect(onboarding.saved.done, isTrue);
  });

  test('o apelido continua depois do nível', () async {
    profile.profile = profile.profile.copyWith(nickname: 'Ana');
    final level = cubit();
    await level.load();
    level.setManual(1500);
    await level.useManual();
    expect(profile.profile.nickname, 'Ana');
  });
}

class _DelayedProfile extends FakeProfileRepository {
  Completer<UserProfile>? gate;

  @override
  Future<UserProfile> load() => gate?.future ?? super.load();
}

class _SlowChessCom extends FakeChessComRepository {
  _SlowChessCom(Map<String, PlatformRating> users) : super(users: users);

  final gate = Completer<void>();

  @override
  Future<PlatformRating> stats(String user) async {
    await gate.future;
    return super.stats(user);
  }
}
