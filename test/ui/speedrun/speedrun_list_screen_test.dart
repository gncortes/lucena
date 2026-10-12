import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/pace/pace_ui.dart';
import 'package:lucena/domain/use_cases/speedrun_category.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_ui.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_list_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

/// A lista dos speedruns, com o ritmo escolhido no alto.
void main() {
  late FakeSettingsRepository settings;
  late SpeedrunCubit cubit;
  late FakeProgressRepository progress;

  setUp(() {
    settings = FakeSettingsRepository(const AppSettings());
    progress = FakeProgressRepository();
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(
        speedruns: [...sampleSpeedruns, sampleMarathon],
      ),
      speedruns: FakeSpeedrunRepository(progress),
      games: FakeOngoingGameRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 4, 12)),
      settings: settings,
      characters: FakeCharacterRepository(),
    );
  });
  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool small = false,
  }) async {
    tester.view.physicalSize = small
        ? const Size(360, 640)
        : const Size(1080, 4000);
    tester.view.devicePixelRatio = small ? 1 : 2.625;
    addTearDown(tester.view.reset);
    await cubit.load();
    final settingsCubit = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settingsCubit.close);
    await settingsCubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settingsCubit,
        child: BlocProvider.value(
          value: cubit,
          child: const SpeedrunListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool chipSelected(WidgetTester tester, String code) => tester
      .widget<ChoiceChip>(find.byKey(SpeedrunKeys.paceOption(code)))
      .selected;

  testWidgets('recorde da lista usa tempo em linha e preserva key e valor', (
    tester,
  ) async {
    await cubit.load(speedrunId: 'rung.1000');
    final (speedrun, attempt) = (await cubit.startWith(
      SpeedrunPaces.standard,
    ))!;
    for (var index = 0; index < speedrun.stages.length; index++) {
      await progress.addAttempt(
        Attempt(
          positionId: 'basic.queen.0001',
          playedAt: DateTime.utc(2026, 10, 4, 12),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          userClock: const Duration(seconds: 10),
          speedrunAttemptId: attempt,
          speedrunStage: index,
        ),
      );
    }
    await pump(tester);
    final recordFinder = find.ancestor(
      of: find.byKey(SpeedrunKeys.itemBest(speedrun.id)),
      matching: find.byType(TimeDisplay),
    );
    final record = tester.widget<TimeDisplay>(recordFinder);
    expect(record.type, TimeDisplayType.record);
    expect(record.size, TimeDisplaySize.inline);
    expect(record.value, '0:20.0');
    expect(record.semanticsLabel, 'Your best time: 0:20.0');
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, small: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o ritmo fica no alto: a categoria e o tempo dela, sem '
      'painel', (tester) async {
    await pump(tester);

    // Abre no 5+3, da categoria dele.
    expect(find.byKey(SpeedrunKeys.pace), findsOneWidget);
    expect(chipSelected(tester, '300+3'), isTrue);
    expect(find.byKey(SpeedrunKeys.item('rung.1000')), findsOneWidget);
    // Sem seção de tentativas em andamento.
    expect(find.byKey(SpeedrunKeys.inProgress('rung.1000')), findsNothing);
  });

  testWidgets('trocar o ritmo troca os speedruns e grava a escolha', (
    tester,
  ) async {
    await pump(tester);
    const threeTwo = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );

    await tester.tap(
      find.byKey(SpeedrunKeys.paceCategory(PaceCategory.of(threeTwo).name)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.paceOption(threeTwo.code)));
    await tester.pumpAndSettle();

    expect(cubit.state.pace, threeTwo);
    expect(chipSelected(tester, threeTwo.code), isTrue);
    expect(
      find.byKey(SpeedrunKeys.item('rung.1000@${threeTwo.code}')),
      findsOneWidget,
    );
    expect((await settings.load()).clock.speedrunTime, threeTwo);
  });

  testWidgets('o Ultra Bullet é um grupo antes do Bullet, com 10 s, 15 s e '
      '30 s', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(SpeedrunKeys.paceCategory('ultraBullet')));
    await tester.pumpAndSettle();
    for (final code in ['10+0', '15+0', '30+0']) {
      expect(find.byKey(SpeedrunKeys.paceOption(code)), findsOneWidget);
    }
    expect(find.text('30 s'), findsWidgets);

    await tester.tap(find.byKey(SpeedrunKeys.paceOption('30+0')));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.item('rung.1000@30+0')), findsOneWidget);
  });

  testWidgets('o modo no alto troca a lista e o ritmo; a Maratona tem o ritmo '
      'dela, e o modo fica gravado', (tester) async {
    await pump(tester);
    // Clássico: os speedruns, sem as Maratonas.
    expect(find.byKey(SpeedrunKeys.item('rung.1000')), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.item('marathon.queen')), findsNothing);

    await tester.tap(find.byKey(SpeedrunKeys.modeOption('marathon')));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.item('marathon.queen')), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.item('rung.1000')), findsNothing);

    await tester.tap(find.byKey(SpeedrunKeys.paceCategory('ultraBullet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.paceOption('30+0')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(SpeedrunKeys.item('marathon.queen@30+0')),
      findsOneWidget,
    );
    final saved = (await settings.load()).clock;
    expect(saved.speedrunMarathon, isTrue);
    expect(
      saved.marathonTime,
      const TimeControl(initial: Duration(seconds: 30)),
    );
    // O ritmo do clássico não mudou.
    expect(saved.speedrunTime, isNull);

    // De volta ao clássico: o ritmo dele.
    await tester.tap(find.byKey(SpeedrunKeys.modeOption('classic')));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.item('rung.1000')), findsOneWidget);
    expect((await settings.load()).clock.speedrunMarathon, isFalse);
  });

  testWidgets('a lista abre no modo gravado', (tester) async {
    await settings.save(
      const AppSettings(clock: ClockSettings(speedrunMarathon: true)),
    );
    await pump(tester);
    expect(find.byKey(SpeedrunKeys.item('marathon.queen')), findsOneWidget);
  });

  testWidgets('a dificuldade dos finais: abre na do nível e troca com um '
      'toque', (tester) async {
    await cubit.close();
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
      games: FakeOngoingGameRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 4, 12)),
      settings: settings,
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(
        UserProfile(rating: RatingLevel.master.rating),
      ),
    );
    await pump(tester);
    // Mestre: os avançados; o mate de dama (iniciante) fica na outra aba.
    expect(find.byKey(SpeedrunKeys.item('ending.queen@60+0')), findsNothing);
    // O speedrun contra o Coco (1000) é de iniciante: some no avançado.
    expect(find.byKey(SpeedrunKeys.item('rung.1000@60+0')), findsNothing);
    await tester.tap(find.byKey(SpeedrunKeys.categoryOption('beginner')));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.item('ending.queen@60+0')), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.item('rung.1000@60+0')), findsOneWidget);
  });

  testWidgets('quem está começando vê o ritmo numa linha, que abre o '
      'seletor', (tester) async {
    await cubit.close();
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
      games: FakeOngoingGameRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 4, 12)),
      settings: settings,
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(
        UserProfile(rating: RatingLevel.beginner.rating),
      ),
    );
    await pump(tester);
    expect(find.byKey(SpeedrunKeys.compactPace), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.pace), findsNothing);
    expect(find.text('Pace: 15 min + 10 s'), findsOneWidget);

    await tester.tap(find.byKey(SpeedrunKeys.compactPace));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PaceKeys.option('180+0')));
    await tester.tap(find.byKey(PaceKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.text('Pace: 3 min + 0 s'), findsOneWidget);
    expect((await settings.load()).clock.speedrunTime!.code, '180+0');
  });
  for (final locale in [
    const Locale('en'),
    const Locale('pt'),
    const Locale('es'),
  ]) {
    for (final marathon in [false, true]) {
      for (final time in [
        const TimeControl(initial: Duration(seconds: 10)),
        const TimeControl(initial: Duration(seconds: 15)),
        const TimeControl(initial: Duration(seconds: 30)),
        const TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
      ]) {
        testWidgets(
          'C12b $locale maratona=$marathon ${time.code}: ajuda usa ritmo atual, modos e rolagem com fonte grande',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = 1.6;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await settings.save(
              AppSettings(
                clock: ClockSettings(
                  speedrunTime: marathon
                      ? const TimeControl(
                          initial: Duration(minutes: 5),
                          increment: Duration(seconds: 3),
                        )
                      : time,
                  marathonTime: marathon
                      ? time
                      : const TimeControl(
                          initial: Duration(minutes: 5),
                          increment: Duration(seconds: 3),
                        ),
                  speedrunMarathon: marathon,
                ),
              ),
            );
            await pump(tester, locale: locale, small: true);
            final l10n = tester.element(find.byKey(SpeedrunKeys.help)).l10n;
            await tester.tap(find.byKey(SpeedrunKeys.help));
            await tester.pumpAndSettle();
            expect(find.text(l10n.speedrunHelpClassic), findsOneWidget);
            expect(find.text(l10n.speedrunHelpMarathon), findsOneWidget);
            expect(
              find.text(l10n.speedrunPaceLine(paceShort(l10n, time))),
              findsOneWidget,
            );
            final initial = time.initial < const Duration(minutes: 1)
                ? l10n.paceSeconds(time.initial.inSeconds)
                : l10n.setupPaceCustomMinutes(time.initial.inMinutes);
            expect(
              tester.widget<Text>(find.byKey(SpeedrunKeys.paceHelp)).data,
              l10n.speedrunHelpClock(initial, time.increment.inSeconds),
            );
            // A ajuda exibe os mesmos nomes e agrupamentos da lista, inclusive
            // as séries de adversário, sem outra classificação paralela.
            final scroll = find.ancestor(
              of: find.byKey(SpeedrunKeys.paceHelp),
              matching: find.byType(SingleChildScrollView),
            );
            expect(scroll, findsOneWidget);
            for (final summary in cubit.state.all!) {
              if (SpeedrunCategories.of(summary.speedrun) != null) {
                final name = speedrunName(
                  l10n,
                  cubit.state.characters,
                  summary.speedrun,
                );
                expect(
                  find.descendant(
                    of: scroll,
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget is Text &&
                          (widget.data?.contains(name) ?? false),
                    ),
                  ),
                  findsWidgets,
                );
              }
            }
            final pause = find.text(l10n.speedrunHelpPause);
            expect(pause.hitTestable(), findsNothing);
            await tester.ensureVisible(pause);
            await tester.pumpAndSettle();
            expect(pause.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            // Retornar ao início continua possível após ler a última seção.
            await tester.ensureVisible(find.byKey(SpeedrunKeys.intro));
            await tester.pumpAndSettle();
            expect(
              find.byKey(SpeedrunKeys.intro).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
