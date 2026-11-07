import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:lucena/ui/race/widgets/race_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

/// A Corrida de finais na coluna A da proposta P2 (canvas SugP2CorridaIntroA,
/// SugP2CorridaIntroBFolha e SugP2CorridaFimA), em português.
void main() {
  late FakeNow now;
  late FakeRaceRepository repository;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 11, 6, 10));
    repository = FakeRaceRepository(now: now);
  });

  Future<RaceCubit> pumpRace(
    WidgetTester tester, {
    Size size = const Size(411, 914),
  }) async {
    await Goldens.loadFonts();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final cubit = RaceCubit(repository, now);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const RaceScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  RaceRun run(List<bool> corrects, {int firstLevel = 400}) => RaceRun(
    startedAt: now(),
    answers: [
      for (final (i, ok) in corrects.indexed)
        RaceAnswer(
          problemId: 'race.001',
          level: firstLevel + i * 10,
          move: 'a1a2',
          correct: ok,
          subcategory: 'queen',
        ),
    ],
  );

  Finder rich(String text) => find.textContaining(text, findRichText: true);

  group('abertura', () {
    testWidgets('título, três fatos da duração, recorde e Começar', (
      tester,
    ) async {
      final cubit = await pumpRace(tester);
      expect(find.text('Problemas só de finais'), findsOneWidget);
      expect(
        find.text('Você joga até o mate; o adversário responde sozinho.'),
        findsOneWidget,
      );
      expect(rich('3 minutos'), findsOneWidget);
      expect(rich('para resolver o máximo'), findsOneWidget);
      expect(rich('3 erros'), findsOneWidget);
      expect(rich('e a corrida acaba'), findsOneWidget);
      expect(find.text('Cada acerto sobe o nível'), findsOneWidget);
      // O texto longo e as regras completas saíram da abertura.
      expect(rich('Treina o olho'), findsNothing);
      expect(rich('Por que só finais'), findsNothing);
      expect(find.text('Vale o caminho mais curto'), findsNothing);
      expect(find.byKey(RaceKeys.recordCard), findsOneWidget);
      expect(find.byKey(RaceKeys.filterRow), findsOneWidget);
      expect(find.byKey(RaceKeys.start), findsOneWidget);

      // Os minutos dos fatos seguem a duração escolhida.
      await tester.tap(
        find.byKey(RaceKeys.durationOption(RaceDuration.fiveMinutes)),
      );
      await tester.pumpAndSettle();
      expect(cubit.state.duration, RaceDuration.fiveMinutes);
      expect(rich('5 minutos'), findsOneWidget);
      expect(rich('3 minutos'), findsNothing);
      await expectLater(
        find.byType(Navigator).first,
        matchesGoldenFile('goldens/p2a/abertura_411x914.png'),
      );
    });

    testWidgets('o (i) abre "Como funciona" com as regras e o Entendi', (
      tester,
    ) async {
      await pumpRace(tester);
      await tester.tap(find.byKey(RaceKeys.howButton));
      await tester.pumpAndSettle();
      expect(find.byKey(RaceKeys.howSheet), findsOneWidget);
      expect(find.text('Como funciona'), findsOneWidget);
      expect(find.text('Fica mais difícil'), findsOneWidget);
      expect(find.text('Três erros e acabou'), findsOneWidget);
      expect(find.text('Vale o caminho mais curto'), findsOneWidget);
      expect(find.text('3 minutos'), findsOneWidget);
      // A folha usa a moldura única, na cor única das folhas.
      expect(
        tester.widget<Material>(find.byKey(SheetKeys.surface)).color,
        AppColors.sheetSurface,
      );
      await expectLater(
        find.byType(Navigator).first,
        matchesGoldenFile('goldens/p2a/como_funciona_411x914.png'),
      );
      await tester.tap(find.byKey(RaceKeys.howGotIt));
      await tester.pumpAndSettle();
      expect(find.byKey(RaceKeys.howSheet), findsNothing);
      expect(find.byKey(RaceKeys.introView), findsOneWidget);
    });

    testWidgets('em 360×640 não estoura e os alvos têm 48 dp', (tester) async {
      await pumpRace(tester, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      final how = tester.getSize(find.byKey(RaceKeys.howButton));
      expect(how.width, greaterThanOrEqualTo(48));
      expect(how.height, greaterThanOrEqualTo(48));
      final start = tester.getRect(find.byKey(RaceKeys.start));
      expect(start.height, greaterThanOrEqualTo(48));
      expect(start.bottom, lessThanOrEqualTo(640));
      expect(start.left, greaterThanOrEqualTo(0));
      expect(start.right, lessThanOrEqualTo(360));
      final facts = tester.getRect(find.byKey(RaceKeys.facts));
      expect(facts.right, lessThanOrEqualTo(360));

      await tester.tap(find.byKey(RaceKeys.howButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(RaceKeys.howGotIt)).bottom,
        lessThanOrEqualTo(640),
      );
    });
  });

  group('fim', () {
    testWidgets('por erros: o motivo, o cartão "O que contou" e os botões', (
      tester,
    ) async {
      repository = FakeRaceRepository(
        now: now,
        ongoing: run([true, true, true, false, false, false]),
      );
      await pumpRace(tester);

      expect(find.byKey(RaceKeys.resultView), findsOneWidget);
      expect(find.text('Três erros e a corrida acabou'), findsOneWidget);
      expect(find.byKey(RaceKeys.counted), findsOneWidget);
      expect(find.text('O que contou'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(RaceKeys.countedCorrects),
          matching: find.textContaining('3 acertos. Seu recorde em 3 min: 3'),
        ),
        findsOneWidget,
      );
      expect(find.text('Chegou ao nível 420'), findsOneWidget);
      expect(
        find.text('Entrou no seu desempenho por final: 1 de 3'),
        findsOneWidget,
      );
      expect(find.text('Os problemas'), findsOneWidget);
      expect(find.text('Jogar novamente'), findsOneWidget);
      expect(find.text('Rever os 3 erros'), findsOneWidget);
      // Saíram os três números, a linha dos dados e o tempo por problema.
      expect(find.text('por problema'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d+ s$').hasMatch(w.data ?? ''),
        ),
        findsNothing,
      );
      expect(find.text('mais difícil'), findsNothing);
      expect(find.byKey(NextStepsKeys.resultsInfo), findsNothing);
      expect(find.text('Como o Lucena usa seus resultados'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Navigator).first,
        matchesGoldenFile('goldens/p2a/fim_erros_411x914.png'),
      );
    });

    testWidgets('por tempo: o motivo é o tempo e sem acerto some o nível', (
      tester,
    ) async {
      repository = FakeRaceRepository(now: now, ongoing: run([false, false]));
      now.advance(const Duration(minutes: 10));
      await pumpRace(tester);

      expect(find.byKey(RaceKeys.resultView), findsOneWidget);
      expect(find.text('O tempo acabou'), findsOneWidget);
      expect(find.text('Três erros e a corrida acabou'), findsNothing);
      expect(find.byKey(RaceKeys.countedCorrects), findsOneWidget);
      expect(find.byKey(RaceKeys.countedLevel), findsNothing);
      expect(find.text('por problema'), findsNothing);
    });

    testWidgets('por tempo com acertos: nível e recorde da duração', (
      tester,
    ) async {
      repository = FakeRaceRepository(
        now: now,
        ongoing: run([true, true, false]),
      );
      now.advance(const Duration(minutes: 10));
      await pumpRace(tester);
      expect(find.text('O tempo acabou'), findsOneWidget);
      expect(find.text('Chegou ao nível 410'), findsOneWidget);
      expect(find.text('Rever o erro'), findsOneWidget);
    });

    testWidgets('em 360×640 o resultado não estoura', (tester) async {
      repository = FakeRaceRepository(
        now: now,
        ongoing: run([true, true, true, false, false, false]),
      );
      await pumpRace(tester, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(find.byKey(RaceKeys.counted), findsOneWidget);
      final card = tester.getRect(find.byKey(RaceKeys.counted));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(360));
      final again = tester.getRect(find.byKey(RaceKeys.again));
      expect(again.height, greaterThanOrEqualTo(48));
      expect(again.bottom, lessThanOrEqualTo(640));
    });
  });
}
