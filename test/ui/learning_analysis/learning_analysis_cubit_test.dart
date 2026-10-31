import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analysis/learning_analysis_repository.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/learning_analysis.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/learning_analysis/view_models/learning_analysis_cubit.dart';

import 'analysis_test_support.dart';

void main() {
  const launch = LearningAnalysisLaunch(
    fen: kInitialFEN,
    moves: ['e2e4', 'e7e5'],
  );
  late AnalysisMemoryPreferences disk;
  late LearningAnalysisRepository repository;
  late ControlledAnalysisEngine engine;
  late LearningAnalysisCubit cubit;
  setUp(() {
    initializeAnalysisPreferences();
    disk = AnalysisMemoryPreferences();
    repository = LearningAnalysisRepository(disk);
    engine = ControlledAnalysisEngine();
    cubit = LearningAnalysisCubit(
      launch: launch,
      repository: repository,
      engine: engine,
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'legal both-side branches survive recreation with cursor and settings',
    () async {
      await cubit.load();
      expect(cubit.state.session.selected, 2);
      expect(cubit.play('e1e8'), isFalse);
      cubit.first();
      expect(cubit.play('d2d4'), isTrue);
      expect(cubit.play('d7d5'), isTrue);
      expect(cubit.state.session.nodes.length, 5);
      cubit.select(1);
      cubit.next();
      expect(cubit.state.session.current.uci, 'e7e5');
      cubit.select(3);
      cubit.next();
      expect(cubit.state.session.current.uci, 'd7d5');
      cubit.previous();
      expect(cubit.state.session.current.uci, 'd2d4');
      await cubit.confirmSettings(
        const LearningAnalysisSettings(showEngine: false, lines: 3),
      );
      await cubit.close();
      cubit = LearningAnalysisCubit(
        launch: launch,
        repository: repository,
        engine: engine,
      );
      await cubit.load();
      expect(cubit.state.session.nodes.length, 5);
      expect(cubit.state.session.selected, 3);
      expect(cubit.state.settings.showEngine, isFalse);
      expect(cubit.state.settings.lines, 3);
      cubit.first();
      cubit.last();
      expect(cubit.state.session.current.uci, 'e7e5');
    },
  );

  test('engine results reordered or after disabling never replace current position', () async {
    await cubit.load();
    final old = engine.requests.single;
    cubit.previous();
    final current = engine.requests.last;
    const line = EngineLine(
      score: EngineScore(centipawns: 30),
      moves: ['e7e5'],
    );
    current.result.complete([line]);
    await Future<void>.delayed(Duration.zero);
    old.result.complete([
      const EngineLine(score: EngineScore(centipawns: 999), moves: []),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.lines.single.score.centipawns, 30);
    cubit.next();
    final pending = engine.requests.last;
    await cubit.confirmSettings(
      const LearningAnalysisSettings(showEngine: false),
    );
    pending.result.complete([line]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.lines, isEmpty);
    expect(cubit.state.loading, isFalse);
    final count = engine.requests.length;
    cubit.previous();
    expect(engine.requests.length, count);
  });

  test(
    'engine failure leaves navigation usable and zero invented evaluations',
    () async {
      await cubit.load();
      engine.requests.single.result.completeError(StateError('engine stopped'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.loading, isFalse);
      cubit.first();
      expect(cubit.state.session.selected, 0);
      expect(cubit.play('g1f3'), isTrue);
    },
  );

  test('failed persistence retains UI state and automatically retries latest snapshot', () async {
    await cubit.load();
    disk.fail = true;
    cubit.first();
    expect(cubit.play('d2d4'), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.saveFailed, isTrue);
    expect(cubit.state.session.current.uci, 'd2d4');
    disk.fail = false;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(cubit.state.saveFailed, isFalse);
    expect((await repository.load(launch.id))!.current.uci, 'd2d4');
  });

  test(
    'route preserves legal source line and orientation using URI escaping',
    () {
      final uri = Uri.parse(
        Routes.learningAnalysisAt(
          launch.fen,
          moves: launch.moves,
          orientation: 'black',
        ),
      );
      expect(uri.path, Routes.learningAnalysis);
      expect(uri.queryParameters['fen'], launch.fen);
      expect(uri.queryParameters['moves'], 'e2e4,e7e5');
      expect(uri.queryParameters['view'], 'black');
    },
  );

  test('terminal position does not ask engine or allow moves', () async {
    await cubit.close();
    cubit = LearningAnalysisCubit(
      launch: const LearningAnalysisLaunch(
        fen: '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',
      ),
      repository: repository,
      engine: engine,
    );
    await cubit.load();
    expect(engine.requests, isEmpty);
    expect(cubit.play('h8g8'), isFalse);
  });

  test('corrupt or illegal persisted tree is ignored', () async {
    await cubit.load();
    await repository.save(launch.id, cubit.state.session);
    final key = disk.values.keys.single;
    disk.values[key] =
        '{"nodes":[{"fen":"$kInitialFEN"},{"fen":"$kInitialFEN","parent":0,"uci":"e2e5"}],"selected":1}';
    expect(await repository.load(launch.id), isNull);
    disk.values[key] = 'not-json';
    expect(await repository.load(launch.id), isNull);
  });
}
