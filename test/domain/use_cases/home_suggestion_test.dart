import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';

void main() {
  const learn = HomePath.learn;
  const journey = HomePath.journey;
  const endgames = HomePath.endgames;
  const forYou = HomePath.forYou;
  const speedrun = HomePath.speedrun;
  const train = HomePath.train;
  const race = HomePath.race;
  const stars = HomePath.stars;

  test('a sugestão de cada nível: a ordem e os marcados', () {
    final expected = {
      // Os finais para você vêm logo antes das aulas de finais e são
      // marcados com elas.
      RatingLevel.beginner: (
        [learn, journey, forYou, endgames, train, speedrun, race, stars],
        {learn, journey, race, stars},
      ),
      RatingLevel.casual: (
        [journey, forYou, endgames, train, speedrun, race, stars, learn],
        {journey, forYou, endgames, train, race, stars},
      ),
      RatingLevel.intermediate: (
        [journey, forYou, endgames, train, speedrun, race, stars, learn],
        {journey, forYou, endgames, train, speedrun, race, stars},
      ),
      RatingLevel.advanced: (
        [forYou, endgames, journey, speedrun, race, stars, train, learn],
        {forYou, endgames, journey, speedrun, train, race, stars},
      ),
      RatingLevel.expert: (
        [forYou, endgames, speedrun, race, stars, train, journey, learn],
        {forYou, endgames, speedrun, train, race, stars},
      ),
      RatingLevel.master: (
        [speedrun, forYou, endgames, race, stars, train, journey, learn],
        {speedrun, forYou, endgames, train, race, stars},
      ),
    };
    for (final MapEntry(key: level, value: (order, visible))
        in expected.entries) {
      // Com a Escola liberada; sem ela, visible_lessons_test.
      final layout = HomeSuggestion.of(level, school: true);
      expect(layout.order, order, reason: level.name);
      expect(layout.visible, visible, reason: level.name);
      expect(layout.custom, isFalse);
      // Todos os caminhos, sempre.
      expect(layout.order.toSet(), HomePath.values.toSet());
    }
  });

  test(
    'o caminho do objetivo vem primeiro e marcado; o resto segue o nível',
    () {
      // Aprender a jogar, iniciante: a Escola já era a primeira.
      var layout = HomeSuggestion.of(
        RatingLevel.beginner,
        school: true,
        goal: GoalPreference.learn,
      );
      expect(layout.order, [
        learn,
        journey,
        forYou,
        endgames,
        train,
        speedrun,
        race,
        stars,
      ]);
      expect(layout.visible, {learn, journey, race, stars});

      // Aprender finais, avançado: as aulas sobem e os finais para você vêm
      // logo depois delas.
      layout = HomeSuggestion.of(
        RatingLevel.advanced,
        school: true,
        goal: GoalPreference.endgames,
      );
      expect(layout.order, [
        endgames,
        forYou,
        journey,
        speedrun,
        race,
        stars,
        train,
        learn,
      ]);
      expect(layout.visible, {
        endgames,
        forYou,
        journey,
        speedrun,
        train,
        race,
        stars,
      });

      // Treinar finais, iniciante: o treino entra marcado, além dos do nível.
      layout = HomeSuggestion.of(
        RatingLevel.beginner,
        school: true,
        goal: GoalPreference.train,
      );
      expect(layout.order, [
        train,
        learn,
        journey,
        forYou,
        endgames,
        speedrun,
        race,
        stars,
      ]);
      expect(layout.visible, {train, learn, journey, race, stars});
      expect(layout.order.toSet(), HomePath.values.toSet());
    },
  );

  test('sem a Escola, o objetivo de aprender a jogar cai na Jornada', () {
    expect(
      HomeSuggestion.goalPath(GoalPreference.learn, school: false),
      journey,
    );
    expect(HomeSuggestion.goalPath(GoalPreference.learn, school: true), learn);
    final layout = HomeSuggestion.of(
      RatingLevel.expert,
      school: false,
      goal: GoalPreference.learn,
    );
    // A Escola fica primeira e marcada (abre como as peças se movem), para
    // poder ser desmarcada em Configurações > Tela inicial.
    expect(layout.order.take(2), [learn, journey]);
    expect(layout.visible, containsAll([learn, journey]));
    // Sem esse objetivo, a Escola sai.
    expect(
      HomeSuggestion.of(RatingLevel.expert, school: false).order,
      isNot(contains(learn)),
    );
  });

  test('aprender a jogar: desmarcar a Escola a tira dos atalhos', () {
    final layout = HomeSuggestion.of(
      RatingLevel.beginner,
      school: false,
      goal: GoalPreference.learn,
    );
    expect(HomeSuggestion.canHide(layout, learn), isTrue);
    final hidden = HomeSuggestion.toggle(layout, learn, RatingLevel.beginner);
    expect(hidden.shown, isNot(contains(learn)));
    expect(
      HomeSuggestion.resolve(
        hidden,
        RatingLevel.beginner,
        school: false,
        goal: GoalPreference.learn,
      ).order.first,
      learn,
    );
  });

  test('o Personalizar ganha do objetivo', () {
    final suggestion = HomeSuggestion.of(RatingLevel.casual);
    final mine = HomeSuggestion.toggle(suggestion, train, RatingLevel.casual);
    expect(
      HomeSuggestion.resolve(
        mine,
        RatingLevel.casual,
        goal: GoalPreference.train,
      ),
      mine,
    );
    expect(
      HomeSuggestion.resolve(
        null,
        RatingLevel.casual,
        goal: GoalPreference.train,
      ),
      HomeSuggestion.of(RatingLevel.casual, goal: GoalPreference.train),
    );
    // Mexer e voltar à ordem do objetivo deixa de ser ajuste.
    final withGoal = HomeSuggestion.of(
      RatingLevel.casual,
      goal: GoalPreference.train,
    );
    final moved = HomeSuggestion.move(
      withGoal,
      0,
      2,
      RatingLevel.casual,
      goal: GoalPreference.train,
    );
    expect(moved.custom, isTrue);
    expect(
      HomeSuggestion.move(
        moved,
        2,
        0,
        RatingLevel.casual,
        goal: GoalPreference.train,
      ).custom,
      isFalse,
    );
  });

  test('sem ajuste, a sugestão acompanha o nível; ajustado, não', () {
    final suggestion = HomeSuggestion.of(RatingLevel.beginner);
    expect(
      HomeSuggestion.resolve(suggestion, RatingLevel.master),
      HomeSuggestion.of(RatingLevel.master),
    );
    expect(
      HomeSuggestion.resolve(null, RatingLevel.master),
      HomeSuggestion.of(RatingLevel.master),
    );
    final mine = HomeSuggestion.toggle(suggestion, train, RatingLevel.beginner);
    expect(mine.custom, isTrue);
    expect(HomeSuggestion.resolve(mine, RatingLevel.master), mine);
  });

  test('pelo menos um caminho fica visível', () {
    var layout = HomeSuggestion.of(RatingLevel.beginner, school: true);
    layout = HomeSuggestion.toggle(layout, learn, RatingLevel.beginner);
    layout = HomeSuggestion.toggle(layout, race, RatingLevel.beginner);
    layout = HomeSuggestion.toggle(layout, stars, RatingLevel.beginner);
    expect(HomeSuggestion.canHide(layout, journey), isFalse);
    layout = HomeSuggestion.toggle(layout, journey, RatingLevel.beginner);
    expect(layout.visible, {journey});
    expect(
      HomeSuggestion.withVisible(layout, {}, RatingLevel.beginner),
      layout,
    );
  });

  test('voltar a ficar igual à sugestão deixa de ser ajuste', () {
    final suggestion = HomeSuggestion.of(RatingLevel.casual);
    final moved = HomeSuggestion.move(suggestion, 0, 2, RatingLevel.casual);
    expect(moved.order.take(3), [forYou, endgames, journey]);
    expect(moved.custom, isTrue);
    final back = HomeSuggestion.move(moved, 2, 0, RatingLevel.casual);
    expect(back, suggestion);
    expect(back.custom, isFalse);
  });

  test('o texto de cada caminho pelo nível', () {
    expect(
      HomeSuggestion.textOf(journey, RatingLevel.beginner),
      HomePathText.standard,
    );
    // A Jornada e a Escola têm um texto só, em todo nível.
    for (final level in RatingLevel.values) {
      expect(HomeSuggestion.textOf(journey, level), HomePathText.standard);
      expect(HomeSuggestion.textOf(learn, level), HomePathText.standard);
    }
    for (final level in RatingLevel.values) {
      expect(
        HomeSuggestion.textOf(speedrun, level),
        level == RatingLevel.expert || level == RatingLevel.master
            ? HomePathText.challenge
            : HomePathText.standard,
        reason: level.name,
      );
      expect(HomeSuggestion.textOf(train, level), HomePathText.standard);
    }
  });

  test('o Continuar só aponta para caminho visível', () {
    final layout = HomeSuggestion.of(RatingLevel.master);
    // A Jornada da vez está escondida: o primeiro visível com progresso.
    expect(
      HomeSuggestion.continuePath(
        layout,
        current: journey,
        withProgress: {journey, endgames},
      ),
      endgames,
    );
    expect(
      HomeSuggestion.continuePath(
        layout,
        current: journey,
        withProgress: {journey},
      ),
      isNull,
    );
    expect(
      HomeSuggestion.continuePath(
        layout,
        current: endgames,
        withProgress: {endgames},
      ),
      endgames,
    );
  });

  test('o layout gravado volta igual; caminho novo vai para o fim', () {
    final layout = HomeSuggestion.toggle(
      HomeSuggestion.of(RatingLevel.casual, school: true),
      speedrun,
      RatingLevel.casual,
    );
    expect(HomeLayout.fromJson(layout.toJson()), layout);
    final old = HomeLayout.fromJson({
      'order': ['train', 'journey'],
      'visible': [],
      'custom': true,
    })!;
    expect(old.order.take(2), [train, journey]);
    expect(old.order.toSet(), HomePath.values.toSet());
    // As Estrelas, que não existiam no gravado, entram marcadas.
    expect(old.visible, {stars});
    expect(HomeLayout.fromJson('nada'), isNull);
  });

  group('sem aula de final liberada (T83 B1)', () {
    test('o curso e os finais para você saem da sugestão de todo nível', () {
      for (final level in RatingLevel.values) {
        final layout = HomeSuggestion.of(level, school: false, course: false);
        expect(layout.order, isNot(contains(endgames)), reason: '$level');
        expect(layout.order, isNot(contains(forYou)), reason: '$level');
        expect(layout.visible, isNot(contains(endgames)), reason: '$level');
        expect(layout.visible, isNot(contains(forYou)), reason: '$level');
        expect(layout.visible, isNotEmpty);
      }
    });

    test('o objetivo "Aprender finais" cai em treinar finais', () {
      expect(
        HomeSuggestion.goalPath(GoalPreference.endgames, course: false),
        train,
      );
      final layout = HomeSuggestion.of(
        RatingLevel.intermediate,
        course: false,
        goal: GoalPreference.endgames,
      );
      expect(layout.order.first, train);
      expect(layout.visible, contains(train));
    });

    test('o layout ajustado pela pessoa também perde os dois', () {
      const saved = HomeLayout(
        order: [journey, forYou, endgames, train, speedrun, race],
        visible: {forYou, endgames},
        custom: true,
      );
      final layout = HomeSuggestion.resolve(
        saved,
        RatingLevel.casual,
        school: false,
        course: false,
      );
      expect(layout.order, [journey, train, speedrun, race]);
      expect(layout.visible, {journey});
    });

    test('com o curso, nada muda (volta sozinho)', () {
      expect(
        HomeSuggestion.of(RatingLevel.casual, school: false),
        HomeSuggestion.of(RatingLevel.casual, school: false, course: true),
      );
      expect(HomeSuggestion.goalPath(GoalPreference.endgames), endgames);
    });
  });
}
