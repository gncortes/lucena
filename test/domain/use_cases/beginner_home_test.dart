import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/use_cases/beginner_home.dart';

void main() {
  test('quem aprende a jogar só vê o rating depois de 3 partidas', () {
    expect(BeginnerHome.showsRating(GoalPreference.learn, 0), isFalse);
    expect(BeginnerHome.showsRating(GoalPreference.learn, 2), isFalse);
    expect(BeginnerHome.showsRating(GoalPreference.learn, 3), isTrue);
  });

  test('os outros objetivos (e nenhum) veem o rating logo', () {
    expect(BeginnerHome.showsRating(null, 0), isTrue);
    expect(BeginnerHome.showsRating(GoalPreference.train, 0), isTrue);
    expect(BeginnerHome.showsRating(GoalPreference.endgames, 0), isTrue);
  });

  test('os finais em destaque esperam a primeira vitória de quem aprende', () {
    expect(BeginnerHome.showsFeatured(GoalPreference.learn, false), isFalse);
    expect(BeginnerHome.showsFeatured(GoalPreference.learn, true), isTrue);
    expect(BeginnerHome.showsFeatured(null, false), isTrue);
    expect(BeginnerHome.showsFeatured(GoalPreference.train, false), isTrue);
  });
}
