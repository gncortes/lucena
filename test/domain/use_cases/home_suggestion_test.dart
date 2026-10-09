import 'package:flutter_test/flutter_test.dart';
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

  test('a sugestão de cada nível: a ordem e os marcados', () {
    final expected = {
      // Os finais para você vêm logo antes das aulas de finais e são
      // marcados com elas.
      RatingLevel.beginner: (
        [learn, journey, forYou, endgames, train, speedrun],
        {learn, journey},
      ),
      RatingLevel.casual: (
        [journey, forYou, endgames, train, speedrun, learn],
        {journey, forYou, endgames, train},
      ),
      RatingLevel.intermediate: (
        [journey, forYou, endgames, train, speedrun, learn],
        {journey, forYou, endgames, train, speedrun},
      ),
      RatingLevel.advanced: (
        [forYou, endgames, journey, speedrun, train, learn],
        {forYou, endgames, journey, speedrun, train},
      ),
      RatingLevel.expert: (
        [forYou, endgames, speedrun, train, journey, learn],
        {forYou, endgames, speedrun, train},
      ),
      RatingLevel.master: (
        [speedrun, forYou, endgames, train, journey, learn],
        {speedrun, forYou, endgames, train},
      ),
    };
    for (final MapEntry(key: level, value: (order, visible))
        in expected.entries) {
      final layout = HomeSuggestion.of(level);
      expect(layout.order, order, reason: level.name);
      expect(layout.visible, visible, reason: level.name);
      expect(layout.custom, isFalse);
      // Todos os caminhos, sempre.
      expect(layout.order.toSet(), HomePath.values.toSet());
    }
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
    var layout = HomeSuggestion.of(RatingLevel.beginner);
    layout = HomeSuggestion.toggle(layout, learn, RatingLevel.beginner);
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
    expect(
      HomeSuggestion.textOf(journey, RatingLevel.casual),
      HomePathText.player,
    );
    expect(
      HomeSuggestion.textOf(learn, RatingLevel.master),
      HomePathText.player,
    );
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
      HomeSuggestion.of(RatingLevel.casual),
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
    expect(old.visible, {train});
    expect(HomeLayout.fromJson('nada'), isNull);
  });
}
