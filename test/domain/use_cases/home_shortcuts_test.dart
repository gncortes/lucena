import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/home_shortcut.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_shortcuts.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';

// Um caso por célula da prancha "Atalhos por usuário" v2 (T83): todos os
// caminhos marcados, na ordem do nível, e os Problemas e as Estrelas no fim.
void main() {
  const school = HomeShortcut.school;
  const journey = HomeShortcut.journey;
  const endgames = HomeShortcut.endgames;
  const train = HomeShortcut.train;
  const speedrun = HomeShortcut.speedrun;
  const race = HomeShortcut.race;
  const stars = HomeShortcut.stars;

  List<HomeShortcut> shortcuts(
    RatingLevel level, {
    GoalPreference? goal,
    bool course = true,
    bool school = false,
    Set<HomePath> unchecked = const {},
  }) {
    final layout = HomeSuggestion.of(
      level,
      school: school,
      course: course,
      goal: goal,
    );
    return HomeShortcuts.of(
      order: layout.order,
      visible: layout.visible.difference(unchecked),
      learning: goal == GoalPreference.learn,
    );
  }

  test('aprender a jogar: Escola, Jornada, Problemas e Estrelas', () {
    expect(shortcuts(RatingLevel.beginner, goal: GoalPreference.learn), [
      school,
      journey,
      race,
      stars,
    ]);
  });

  test('aprender a jogar: some o que a pessoa desmarcou, a Escola também', () {
    expect(
      shortcuts(
        RatingLevel.beginner,
        goal: GoalPreference.learn,
        unchecked: {HomePath.journey, HomePath.stars},
      ),
      [school, race],
    );
    expect(
      shortcuts(
        RatingLevel.beginner,
        goal: GoalPreference.learn,
        unchecked: {HomePath.learn},
      ),
      [journey, race, stars],
    );
  });

  test('aprender finais (1450): o Curso primeiro, mesmo sendo o cartão', () {
    expect(shortcuts(RatingLevel.intermediate, goal: GoalPreference.endgames), [
      endgames,
      journey,
      train,
      speedrun,
      race,
      stars,
    ]);
  });

  test('treinar finais (1450): o treino primeiro; os finais para você entram '
      'no Curso', () {
    expect(shortcuts(RatingLevel.intermediate, goal: GoalPreference.train), [
      train,
      journey,
      endgames,
      speedrun,
      race,
      stars,
    ]);
  });

  test('sem objetivo (1450): a ordem do nível', () {
    expect(shortcuts(RatingLevel.intermediate), [
      journey,
      endgames,
      train,
      speedrun,
      race,
      stars,
    ]);
  });

  test('desmarcados em Configurações > Tela inicial somem', () {
    expect(
      shortcuts(
        RatingLevel.intermediate,
        goal: GoalPreference.endgames,
        unchecked: {HomePath.speedrun, HomePath.stars},
      ),
      [endgames, journey, train, race],
    );
  });

  test('sem aula liberada: o Curso some', () {
    expect(
      shortcuts(
        RatingLevel.intermediate,
        goal: GoalPreference.endgames,
        course: false,
      ),
      isNot(contains(endgames)),
    );
  });

  test('com a Escola liberada, o iniciante a vê primeiro', () {
    expect(shortcuts(RatingLevel.beginner, school: true).first, school);
  });

  test('nada se repete, em nenhum nível e objetivo', () {
    for (final level in RatingLevel.values) {
      for (final goal in [null, ...GoalPreference.values]) {
        final list = shortcuts(level, goal: goal, school: true);
        expect(list.toSet(), hasLength(list.length), reason: '$level $goal');
        expect(list.sublist(list.length - 2), [race, stars]);
      }
    }
  });
}
