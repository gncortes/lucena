import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/journey/widgets/journey_screen.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Set<String> done = const {},
    Locale locale = const Locale('en'),
  }) async {
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
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: BlocProvider.value(value: cubit, child: const JourneyScreen()),
      ),
    );
  }

  testWidgets('mostra onde o jogador está, o próximo e os trancados', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('You are at Maia 1000'), findsOneWidget);
    expect(find.text('Next: Maia 1200'), findsOneWidget);
    expect(find.byKey(JourneyKeys.rungLocked('1200')), findsOneWidget);
    expect(find.byKey(JourneyKeys.rungLocked('stockfish')), findsOneWidget);
    expect(find.text('0 of 2 challenges'), findsWidgets);
  });

  testWidgets('tocar no degrau trancado diz quanto falta', (tester) async {
    await pump(tester, done: {'1000/basic.queen.0001'});

    await tester.tap(find.byKey(JourneyKeys.rung('1200')));
    await tester.pump();

    expect(
      find.text('Complete 1 more challenge at Maia 1000 to unlock'),
      findsOneWidget,
    );
  });

  testWidgets('degrau concluído ganha a marca e libera o seguinte', (
    tester,
  ) async {
    await pump(tester, done: {'1000/basic.queen.0001', '1000/basic.rook.0001'});

    expect(find.byKey(JourneyKeys.rungCompleted('1000')), findsOneWidget);
    expect(find.byKey(JourneyKeys.rungLocked('1200')), findsNothing);
    expect(find.text('You are at Maia 1200'), findsOneWidget);
  });

  testWidgets('em português', (tester) async {
    await pump(tester, locale: const Locale('pt'));

    expect(find.text('Você está no Maia 1000'), findsOneWidget);
  });
}
