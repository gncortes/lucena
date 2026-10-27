import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/models/streak.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/position_judge.dart';
import 'package:lucena/ui/daily/view_models/daily_game_cubit.dart';
import 'package:lucena/ui/daily/view_models/daily_start_cubit.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/free_board/view_models/free_board_state.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';

import '../../../../testing/fakes/fake_activity_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_kpk_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_race_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';

class _RookJudge implements PositionJudge {
  @override
  Future<Wdl?> evaluate(Position position) async {
    final rookOnH5 = position.board.roleAt(Square.h5) == Role.rook;
    final white = rookOnH5 ? Wdl.draw : Wdl.win;
    return position.turn == Side.white ? white : white.flipped;
  }
}

void main() {
  late FakeAnalyticsRepository analytics;
  final now = FakeNow(DateTime(2026, 10, 22, 9));

  setUp(() => analytics = FakeAnalyticsRepository());

  test('StreakCubit loga sequencia_vista com a atual e o recorde', () async {
    final cubit = StreakCubit(
      activity: FakeActivityRepository(
        days: {
          DateTime(2026, 10, 10),
          DateTime(2026, 10, 11),
          DateTime(2026, 10, 12),
          DateTime(2026, 10, 21),
        },
      ),
      now: now,
      analytics: analytics,
    );
    addTearDown(cubit.close);
    await cubit.load();
    expect(analytics.eventsNamed('sequencia_vista').single.params, {
      'sequencia': 1,
      'recorde': 3,
    });
  });

  test('LessonFinishedCubit loga aula_concluida com o tipo', () async {
    for (final (kind, type) in [
      (SurveyKind.school, 'escola'),
      (SurveyKind.endgames, 'finais'),
    ]) {
      analytics.events.clear();
      final cubit = LessonFinishedCubit(
        kind: kind,
        lessonId: 'x.1',
        nextId: null,
        school: FakeLessonRepository(),
        endgames: FakeEndgameLessonRepository(),
        race: FakeRaceRepository(now: now, problems: raceTestProblems),
        analytics: analytics,
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      final params = analytics.eventsNamed('aula_concluida').single.params;
      expect(params['aula_id'], 'x.1');
      expect(params['tipo_aula'], type);
    }
  });

  group('DailyStartCubit', () {
    Future<void> open({String entry = 'home', Set<DateTime>? days}) async {
      final daily = FakeDailyFinalRepository();
      final cubit = DailyStartCubit(
        daily: daily,
        rating: FakeRatingRepository(),
        now: now,
        activity: FakeActivityRepository(days: days ?? {}),
        analytics: analytics,
        entry: entry,
      );
      addTearDown(cubit.close);
      await cubit.load();
    }

    test(
      'final_dia_aberto traz a entrada, a sequência e se já jogou',
      () async {
        await open(entry: 'lembrete', days: {DateTime(2026, 10, 21)});
        expect(analytics.eventsNamed('final_dia_aberto').single.params, {
          'entrada': 'lembrete',
          'sequencia': 1,
          'ja_jogou_hoje': 'nao',
        });
      },
    );

    test('sem final hoje, nada é logado', () async {
      final cubit = DailyStartCubit(
        daily: FakeDailyFinalRepository(none: true),
        rating: FakeRatingRepository(),
        now: now,
        analytics: analytics,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(analytics.events, isEmpty);
    });
  });

  group('DailyGameCubit', () {
    final rook = samplePositions.firstWhere((p) => p.id == 'basic.rook.0001');
    final start = GameRules.fromFen(rook.fen)!;
    const mode = GameMode(
      opponent: OpponentKind.maia,
      level: 1400,
      userSide: Side.white,
      goal: PositionGoal.win,
      dailyDate: '2026-10-22',
    );

    FreeBoardState game(List<String> ucis, {GameEnd? end}) {
      var position = start;
      for (final uci in ucis) {
        position = GameRules.play(position, Move.parse(uci)!)!.position;
      }
      return FreeBoardState(
        start: start,
        position: position,
        ucis: ucis,
        mode: mode,
        forcedEnd: end,
      );
    }

    test('final_dia_concluido: a primeira tentativa, uma vez só', () async {
      final cubit = DailyGameCubit(
        date: '2026-10-22',
        daily: FakeDailyFinalRepository(position: rook),
        activity: FakeActivityRepository(),
        kpk: FakeKpkRepository(FakeKpkOracle(fallback: KpkOutcome.outside)),
        engine: _RookJudge(),
        analytics: analytics,
        now: now,
      );
      addTearDown(cubit.close);
      await cubit.load();
      cubit.update(
        game([
          'h1h2',
          'd6c6',
          'h2h5',
        ], end: const GameEnd(GameEndReason.resign, winner: Side.black)),
      );
      await cubit.settle();
      cubit
        ..update(game(const []))
        ..update(
          game([
            'h1h2',
          ], end: const GameEnd(GameEndReason.checkmate, winner: Side.white)),
        );
      await cubit.settle();

      final done = analytics.eventsNamed('final_dia_concluido');
      expect(done, hasLength(1));
      expect(done.single.params, {
        'final_id': rook.id,
        'data': '2026-10-22',
        'acertou': 'nao',
        'lances': 2,
        'verdes': 1,
        'amarelos': 0,
        'vermelhos': 1,
        'sequencia': 1,
      });
    });
  });

  test('aulas sem conteúdo: aula_indisponivel com a origem da tela', () async {
    final endgames = EndgamesCubit(
      lessons: _NoEndgameLessons(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      analytics: analytics,
    );
    addTearDown(endgames.close);
    await endgames.load('en');
    final school = SchoolCubit(
      lessons: _NoSchoolLessons(),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(const UserProfile()),
      analytics: analytics,
    );
    addTearDown(school.close);
    await school.load('en');
    expect(
      analytics.eventsNamed('aula_indisponivel').map((e) => e.params['origem']),
      ['trilha_finais', 'escola'],
    );
  });

  test('HomeCubit: sequencia_perdida com tamanho, recorde e ação', () {
    final home = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: FakeProgressRepository(),
      onboarding: FakeOnboardingRepository(const Onboarding(done: true)),
      characters: FakeCharacterRepository(),
      rating: FakeRatingRepository(),
      lessons: FakeLessonRepository(),
      school: FakeSchoolProgressRepository(),
      profile: FakeProfileRepository(const UserProfile()),
      endgameLessons: FakeEndgameLessonRepository(),
      endgameProgress: FakeEndgameProgressRepository(),
      analytics: analytics,
    );
    addTearDown(home.close);
    const lost = Streak(current: 0, record: 9, activeToday: false, lost: 5);
    home.lostAnswered(lost, played: true);
    home.lostAnswered(lost, played: false);
    expect(analytics.eventsNamed('sequencia_perdida').map((e) => e.params), [
      {'tamanho': 5, 'recorde': 9, 'acao': 'jogou_hoje'},
      {'tamanho': 5, 'recorde': 9, 'acao': 'agora_nao'},
    ]);
  });
}

class _NoEndgameLessons extends FakeEndgameLessonRepository {
  @override
  Future<EndgameTrail> trail() => throw const LessonContentUnavailable();
}

class _NoSchoolLessons extends FakeLessonRepository {
  @override
  Future<Course> course() => throw const LessonContentUnavailable();
}
