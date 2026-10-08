import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
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

  setUp(() {
    settings = FakeSettingsRepository(const AppSettings());
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(
        speedruns: [...sampleSpeedruns, sampleMarathon],
      ),
      speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
      games: FakeOngoingGameRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 4, 12)),
      settings: settings,
      characters: FakeCharacterRepository(),
    );
  });
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.625;
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
}
