import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository.dart';
import 'package:lucena/data/repositories/tablebase/exercise_judge_repository.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';
import 'package:lucena/domain/use_cases/exercise_review.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';

const _fen = '8/k1K5/3N4/8/8/8/8/5B2 w - - 0 1';
const _hash =
    '95507b845908630c15307c028e32b60eccfdaac52336bb97d95774f3bd60c10b';
const _lesson = 'mates.bishopKnight.w';
const _line = [
  MoveTurn(accept: {'d6c8'}, reply: 'a7a8'),
  MoveTurn(accept: {'f1g2'}),
];

Move _move(String uci) => Move.parse(uci)!;

class _DelayedLessons extends FakeEndgameLessonRepository {
  _DelayedLessons(EndgameTrail trail) : super(trail: trail);
  Completer<void>? gate;
  final entered = Completer<void>();
  @override
  Future<EndgameTrail> trail() async {
    if (gate != null) {
      if (!entered.isCompleted) entered.complete();
      await gate!.future;
    }
    return super.trail();
  }
}

class _HeldProgress extends FakeEndgameProgressRepository {
  Completer<void>? gate;
  final entered = Completer<void>();
  @override
  Future<EndgameProgress> load() async {
    if (gate != null) {
      if (!entered.isCompleted) entered.complete();
      await gate!.future;
    }
    return super.load();
  }
}

class _HeldCompletionProgress extends FakeEndgameProgressRepository {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> save(EndgameProgress progress) async {
    if (progress.of(_lesson).stars.isNotEmpty) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
    await super.save(progress);
  }
}

// Fake scheduling/transport only. Every WDL comes from the real public bytes.
class _ProofTransport implements ExerciseProofProvider {
  _ProofTransport(this.delegate);
  final ExerciseProofProvider delegate;
  final entered = Completer<void>();
  Completer<void>? gate;
  bool fail = false;
  @override
  Future<ExerciseJudgement> lookup(String fen) async {
    if (!entered.isCompleted) entered.complete();
    await gate?.future;
    if (fail) throw StateError('transport unavailable');
    return delegate.lookup(fen);
  }
}

// Explicit opponent infrastructure: returns only the requested scripted move;
// production selection and chess evaluation are never simulated here.
class _Opponent implements OpponentRepository {
  String? reply = 'a7a8';
  bool fail = false;
  Completer<void>? gate;
  final entered = Completer<void>();
  final histories = <List<Position>>[];
  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
    TimeControl? time,
  }) async {
    histories.add(history);
    if (!entered.isCompleted) entered.complete();
    await gate?.future;
    if (fail) throw StateError('opponent unavailable');
    return reply == null ? null : Move.parse(reply!);
  }
}

FakeEndgameLessonRepository _lessons({
  List<MoveTurn> line = _line,
  ExerciseCompletion completion = ExerciseCompletion.checkmate,
  String fen = _fen,
}) => FakeEndgameLessonRepository(
  trail: EndgameTrail(
    modules: [
      EndgameModule(
        id: 'mates',
        lessons: [
          EndgameLesson(
            id: _lesson,
            module: 'mates',
            lesson: const Lesson(id: _lesson, steps: []),
            exercises: [
              Exercise(
                id: 'e13',
                stars: 3,
                fen: fen,
                goal: PositionGoal.win,
                line: line,
                completion: completion,
              ),
            ],
            passScore: 3,
            keyPositions: const [],
            practice: Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  ),
  texts: LessonTexts.fromJson({
    '$_lesson.ex.e13.hint': 'Limite as casas de fuga do rei.',
  }),
);

void main() {
  final raw = io.File(
    'test/data/repositories/tablebase/fixtures/e13.response.json',
  ).readAsBytesSync();
  final envelope = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'version': 1,
        'queryFen': _fen,
        'source': Uri.https('tablebase.lichess.ovh', '/standard', {
          'fen': _fen,
        }).toString(),
        'rawSha256': _hash,
        'raw': utf8.decode(raw),
      }),
    ),
  );
  AssetExerciseJudgeRepository proofs({
    bool available = true,
  }) => AssetExerciseJudgeRepository.bytes(
    bytes: available ? envelope : Uint8List(0),
    queryFen: _fen,
    rawSha256: _hash,
    // Compare every byte with the pinned public fixture, not a mocked digest.
    verify: (bytes, digest) async =>
        digest == _hash &&
        bytes.length == raw.length &&
        Iterable<int>.generate(raw.length).every((i) => bytes[i] == raw[i]),
  );

  late FakeEndgameProgressRepository progress;
  late FakeNow now;
  late _Opponent opponent;
  setUp(() {
    progress = FakeEndgameProgressRepository();
    now = FakeNow(DateTime.utc(2026, 10, 18));
    opponent = _Opponent();
  });

  ExerciseCubit create({
    List<MoveTurn> line = _line,
    ExerciseCompletion completion = ExerciseCompletion.checkmate,
    ExerciseProofProvider? provider,
    bool ports = true,
    String fen = _fen,
    Duration opponentTimeout = const Duration(seconds: 10),
    EndgameLessonRepository? lessons,
  }) {
    final cubit = ExerciseCubit(
      lessons:
          lessons ?? _lessons(line: line, completion: completion, fen: fen),
      progress: progress,
      characters: FakeCharacterRepository(),
      now: now,
      exerciseJudge: ports ? ExerciseJudge(provider ?? proofs()) : null,
      opponent: ports ? opponent : null,
      opponentTimeout: opponentTimeout,
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> open(ExerciseCubit cubit) => cubit.load(_lesson, 'e13', 'pt');
  void noCredit(ExerciseCubit cubit) {
    expect(cubit.state.phase, isNot(ExercisePhase.done));
    expect(cubit.state.earned, isNull);
    expect(progress.saved.of(_lesson).stars, isEmpty);
  }

  for (final first in ['d6c8', 'd6b5']) {
    test(
      'real e13 $first / Ka8 / Bg2# completes only at student mate',
      () async {
        var position = GameRules.fromFen(_fen)!;
        for (final uci in [first, 'a7a8', 'f1g2']) {
          final next = GameRules.play(position, _move(uci));
          expect(next, isNotNull, reason: 'public sequence must be legal');
          position = next!.position;
        }
        expect(position.isCheckmate, isTrue);
        expect(GameRules.endOf(position)!.winner, Side.white);
        final cubit = create();
        await open(cubit);
        await cubit.play(_move(first));
        noCredit(cubit);
        expect(cubit.state.mistakes, 0);
        expect(cubit.state.played, [first, 'a7a8']);
        expect(opponent.histories.length, first == 'd6b5' ? 1 : 0);
        if (first == 'd6b5') {
          expect(opponent.histories.single.length, 2);
          expect(opponent.histories.single.first.fen, _fen);
        }
        await cubit.play(_move('f1g2'));
        expect(cubit.state.phase, ExercisePhase.done);
        expect(cubit.state.earned, 3);
        expect(progress.saved.of(_lesson).stars, {'e13': 3});
        expect(progress.saved.of(_lesson).exercise, isNull);
        expect(cubit.state.played, [first, 'a7a8', 'f1g2']);
        expect(cubit.state.review.map((node) => node.uci), [
          first,
          'a7a8',
          'f1g2',
        ]);
      },
    );
  }

  for (final line in [
    [_line.first],
    [
      const MoveTurn(accept: {'d6c8', 'd6b5'}, reply: 'a7a8'),
    ],
  ]) {
    test(
      'RED explicit checkmate ignores end of PV/accepted alternative $line',
      () async {
        final cubit = create(line: line);
        await open(cubit);
        await cubit.play(_move(line.first.accept.length > 1 ? 'd6b5' : 'd6c8'));
        noCredit(cubit);
        expect(cubit.state.mistakes, 0);
        expect(cubit.state.turn, 1);
        await cubit.play(_move('f1g2'));
        expect(cubit.state.earned, 3);
        // Review is longer than the registered PV and contains no invented branch.
        expect(cubit.state.review.length, 3);
        expect(cubit.state.review.every((node) => node.depth == 0), isTrue);
      },
    );
  }

  test(
    'RED illegal registered reply preserves post-student checkpoint',
    () async {
      final cubit = create(
        line: const [
          MoveTurn(accept: {'d6c8'}, reply: 'a7a6'),
        ],
      );
      await open(cubit);
      await cubit.play(_move('d6c8'));
      noCredit(cubit);
      expect(cubit.state.technicalFailure, 'illegalRegisteredReply');
      expect(cubit.state.played, ['d6c8']);
      expect(cubit.state.mistakes, 0);
      expect(opponent.histories, isEmpty);
      final checkpoint = progress.saved.of(_lesson).exercise!;
      expect(checkpoint.played, ['d6c8']);
      await cubit.askHint();
      await cubit.showSolution();
      await cubit.play(_move('a7a8'));
      expect(progress.saved.of(_lesson).exercise, checkpoint);
    },
  );

  test(
    'known real draw is wrong without advancing the actual history',
    () async {
      final cubit = create();
      await open(cubit);
      await cubit.play(_move('f1a6'));
      noCredit(cubit);
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.firstMoveMistake, isTrue);
      expect(cubit.state.say, ExerciseSay.wrong);
      expect(cubit.state.fen, _fen);
      expect(cubit.state.played, isEmpty);
    },
  );

  test(
    'missing proof and provider exception preserve attempt without penalty',
    () async {
      for (final provider in [
        proofs(available: false),
        _ProofTransport(proofs())..fail = true,
      ]) {
        final cubit = create(provider: provider);
        await open(cubit);
        final checkpoint = progress.saved.of(_lesson).exercise;
        await cubit.play(_move('d6c8'));
        noCredit(cubit);
        expect(cubit.state.technicalFailure, isNotNull);
        expect(cubit.state.mistakes, 0);
        expect(cubit.state.firstMoveMistake, isFalse);
        expect(cubit.state.played, isEmpty);
        expect(cubit.state.fen, _fen);
        expect(progress.saved.of(_lesson).exercise, checkpoint);
        await cubit.close();
      }
    },
  );

  test(
    'unproved descendant is technical even when its move is in accept',
    () async {
      final cubit = create(
        line: const [
          MoveTurn(accept: {'d6c8'}, reply: 'a7a8'),
          MoveTurn(accept: {'c8e7'}),
        ],
      );
      await open(cubit);
      await cubit.play(_move('d6c8'));
      final checkpoint = progress.saved.of(_lesson).exercise;
      final candidate = GameRules.play(
        GameRules.fromFen(cubit.state.fen!)!,
        _move('c8e7'),
      );
      expect(candidate, isNotNull);
      expect(
        GameRules.endOf(candidate!.position),
        isNull,
        reason: 'the unknown-proof case must remain nonterminal',
      );
      await cubit.play(_move('c8e7'));
      noCredit(cubit);
      expect(cubit.state.technicalFailure, 'noExactProof');
      expect(cubit.state.mistakes, 0);
      expect(progress.saved.of(_lesson).exercise, checkpoint);
    },
  );

  for (final invalid in ['a7b7', null, 'exception']) {
    test(
      'real opponent invalid/null/exception $invalid never substitutes a move',
      () async {
        opponent.reply = invalid == 'exception' ? null : invalid;
        opponent.fail = invalid == 'exception';
        final child = GameRules.play(GameRules.fromFen(_fen)!, _move('d6b5'));
        expect(child, isNotNull);
        expect(GameRules.endOf(child!.position), isNull);
        expect(
          GameRules.play(child.position, _move('a7b7')),
          isNull,
          reason: 'b7 is controlled by the student king on c7',
        );
        final cubit = create();
        await open(cubit);
        await cubit.play(_move('d6b5'));
        noCredit(cubit);
        expect(cubit.state.technicalFailure, isNotNull);
        expect(cubit.state.played, ['d6b5']);
        expect(cubit.state.mistakes, 0);
        expect(progress.saved.of(_lesson).exercise!.played, ['d6b5']);
      },
    );
  }

  test('missing registered reply calls the opponent port', () async {
    final cubit = create(
      line: const [
        MoveTurn(accept: {'d6c8'}),
      ],
    );
    await open(cubit);
    await cubit.play(_move('d6c8'));
    noCredit(cubit);
    expect(opponent.histories.length, 1);
    expect(cubit.state.played, ['d6c8', 'a7a8']);
  });

  test(
    'opponent timeout preserves checkpoint without a substitute move',
    () async {
      opponent.gate = Completer<void>();
      final cubit = create(opponentTimeout: const Duration(milliseconds: 1));
      await open(cubit);
      await cubit.play(_move('d6b5'));
      expect(cubit.state.technicalFailure, 'opponentUnavailable');
      noCredit(cubit);
      expect(cubit.state.played, ['d6b5']);
      final checkpoint = progress.saved.of(_lesson).exercise;
      opponent.gate!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(progress.saved.of(_lesson).exercise, checkpoint);
      expect(cubit.state.played, ['d6b5']);
    },
  );

  test('ports absent fail technically without grading the new mode', () async {
    final cubit = create(ports: false);
    await open(cubit);
    expect(cubit.state.technicalFailure, 'evaluationUnavailable');
    await cubit.play(_move('d6c8'));
    noCredit(cubit);
  });

  test(
    'background holds judge result; concurrent input cannot duplicate move',
    () async {
      final provider = _ProofTransport(proofs())..gate = Completer<void>();
      final cubit = create(provider: provider);
      await open(cubit);
      final playing = cubit.play(_move('d6c8'));
      await provider.entered.future;
      await cubit.play(_move('d6c8'));
      await cubit.askHint();
      await cubit.pauseForBackground();
      provider.gate!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.played, isEmpty);
      expect(cubit.state.hints, 0);
      noCredit(cubit);
      await cubit.resumeFromBackground();
      await playing;
      expect(cubit.state.played, ['d6c8', 'a7a8']);
    },
  );

  test(
    'load revision rejects an old judge return, even at identical FEN',
    () async {
      final provider = _ProofTransport(proofs())..gate = Completer<void>();
      final cubit = create(provider: provider);
      await open(cubit);
      final playing = cubit.play(_move('d6c8'));
      await provider.entered.future;
      await open(cubit);
      provider.gate!.complete();
      await playing;
      expect(cubit.state.played, isEmpty);
      expect(progress.saved.of(_lesson).exercise!.played, isEmpty);
      noCredit(cubit);
    },
  );

  test(
    'loading another exercise blocks old input and cannot inherit its game',
    () async {
      var target = GameRules.fromFen(_fen)!;
      for (final uci in ['d6c8', 'a7a8']) {
        target = GameRules.play(target, _move(uci))!.position;
      }
      expect(GameRules.endOf(target), isNull);
      final lessons = _DelayedLessons(
        EndgameTrail(
          modules: [
            EndgameModule(
              id: 'mates',
              lessons: [
                EndgameLesson(
                  id: _lesson,
                  module: 'mates',
                  lesson: const Lesson(id: _lesson, steps: []),
                  exercises: [
                    const Exercise(
                      id: 'e13',
                      stars: 3,
                      fen: _fen,
                      goal: PositionGoal.win,
                      line: _line,
                      completion: ExerciseCompletion.checkmate,
                    ),
                    Exercise(
                      id: 'e14',
                      stars: 2,
                      fen: target.fen,
                      goal: PositionGoal.win,
                      line: const [
                        MoveTurn(accept: {'f1g2'}),
                      ],
                      completion: ExerciseCompletion.checkmate,
                    ),
                  ],
                  passScore: 3,
                  keyPositions: const [],
                  practice: const Practice(fen: _fen, goal: PositionGoal.win),
                ),
              ],
            ),
          ],
        ),
      );
      final provider = _ProofTransport(proofs())..gate = Completer<void>();
      final cubit = create(lessons: lessons, provider: provider);
      await open(cubit);
      lessons.gate = Completer<void>();
      final loading = cubit.load(_lesson, 'e14', 'pt');
      await lessons.entered.future;
      expect(cubit.state.interactive, isFalse);
      final stalePlaying = cubit.play(_move('d6c8'));
      await cubit.askHint();
      await cubit.showSolution();
      expect(
        provider.entered.isCompleted,
        isFalse,
        reason: 'old exercise input must not acquire the new load revision',
      );
      lessons.gate!.complete();
      await loading;
      provider.gate!.complete();
      await stalePlaying;
      expect(cubit.state.exercise!.id, 'e14');
      expect(cubit.state.fen, target.fen);
      expect(cubit.state.played, isEmpty);
      expect(cubit.state.hints, 0);
      expect(progress.saved.of(_lesson).exercise!.exerciseId, 'e14');
      noCredit(cubit);
      await cubit.play(_move('f1g2'));
      expect(cubit.state.earned, 2);
      expect(progress.saved.of(_lesson).stars, {'e14': 2});
    },
  );

  test('close drains an emitted hint checkpoint before reopening', () async {
    final held = _HeldProgress();
    progress = held;
    final cubit = create();
    await open(cubit);
    held.gate = Completer<void>();
    final hinting = cubit.askHint();
    await held.entered.future;
    expect(cubit.state.hints, 1);
    expect(cubit.state.hintShown, isTrue);
    final closing = cubit.close();
    held.gate!.complete();
    await Future.wait([hinting, closing]);
    expect(held.saved.of(_lesson).exercise!.hints, 1);
    expect(held.saved.of(_lesson).exercise!.hintTurn, 0);
    final resumed = create();
    await open(resumed);
    expect(resumed.state.hints, 1);
    expect(resumed.state.hintShown, isTrue);
    await resumed.askHint();
    expect(resumed.state.hints, 1);
    await resumed.play(_move('d6c8'));
    await resumed.play(_move('f1g2'));
    expect(resumed.state.earned, 2);
  });

  for (final completion in ExerciseCompletion.values) {
    test('leave then close keeps checkpoint closed: $completion', () async {
      final cubit = create(completion: completion);
      await open(cubit);
      await cubit.leave();
      expect(progress.saved.of(_lesson).exercise!.open, isFalse);
      await cubit.close();
      expect(progress.saved.of(_lesson).exercise!.open, isFalse);
    });
  }

  test('close during completion cannot restore a cleared checkpoint', () async {
    final held = _HeldCompletionProgress();
    progress = held;
    final cubit = create();
    await open(cubit);
    await cubit.play(_move('d6c8'));
    final playing = cubit.play(_move('f1g2'));
    await held.entered.future;
    final closing = cubit.close();
    held.release.complete();
    await Future.wait([playing, closing]);
    expect(held.saved.of(_lesson).exercise, isNull);
    expect(held.saved.of(_lesson).stars, {'e13': 3});
  });

  test(
    'leaving a technical failure closes only the stored open flag',
    () async {
      final cubit = create(provider: proofs(available: false));
      await open(cubit);
      final saved = progress.saved.of(_lesson).exercise!;
      await cubit.play(_move('d6c8'));
      expect(cubit.state.technicalFailure, isNotNull);
      await cubit.leave();
      await cubit.close();
      expect(progress.saved.of(_lesson).exercise!.toJson(), {
        ...saved.toJson(),
        'open': false,
      });
      expect(progress.saved.of(_lesson).stars, isEmpty);
    },
  );

  test('leaving an invalid checkpoint preserves its diagnostic data', () async {
    final cubit = create();
    await open(cubit);
    final saved = progress.saved.of(_lesson).exercise!;
    final broken = ExerciseCheckpoint.fromJson({
      ...saved.toJson(),
      'contractIdentity': 'tampered',
    })!;
    progress.saved = progress.saved.withLesson(
      _lesson,
      progress.saved.of(_lesson).copyWith(exercise: broken),
    );
    await open(cubit);
    expect(cubit.state.technicalFailure, 'invalidCheckpoint');
    await cubit.leave();
    expect(progress.saved.of(_lesson).exercise!.toJson(), {
      ...broken.toJson(),
      'open': false,
    });
    expect(progress.saved.of(_lesson).stars, isEmpty);
  });

  test('close rejects pending judge result and keeps checkpoint', () async {
    final provider = _ProofTransport(proofs())..gate = Completer<void>();
    final cubit = create(provider: provider);
    await open(cubit);
    final checkpoint = progress.saved.of(_lesson).exercise;
    final playing = cubit.play(_move('d6c8'));
    await provider.entered.future;
    await cubit.close();
    provider.gate!.complete();
    await playing;
    expect(progress.saved.of(_lesson).exercise, checkpoint);
    expect(progress.saved.of(_lesson).stars, isEmpty);
  });

  test('load invalidates a judge return waiting for foreground', () async {
    final provider = _ProofTransport(proofs())..gate = Completer<void>();
    final cubit = create(provider: provider);
    await open(cubit);
    final playing = cubit.play(_move('d6c8'));
    await provider.entered.future;
    await cubit.pauseForBackground();
    provider.gate!.complete();
    await Future<void>.delayed(Duration.zero);
    await open(cubit).timeout(const Duration(seconds: 2));
    await playing.timeout(const Duration(seconds: 2));
    expect(cubit.state.played, isEmpty);
    noCredit(cubit);
    await cubit.resumeFromBackground();
  });

  test(
    'pending opponent resumes checkpoint and cannot append its stale reply',
    () async {
      opponent.gate = Completer<void>();
      final first = create();
      await open(first);
      final playing = first.play(_move('d6b5'));
      await opponent.entered.future;
      final saved = progress.saved.of(_lesson).exercise!;
      expect(saved.played, ['d6b5']);
      expect(saved.contractVersion, 1);
      expect(saved.contractIdentity, isNotNull);
      await first.close();
      opponent.gate!.complete();
      await playing;
      final resumed = create();
      final replied = resumed.stream.firstWhere(
        (state) => state.ready && state.played.length == 2,
      );
      await open(resumed);
      await replied;
      await Future<void>.delayed(Duration.zero);
      expect(resumed.state.played, ['d6b5', 'a7a8']);
      await resumed.play(_move('f1g2'));
      expect(resumed.state.earned, 3);
    },
  );

  test('checkpoint JSON preserves assistance/version/identity and detects tampering', () async {
    final cubit = create();
    await open(cubit);
    await cubit.play(_move('d6c8'));
    await cubit.leave();
    final checkpoint = progress.saved.of(_lesson).exercise!;
    expect(ExerciseCheckpoint.fromJson(checkpoint.toJson()), checkpoint);
    final before = progress.saved;
    for (final patch in [
      {'fen': _fen},
      {'turn': 9},
      {
        'played': ['d6c8', 'a7a6'],
      },
      {'contractVersion': 2},
      {'contractIdentity': 'different exercise'},
    ]) {
      final broken = ExerciseCheckpoint.fromJson({
        ...checkpoint.toJson(),
        ...patch,
      })!;
      progress.saved = before.withLesson(
        _lesson,
        before.of(_lesson).copyWith(exercise: broken),
      );
      final resumed = create();
      await open(resumed);
      expect(resumed.state.technicalFailure, 'invalidCheckpoint');
      expect(progress.saved.of(_lesson).exercise, broken);
      noCredit(resumed);
      await resumed.close();
    }
  });

  test(
    'old unversioned checkpoint is preserved and cannot certify history',
    () async {
      const old = ExerciseCheckpoint(exerciseId: 'e13', fen: _fen);
      progress.saved = progress.saved.withLesson(
        _lesson,
        const EndgameLessonProgress(exercise: old),
      );
      final cubit = create();
      await open(cubit);
      expect(cubit.state.technicalFailure, 'invalidCheckpoint');
      expect(progress.saved.of(_lesson).exercise, old);
      noCredit(cubit);
    },
  );

  test(
    'conceptual help is charged once per student turn, including reload',
    () async {
      final cubit = create();
      await open(cubit);
      await Future.wait([cubit.askHint(), cubit.askHint()]);
      await cubit.askHint();
      expect(cubit.state.hints, 1);
      expect(cubit.state.hint, isNull);
      await cubit.close();
      final resumed = create();
      await open(resumed);
      await resumed.askHint();
      expect(resumed.state.hints, 1);
      await resumed.play(_move('d6c8'));
      await resumed.askHint();
      expect(resumed.state.hints, 2);
      await resumed.play(_move('f1g2'));
      expect(resumed.state.earned, 1);
    },
  );

  test(
    'complete solution is assisted and can only finish at actual mate',
    () async {
      final cubit = create();
      await open(cubit);
      await cubit.showSolution();
      expect(cubit.state.phase, ExercisePhase.done);
      expect(cubit.state.solutionShown, isTrue);
      expect(cubit.state.earned, 0);
      expect(cubit.state.played, ['d6c8', 'a7a8', 'f1g2']);
      expect(progress.saved.of(_lesson).stars, {'e13': 0});
      final finalFen = cubit.state.review.last.fenAfter;
      expect(GameRules.fromFen(finalFen)!.isCheckmate, isTrue);
    },
  );

  test(
    'interrupted solution saves assistance before any solution move',
    () async {
      final cubit = create();
      await open(cubit);
      final showing = cubit.showSolution();
      await cubit.pauseForBackground();
      final saved = progress.saved.of(_lesson).exercise!;
      expect(saved.solutionShown, isTrue);
      expect(saved.played, isEmpty);
      noCredit(cubit);
      await cubit.close();
      await showing;
      final resumed = create();
      await open(resumed);
      expect(resumed.state.solutionShown, isTrue);
      await resumed.play(_move('d6c8'));
      await resumed.play(_move('f1g2'));
      expect(resumed.state.earned, 0);
    },
  );

  test('incomplete solution persists assistance across reload and later mate scores 0', () async {
    final cubit = create(line: [_line.first]);
    await open(cubit);
    await cubit.showSolution();
    noCredit(cubit);
    expect(cubit.state.technicalFailure, 'incompleteSolution');
    expect(cubit.state.solutionShown, isTrue);
    expect(cubit.state.worth, 0);
    final saved = progress.saved.of(_lesson).exercise!;
    expect(saved.solutionShown, isTrue);
    expect(ExerciseCheckpoint.fromJson(saved.toJson()), saved);
    await cubit.close();
    final resumed = create(line: [_line.first]);
    await open(resumed);
    expect(resumed.state.solutionShown, isTrue);
    await resumed.play(_move('f1g2'));
    expect(resumed.state.earned, 0);
    expect(progress.saved.of(_lesson).stars, {'e13': 0});
  });

  test(
    'pure rule terminals with wrong winner/draw never score on load',
    () async {
      // Existing rule fixtures from exercise_judge_test.dart, no new engine/FEN claim.
      for (final fen in [
        '7k/6Q1/6K1/8/8/8/8/8 b - - 100 70',
        '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
        '8/8/4k3/8/8/4K3/8/8 w - - 0 1',
        '8/8/8/4k3/8/8/8/R3K3 w - - 100 70',
      ]) {
        final cubit = create(fen: fen, line: const []);
        await open(cubit);
        expect(cubit.state.technicalFailure, 'terminalCheckpoint');
        noCredit(cubit);
        await cubit.close();
      }
    },
  );

  test('legacy technical completion and whitelist remain unchanged', () async {
    final cubit = create(
      completion: ExerciseCompletion.technicalLine,
      line: [_line.first],
      ports: false,
    );
    await open(cubit);
    await cubit.play(_move('d6c8'));
    expect(cubit.state.phase, ExercisePhase.done);
    expect(cubit.state.earned, 3);
    expect(GameRules.fromFen(cubit.state.fen!)!.isCheckmate, isFalse);
  });

  test('review retains eight legal plies beyond a one-turn PV', () async {
    // Existing rule-test position/shuffle; this asserts replay, not a WDL proof.
    const fen = '8/8/8/4k3/8/8/8/R3K3 w - - 0 1';
    const shuffle = ['e1d1', 'e5d5', 'd1e1', 'd5e5'];
    final trail = await _lessons(
      fen: fen,
      line: const [
        MoveTurn(accept: {'e1d1'}, reply: 'e5d5'),
      ],
    ).trail();
    final exercise = trail.lesson(_lesson)!.exercise('e13')!;
    final played = [...shuffle, ...shuffle];
    final review = ExerciseReview.full(exercise, played);
    expect(review.map((node) => node.uci), played);
    expect(review.length, 8);
    expect(review.every((node) => node.depth == 0), isTrue);
  });

  test('review walks the complete actual game beyond empty or short PV', () {
    final exercise = _lessons(line: const []).trail();
    return exercise.then((trail) {
      final target = trail.lesson(_lesson)!.exercise('e13')!;
      final review = ExerciseReview.full(target, ['d6b5', 'a7a8', 'f1g2']);
      expect(review.map((node) => node.uci), ['d6b5', 'a7a8', 'f1g2']);
      expect(review.last.result, '1–0');
      expect(review.every((node) => node.depth == 0), isTrue);
    });
  });
}
