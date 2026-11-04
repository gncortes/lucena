import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/hero_card.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

/// H-ANI-02 (combinado da D1): o tabuleiro do cartão do Início voa com o id
/// = FEN da posição que a tela de destino mostra ao abrir.
void main() {
  const fen = '8/8/8/4k3/8/8/4P3/4K3 w - - 0 1';

  testWidgets('o tabuleiro do cartão do curso é o TabuleiroHero da posição', (
    tester,
  ) async {
    final training = HomeTraining(
      config: TrainingCourseConfig.pilares,
      state: TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'hero-tabuleiro',
      ),
      resources: TrainingResources(
        banks: {
          'banco': [
            TrainingExercise(id: 'ex1', stars: 1, fen: fen, solution: ['e2e4']),
          ],
        },
      ),
      card: HomeCourseCard(
        HomeCourseStatus.exercise,
        HomeCourseDestination.exercise,
        'banco',
        goal: TrainingGoal(
          kind: GoalKind.exercise,
          ref: 'banco',
          itemId: 'ex1',
        ),
      ),
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: SettingsCubit(
          FakeSettingsRepository(const AppSettings()),
          languages: AppLanguage.selectable,
        )..load(),
        child: Scaffold(
          body: SingleChildScrollView(
            child: HeroCard(
              state: HomeState(
                ready: true,
                teacher: FakeCharacterRepository.viktor,
                training: training,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hero = find.ancestor(
      of: find.byKey(HomeKeys.heroBoard),
      matching: find.byType(TabuleiroHero),
    );
    expect(hero, findsOneWidget);
    expect(tester.widget<TabuleiroHero>(hero).id, fen);
    // Uma marca só: a do kit, sem a antiga do tabuleiro da partida.
    expect(
      find.descendant(
        of: find.byKey(HomeKeys.heroBoard),
        matching: find.byType(Hero),
      ),
      findsNothing,
    );
    final tags = tester
        .widgetList<Hero>(find.byType(Hero))
        .map((h) => h.tag)
        .toList();
    expect(tags, contains(TabuleiroHero.tag(fen)));
  });
}
