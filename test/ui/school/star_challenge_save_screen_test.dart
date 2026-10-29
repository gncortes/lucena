import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';
import 'package:lucena/ui/school/widgets/star_challenge_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';
import '../../../testing/test_app.dart';

class GateRuns extends FakeStarChallengeRepository {
  Completer<void> gate = Completer<void>();
  bool fail = true;
  @override
  Future<void> addRun({
    required ChallengePiece piece,
    required ChallengeLevel level,
    required int points,
    required DateTime at,
  }) async {
    await gate.future;
    if (fail) throw StateError('disk unavailable');
    await super.addRun(piece: piece, level: level, points: points, at: at);
  }
}

void main() {
  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets(
      'save pending and error expose retry without premature success $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final now = FakeNow(DateTime(2026, 10, 26, 12));
        final repository = GateRuns();
        final settings = SettingsCubit(
          FakeSettingsRepository(const AppSettings()),
          languages: AppLanguage.selectable,
        );
        addTearDown(settings.close);
        await settings.load();
        final cubit = StarChallengeCubit(
          progress: repository,
          now: now,
          tickEvery: const Duration(hours: 1),
        );
        addTearDown(cubit.close);
        await cubit.load(ChallengePiece.rook, ChallengeLevel.easy);
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            settingsCubit: settings,
            child: BlocProvider.value(
              value: cubit,
              child: const StarChallengeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(StarChallengeKeys.goButton));
        now.advance(const Duration(minutes: 1));
        cubit.tick();
        await tester.pump();
        expect(find.byKey(StarChallengeKeys.saveProgress), findsOneWidget);
        expect(find.byKey(StarChallengeKeys.result), findsNothing);
        repository.gate.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(StarChallengeKeys.saveError), findsOneWidget);
        expect(
          find.text('Não foi possível salvar seu progresso. Tente novamente.'),
          findsOneWidget,
        );
        expect(find.byKey(StarChallengeKeys.retrySave), findsOneWidget);
        expect(find.byKey(StarChallengeKeys.result), findsNothing);
        expect(tester.takeException(), isNull);
        repository.fail = false;
        repository.gate = Completer<void>();
        await tester.tap(find.byKey(StarChallengeKeys.retrySave));
        await tester.pump();
        expect(find.byKey(StarChallengeKeys.saveProgress), findsOneWidget);
        repository.gate.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(StarChallengeKeys.result), findsOneWidget);
        expect(find.byKey(StarChallengeKeys.retryButton), findsOneWidget);
        expect(repository.runs, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
