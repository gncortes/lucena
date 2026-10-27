import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/home_shortcut.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_shortcuts.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';

// Um caso por célula da prancha "Atalhos por tipo de usuário" (T83).
void main() {
  const journey = HomeShortcut.journey;
  const endgames = HomeShortcut.endgames;
  const train = HomeShortcut.train;
  const speedrun = HomeShortcut.speedrun;
  const race = HomeShortcut.race;
  const stars = HomeShortcut.stars;

  List<HomePath> order(
    RatingLevel level, {
    GoalPreference? goal,
    bool course = true,
  }) =>
      HomeSuggestion.of(level, school: false, course: course, goal: goal).order;

  test('aprender a jogar antes de vencer o Coco: só Estrelas e Problemas', () {
    expect(
      HomeShortcuts.of(
        order: order(RatingLevel.beginner, goal: GoalPreference.learn),
        hero: HomePath.journey,
        learning: true,
        firstWin: false,
      ),
      [stars, race],
    );
  });

  test('aprender a jogar depois do Coco: Estrelas primeiro, o treino antes '
      'do curso e os Problemas', () {
    expect(
      HomeShortcuts.of(
        order: order(RatingLevel.beginner, goal: GoalPreference.learn),
        hero: HomePath.journey,
        learning: true,
      ),
      [stars, train, endgames, race],
    );
  });

  test('aprender finais: sem o Curso, que é o cartão', () {
    expect(
      HomeShortcuts.of(
        order: order(RatingLevel.intermediate, goal: GoalPreference.endgames),
        hero: HomePath.endgames,
      ),
      [journey, train, speedrun, race],
    );
  });

  test('treinar finais: os finais para você entram no Curso', () {
    final paths = order(RatingLevel.intermediate, goal: GoalPreference.train);
    expect(paths, contains(HomePath.forYou));
    expect(HomeShortcuts.of(order: paths, hero: HomePath.train), [
      journey,
      endgames,
      speedrun,
      race,
    ]);
  });

  test('sem objetivo: sem a Jornada do cartão', () {
    expect(
      HomeShortcuts.of(
        order: order(RatingLevel.casual),
        hero: HomePath.journey,
      ),
      [endgames, train, speedrun, race],
    );
  });

  test('sem aula liberada: o Curso some e as Estrelas completam', () {
    expect(
      HomeShortcuts.of(
        order: order(
          RatingLevel.intermediate,
          goal: GoalPreference.endgames,
          course: false,
        ),
        hero: HomePath.train,
      ),
      [journey, speedrun, race, stars],
    );
  });

  test('curso concluído: o cartão é o treino; o curso fica para rever', () {
    expect(
      HomeShortcuts.of(
        order: order(RatingLevel.intermediate, goal: GoalPreference.endgames),
        hero: HomePath.train,
        courseDone: true,
      ),
      [journey, speedrun, endgames, race],
    );
  });

  test('Jornada vencida: o Speedrun no lugar dela e as Estrelas antes dos '
      'Problemas', () {
    expect(
      HomeShortcuts.of(
        order: order(RatingLevel.beginner, goal: GoalPreference.learn),
        hero: HomePath.train,
        learning: true,
        journeyDone: true,
      ),
      [speedrun, endgames, stars, race],
    );
  });

  group('sem objetivo, pela faixa de rating', () {
    test('até 999 (iniciante)', () {
      expect(
        HomeShortcuts.of(
          order: order(RatingLevel.beginner),
          hero: HomePath.journey,
        ),
        [endgames, train, speedrun, race],
      );
    });

    test('1000–1599', () {
      expect(
        HomeShortcuts.of(
          order: order(RatingLevel.intermediate),
          hero: HomePath.journey,
        ),
        [endgames, train, speedrun, race],
      );
    });

    test('1600–1899, com a aula aberta no cartão', () {
      expect(
        HomeShortcuts.of(
          order: order(RatingLevel.advanced),
          hero: HomePath.endgames,
        ),
        [journey, speedrun, train, race],
      );
    });

    test('1900–2199', () {
      expect(
        HomeShortcuts.of(
          order: order(RatingLevel.expert),
          hero: HomePath.journey,
        ),
        [endgames, speedrun, train, race],
      );
    });

    test('2200+', () {
      expect(
        HomeShortcuts.of(
          order: order(RatingLevel.master),
          hero: HomePath.journey,
        ),
        [speedrun, endgames, train, race],
      );
    });
  });

  test('a Escola nunca vira atalho e nada se repete', () {
    final shortcuts = HomeShortcuts.of(
      order: HomeSuggestion.of(RatingLevel.beginner, school: true).order,
    );
    expect(shortcuts, [journey, endgames, train, race]);
    expect(shortcuts.toSet(), hasLength(shortcuts.length));
  });
}
