import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/placement/view_models/placement_cubit.dart';
import 'package:lucena/ui/placement/widgets/placement_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/placement_synthetic.dart';

void main() {
  final skills = SkillMap.fromJson(syntheticSkillsJson());
  final bank = PlacementBank.fromJson(syntheticItemsJson());

  Future<(PlacementCubit, FakeProfileRepository)> pump(
    WidgetTester tester, {
    VoidCallback? onDone,
    VoidCallback? onChooseByHand,
    Size size = const Size(400, 800),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final profile = FakeProfileRepository();
    final cubit = PlacementCubit(
      placement: FakePlacementRepository(skills: skills, bank: bank),
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
        child: BlocProvider.value(
          value: cubit,
          child: PlacementScreen(
            onDone: onDone,
            onChooseByHand: onChooseByHand,
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

  for (final size in [const Size(360, 640), const Size(412, 915)]) {
    testWidgets('T64, $size: o tabuleiro no centro do espaço entre a barra '
        'do app e as respostas, com a pergunta colada nele', (tester) async {
      final (cubit, _) = await pump(tester, size: size);
      await cubit.start();
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        final appBar = tester.getRect(find.byType(AppBar));
        final answers = tester.getRect(find.byKey(PlacementKeys.answers));
        final board = tester.getRect(find.byKey(PlacementKeys.board));
        final prompt = tester.getRect(find.byKey(PlacementKeys.prompt));
        expect(board.center.dy, closeTo((appBar.bottom + answers.top) / 2, 1));
        expect(
          prompt.bottom <= board.top || prompt.top >= board.bottom,
          isTrue,
        );
        expect(answers.top, greaterThanOrEqualTo(board.bottom));
        expect(tester.takeException(), isNull);
        await cubit.answer(PlacementOutcome.dontKnow);
        await tester.pumpAndSettle();
      }
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
