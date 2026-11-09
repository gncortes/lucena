import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/coach/your_game_filter_repository.dart';
import 'package:lucena/data/services/firebase/coach_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/coach_your_game/view_models/opening_course_cubit.dart';
import 'package:lucena/ui/coach_your_game/view_models/model_games_cubit.dart';
import 'package:lucena/ui/coach_your_game/view_models/your_game_cubit.dart';
import 'package:lucena/ui/coach_your_game/view_models/theory_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_coach_repository.dart';
import '../../../../testing/coach_fixtures.dart';
import '../../../../testing/coach_your_game_fixtures.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  group('SeuJogoCubit', () {
    YourGameCubit cubit(FakeCoachRepository repo) => YourGameCubit(
      repository: repo,
      filter: YourGameFilterRepository(PreferencesService()),
      now: FakeNow(YourGameFixtures.currentTime),
    );

    FakeCoachRepository repo() => FakeCoachRepository(
      account: CoachFixtures.account,
      games: YourGameFixtures.games(),
      stats: YourGameFixtures.stats(),
    );

    test('carrega o resumo das partidas e a plataforma da conta', () async {
      final c = cubit(repo());
      await c.load();
      await pumpEventQueue();
      expect(c.state.status, YourGameStatus.ready);
      expect(c.state.summary?.games, 60);
      expect(c.state.platform, Platform.lichess);
      await c.close();
    });

    test('o ritmo escolhido refaz o resumo e volta depois de fechar', () async {
      final c = cubit(repo());
      await c.load();
      await pumpEventQueue();
      await c.pickTimeControl(TimeControl.blitz);
      expect(c.state.summary?.games, 20);
      await c.close();

      final reopened = cubit(repo());
      await reopened.load();
      await pumpEventQueue();
      expect(reopened.state.timeControl, TimeControl.blitz);
      expect(reopened.state.summary?.games, 20);
      await reopened.pickTimeControl(null);
      expect(reopened.state.summary?.games, 60);
      await reopened.close();
    });

    test('servidor fora: erro; tentar de novo carrega uma vez só', () async {
      final r = _WithFailure(
        account: CoachFixtures.account,
        games: YourGameFixtures.games(),
        stats: YourGameFixtures.stats(),
      );
      final c = cubit(r);
      await c.load();
      await pumpEventQueue();
      expect(c.state.status, YourGameStatus.error);

      r.fail = false;
      final states = <YourGameStatus>[];
      final sub = c.stream.listen((s) => states.add(s.status));
      await c.load();
      await pumpEventQueue();
      expect(states.first, YourGameStatus.loading);
      expect(c.state.status, YourGameStatus.ready);
      expect(c.state.summary?.games, 60);
      await sub.cancel();
      await c.close();
    });

    test('partida com status erro fica fora do resumo', () async {
      final c = cubit(
        FakeCoachRepository(
          account: CoachFixtures.account,
          games: [
            ...YourGameFixtures.games(12),
            CoachFixtures.tiago(status: 'erro'),
          ],
          stats: YourGameFixtures.stats(),
        ),
      );
      await c.load();
      await pumpEventQueue();
      expect(c.state.summary?.games, 12);
      await c.close();
    });

    test('partida nova do servidor entra no resumo', () async {
      final r = repo();
      final c = cubit(r);
      await c.load();
      await pumpEventQueue();
      r.currentGames = YourGameFixtures.games(9);
      await pumpEventQueue();
      expect(c.state.summary?.few, isTrue);
      await c.close();
    });
  });

  group('TeoriaCubit', () {
    test('tocar escolhe a linha; tocar de novo solta', () async {
      final game = YourGameFixtures.games(2)[1];
      final c = TheoryCubit(
        repository: FakeCoachRepository(games: [game]),
        gameId: game.id,
      )..load();
      await pumpEventQueue();
      expect(c.state.status, TheoryStatus.ready);
      expect(c.state.played, 'c5');
      expect(c.state.chosen, isNull);
      // Sem toque: o tabuleiro depois do c5 dele, com o c5 em destaque e
      // marcado na lista.
      expect(c.state.board.fen, game.moves[9].fen);
      expect(c.state.board.chessMove, Move.parse('c6c5'));
      expect(c.state.markedInGame, 9);
      expect(c.state.markedInLine, isNull);

      c.pick('Nd7');
      expect(c.state.line, ['Nd7', 'O-O', 'Ne7']);
      expect(c.state.board.chessMove, Move.parse('g8e7'));
      expect(c.state.markedInGame, isNull);
      expect(c.state.markedInLine, 2);

      // Passo 0: a posição da saída, com 5.Be2 marcado e em destaque.
      c.goTo(0);
      expect(c.state.board.fen, YourGameFixtures.fenTheory);
      expect(c.state.board.chessMove, Move.parse('f1e2'));
      expect(c.state.markedInGame, 8);
      expect(c.state.markedInLine, isNull);
      c.next();
      expect(c.state.board.chessMove, Move.parse('b8d7'));
      expect(c.state.markedInLine, 0);

      c.pick('Nd7');
      expect(c.state.chosen, isNull);
      await c.close();
    });

    test('lista e tabuleiro só com os lances legais da linha', () async {
      final json = YourGameFixtures.gameJson(1);
      final theory = {...json['teoria']! as Map<String, Object?>};
      theory['candidatos'] = [
        {
          'san': 'Nd7',
          'partidas': 1,
          'brancas': 1,
          'empates': 0,
          'pretas': 0,
          'linha': ['Nd7', 'O-O', 'Qxh8'],
        },
      ];
      final game = CoachGame.fromJson(YourGameFixtures.id(1), {
        ...json,
        'teoria': theory,
      })!;
      final c = TheoryCubit(
        repository: FakeCoachRepository(games: [game]),
        gameId: game.id,
      )..load();
      await pumpEventQueue();
      c.pick('Nd7');
      expect(c.state.line, ['Nd7', 'O-O']);
      expect(c.state.markedInLine, 1);
      await c.close();
    });

    test('partida sem teoria', () async {
      final game = YourGameFixtures.games(3)[2];
      final c = TheoryCubit(
        repository: FakeCoachRepository(games: [game]),
        gameId: game.id,
      )..load();
      await pumpEventQueue();
      expect(c.state.status, TheoryStatus.noTheory);
      await c.close();
    });
  });

  group('PartidasModeloCubit', () {
    test('sem internet: erro; tentar de novo lista', () async {
      final repo = _WithFailure(account: CoachFixtures.account);
      final c = ModelGamesCubit(repository: repo, eco: 'B12');
      await c.load();
      expect(c.state.status, ModelGamesStatus.error);
      repo.fail = false;
      await c.load();
      expect(c.state.status, ModelGamesStatus.ready);
      await c.close();
    });

    test('lista as partidas do ECO e grava o aviso', () async {
      final repo = FakeCoachRepository(
        account: CoachFixtures.account,
        modelGamesByEco: {
          'B12': [
            const ModelGame(source: 'torneio', title: 'Carlsen x Caruana'),
          ],
        },
      );
      final c = ModelGamesCubit(repository: repo, eco: 'B12');
      await c.load();
      await pumpEventQueue();
      expect(c.state.status, ModelGamesStatus.ready);
      expect(c.state.modelGames.single.title, 'Carlsen x Caruana');
      expect(c.state.aviso, isFalse);

      await c.setNotice(linked: true);
      await pumpEventQueue();
      expect(repo.modelGamesNotices, [true]);
      expect(c.state.aviso, isTrue);
      await c.close();
    });
  });

  group('CursoDaAberturaCubit', () {
    final resources = TrainingResources(
      lessons: [
        for (final id in ['pilares.ab1.caroKann1', 'pilares.ab2.caroKann2'])
          TrainingLesson(id: id, kind: TrainingLessonKind.opening, title: id),
      ],
    );

    Future<OpeningCourseState> loadAll(CourseAccess grant) async {
      final c = OpeningCourseCubit(
        training: FakeTrainingRepository(
          content: {TrainingCourse.pilares: resources},
        ),
        access: FakeCourseAccessRepository(grant),
        slot: 'caroKann',
        part: 2,
      );
      await c.load();
      final s = c.state;
      await c.close();
      return s;
    }

    test('sem o curso: as partes e a do servidor em destaque', () async {
      final s = await loadAll(CourseAccess.demo);
      expect(s.loading, isFalse);
      expect(s.hasCourse, isFalse);
      expect(s.opening?.highlight.number, 2);
    });

    test('comprar e terminar a parte já mudam a tela, sem reabrir', () async {
      final grant = FakeCourseAccessRepository();
      final training = FakeTrainingRepository(
        content: {TrainingCourse.pilares: resources},
      );
      final c = OpeningCourseCubit(
        training: training,
        access: grant,
        slot: 'caroKann',
      );
      await c.load();
      expect(c.state.hasCourse, isFalse);

      grant.access = CourseAccess.owned;
      await pumpEventQueue();
      expect(c.state.hasCourse, isTrue);
      expect(c.state.opening?.highlight.number, 1);

      await training.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(
          completedLessons: const {'pilares.ab1.caroKann1': '2026-11-09'},
        ),
      );
      await pumpEventQueue();
      expect(c.state.opening?.highlight.number, 2);
      await c.close();
    });

    test('com o curso: temOCurso', () async {
      final s = await loadAll(CourseAccess.owned);
      expect(s.hasCourse, isTrue);
      expect(s.opening?.parts, hasLength(2));
    });
  });
}

/// O servidor fora do ar: a lista e as partidas-modelo falham enquanto
/// [fail] for verdadeiro.
class _WithFailure extends FakeCoachRepository {
  _WithFailure({super.account, super.games, super.stats});

  var fail = true;

  @override
  Stream<List<CoachGame>> games() => fail
      ? Stream.error(const CoachCallException('unavailable'))
      : super.games();

  @override
  Future<List<ModelGame>> modelGames(String eco) async {
    if (fail) throw const CoachCallException('unavailable');
    return super.modelGames(eco);
  }
}
