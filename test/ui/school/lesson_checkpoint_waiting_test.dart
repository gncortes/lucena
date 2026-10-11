import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  const step = MoveStep(
    id: 'bridge',
    fen: fen,
    line: [
      MoveTurn(accept: {'c1c4'}, reply: 'a2a1'),
      MoveTurn(accept: {'c4c5'}),
    ],
  );
  late FakeSchoolProgressRepository progress;
  late FakeNow now;
  setUp(() {
    progress = FakeSchoolProgressRepository();
    now = FakeNow(DateTime.utc(2026, 10, 11));
  });
  Future<LessonCubit> open(
    LessonStep step, {
    FakeOpponentRepository? opponent,
  }) async {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(
        course: Course(
          modules: [
            CourseModule(
              id: 'pieces',
              lessons: [
                Lesson(id: 'pieces.test', steps: [step]),
              ],
            ),
          ],
        ),
      ),
      progress: progress,
      characters: FakeCharacterRepository(),
      opponent: opponent ?? FakeOpponentRepository(),
      now: now,
      replyDelay: const Duration(milliseconds: 10),
    );
    addTearDown(cubit.close);
    await cubit.load('pieces.test', 'en');
    return cubit;
  }

  test(
    'T65: fechar no delay da resposta restaura FEN e completa a vez',
    () async {
      final first = await open(step);
      final playing = first.play(Move.parse('c1c4')!);
      await Future<void>.delayed(Duration.zero);
      expect(first.state.phase, StepPhase.waiting);
      final waitingFen = first.state.fen;
      await first.pauseForBackground();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(first.state.fen, waitingFen);
      await first.close();
      await playing;
      final restored = await open(step);
      expect(restored.state.phase, StepPhase.waiting);
      expect(restored.state.fen, waitingFen);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(restored.state.phase, StepPhase.active);
      expect(restored.state.turn, 1);
      expect(restored.state.lastMove?.uci, 'a2a1');
      expect(restored.state.fen, isNot(waitingFen));
    },
  );

  test(
    'T65: ThinkStep não abre explicação em fundo e restaura lance pendente',
    () async {
      final think = const ThinkStep(id: 'think', fen: fen);
      final first = await open(think);
      final playing = first.play(Move.parse('c1c4')!);
      await Future<void>.delayed(Duration.zero);
      expect(first.state.phase, StepPhase.waiting);
      await first.pauseForBackground();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(first.state.current?.id, 'think');
      expect(first.state.finished, isFalse);
      final waitingFen = first.state.fen;
      await first.close();
      await playing;
      final restored = await open(think);
      expect(restored.state.fen, waitingFen);
      expect(restored.state.phase, StepPhase.waiting);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(restored.state.finished, isTrue);
    },
  );

  test('T65: partida da aula restaura resposta do motor pendente', () async {
    const playStep = PlayStep(id: 'play', fen: fen);
    final opponent = FakeOpponentRepository()..hold();
    final first = await open(playStep, opponent: opponent);
    final playing = first.play(Move.parse('c1c4')!);
    await pumpEventQueue();
    expect(first.state.phase, StepPhase.waiting);
    await first.pauseForBackground();
    final waitingFen = first.state.fen;
    await first.close();
    opponent.release();
    await playing;
    final restored = await open(playStep);
    await pumpEventQueue();
    expect(restored.state.phase, StepPhase.active);
    expect(restored.state.moves, hasLength(2));
    expect(restored.state.fen, isNot(waitingFen));
  });
}
