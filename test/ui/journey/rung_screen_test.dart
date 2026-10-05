import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/journey/widgets/rung_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  final rung = sampleLadder.first;
  final queen = rung.challenges[0];
  final rook = rung.challenges[1];

  Future<void> pump(WidgetTester tester, {Set<String> done = const {}}) async {
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository([
        for (final id in done)
          Attempt(
            positionId: 'basic.queen.0001',
            playedAt: DateTime.utc(2026, 10),
            outcome: AttemptOutcome.win,
            fulfilled: true,
            opponent: OpponentKind.maia,
            challengeId: id,
          ),
      ]),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: RungScreen(rungId: rung.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('o personagem no alto, com o progresso', (tester) async {
    await pump(tester, done: {queen.id});

    expect(find.text('Coco'), findsWidgets);
    expect(find.text('1 of 2 challenges'), findsOneWidget);
  });

  testWidgets('o próximo desafio por fazer fica em destaque', (tester) async {
    await pump(tester, done: {queen.id});

    final next = find.byKey(JourneyKeys.nextChallenge);
    expect(next, findsOneWidget);
    // O da torre é o que falta: o nome do final aparece no destaque.
    expect(
      find.descendant(of: next, matching: find.text('Rook mate')),
      findsOneWidget,
    );
    expect(find.byKey(JourneyKeys.nextChallengePlay), findsOneWidget);
  });

  testWidgets('a grade marca os feitos', (tester) async {
    await pump(tester, done: {queen.id});

    expect(
      find.byKey(JourneyKeys.challengeDone(queen.position.id)),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(JourneyKeys.challenge(rook.position.id)),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(JourneyKeys.challengeDone(rook.position.id)),
      findsNothing,
    );
  });

  testWidgets('tudo feito: sem destaque de próximo desafio', (tester) async {
    await pump(tester, done: {queen.id, rook.id});

    expect(find.byKey(JourneyKeys.nextChallenge), findsNothing);
  });
}
