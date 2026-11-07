import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/ui/core/theme/app_bar_height.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/numero_que_conta.dart';
import 'package:lucena/ui/core/motion/tabuleiro_animado.dart';
import 'package:lucena/ui/core/motion/transicao_eixo_x.dart';
import 'package:lucena/ui/placement/view_models/placement_cubit.dart';
import 'package:lucena/ui/placement/widgets/placement_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/aparelho_principal.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/placement_synthetic.dart';

import 'package:lucena/ui/core/widgets/info_chip.dart';

void main() {
  final skills = SkillMap.fromJson(syntheticSkillsJson());
  final bank = PlacementBank.fromJson(syntheticItemsJson());
  // Enunciados reais e quatro respostas para exercitar a geometria; as
  // posições sintéticas continuam sem uso como avaliação enxadrística.
  final geometryJson = syntheticItemsJson();
  for (final item in geometryJson['items'] as List<Map<String, dynamic>>) {
    item['prompt'] = 'placementCheckMateNone';
    if (item['type'] == 'squares') item['squares'] = ['c3', 'd4', 'e5'];
    if (item['type'] == 'choice') {
      item['options'] = ['check', 'mate', 'stalemate', 'none'];
      item['answer'] = 'check';
    }
  }
  final geometryBank = PlacementBank.fromJson(geometryJson);

  Future<(PlacementCubit, FakeProfileRepository)> pump(
    WidgetTester tester, {
    VoidCallback? onDone,
    VoidCallback? onPreferRating,
    Size size = const Size(400, 800),
    bool systemBars = false,
    bool geometry = false,
    double textScale = 1,
    bool disableAnimations = false,
    SpeechCubit? speech,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    if (systemBars) {
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    }
    final profile = FakeProfileRepository();
    final cubit = PlacementCubit(
      placement: FakePlacementRepository(
        skills: skills,
        bank: geometry ? geometryBank : bank,
      ),
      profile: profile,
      now: FakeNow(DateTime.utc(2026, 10, 8, 20)),
      characters: FakeCharacterRepository(),
      seed: 3,
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        speechCubit: speech,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: BlocProvider.value(
              value: cubit,
              child: PlacementScreen(
                onDone: onDone,
                onPreferRating: onPreferRating,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (cubit, profile);
  }

  testWidgets('abertura → 20 perguntas com "Não sei" → resultado; usar o '
      'nível leva o rating ao perfil e fecha', (tester) async {
    var done = false;
    final (cubit, profile) = await pump(tester, onDone: () => done = true);
    expect(find.byKey(PlacementKeys.start), findsOneWidget);

    await tester.tap(find.byKey(PlacementKeys.start));
    await tester.pumpAndSettle();
    expect(find.text('Pergunta 1 de 20'), findsOneWidget);
    expect(find.byKey(PlacementKeys.board), findsOneWidget);
    expect(find.byKey(PlacementKeys.prompt), findsOneWidget);

    for (var i = 0; i < PlacementState.questionCount; i++) {
      await tester.tap(find.byKey(PlacementKeys.dontKnow));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(PlacementKeys.result), findsOneWidget);
    expect(find.byKey(PlacementKeys.resultHeader), findsOneWidget);
    expect(find.byKey(PlacementKeys.level), findsOneWidget);

    await tester.tap(find.byKey(PlacementKeys.useLevel));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(profile.profile.rating, cubit.state.result!.theta);
  });

  for (final size in [const Size(412, 915), const Size(360, 640)]) {
    testWidgets('abertura, $size: "Começar" na largura toda, encostado na '
        'base', (tester) async {
      await pump(tester, size: size);
      final footerFinder = find.byKey(PlacementKeys.footer);
      final footer = tester.getRect(footerFinder);
      final start = tester.getRect(find.byKey(PlacementKeys.start));
      // O rodapé encosta na base da tela (canvas PropV2TesteAbertura).
      expect(footer.bottom, size.height);
      expect(footer.left, 0);
      expect(footer.right, size.width);
      expect(start.top - footer.top, 8);
      expect(start.height, 52);
      expect(start.left, 16);
      expect(start.right, size.width - 16);
      expect(size.height - start.bottom, 8);
    });
  }

  for (final enabled in [true, false]) {
    testWidgets('abertura, voz ${enabled ? 'ligada' : 'desligada'}: o "1×" '
        '${enabled ? 'aparece' : 'some'} e o som fica à vista', (tester) async {
      final speech = SpeechCubit(
        FakeVoiceRepository(settings: VoiceSettings(enabled: enabled)),
      );
      addTearDown(speech.close);
      await speech.load();
      await pump(tester, speech: speech);
      expect(
        find.byKey(VoiceKeys.speedButton),
        enabled ? findsOneWidget : findsNothing,
      );
      expect(find.byKey(VoiceKeys.speakButton), findsOneWidget);
    });
  }

  testWidgets('abertura: os selos são cheios e sem contorno (CompChip info)', (
    tester,
  ) async {
    await pump(tester);
    final chips = find.byType(InfoChip);
    expect(chips, findsNWidgets(3));
    final colors = Theme.of(tester.element(chips.first)).colorScheme;
    for (final chip in chips.evaluate()) {
      final box = (chip.widget as InfoChip);
      expect(box.background, isNull);
      final decoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byWidget(box),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, colors.surfaceContainer);
      expect(decoration.border, isNull);
    }
  });

  testWidgets('abertura: "Prefiro informar meu rating" sai do teste', (
    tester,
  ) async {
    var left = false;
    await pump(tester, onPreferRating: () => left = true);
    expect(find.text('Prefiro informar meu rating'), findsOneWidget);
    await tester.tap(find.byKey(PlacementKeys.preferRating));
    expect(left, isTrue);
  });

  testWidgets('abertura (H-ABE-14): app bar "Teste de nível" colada no topo, '
      'sem faixa acima e sem subtítulo', (tester) async {
    await pump(tester);
    final bar = find.byType(AppBar);
    expect(bar, findsOneWidget);
    expect(tester.getTopLeft(bar).dy, 0);
    expect(
      find.descendant(of: bar, matching: find.text('Teste de nível')),
      findsOneWidget,
    );
    expect(tester.widget<AppBar>(bar).bottom, isNull);
  });

  testWidgets('pergunta (regra da app bar): com a barra de progresso, o total '
      'fica em 64, como no teste do capítulo e na Opinião', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(PlacementKeys.start));
    await tester.pumpAndSettle();
    expect(find.byKey(PlacementKeys.progress), findsOneWidget);
    final bar = find.byType(AppBar);
    expect(tester.getTopLeft(bar).dy, 0);
    expect(tester.getSize(bar).height, AppBarHeight.standard);
  });

  testWidgets('abertura sem a saída: o botão não aparece', (tester) async {
    await pump(tester);
    expect(find.byKey(PlacementKeys.preferRating), findsNothing);
  });

  testWidgets('abertura: Começar mostra carregando e leva à pergunta 1', (
    tester,
  ) async {
    final (cubit, _) = await pump(tester);
    final seen = <bool>[];
    final sub = cubit.stream.listen((state) => seen.add(state.starting));
    addTearDown(sub.cancel);
    await tester.tap(find.byKey(PlacementKeys.start));
    // O primeiro estado é o do botão carregando; o último, a pergunta.
    await tester.pumpAndSettle();
    expect(seen.first, isTrue);
    expect(seen.last, isFalse);
    expect(find.text('Pergunta 1 de 20'), findsOneWidget);
  });

  testWidgets('abertura: o balão não repete o que os selos dizem', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('20 perguntas, sem relógio'), findsNothing);
    expect(find.textContaining('Se não souber, toque em'), findsOneWidget);
    expect(find.text('uns 8 a 12 minutos'), findsOneWidget);
  });

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    final w = size.width;
    testWidgets('${w.toInt()}: abertura retomada: card de onde parou abaixo '
        'dos selos; "Continuar teste" cheio e "Recomeçar" em texto', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester, size: size);
      await tester.tap(find.byKey(PlacementKeys.start));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PlacementKeys.dontKnow));
      await tester.pumpAndSettle();
      await cubit.load();
      await tester.pumpAndSettle();
      expect(cubit.state.resuming, isTrue);
      final footer = find.byKey(PlacementKeys.footer);
      for (final key in [PlacementKeys.restart, PlacementKeys.resume]) {
        expect(
          find.descendant(of: footer, matching: find.byKey(key)),
          findsOneWidget,
        );
      }
      final resume = tester.getRect(find.byKey(PlacementKeys.resume));
      final restart = tester.getRect(find.byKey(PlacementKeys.restart));
      expect(resume.left, 16);
      expect(resume.right, w - 16);
      expect(restart.top - resume.bottom, 8);
      expect(size.height - restart.bottom, 8);
      expect(find.byKey(PlacementKeys.start), findsNothing);
      expect(find.text('Continuar teste'), findsOneWidget);

      // O card (variante B): fora do rodapé, 24 abaixo dos selos, na
      // largura do conteúdo, padding 16, ícone e duas linhas.
      final card = find.byKey(PlacementKeys.stoppedCard);
      expect(find.descendant(of: footer, matching: card), findsNothing);
      final box = tester.getRect(card);
      final chips = find.byType(InfoChip);
      final chipsBottom = [
        for (final e in chips.evaluate())
          tester.getRect(find.byWidget(e.widget)).bottom,
      ].reduce((a, b) => a > b ? a : b);
      expect(box.top - chipsBottom, 24);
      expect(box.left, 16);
      expect(box.width, w - 32);
      // O cartão do tema (D24): sem cor nem raio próprios.
      final colors = Theme.of(tester.element(card)).colorScheme;
      expect(tester.widget<Card>(card).color, isNull);
      final icon = find.descendant(of: card, matching: find.byType(Icon));
      final iconBox = tester.getRect(icon);
      expect(iconBox.topLeft - box.topLeft, const Offset(16, 16));
      expect(tester.widget<Icon>(icon).color, colors.primary);
      final title = find.byKey(PlacementKeys.stoppedAt);
      final saved = find.byKey(PlacementKeys.answersSaved);
      expect(tester.getRect(title).left - iconBox.right, 12);
      expect(tester.getRect(saved).top - tester.getRect(title).bottom, 4);
      expect(box.bottom - tester.getRect(saved).bottom, 16);
      expect(find.text('Você parou na pergunta 2 de 20'), findsOneWidget);
      expect(
        find.text('As respostas que você já deu estão salvas.'),
        findsOneWidget,
      );
    });
  }

  for (final reducedMotion in [false, true]) {
    testWidgets('B7: troca de pergunta sem deslocar o tabuleiro, '
        'movimento reduzido=$reducedMotion', (tester) async {
      final (cubit, _) = await pump(
        tester,
        geometry: true,
        disableAnimations: reducedMotion,
      );
      await cubit.start();
      await tester.pumpAndSettle();
      final initial = tester.getRect(find.byKey(PlacementKeys.board));
      await cubit.answer(PlacementOutcome.dontKnow);
      await tester.pump();
      // O fade cruzado do TrocaComFade: 300 ms, ou 100 ms com movimento
      // reduzido; aos 50 ms as duas perguntas estão na tela.
      await tester.pump(const Duration(milliseconds: 50));
      final boards = find.byKey(PlacementKeys.board);
      for (final element in boards.evaluate()) {
        expect(
          tester.getRect(find.byElementPredicate((e) => e == element)),
          initial,
        );
      }
      expect(
        find.descendant(
          of: find.byType(PlacementScreen),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('q1')), findsOneWidget);
      expect(boards, findsNWidgets(2));
      if (reducedMotion) {
        // O relógio do fade começa no quadro dos 50 ms: 100 ms depois dele,
        // a pergunta velha saiu.
        await tester.pump(const Duration(milliseconds: 101));
        expect(find.byKey(const ValueKey('q1')), findsNothing);
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('q2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    testWidgets('B6, $size: centro entre status e navegação, enunciado acima '
        'e respostas no rodapé', (tester) async {
      final (cubit, _) = await pump(
        tester,
        size: size,
        systemBars: true,
        geometry: true,
      );
      await cubit.start();
      await tester.pumpAndSettle();
      for (var i = 0; i < PlacementState.questionCount; i++) {
        final appBar = tester.getRect(find.byType(AppBar));
        final answers = tester.getRect(find.byKey(PlacementKeys.answers));
        final board = tester.getRect(find.byKey(PlacementKeys.board));
        final prompt = tester.getRect(find.byKey(PlacementKeys.prompt));
        final above = board.top - 24;
        final below = size.height - 24 - board.bottom;
        expect(
          (above - below).abs() / (size.height - 48),
          lessThanOrEqualTo(.05),
          reason: 'board=$board prompt=$prompt answers=$answers',
        );
        expect(board.center.dx, closeTo(size.width / 2, 1));
        expect(prompt.top, greaterThanOrEqualTo(appBar.bottom));
        expect(prompt.bottom, lessThanOrEqualTo(board.top));
        expect(answers.top, greaterThanOrEqualTo(board.bottom));
        expect(answers.bottom, closeTo(size.height - 24, 1));
        expect(
          find.byKey(PlacementKeys.dontKnow).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await cubit.answer(PlacementOutcome.dontKnow);
        await tester.pumpAndSettle();
      }
    });
  }

  for (final size in [const Size(412, 915), aparelhoPrincipal]) {
    testWidgets(
      '$size, pergunta (canvas PropV1TesteNivelLance): o enunciado em texto '
      'normal, à esquerda e colado ao tabuleiro',
      (tester) async {
        final (cubit, _) = await pump(tester, size: size);
        await cubit.start();
        await tester.pumpAndSettle();
        final text = tester.widget<Text>(find.byKey(PlacementKeys.prompt));
        expect(text.textAlign, TextAlign.start);
        final style = DefaultTextStyle.of(
          tester.element(find.byKey(PlacementKeys.prompt)),
        ).style.merge(text.style);
        expect(style.fontWeight, anyOf(isNull, FontWeight.w400));
        expect(style.fontSize, 16);
        final prompt = tester.getRect(find.byKey(PlacementKeys.prompt));
        final board = tester.getRect(find.byKey(PlacementKeys.board));
        expect(prompt.left, closeTo(AppSpacing.screen, 1));
        expect(board.top - prompt.bottom, closeTo(AppSpacing.md, 1));
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('B6: rotação e fonte $scale preservam tabuleiro e respostas', (
      tester,
    ) async {
      final (cubit, _) = await pump(
        tester,
        size: const Size(360, 800),
        systemBars: true,
        geometry: true,
        textScale: scale,
      );
      await cubit.start();
      while (cubit.state.item!.type != PlacementItemType.choice) {
        await cubit.answer(PlacementOutcome.dontKnow);
      }
      await tester.pumpAndSettle();
      final number = cubit.state.number;
      final item = cubit.state.item;
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpAndSettle();
      expect(cubit.state.number, number);
      expect(cubit.state.item, same(item));
      final board = tester.getRect(find.byKey(PlacementKeys.board));
      final prompt = tester.getRect(find.byKey(PlacementKeys.prompt));
      expect(board.width, greaterThanOrEqualTo(200));
      expect(board.height, board.width);
      expect(prompt.height, greaterThanOrEqualTo(20 * scale));
      expect(prompt.bottom, lessThanOrEqualTo(board.top));
      for (final option in item!.options) {
        await tester.ensureVisible(find.byKey(PlacementKeys.option(option)));
        expect(
          find.byKey(PlacementKeys.option(option)).hitTestable(),
          findsOneWidget,
        );
      }
      await tester.ensureVisible(find.byKey(PlacementKeys.dontKnow));
      await tester.tap(find.byKey(PlacementKeys.dontKnow));
      await tester.pumpAndSettle();
      expect(cubit.state.number, number + 1);
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(PlacementKeys.board)).width,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pergunta de escolha: as opções cabem em 320 dp', (tester) async {
    final (cubit, _) = await pump(tester, size: const Size(320, 640));
    await cubit.start();
    // Até cair numa pergunta de escolha.
    for (var i = 0; i < 20; i++) {
      if (cubit.state.item?.type == PlacementItemType.choice) break;
      await cubit.answer(PlacementOutcome.dontKnow);
    }
    await tester.pumpAndSettle();
    final item = cubit.state.item!;
    expect(item.type, PlacementItemType.choice);
    expect(tester.takeException(), isNull);
    for (final option in item.options) {
      final rect = tester.getRect(find.byKey(PlacementKeys.option(option)));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    final number = cubit.state.number;
    await tester.tap(find.byKey(PlacementKeys.option(item.options.first)));
    await tester.pumpAndSettle();
    expect(cubit.state.number, number + 1);
  });

  group('animações da abertura (T85-D3)', () {
    Finder quadro(String id) =>
        find.byWidgetPredicate((w) => w is EntradaDaTela && w.id == id);

    testWidgets('a abertura é o quadro PropV2TesteAbertura', (tester) async {
      await pump(tester);
      expect(quadro('PropV2TesteAbertura'), findsOneWidget);
    });

    testWidgets('na retomada é o quadro PropV2TesteAberturaRetomada', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester);
      await tester.tap(find.byKey(PlacementKeys.start));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PlacementKeys.dontKnow));
      await tester.pumpAndSettle();
      await cubit.load();
      await tester.pumpAndSettle();
      expect(cubit.state.resuming, isTrue);
      expect(quadro('PropV2TesteAberturaRetomada'), findsOneWidget);
    });

    testWidgets('"Começar" troca o rótulo pelo círculo do BotaoCarregando', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester);
      expect(find.byKey(CoreKeys.busySpinner), findsNothing);
      unawaited(cubit.start());
      await tester.pump();
      if (cubit.state.starting) {
        await tester.pump(LucenaMotion.trocaRotulo);
        expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      }
      await tester.pumpAndSettle();
    });

    testWidgets('a barra de progresso da pergunta enche (BarraQueEnche) e '
        'guarda a key', (tester) async {
      final (cubit, _) = await pump(tester);
      await cubit.start();
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(PlacementKeys.progress),
          matching: find.byKey(MotionKeys.barraQueEnche),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('cada tipo de pergunta é um quadro do canvas', (tester) async {
      final (cubit, _) = await pump(tester);
      await cubit.start();
      await tester.pumpAndSettle();
      const ids = {
        PlacementItemType.squares: 'PropV1TesteNivelCasas',
        PlacementItemType.choice: 'PropV1TesteNivelEscolha',
        PlacementItemType.move: 'PropV1TesteNivelLance',
      };
      final vistos = <PlacementItemType>{};
      for (var i = 0; i < PlacementState.questionCount; i++) {
        final tipo = cubit.state.item!.type;
        vistos.add(tipo);
        expect(quadro(ids[tipo]!), findsOneWidget, reason: '$tipo');
        await cubit.answer(PlacementOutcome.dontKnow);
        await tester.pumpAndSettle();
      }
      expect(vistos, containsAll(ids.keys));
    });

    testWidgets('na pergunta de lance o tabuleiro desliza em 300 ms '
        '(TabuleiroAnimado)', (tester) async {
      final (cubit, _) = await pump(tester);
      await cubit.start();
      for (var i = 0; i < 20; i++) {
        if (cubit.state.item?.type == PlacementItemType.move) break;
        await cubit.answer(PlacementOutcome.dontKnow);
      }
      await tester.pumpAndSettle();
      expect(cubit.state.item!.type, PlacementItemType.move);
      expect(find.byType(TabuleiroAnimado), findsOneWidget);
      final board = tester.widget<Chessboard>(find.byKey(PlacementKeys.board));
      expect(board.settings.animationDuration, LucenaMotion.lance);
    });

    testWidgets('movimento reduzido: o lance aparece no destino, sem deslize', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester, disableAnimations: true);
      await cubit.start();
      for (var i = 0; i < 20; i++) {
        if (cubit.state.item?.type == PlacementItemType.move) break;
        await cubit.answer(PlacementOutcome.dontKnow);
      }
      await tester.pumpAndSettle();
      final board = tester.widget<Chessboard>(find.byKey(PlacementKeys.board));
      expect(board.settings.animationDuration, Duration.zero);
    });

    // Combinado com o ORQ: o eixo X só na entrada e na saída; entre as
    // perguntas fica o fade da B7.
    testWidgets('H-ANI-03: abertura → 1ª pergunta entra pelo eixo X', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester, geometry: true);
      await cubit.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final q1 = find.byKey(const ValueKey('q1'));
      expect(q1, findsOneWidget);
      expect(
        find.ancestor(of: q1, matching: find.byType(TransicaoEixoX)),
        findsOneWidget,
      );
      final meio = tester.getTopLeft(q1).dx;
      await tester.pumpAndSettle();
      final fim = tester.getTopLeft(q1).dx;
      expect(meio, greaterThan(fim));
      expect(meio - fim, lessThanOrEqualTo(LucenaMotion.deslocamentoDoEixo));
    });

    testWidgets('H-ANI-03: última pergunta → resultado entra pelo eixo X', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester, geometry: true);
      await cubit.start();
      for (var i = 0; i < PlacementState.questionCount - 1; i++) {
        await cubit.answer(PlacementOutcome.dontKnow);
      }
      await tester.pumpAndSettle();
      await cubit.answer(PlacementOutcome.dontKnow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final resultado = find.byKey(const ValueKey('result'));
      expect(resultado, findsOneWidget);
      final meio = tester.getTopLeft(resultado).dx;
      await tester.pumpAndSettle();
      final fim = tester.getTopLeft(resultado).dx;
      expect(meio, greaterThan(fim));
      expect(meio - fim, lessThanOrEqualTo(LucenaMotion.deslocamentoDoEixo));
    });

    testWidgets('resultado: quadro do canvas e rating que conta até o valor', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester);
      await cubit.start();
      for (var i = 0; i < PlacementState.questionCount; i++) {
        await cubit.answer(PlacementOutcome.dontKnow);
      }
      await tester.pump();
      final result = cubit.state.result!;
      final id = result.levels.length > 1
          ? 'TelaTesteResultadoDuasFaixas'
          : 'TelaTesteResultado';
      expect(quadro(id), findsOneWidget);
      final numero = find.descendant(
        of: find.byKey(PlacementKeys.level),
        matching: find.byType(NumeroQueConta),
      );
      expect(numero, findsOneWidget);
      String texto() => tester
          .widget<Text>(
            find.descendant(of: numero, matching: find.byType(Text)),
          )
          .data!;
      final comeco = texto();
      await tester.pumpAndSettle();
      // O rating sai sem separador, como no resto do app ("1200").
      final fim = '${result.theta}';
      expect(texto(), fim);
      expect(comeco, isNot(fim));
    });

    testWidgets(
      'resultado: o número mostrado é o do perfil e cabe na '
      'escala (o início dela desce até o valor); a lista tem barra de rolagem sempre visível',
      (tester) async {
        final (cubit, profile) = await pump(tester);
        await cubit.start();
        for (var i = 0; i < PlacementState.questionCount; i++) {
          await cubit.answer(PlacementOutcome.dontKnow);
        }
        await tester.pumpAndSettle();
        final numero = find.descendant(
          of: find.byKey(PlacementKeys.level),
          matching: find.byType(NumeroQueConta),
        );
        final shown = int.parse(
          tester
              .widget<Text>(
                find.descendant(of: numero, matching: find.byType(Text)),
              )
              .data!,
        );
        expect(shown, lessThan(1000));
        final start = int.parse(
          tester.widget<Text>(find.byKey(PlacementKeys.rulerStart)).data!,
        );
        expect(start, lessThanOrEqualTo(shown));
        final result = cubit.state.result!;
        expect(start, result.low < shown ? result.low : shown);
        await tester.tap(find.byKey(PlacementKeys.useLevel));
        await tester.pumpAndSettle();
        expect(profile.profile.rating, shown);

        final bar = find.descendant(
          of: find.byKey(PlacementKeys.result),
          matching: find.byType(Scrollbar),
        );
        expect(bar, findsOneWidget);
        expect(tester.widget<Scrollbar>(bar).thumbVisibility, isTrue);
      },
    );

    testWidgets('pergunta de casas: diz quantas casas faltam marcar', (
      tester,
    ) async {
      final (cubit, _) = await pump(tester, geometry: true);
      await cubit.start();
      while (cubit.state.item?.type != PlacementItemType.squares) {
        await cubit.answer(PlacementOutcome.dontKnow);
      }
      await tester.pumpAndSettle();
      final item = cubit.state.item!;
      final total = item.squares.toSet().length;
      final hint = find.byKey(PlacementKeys.squaresLeft);
      expect(hint, findsOneWidget);
      String texto() => tester.widget<Text>(hint).data!;
      expect(texto(), total == 1 ? 'Falta 1 casa' : 'Faltam $total casas');
      cubit.toggleSquare(item.squares.first);
      await tester.pumpAndSettle();
      expect(
        texto(),
        total == 1
            ? 'Pode confirmar'
            : total == 2
            ? 'Falta 1 casa'
            : 'Faltam ${total - 1} casas',
      );
    });
  });
}
