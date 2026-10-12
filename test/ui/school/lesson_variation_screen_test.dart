import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Move, Square;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/core/keys/lesson_sound_keys.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/ui/core/keys/explanation_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/domain/use_cases/speech_links.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

class _AuthoredFeedback extends EmptyExerciseFeedbackRepository
    implements ExplanationRepository {
  const _AuthoredFeedback(this.payload);
  final ExplanationPayload payload;
  @override
  Future<ExplanationPayload?> findPayload({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String language,
    required ExplanationState state,
    String? playedUci,
  }) async =>
      (kind == 'talk' && exerciseId == 'intro') ||
          (kind == 'move' && exerciseId == 'bridge')
      ? payload.forState(state, playedUci: playedUci)
      : null;
}

/// A variante citada na fala: o lance tocado mostra a posição e o botão do
/// rodapé anda por ela lance a lance.
void main() {
  const said = 'Play 1.Rd1+ Ke7 2.Rd4 and the rook shields the king.';

  Future<LessonCubit> pump(
    WidgetTester tester,
    String intro, {
    ExerciseFeedbackRepository? feedback,
    SpeechCubit? speechCubit,
    String? movePrompt,
  }) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          texts: LessonTexts.fromJson({
            ...FakeEndgameLessonRepository.sampleTexts.toJson(),
            'rook.lucena.intro': intro,
            'rook.lucena.bridge': ?movePrompt,
          }),
        ),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      feedback: feedback,
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        speechCubit: speechCubit,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  String fen(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(LessonKeys.board))
      .controller
      .game
      .fen;

  Future<void> tapText(WidgetTester tester, String move) async {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(LessonKeys.speech),
        matching: find.byType(RichText),
      ),
    );
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: said.indexOf(move) + 1),
      Rect.zero,
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 8)));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('tocar num lance da linha mostra a posição com ele jogado e '
      'tocar de novo volta ao passo', (tester) async {
    await pump(tester, said);
    final start = fen(tester);
    expect(start, startsWith('1K1k4/1P6/8/8/8/8/r7/2R5'));
    await tapText(tester, 'Ke7');
    // Depois de 1.Rd1+ Ke7: a torre em d1, o rei preto em e7.
    expect(fen(tester), startsWith('1K6/1P2k3/8/8/8/8/r7/3R4'));
    expect(find.byKey(LessonKeys.variationExit), findsOneWidget);
    await tapText(tester, 'Ke7');
    expect(fen(tester), start);
    expect(find.byKey(LessonKeys.variationExit), findsNothing);
  });

  testWidgets('o lance no texto abre a variante e as setas andam por ela', (
    tester,
  ) async {
    final cubit = await pump(tester, said);
    final originalStep = cubit.state.step;
    final originalReached = cubit.state.reached;
    final start = fen(tester);
    expect(find.byKey(LessonKeys.variationShow), findsNothing);
    await tapText(tester, 'Rd1+');
    // O primeiro lance já jogado.
    expect(fen(tester), startsWith('1K1k4/1P6/8/8/8/8/r7/3R4'));
    // A linha deste passo não é a errada: sem o selo.
    expect(find.byKey(LessonKeys.wrongLine), findsNothing);
    await press(tester, LessonKeys.variationForward);
    await press(tester, LessonKeys.variationForward);
    expect(fen(tester), startsWith('1K6/1P2k3/8/8/3R4/8/r7/8'));
    // No fim, a seta de próximo lance desliga.
    expect(
      tester
          .widget<FloatingActionButton>(find.byKey(LessonKeys.variationForward))
          .onPressed,
      isNull,
    );
    await press(tester, LessonKeys.variationBack);
    expect(fen(tester), startsWith('1K6/1P2k3/8/8/8/8/r7/3R4'));
    await press(tester, LessonKeys.variationExit);
    expect(fen(tester), start);
    expect(find.byKey(LessonKeys.variationShow), findsNothing);
    expect(cubit.state.step, originalStep);
    expect(cubit.state.reached, originalReached);
  });

  testWidgets('fala sem variante: sem o botão', (tester) async {
    await pump(tester, 'This is the Lucena position.');
    expect(find.byKey(LessonKeys.variationShow), findsNothing);
  });

  testWidgets('long speech remains readable behind the elapsed timer', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final cubit = await pump(
      tester,
      said,
      movePrompt: List.filled(30, 'Build the bridge.').join(' '),
    );
    await cubit.next();
    await tester.pumpAndSettle();
    final timer = find.byKey(LessonKeys.stepTimer);
    expect(timer, findsOneWidget);
    final material = tester.widget<Material>(
      find.ancestor(of: timer, matching: find.byType(Material)).first,
    );
    expect(material.color?.a, 1);
    expect(
      tester.getRect(timer).overlaps(
        tester.getRect(find.byKey(LessonKeys.hintButton)),
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lesson header opens dedicated sound panel and mute survives the next step',
    (tester) async {
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true, charactersMuted: true),
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      final cubit = await pump(tester, said, speechCubit: speech);
      expect(voice.spoken, isNotEmpty);
      await press(tester, VoiceKeys.speakButton);
      expect(find.byKey(LessonSoundKeys.dialog), findsOneWidget);
      expect(find.text("Viktor's voice"), findsOneWidget);
      await press(tester, LessonSoundKeys.speed(1.5));
      expect(voice.settings.speed, 1.5);
      await press(tester, LessonSoundKeys.sound);
      expect(speech.state.speaking, isNull);
      final count = voice.spoken.length;
      expect(voice.settings.enabled, isTrue);
      expect(voice.settings.charactersMuted, isTrue);
      await press(tester, LessonSoundKeys.close);
      await cubit.next();
      await tester.pumpAndSettle();
      expect(voice.spoken, hasLength(count));
      await press(tester, VoiceKeys.speakButton);
      expect(
        tester.widget<Switch>(find.byKey(LessonSoundKeys.sound)).value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(find.byKey(LessonSoundKeys.teacherVoice))
            .value,
        isTrue,
      );
      expect(find.byKey(LessonSoundKeys.speeds), findsNothing);
      await press(tester, LessonSoundKeys.close);
    },
  );

  testWidgets(
    'authored replay switches origins and returns without changing lesson progress',
    (tester) async {
      final primary = ExplanationVariation(
        id: 'main',
        label: '1.Rd1+',
        outcome: VariationOutcome.accepted,
        texts: ['The rook checks before making a shield.'],
        originFen: '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
        movesUci: ['c1d1', 'd8e7', 'd1d4'],
        movesSan: ['1.Rd1+', '1...Ke7', '2.Rd4'],
        validated: true,
      );
      final secondary = ExplanationVariation(
        id: 'reply',
        label: '1...Ke7',
        outcome: VariationOutcome.accepted,
        texts: ['The king leaves the file.'],
        originFen: primary.open()!.fen,
        movesUci: ['d8e7', 'd1d4'],
        movesSan: ['1...Ke7', '2.Rd4'],
        validated: true,
      );
      final payload = ExplanationPayload(
        positionId: 'intro',
        state: ExplanationState.review,
        explanations: [
          ExplanationBlock(
            id: 'main',
            kind: ExplanationKind.mainSolution,
            variations: [primary, secondary],
          ),
        ],
      );
      final cubit = await pump(
        tester,
        said,
        feedback: _AuthoredFeedback(payload),
      );
      final snapshot = cubit.state;
      final start = fen(tester);
      await tester.drag(find.byKey(LessonKeys.scroll), const Offset(0, -700));
      await tester.pumpAndSettle();
      Future<void> select(String id) async {
        await tester.ensureVisible(find.byKey(ExplanationKeys.variation(id)));
        await tester.tap(find.byKey(ExplanationKeys.variation(id)));
        await tester.pumpAndSettle();
      }

      await select('main');
      expect(fen(tester), primary.open()!.fen);
      expect(identical(cubit.state, snapshot), isTrue);
      await tester.ensureVisible(find.byKey(ExplanationKeys.last));
      await press(tester, ExplanationKeys.last);
      expect(fen(tester), primary.open()!.at(3).fen);
      tester.widget<TeacherSpeech>(find.byType(TeacherSpeech).last).onSpoken!(
        const SpeechLink(start: 0, end: 2, text: 'd4', square: Square.d4),
      );
      await tester.pump();
      final highlighted = tester.widget<Chessboard>(
        find.byKey(LessonKeys.board),
      );
      expect(
        highlighted.shapes.whereType<CustomShape>().single.orig,
        Square.d4,
      );
      expect(identical(cubit.state, snapshot), isTrue);
      await select('reply');
      expect(fen(tester), secondary.open()!.fen);
      expect(identical(cubit.state, snapshot), isTrue);
      await tester.ensureVisible(find.byKey(ExplanationKeys.restore));
      await press(tester, ExplanationKeys.restore);
      expect(fen(tester), start);
      expect(identical(cubit.state, snapshot), isTrue);
    },
  );
  testWidgets(
    'single-ply child returns to its parent origin separately from the lesson',
    (tester) async {
      const origin = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
      final parent = ExplanationVariation(
        id: 'A',
        label: 'A',
        outcome: VariationOutcome.accepted,
        texts: ['Advance the pawn two squares.'],
        originFen: origin,
        movesUci: ['d2d4'],
        movesSan: ['1.d4'],
        validated: true,
      );
      final child = ExplanationVariation(
        id: 'A.1',
        label: 'A.1',
        parentId: 'A',
        parentPly: 0,
        outcome: VariationOutcome.accepted,
        texts: ['Advance the pawn one square.'],
        originFen: origin,
        movesUci: ['d2d3'],
        movesSan: ['1.d3'],
        validated: true,
      );
      final payload = ExplanationPayload(
        positionId: 'intro',
        state: ExplanationState.review,
        explanations: [
          ExplanationBlock(
            id: 'main',
            kind: ExplanationKind.mainSolution,
            variations: [parent, child],
          ),
        ],
      );
      final cubit = await pump(
        tester,
        'Explore the alternatives.',
        feedback: _AuthoredFeedback(payload),
      );
      final snapshot = cubit.state;
      final lessonFen = fen(tester);
      expect(lessonFen, isNot(origin));
      Future<void> activate(Key key) async {
        await tester.ensureVisible(find.byKey(key));
        await press(tester, key);
      }

      await activate(ExplanationKeys.variation('A'));
      expect(fen(tester), parent.open()!.fen);
      await activate(ExplanationKeys.variation('A.1'));
      expect(fen(tester), child.open()!.fen);
      expect(find.byKey(ExplanationKeys.first), findsNothing);
      await activate(ExplanationKeys.parent);
      expect(fen(tester), payload.parentCursor(child)!.fen);
      expect(fen(tester), origin);
      expect(find.byKey(ExplanationKeys.parent), findsNothing);
      expect(identical(cubit.state, snapshot), isTrue);
      await activate(ExplanationKeys.restore);
      expect(fen(tester), lessonFen);
      expect(identical(cubit.state, snapshot), isTrue);
    },
  );
  testWidgets(
    'interactive lesson shows authored context then error before the solution',
    (tester) async {
      ExplanationVariation variant(
        String id,
        String uci,
        String text,
        VariationOutcome outcome,
      ) => ExplanationVariation(
        id: id,
        label: uci == 'c1c4' ? '1.Rc4' : '1.Rd1+',
        outcome: outcome,
        texts: [text],
        originFen: FakeEndgameLessonRepository.lucenaFen,
        movesUci: [uci],
        movesSan: [uci],
        validated: true,
      );
      final payload = ExplanationPayload(
        positionId: 'bridge',
        state: ExplanationState.review,
        explanations: [
          ExplanationBlock(
            id: 'context',
            kind: ExplanationKind.context,
            texts: ['The task is to reach the fourth rank.'],
          ),
          ExplanationBlock(
            id: 'main',
            kind: ExplanationKind.mainSolution,
            texts: ['The rook reaches the fourth rank.'],
            variations: [
              variant(
                'correct',
                'c1c4',
                'The rook reaches the fourth rank.',
                VariationOutcome.accepted,
              ),
            ],
          ),
          ExplanationBlock(
            id: 'failed',
            kind: ExplanationKind.failedAlternatives,
            variations: [
              variant(
                'incorrect',
                'c1d1',
                'This keeps the rook on the first rank.',
                VariationOutcome.doesNotMeetGoal,
              ),
            ],
          ),
        ],
      );
      final cubit = await pump(
        tester,
        said,
        feedback: _AuthoredFeedback(payload),
      );
      await cubit.next();
      await tester.pumpAndSettle();
      expect(cubit.state.layout, LessonLayoutMode.solving);
      expect(
        find.textContaining(
          'The task is to reach the fourth rank.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.byKey(ExplanationKeys.variation('correct')), findsNothing);
      await tester.runAsync(() => cubit.play(Move.parse('c1d1')!));
      await tester.pumpAndSettle();
      expect(cubit.state.layout, LessonLayoutMode.solving);
      expect(find.byKey(ExplanationKeys.block('played')), findsOneWidget);
      expect(find.byKey(ExplanationKeys.variation('correct')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(ExplanationKeys.block('played'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(ExplanationKeys.block('main'))).dy,
        ),
      );
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.turn, 0);
      expect(cubit.state.fen, FakeEndgameLessonRepository.lucenaFen);
    },
  );
}
