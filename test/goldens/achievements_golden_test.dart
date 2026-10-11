import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/ui/achievements/view_models/achievement_facts_loader.dart';
import 'package:lucena/ui/achievements/view_models/achievements_cubit.dart';
import 'package:lucena/ui/achievements/widgets/achievement_detail.dart';
import 'package:lucena/ui/achievements/widgets/achievements_screen.dart';

import '../../testing/fakes/fake_achievements_repository.dart';
import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_journey_repository.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_positions_repository.dart';
import '../../testing/fakes/fake_progress_repository.dart';
import '../../testing/fakes/fake_speedrun_repository.dart';
import '../../testing/goldens/golden_harness.dart';
import '../../testing/test_app.dart';

/// As conquistas de verdade, do catálogo.
List<Achievement> _catalog() {
  final json = jsonDecode(
    File('assets/achievements.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [
    for (final entry
        in (json['achievements'] as List).cast<Map<String, dynamic>>())
      ?Achievement.fromJson(entry),
  ];
}

final _now = DateTime(2026, 10, 8, 12);

void main() {
  // A lista com algumas conquistadas em dias diferentes.
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('achievements_list · ${theme.name}', (tester) async {
      await Goldens.loadFonts();
      final repository = FakeAchievementsRepository(_catalog());
      await repository.unlock([
        UnlockedAchievement(id: 'first-fulfilled', at: _now, gameId: 1),
        UnlockedAchievement(
          id: 'beat-1000',
          at: _now.subtract(const Duration(days: 1)),
          gameId: 2,
        ),
        UnlockedAchievement(
          id: 'beat-1200',
          at: _now.subtract(const Duration(days: 3)),
        ),
        UnlockedAchievement(
          id: 'first-speedrun',
          at: _now.subtract(const Duration(days: 40)),
        ),
      ]);
      const size = Size(412, 1400);
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          themeMode: theme,
          child: MediaQuery(
            data: const MediaQueryData(size: size, disableAnimations: true),
            child: BlocProvider(
              create: (_) => AchievementsCubit(
                repository,
                now: FakeNow(_now),
                characters: FakeCharacterRepository(),
                facts: AchievementFactsLoader(
                  journey: FakeJourneyRepository(),
                  progress: FakeProgressRepository(),
                  speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
                  positions: FakePositionsRepository(),
                ),
              )..load(),
              child: const AchievementsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AchievementsScreen),
        matchesGoldenFile('goldens/achievements/list_${theme.name}.png'),
      );
    });
  }

  // O detalhe: conquistada com a partida de origem e faltando com o atalho.
  final catalog = _catalog();
  Achievement byId(String id) => catalog.firstWhere((a) => a.id == id);
  final details = {
    'unlocked': AchievementDetail(
      achievement: byId('beat-1000'),
      unlocked: UnlockedAchievement(
        id: 'beat-1000',
        at: DateTime(2026, 10, 7, 22, 41),
        gameId: 7,
      ),
      characters: FakeCharacterRepository.sampleCharacters,
      onOpen: (_) {},
    ),
    'locked': AchievementDetail(
      achievement: byId('all-levels-queen'),
      characters: FakeCharacterRepository.sampleCharacters,
      progress: const AchievementProgress(
        done: 3,
        total: 9,
        unit: AchievementProgressUnit.levels,
      ),
      onOpen: (_) {},
    ),
  };
  for (final MapEntry(key: name, value: detail) in details.entries) {
    Goldens.matrix('achievement_detail_$name', (variant) => detail);
  }
}
