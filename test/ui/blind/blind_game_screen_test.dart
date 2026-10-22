import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';
import 'package:lucena/ui/blind/widgets/blind_game_screen.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/core/theme/app_icon_size.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_blind_log_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speech_input_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSpeechInputRepository input;
  late BlindGameCubit cubit;

  Future<void> pump(
    WidgetTester tester, {
    bool permitted = true,
    Size size = const Size(400, 900),
    bool systemBars = false,
    TextDirection direction = TextDirection.ltr,
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('en'),
    double textScale = 1,
    String fen = '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
    ClockConfig? clock,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    if (systemBars) {
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 32);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 32);
    }
    input = FakeSpeechInputRepository(permitted: permitted, grants: false);
    cubit = BlindGameCubit(
      restartDelay: Duration.zero,
      releaseWait: Duration.zero,
      opponent: FakeOpponentRepository(),
      voice: FakeVoiceRepository()..autoFinish = true,
      input: input,
      log: FakeBlindLogRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 7)),
      thinkTime: Duration.zero,
    );
    addTearDown(cubit.close);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await cubit.load(
      fen: fen,
      userSide: Side.white,
      kind: OpponentKind.maia,
      level: 1000,
      language: 'en-US',
      phrases: blindPhrases(l10n),
      clock: clock,
    );
    await cubit.start();
    await cubit.release();
    // No fim, a conclusão abre no lugar da partida.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Directionality(
            textDirection: direction,
            child: BlocProvider.value(
              value: cubit,
              child: const BlindGameScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final args = state.extra! as ConclusionArgs;
            return Scaffold(
              body: Text(
                'conclusion ${args.conclusion.result.name} '
                '${args.conclusion.blindMoves}',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: themeMode,
        settingsCubit: settings,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets('seletor do canvas 111×36 tem três alvos em $direction', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await pump(tester, direction: direction);
        final picker = find.byType(SegmentedButton<BlindView>);
        expect(tester.getSize(picker), const Size(111, 36));
        expect(
          tester
              .widget<Icon>(find.byKey(BlindKeys.view(BlindView.hidden)))
              .icon,
          Icons.visibility_off_outlined,
        );
        for (final view in BlindView.values) {
          final icon = find.byKey(BlindKeys.view(view));
          final node = tester.getSemantics(icon);
          expect(node.rect.size, const Size(37, 36));
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          tester
              .renderObject(icon)
              .owner!
              .semanticsOwner!
              .performAction(node.id, SemanticsAction.tap);
          await tester.pumpAndSettle();
          expect(cubit.state.view, view);
          for (final dx in [-15.0, 15.0]) {
            cubit.setView(
              view == BlindView.board ? BlindView.hidden : BlindView.board,
            );
            await tester.pumpAndSettle();
            await tester.tapAt(tester.getCenter(icon) + Offset(dx, 0));
            await tester.pumpAndSettle();
            expect(cubit.state.view, view);
          }
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final mode in [ThemeMode.light]) {
    testWidgets('barra e ícones de voz seguem paleta Canvas em $mode', (
      tester,
    ) async {
      await pump(tester, themeMode: mode);
      final action = find.byKey(BlindKeys.narratePosition);
      final colors = Theme.of(tester.element(action)).colorScheme;
      final frame = tester
          .widgetList<DecoratedBox>(
            find.ancestor(of: action, matching: find.byType(DecoratedBox)),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .singleWhere(
            (box) =>
                box.boxShadow?.any((shadow) => shadow.blurRadius == 12) ??
                false,
          );
      expect(frame.color, Colors.white);
      for (final key in [
        BlindKeys.narratePosition,
        BlindKeys.narrateGame,
        BlindKeys.copyLog,
      ]) {
        final chip = tester.widget<ActionChip>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(ActionChip),
          ),
        );
        expect((chip.avatar! as Icon).color, colors.onSurfaceVariant);
        expect(tester.getSize(find.byKey(key)).height, 28);
      }
      final icon = tester.widget<Icon>(
        find.descendant(of: action, matching: find.byType(Icon)),
      );
      expect(icon.icon, Icons.hearing_outlined);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'fonte 2 no piso mantém dica completa e chips sem corte vertical',
    (tester) async {
      await pump(
        tester,
        size: const Size(360, 740),
        textScale: 2,
        locale: const Locale('pt'),
      );
      final hint = find.byKey(BlindKeys.hint);
      final text = tester.widget<Text>(hint).data!;
      expect(text, tester.element(hint).l10n.blindMicHint);
      void expectTextFits(Finder finder) {
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        final data = paragraph.text.toPlainText();
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: data.length),
        );
        expect(boxes, isNotEmpty);
        for (final box in boxes) {
          expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 1));
        }
      }

      expectTextFits(hint);
      expectTextFits(
        find.descendant(
          of: find.byKey(BlindKeys.narratePosition),
          matching: find.byType(Text),
        ),
      );
      expect(find.byKey(BlindKeys.mic), findsOneWidget);
      final boardBeforeProposal = tester.getRect(
        find.byKey(BlindKeys.emptyBoard),
      );
      final audioHeight = tester
          .getSize(
            find.ancestor(of: hint, matching: find.byType(SizedBox)).first,
          )
          .height;
      await tester.tap(find.byKey(BlindKeys.mic));
      await tester.pump(const Duration(milliseconds: 600));
      input.hear(['rook a7']);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(BlindKeys.mic));
      await tester.pumpAndSettle();
      expect(find.byKey(BlindKeys.proposal), findsOneWidget);
      expect(
        tester.getRect(find.byKey(BlindKeys.emptyBoard)),
        boardBeforeProposal,
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byKey(BlindKeys.reRecord),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .height,
        audioHeight,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets('proposta em $direction usa botões 44 e margem final 6', (
      tester,
    ) async {
      await pump(tester, direction: direction);
      await tester.tap(find.byKey(BlindKeys.mic));
      await tester.pump(const Duration(milliseconds: 600));
      input.hear(['rook a7']);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(BlindKeys.mic));
      await tester.pumpAndSettle();
      for (final key in [
        BlindKeys.reject,
        BlindKeys.confirm,
        BlindKeys.sayProposal,
      ]) {
        expect(tester.getSize(find.byKey(key)), const Size.square(44));
      }
      final pillFinder = find
          .ancestor(
            of: find.byKey(BlindKeys.proposal),
            matching: find.byType(Container),
          )
          .first;
      final pill = tester.getRect(pillFinder);
      final reject = tester.getRect(find.byKey(BlindKeys.reject));
      final speaker = tester.getRect(find.byKey(BlindKeys.sayProposal));
      if (direction == TextDirection.ltr) {
        expect(pill.left - reject.right, 8);
        expect(pill.right - speaker.right, 8);
      } else {
        expect(reject.left - pill.right, 8);
        expect(speaker.left - pill.left, 8);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('painel pinta 164/160 dp com reserva estável para o tabuleiro', (
    tester,
  ) async {
    await pump(tester, size: const Size(360, 740));
    final surface = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          ((widget.decoration as BoxDecoration).boxShadow?.any(
                (shadow) => shadow.blurRadius == 12,
              ) ??
              false),
    );
    final board = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    final idle = tester.getRect(surface);
    expect(idle.height, 164);
    expect(idle.bottom, 740);
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump(const Duration(milliseconds: 600));
    input.hear(['rook a7']);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    final proposal = tester.getRect(surface);
    expect(proposal.height, 160);
    expect(proposal.bottom, idle.bottom);
    expect(tester.getRect(find.byKey(BlindKeys.emptyBoard)), board);
    expect(
      tester.getSize(find.byKey(BlindKeys.sayProposal)),
      const Size.square(44),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ação semântica do microfone inicia e envia a gravação', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pump(tester);
      void activate() {
        final mic = find.byKey(BlindKeys.mic);
        final node = tester.getSemantics(mic);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester
            .renderObject(mic)
            .owner!
            .semanticsOwner!
            .performAction(node.id, SemanticsAction.tap);
      }

      activate();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(BlindKeys.recording), findsOneWidget);
      input.hear(['rook a7']);
      await tester.pump(const Duration(milliseconds: 100));
      activate();
      await tester.pumpAndSettle();
      expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('X externo cancela a desistência e preserva a partida', (
    tester,
  ) async {
    await pump(tester);
    final before = cubit.state.position!.fen;
    await tester.tap(find.byKey(BlindKeys.resign));
    await tester.pumpAndSettle();
    final close = find.byTooltip('Close');
    expect(tester.getSize(close), const Size.square(40));
    expect(
      tester.getRect(close).bottom,
      lessThan(tester.getRect(find.byKey(SheetKeys.surface)).top),
    );
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byKey(SheetKeys.surface), findsNothing);
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.position!.fen, before);
  });

  testWidgets('X externo recusa permissão sem solicitá-la', (tester) async {
    await pump(tester, permitted: false);
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.text('Use the microphone?'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(cubit.state.mic, MicPermission.denied);
    expect(input.requests, 0);
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(find.byKey(BlindKeys.board), findsOneWidget);
  });

  testWidgets('X externo permanece à direita em RTL', (tester) async {
    await pump(tester, direction: TextDirection.rtl);
    await tester.tap(find.byKey(BlindKeys.resign));
    await tester.pumpAndSettle();
    final close = find.byTooltip('Close');
    expect(tester.getSize(close), const Size.square(40));
    expect(
      tester.getCenter(close).dx,
      greaterThan(tester.getCenter(find.byKey(SheetKeys.surface)).dx),
    );
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(cubit.state.phase, BlindPhase.playerTurn);
  });

  testWidgets('X externo cancela escolha ambígua sem jogar', (tester) async {
    await pump(tester, fen: '4k3/8/8/8/8/R6R/8/4K3 w - - 0 1');
    final before = cubit.state.position!.fen;
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump(const Duration(milliseconds: 600));
    input.hear(['rook f3']);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.byKey(SheetKeys.surface), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(SheetKeys.surface), findsNothing);
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.position!.fen, before);
  });

  testWidgets('a vez do jogador, só as casas; o microfone escuta e o lance '
      'dito é jogado', (tester) async {
    await pump(tester);
    expect(find.text('Your move'), findsOneWidget);
    expect(find.byKey(BlindKeys.board), findsNothing);

    // Segura para falar; soltar envia.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    // Gravando: o tempo e as ondas no balão.
    expect(find.byKey(BlindKeys.recording), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    input.hear(['rook a7']);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    // Só a torre vai a a7: o app propõe e espera o "sim".
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    await tester.tap(find.byKey(BlindKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.status), findsOneWidget);
    expect(find.text('Your move'), findsOneWidget);
    // O lance da máquina pode ser ouvido de novo.
    expect(find.text('Hear again'), findsOneWidget);
  });

  testWidgets('não entendeu: o recado fica junto do microfone', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    input.hear(['good morning']);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    // O recado sobe num aviso no topo; o balão continua no convite.
    expect(find.byKey(BlindKeys.toast), findsOneWidget);
    expect(find.textContaining('good morning'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(BlindKeys.hint)).data,
      'Tap or hold to talk',
    );
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
    testWidgets('B6b $size: vão igual nas vistas e ao confirmar fala', (
      tester,
    ) async {
      await pump(tester, size: size, systemBars: true);
      final before = tester.getRect(find.byKey(BlindKeys.emptyBoard));
      // T73, D2: a barra tem ação, então o título fica à esquerda.
      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isFalse);
      expect(
        tester.getCenter(find.byType(SegmentedButton<BlindView>)).dx,
        closeTo(size.width / 2, 1),
      );
      expectEqualGaps(tester);
      expect(before.width, greaterThanOrEqualTo(120));
      await tester.tap(find.byKey(BlindKeys.view(BlindView.board)));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(BlindKeys.board)), before);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(BlindKeys.mic)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      input.hear(['rook a7']);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(BlindKeys.proposal), findsOneWidget);
      expectEqualGaps(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(412, 917),
    const Size(414, 896),
  ]) {
    testWidgets('Canvas $size: largura disponível, cantos retos e vão igual', (
      tester,
    ) async {
      await pump(tester, size: size);
      final emptyFinder = find.byKey(BlindKeys.emptyBoard);
      final before = tester.getRect(emptyFinder);
      final position = tester.widget<PositionBoard>(
        find.descendant(of: emptyFinder, matching: find.byType(PositionBoard)),
      );
      expect(position.radius, 0);
      expect(position.orientation, Side.white);
      expect(position.coordinates, isTrue);
      expect(before.center.dx, size.width / 2);
      expectEqualGaps(tester);
      expect(
        tester.getRect(find.byKey(BlindKeys.status)).top - before.bottom,
        closeTo(8, 0.1),
      );
      // No piso a altura do painel limita o lado. Nas demais resoluções,
      // o tabuleiro usa a largura toda, sem a margem antiga de 16 dp.
      expect(before.width, greaterThan(size.width - 32));
      expect(before.width, lessThanOrEqualTo(size.width));
      if (size.height >= 800) expect(before.width, closeTo(size.width, 1));
      // A barra de topo é a padrão de 56 (E1.08, D21).
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
      await tester.tap(find.byKey(BlindKeys.view(BlindView.board)));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(BlindKeys.board)), before);
      await tester.tap(find.byKey(BlindKeys.view(BlindView.empty)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BlindKeys.mic));
      await tester.pump();
      input.hear(['rook a7']);
      await tester.pump();
      await tester.tap(find.byKey(BlindKeys.mic));
      await tester.pumpAndSettle();
      expect(find.byKey(BlindKeys.proposal), findsOneWidget);
      expect(tester.getRect(emptyFinder), before);
      expect(
        tester.getRect(find.byKey(BlindKeys.status)).top - before.bottom,
        closeTo(8, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('vista oculta preserva raio 16 e centro', (tester) async {
    await pump(tester);
    final before = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    await tester.tap(find.byKey(BlindKeys.view(BlindView.hidden)));
    await tester.pumpAndSettle();
    final hidden = find
        .ancestor(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is Icon &&
                widget.icon == Icons.visibility_off_outlined &&
                widget.size == AppIconSize.illustration,
          ),
          matching: find.byType(Card),
        )
        .first;
    // O raio 16 vem do cartão do tema.
    expect(tester.getRect(hidden), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('T65: o bloco seletor + tabuleiro + "Sua vez" no centro do '
      'espaço entre a barra do app e o painel de baixo', (tester) async {
    await pump(tester);
    final appBar = tester.getRect(find.byType(AppBar));
    final area = tester.getRect(find.byKey(BlindKeys.boardArea));
    expect(area.top, appBar.bottom);
    final empty = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    expectEqualGaps(tester);
    expect(
      tester.getRect(find.byKey(BlindKeys.status)).top,
      greaterThanOrEqualTo(empty.bottom),
    );
    await tester.tap(find.byKey(BlindKeys.view(BlindView.board)));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(BlindKeys.board)), empty);
    expectEqualGaps(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o tabuleiro com as peças aceita o toque', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.view(BlindView.board)));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.board), findsOneWidget);
  });

  testWidgets('sem microfone: a explicação antes do pedido; recusar deixa o '
      'toque e o aviso', (tester) async {
    await pump(tester, permitted: false);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Use the microphone?'), findsOneWidget);
    await tester.tap(find.byKey(BlindKeys.micDeny));
    await tester.pumpAndSettle();
    expect(
      find.text('No microphone: play by tapping the board.'),
      findsOneWidget,
    );
    expect(find.byKey(BlindKeys.board), findsOneWidget);
  });

  testWidgets('um toque rápido abre a gravação sem segurar: descartar e '
      'enviar nos botões, e o lance aparece escrito para confirmar', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump();
    expect(find.byKey(BlindKeys.recording), findsOneWidget);
    expect(find.byKey(BlindKeys.discard), findsOneWidget);

    // Descartar fecha a gravação.
    await tester.tap(find.byKey(BlindKeys.discard));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.recording), findsNothing);

    // De novo: fala e toca no enviar.
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump();
    input.hear(['rook a7']);
    await tester.pump();
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(BlindKeys.proposal)).data, 'Rook a7');
    await tester.tap(find.byKey(BlindKeys.confirm));
    await tester.pumpAndSettle();
    expect(cubit.state.lastUser, 'Ra7');
  });

  testWidgets('arrastar o dedo para longe cancela a gravação', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Your move'), findsOneWidget);
    expect(input.cancels, 1);
  });

  testWidgets('digitar o lance no campo da barra', (tester) async {
    await pump(tester);
    // O campo já está na barra; com texto, o microfone vira o enviar.
    expect(find.byKey(BlindKeys.mic), findsOneWidget);
    await tester.enterText(find.byKey(BlindKeys.typeField), 'Ra7');
    await tester.pump();
    expect(find.byKey(BlindKeys.mic), findsNothing);
    await tester.tap(find.byKey(BlindKeys.typeSend));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.status), findsOneWidget);
  });

  testWidgets('tocar nas casas do tabuleiro vazio joga o lance', (
    tester,
  ) async {
    await pump(tester);
    final board = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    final cell = board.width / 8;
    // a1 e depois a7, com as brancas embaixo.
    await tester.tapAt(board.bottomLeft + Offset(cell / 2, -cell / 2));
    await tester.pump();
    await tester.tapAt(board.topLeft + Offset(cell / 2, cell * 1.5));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.status), findsOneWidget);
  });

  testWidgets('o "é isso?" fica no painel de baixo: o tabuleiro não muda '
      'de tamanho', (tester) async {
    await pump(tester);
    final before = tester.getRect(find.byKey(BlindKeys.emptyBoard));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(BlindKeys.mic)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    input.hear(['rook a7']);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    expect(tester.getRect(find.byKey(BlindKeys.emptyBoard)), before);
    await tester.tap(find.byKey(BlindKeys.reject));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsNothing);
    expect(find.text('Your move'), findsOneWidget);
  });

  testWidgets('desistir, no alto, pede confirmação e encerra', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.resign));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BlindKeys.resignConfirm));
    await tester.pumpAndSettle();
    expect(cubit.state.phase, BlindPhase.finished);
    // Dito o resultado, a conclusão às cegas, sem nenhum lance jogado.
    expect(find.text('conclusion lost 0'), findsOneWidget);
    expect(find.byType(BlindGameScreen), findsNothing);
  });

  testWidgets('com o teclado aberto e pouca altura, nada estoura', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.typeField));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 560);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(BlindKeys.typeField), findsOneWidget);
  });

  for (final (size, keyboard) in [
    (const Size(360, 740), 300.0),
    (const Size(412, 917), 300.0),
  ]) {
    testWidgets('T65 $size, teclado aberto: relógios, mini tabuleiro e '
        '"Sua vez" à vista, nunca a área vazia', (tester) async {
      await pump(
        tester,
        size: size,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 5)),
        ),
      );
      await tester.tap(find.byKey(BlindKeys.typeField));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final opponent = tester.getRect(find.byKey(BlindKeys.opponentClock));
      final user = tester.getRect(find.byKey(BlindKeys.userClock));
      final status = tester.getRect(find.byKey(BlindKeys.status));
      final field = tester.getRect(find.byKey(BlindKeys.typeField));
      final appBar = tester.getRect(find.byType(AppBar));
      // Na ordem: adversário, jogador, "Sua vez", tudo acima do painel.
      expect(opponent.top, greaterThanOrEqualTo(appBar.bottom));
      expect(user.top, greaterThan(opponent.bottom));
      expect(status.top, greaterThan(user.top));
      expect(status.bottom, lessThan(field.top));
      // O relógio corre: para antes de o teste acabar.
      await cubit.pauseForBackground();
    });
  }

  testWidgets('teclado aberto com pouquíssima altura: "Sua vez" fica', (
    tester,
  ) async {
    await pump(
      tester,
      size: const Size(360, 740),
      clock: ClockConfig.same(const TimeControl(initial: Duration(minutes: 5))),
    );
    await tester.tap(find.byKey(BlindKeys.typeField));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 420);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(BlindKeys.status), findsOneWidget);
    await cubit.pauseForBackground();
  });

  testWidgets('as ações em voz ficam à vista também gravando e confirmando', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(BlindKeys.narrateGame), findsOneWidget);
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pump();
    expect(find.byKey(BlindKeys.recording), findsOneWidget);
    expect(find.byKey(BlindKeys.narrateGame), findsOneWidget);
    input.hear(['rook a7']);
    await tester.pump();
    await tester.tap(find.byKey(BlindKeys.mic));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.proposal), findsOneWidget);
    expect(find.byKey(BlindKeys.narrateGame), findsOneWidget);
    // O áudio gravado fica em cima, com o microfone para gravar de novo.
    expect(find.byKey(BlindKeys.reRecord), findsOneWidget);
  });

  testWidgets('o ⓘ explica como dizer e digitar os lances, no idioma', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(BlindKeys.help));
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.helpSheet), findsOneWidget);
    expect(find.textContaining('K king, Q queen'), findsOneWidget);
    final close = find.byTooltip('Close');
    expect(tester.getSize(close), const Size.square(40));
    expect(
      tester.getRect(close).bottom,
      lessThan(tester.getRect(find.byKey(BlindKeys.helpSheet)).top),
    );
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byKey(BlindKeys.helpSheet), findsNothing);
    expect(cubit.state.phase, BlindPhase.playerTurn);
  });
}

/// T65: o seletor, o tabuleiro e "Sua vez" formam um bloco com o mesmo vão
/// (1 dp) entre a barra do app e o seletor e entre "Sua vez" e o painel.
void expectEqualGaps(WidgetTester tester) {
  final area = tester.getRect(find.byKey(BlindKeys.boardArea));
  final picker = tester.getRect(find.byType(SegmentedButton<BlindView>));
  final status = tester.getRect(find.byKey(BlindKeys.status));
  final above = picker.top - area.top;
  final below = area.bottom - status.bottom;
  expect(above, greaterThanOrEqualTo(0));
  expect(above, closeTo(below, 1));
}
