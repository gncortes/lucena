import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:dartchess/dartchess.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/sheet_settle.dart';
import '../../../testing/test_app.dart';

/// T60: o modo exercício da lição. Resolvendo, o enunciado curto em cima, o
/// tabuleiro no centro e o cronômetro (contando para cima) no canto de
/// início do rodapé; respondido o passo, o tabuleiro sobe e a folha da fala
/// entra.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lesson = Lesson.parted(
    id: 'rook.lucena',
    parts: const [
      LessonPart(
        id: 'bridge',
        steps: [
          ThinkStep(id: 'think', fen: fen),
          MoveStep(
            id: 'try',
            fen: fen,
            line: [
              MoveTurn(accept: {'c1c4'}),
            ],
          ),
          TalkStep(id: 'end', fen: fen),
        ],
      ),
    ],
  );
  final trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: lesson,
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  );
  final texts = LessonTexts.fromJson({
    'rook.lucena.think': 'Where should the rook go?',
    'rook.lucena.think.hint1': 'Think about a bridge.',
    'rook.lucena.try': 'Now you: build the bridge.',
    'rook.lucena.try.done': 'Perfect, that is the bridge.',
    'rook.lucena.try.hint': 'No.',
    'rook.lucena.end': 'That is all.',
  });

  late FakeNow now;

  setUp(() => now = FakeNow(DateTime.utc(2026, 10, 9, 20)));

  Future<LessonCubit> pump(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    Locale locale = const Locale('en'),
    double scale = 1.0,
    bool systemBars = false,
    bool reducedMotion = false,
    ExerciseFeedbackRepository? feedback,
    LessonTexts? promptTexts,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: promptTexts ?? texts),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      feedback: feedback,
      opponent: FakeOpponentRepository(),
      now: now,
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', locale.languageCode);
    await cubit.startStepClock();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: systemBars
                  ? const EdgeInsets.only(top: 52, bottom: 24)
                  : EdgeInsets.zero,
              viewPadding: systemBars
                  ? const EdgeInsets.only(top: 52, bottom: 24)
                  : EdgeInsets.zero,
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion,
            ),
            child: BlocProvider.value(
              value: cubit,
              child: const LessonScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A folha abre sozinha com o texto novo e recolhe depois do tempo de
    // leitura: o teste parte dela recolhida.
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('B5: trocar o passo recolhe a folha com movimento reduzido', (
    tester,
  ) async {
    final cubit = await pump(tester, reducedMotion: true);
    await tester.tapAt(
      tester.getTopLeft(find.byKey(LessonKeys.scroll)) + const Offset(40, 12),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.closeSheet).hitTestable(), findsOneWidget);
    cubit.next();
    await tester.pumpAndSettle();
    expect(cubit.state.step, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('B5: recolhida mantém ações após alterar altura da tela', (
    tester,
  ) async {
    await pump(tester, systemBars: true);
    for (final height in [640.0, 800.0, 915.0, 800.0]) {
      tester.view.physicalSize = Size(360, height);
      await tester.pumpAndSettle();
      expect(
        find.byKey(LessonKeys.footer).hitTestable(),
        findsOneWidget,
        reason: 'altura=$height',
      );
      expect(find.byKey(LessonKeys.closeSheet).hitTestable(), findsNothing);
      expect(
        tester.getRect(find.byKey(LessonKeys.scroll)).top,
        greaterThan(tester.getRect(find.byKey(LessonKeys.board)).bottom),
        reason: 'a folha recolhida não cobre o tabuleiro; altura=$height',
      );
      expect(tester.takeException(), isNull);
    }
  });

  Future<void> expectBoardAboveSpeech(WidgetTester tester) async {
    await settleSheet(tester);
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(board.center.dx, closeTo(size.width / 2, 1));
    final progress = tester.getRect(find.byKey(LessonKeys.progress));
    expect(board.top, greaterThanOrEqualTo(progress.bottom));
    expect(board.top - progress.bottom, lessThanOrEqualTo(20));
    final teacher = find.byWidgetPredicate(
      (widget) =>
          widget is TeacherSpeech && widget.part != TeacherSpeechPart.bubble,
    );
    expect(tester.getTopLeft(teacher).dy, greaterThan(board.bottom));
    expect(find.byKey(LessonKeys.prompt), findsNothing);
    expect(
      tester.getRect(find.byKey(LessonKeys.scroll)).top,
      greaterThan(board.bottom),
    );
  }

  void expectPeek(WidgetTester tester) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(LessonKeys.speech),
    );
    final first = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first;
    final bottom = paragraph.localToGlobal(Offset(0, first.bottom)).dy;
    expect(
      bottom,
      lessThanOrEqualTo(tester.getRect(find.byKey(LessonKeys.footer)).top),
    );
    final avatar = tester.widget<CharacterAvatar>(
      find.byType(CharacterAvatar).first,
    );
    expect(avatar.size, 28);
  }

  String timerText(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(LessonKeys.stepTimer),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('T65: lifecycle congela timer, lance e fala e retoma', (
    tester,
  ) async {
    final cubit = await pump(tester);
    await cubit.next();
    await cubit.startStepClock();
    await tester.pumpAndSettle();
    final fen = cubit.state.fen;
    final speech = cubit.state.speech;
    now.advance(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    now.advance(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(timerText(tester), '0:07');
    expect(cubit.state.fen, fen);
    expect(cubit.state.speech, speech);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    now.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(timerText(tester), '0:09');
  });

  testWidgets(
    'pensar: o tabuleiro no centro do espaço livre e a folha abaixo',
    (tester) async {
      await pump(tester);
      expect(find.byKey(LessonKeys.scroll), findsOneWidget);
      expect(find.byKey(LessonKeys.prompt), findsNothing);
      await expectBoardAboveSpeech(tester);
      // T70: sem Dica, sem "Ver explicação" e sem cronômetro no pensar.
      expect(find.byKey(LessonKeys.moreHintButton), findsNothing);
      expect(find.byKey(LessonKeys.nextButton), findsNothing);
      expect(find.byKey(LessonKeys.stepTimer), findsNothing);
      expect(find.byKey(LessonKeys.showAnswerLink), findsOneWidget);
    },
  );

  testWidgets('a fala do enunciado encolhe no meio do passo (lance errado): '
      'o tabuleiro não sai do lugar', (tester) async {
    final cubit = await pump(tester);
    await cubit.next();
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(LessonKeys.board));
    await cubit.play(Move.parse('c1c2')!);
    await tester.pumpAndSettle();
    expect(find.text('No.'), findsOneWidget);
    expect(tester.getRect(find.byKey(LessonKeys.board)), before);
  });

  testWidgets('respondido o passo de lance: o cronômetro para, o tabuleiro '
      'sobe e o Viktor fala na folha', (tester) async {
    final cubit = await pump(tester);
    await cubit.next();
    await tester.pumpAndSettle();
    final centered = tester.getRect(find.byKey(LessonKeys.board));
    now.advance(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 300));
    expect(timerText(tester), '0:20');

    await cubit.play(Move.parse('c1c4')!);
    await tester.pump();
    // Durante a transição, o cronômetro fica parado no tempo final.
    now.advance(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 100));
    expect(timerText(tester), '0:20');
    await tester.pumpAndSettle();

    expect(find.byKey(LessonKeys.stepTimer), findsNothing);
    expect(find.byKey(LessonKeys.prompt), findsNothing);
    // Explicando, o tabuleiro sobe (mesmo tamanho) e a folha fica com o resto.
    final raised = tester.getRect(find.byKey(LessonKeys.board));
    expect(raised.size, centered.size);
    expect(raised.top, closeTo(centered.top, 1));
    await settleSheet(tester);
    expect(find.byKey(LessonKeys.scroll), findsOneWidget);
    expect(find.text('Perfect, that is the bridge.'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(LessonKeys.speech)).top,
      greaterThan(raised.bottom),
    );

    // Voltar um passo (o de pensar): o caminho inverso, o tabuleiro desce ao
    // centro e a folha sai.
    await tester.tap(find.byKey(LessonKeys.backButton));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.step('rook.lucena', 'think')), findsOneWidget);
    expect(find.byKey(LessonKeys.scroll), findsOneWidget);
    await expectBoardAboveSpeech(tester);
    expect(tester.getRect(find.byKey(LessonKeys.board)).width, centered.width);
    expect(find.byKey(LessonKeys.stepTimer), findsNothing);
  });
  for (final size in [
    const Size(360, 640),
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets(
      'D15 $size: pensar, jogar e explicar mantêm tabuleiro acima do Viktor',
      (tester) async {
        final cubit = await pump(tester, size: size, systemBars: true);
        final board = tester.getRect(find.byKey(LessonKeys.board));
        await expectBoardAboveSpeech(tester);
        expect(board.width, greaterThanOrEqualTo(200));
        expect(find.byKey(LessonKeys.prompt), findsNothing);
        expect(
          tester.getRect(find.byKey(LessonKeys.scroll)).top,
          greaterThan(board.bottom),
        );
        // Explicando, o tabuleiro sobe com o mesmo tamanho; jogando, volta ao
        // centro.
        Future<void> raised() async {
          final rect = tester.getRect(find.byKey(LessonKeys.board));
          expect(rect.size, board.size);
          expect(rect.top, closeTo(board.top, 1));
          await expectBoardAboveSpeech(tester);
        }

        await cubit.next();
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(LessonKeys.board)), board);
        expectPeek(tester);
        await cubit.play(Move.parse('c1c4')!);
        await tester.pumpAndSettle();
        await raised();
        expect(
          tester.getRect(find.byKey(LessonKeys.scroll)).top,
          greaterThan(tester.getRect(find.byKey(LessonKeys.board)).bottom),
        );
        expectPeek(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
