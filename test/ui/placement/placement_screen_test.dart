import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/placement/view_models/placement_cubit.dart';
import 'package:lucena/ui/placement/widgets/placement_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/placement_synthetic.dart';

void main() {
  final skills = SkillMap.fromJson(syntheticSkillsJson());
  final bank = PlacementBank.fromJson(syntheticItemsJson());
  // Enunciados reais e quatro respostas para exercitar a geometria; as
  // posições sintéticas continuam sem uso como avaliação enxadrística.
  final geometryJson = syntheticItemsJson();
  for (final item in geometryJson['items'] as List<Map<String, dynamic>>) {
    item['prompt'] = 'placementCheckMateNone';
    if (item['type'] == 'choice') {
      item['options'] = ['check', 'mate', 'stalemate', 'none'];
      item['answer'] = 'check';
    }
  }
  final geometryBank = PlacementBank.fromJson(geometryJson);

  Future<(PlacementCubit, FakeProfileRepository)> pump(
    WidgetTester tester, {
    VoidCallback? onDone,
    VoidCallback? onChooseByHand,
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
                onChooseByHand: onChooseByHand,
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
    // Fora do tour, sem "prefiro escolher".
    expect(find.byKey(PlacementKeys.chooseByHand), findsNothing);

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
    testWidgets('abertura, $size: rodapé em coluna, "Começar" na largura '
        'toda e "Prefiro informar" em texto abaixo', (tester) async {
      await pump(tester, size: size, onChooseByHand: () {});
      final footerFinder = find.byKey(PlacementKeys.footer);
      final footer = tester.getRect(footerFinder);
      final start = tester.getRect(find.byKey(PlacementKeys.start));
      final choose = tester.getRect(find.byKey(PlacementKeys.chooseByHand));
      // O rodapé encosta na base da tela (canvas PropV2TesteAbertura).
      expect(footer.bottom, size.height);
      expect(footer.left, 0);
      expect(footer.right, size.width);
      expect(start.top - footer.top, 12);
      expect(start.height, 52);
      expect(start.left, 16);
      expect(start.right, size.width - 16);
      expect(
        find.descendant(
          of: footerFinder,
          matching: find.byKey(PlacementKeys.chooseByHand),
        ),
        findsOneWidget,
      );
      expect(choose.top - start.bottom, 4);
      // Mínimo de 40 (na fonte de teste o rótulo quebra em duas linhas).
      final style = tester
          .widget<TextButton>(find.byKey(PlacementKeys.chooseByHand))
          .style!;
      expect(style.minimumSize!.resolve({}), const Size.fromHeight(40));
      expect(choose.left, 16);
      expect(choose.right, size.width - 16);
      expect(size.height - choose.bottom, 24);
      final label = tester.getRect(
        find.descendant(
          of: find.byKey(PlacementKeys.chooseByHand),
          matching: find.byType(Text),
        ),
      );
      expect(label.center.dx, closeTo(size.width / 2, 0.5));
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
    final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
    expect(chips, hasLength(3));
    final context = tester.element(find.byType(Chip).first);
    final colors = Theme.of(context).colorScheme;
    for (final chip in chips) {
      expect(chip.side, BorderSide.none);
      expect(chip.backgroundColor, colors.surfaceContainer);
    }
  });

  testWidgets('abertura: o balão não repete o que os selos dizem', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('20 perguntas, sem relógio'), findsNothing);
    expect(find.textContaining('Não vale chutar'), findsOneWidget);
  });

  testWidgets('abertura retomada: "Continuar" cheio e "Recomeçar" em texto '
      'abaixo, sem o link de rating', (tester) async {
    final (cubit, _) = await pump(tester, onChooseByHand: () {});
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
    expect(resume.right, 800 - 400 - 16);
    expect(restart.top - resume.bottom, 4);
    expect(800 - restart.bottom, 24);
    expect(find.byKey(PlacementKeys.start), findsNothing);
    expect(find.byKey(PlacementKeys.chooseByHand), findsNothing);
    // A legenda de onde parou, centrada, 8 acima do "Continuar teste".
    final stopped = find.byKey(PlacementKeys.stoppedAt);
    expect(find.descendant(of: footer, matching: stopped), findsOneWidget);
    expect(resume.top - tester.getRect(stopped).bottom, 8);
    expect(tester.widget<Text>(stopped).textAlign, TextAlign.center);
    expect(find.text('Você parou na pergunta 2 de 20'), findsOneWidget);
    expect(find.text('Continuar teste'), findsOneWidget);
  });

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
      await tester.pump(const Duration(milliseconds: 80));
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
      if (reducedMotion) {
        expect(find.byKey(const ValueKey('q1')), findsNothing);
        expect(boards, findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('q1')), findsOneWidget);
        expect(boards, findsNWidgets(2));
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

  testWidgets('no tour, "prefiro informar meu rating" aparece e avisa', (
    tester,
  ) async {
    var byHand = false;
    await pump(tester, onChooseByHand: () => byHand = true);
    await tester.tap(find.byKey(PlacementKeys.chooseByHand));
    expect(byHand, isTrue);
  });

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
}
