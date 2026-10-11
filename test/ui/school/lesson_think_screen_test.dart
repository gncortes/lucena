import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:dartchess/dartchess.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
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
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: texts),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: now,
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', locale.languageCode);
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
        find.byKey(LessonKeys.nextButton).hitTestable(),
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

  void expectCentered(WidgetTester tester) {
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(board.center.dx, closeTo(size.width / 2, 1));
    expect(board.center.dy, closeTo(size.height / 2, 1));
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
    expect(avatar.size, 56);
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

  testWidgets('pensar: sem seletor de tempo, o tabuleiro no centro do espaço '
      'livre e o cronômetro no canto de início, contando', (tester) async {
    await pump(tester);
    expect(find.byKey(LessonKeys.scroll), findsOneWidget);
    expect(find.byKey(LessonKeys.prompt), findsNothing);
    expectCentered(tester);
    final board = tester.getRect(find.byKey(LessonKeys.board));
    // O cronômetro no canto inferior direito, do zero.
    final timer = tester.getRect(find.byKey(LessonKeys.stepTimer));
    expect(timer.right, closeTo(400 - 16, 1));
    expect(timer.bottom, greaterThan(board.bottom));
    expect(timerText(tester), '0:00');

    now.advance(const Duration(seconds: 90));
    await tester.pump(const Duration(milliseconds: 300));
    expect(timerText(tester), '1:30');
    // Passar de 6 minutos não muda nada além do cronômetro.
    now.advance(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(timerText(tester), '6:30');
    expect(find.byKey(LessonKeys.scroll), findsOneWidget);
    expect(find.byKey(LessonKeys.moreHintButton), findsOneWidget);
    expect(find.byKey(LessonKeys.nextButton), findsOneWidget);
  });

  testWidgets('em árabe o cronômetro fica no canto de fim: à esquerda', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('ar'));
    final timer = tester.getRect(find.byKey(LessonKeys.stepTimer));
    expect(timer.left, closeTo(16, 1));
    final board = tester.getRect(find.byKey(LessonKeys.board));
    expect(board.center.dx, closeTo(200, 1));
  });

  for (final (locale, scale) in [
    (const Locale('pt'), 1.3),
    (const Locale('de'), 1.3),
    (const Locale('pt'), 1.0),
  ]) {
    testWidgets('pensando, em ${locale.languageCode} com letra ×$scale e 360 '
        'dp: dica, "Ver explicação" e cronômetro cabem', (tester) async {
      const size = Size(360, 780);
      await pump(tester, size: size, locale: locale, scale: scale);
      expect(tester.takeException(), isNull);
      final keys = [
        LessonKeys.moreHintButton,
        LessonKeys.nextButton,
        LessonKeys.stepTimer,
      ];
      for (final key in keys) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$key');
        expect(rect.right, lessThanOrEqualTo(size.width), reason: '$key');
        expect(find.byKey(key).hitTestable(), findsOneWidget, reason: '$key');
      }
      // Os botões da mesma altura.
      for (final key in keys.take(2)) {
        expect(tester.getRect(find.byKey(key)).height, 56, reason: '$key');
      }
      // Lado a lado, sem se cobrir.
      for (var i = 1; i < keys.length; i++) {
        expect(
          tester.getRect(find.byKey(keys[i - 1])).right,
          lessThanOrEqualTo(tester.getRect(find.byKey(keys[i])).left),
          reason: '${keys[i - 1]} / ${keys[i]}',
        );
      }
    });
  }

  testWidgets('a dica e "Ver explicação" funcionam desde o começo; a '
      'explicação leva o tabuleiro para o alto, com a folha da fala', (
    tester,
  ) async {
    await pump(tester);
    final centered = tester.getRect(find.byKey(LessonKeys.board));
    await tester.tap(find.byKey(LessonKeys.moreHintButton));
    await tester.pumpAndSettle();
    expect(find.text('Think about a bridge.'), findsOneWidget);
    expect(find.byKey(LessonKeys.scroll), findsOneWidget);

    await tester.tap(find.byKey(LessonKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.step('rook.lucena', 'try')), findsOneWidget);
    // O passo de lance também se resolve: segue no centro (o enunciado
    // mudou de altura, então o centro também), com o cronômetro do zero.
    expect(find.byKey(LessonKeys.scroll), findsOneWidget);
    expect(timerText(tester), '0:00');
    expectCentered(tester);
    expect(tester.getRect(find.byKey(LessonKeys.board)).width, centered.width);
  });

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
    expect(raised.top, lessThan(centered.top));
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
    expectCentered(tester);
    expect(tester.getRect(find.byKey(LessonKeys.board)).width, centered.width);
    expect(find.byKey(LessonKeys.stepTimer), findsOneWidget);
  });
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    testWidgets(
      'B5 $size: pensar e jogar no centro; explicar sobe o tabuleiro',
      (tester) async {
        final cubit = await pump(tester, size: size, systemBars: true);
        final board = tester.getRect(find.byKey(LessonKeys.board));
        expect(board.center.dy, closeTo((52 + size.height - 24) / 2, 1));
        expect(board.width, greaterThanOrEqualTo(200));
        expect(find.byKey(LessonKeys.prompt), findsNothing);
        expect(
          tester.getRect(find.byKey(LessonKeys.scroll)).top,
          greaterThan(board.bottom),
        );
        expectPeek(tester);
        // Explicando, o tabuleiro sobe com o mesmo tamanho; jogando, volta ao
        // centro.
        void raised() {
          final rect = tester.getRect(find.byKey(LessonKeys.board));
          expect(rect.size, board.size);
          expect(rect.top, lessThan(board.top));
        }

        await cubit.next();
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(LessonKeys.board)), board);
        expectPeek(tester);
        await cubit.play(Move.parse('c1c4')!);
        await tester.pumpAndSettle();
        raised();
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
