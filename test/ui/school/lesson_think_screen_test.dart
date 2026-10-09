import 'package:flutter/material.dart';
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
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: BlocProvider.value(value: cubit, child: const LessonScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  /// O tabuleiro no centro da tela (400 × 800), a não ser que ali ele
  /// cobrisse o enunciado: então logo abaixo dele. Nunca sobre o rodapé.
  void expectCentered(WidgetTester tester) {
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final prompt = tester.getRect(find.byKey(LessonKeys.prompt));
    final footer = tester.getRect(find.byKey(LessonKeys.footer));
    expect(board.center.dx, closeTo(200, 1));
    expect(board.top, greaterThanOrEqualTo(prompt.bottom));
    expect(board.bottom, lessThanOrEqualTo(footer.top));
    if (board.top > prompt.bottom + 8.5) {
      expect(board.center.dy, closeTo(400, 1));
    } else {
      expect(board.center.dy, greaterThan(400));
    }
  }

  String timerText(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(LessonKeys.stepTimer),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('pensar: sem seletor de tempo, o tabuleiro no centro do espaço '
      'livre e o cronômetro no canto de início, contando', (tester) async {
    await pump(tester);
    expect(find.byKey(LessonKeys.scroll), findsNothing);
    expect(find.byKey(LessonKeys.prompt), findsOneWidget);
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
    expect(find.byKey(LessonKeys.scroll), findsNothing);
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
        'dp: cronômetro, dica, voltar à posição e "Ver explicação" cabem', (
      tester,
    ) async {
      const size = Size(360, 780);
      final cubit = await pump(
        tester,
        size: size,
        locale: locale,
        scale: scale,
      );
      // Mexeu numa peça: "Voltar à posição" aparece.
      await cubit.play(Move.parse('c1c3')!);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final keys = [
        LessonKeys.moreHintButton,
        LessonKeys.thinkReset,
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
      for (final key in keys.take(3)) {
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
      await tester.tap(find.byKey(LessonKeys.thinkReset));
      await tester.pumpAndSettle();
      expect(cubit.state.fen, fen);
      expect(find.byKey(LessonKeys.thinkReset), findsNothing);
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
    expect(find.byKey(LessonKeys.scroll), findsNothing);

    await tester.tap(find.byKey(LessonKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.step('rook.lucena', 'try')), findsOneWidget);
    // O passo de lance também se resolve: segue no centro (o enunciado
    // mudou de altura, então o centro também), com o cronômetro do zero.
    expect(find.byKey(LessonKeys.scroll), findsNothing);
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
    final raised = tester.getRect(find.byKey(LessonKeys.board));
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
    expect(find.byKey(LessonKeys.scroll), findsNothing);
    expectCentered(tester);
    expect(tester.getRect(find.byKey(LessonKeys.board)).width, centered.width);
    expect(find.byKey(LessonKeys.stepTimer), findsOneWidget);
  });
}
