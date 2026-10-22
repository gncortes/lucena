import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/update_policy.dart';

void main() {
  UpdateDecision decide({
    int build = 100,
    int minBuild = 0,
    int recommendedBuild = 0,
    int seen = 0,
    bool? playHasUpdate = true,
  }) => UpdatePolicy.decide(
    build: build,
    minBuild: minBuild,
    recommendedBuild: recommendedBuild,
    seen: seen,
    playHasUpdate: playHasUpdate,
  );

  test('o padrão 0 nunca bloqueia nem recomenda', () {
    expect(decide(build: 1), UpdateDecision.none);
    expect(decide(build: 1, playHasUpdate: null), UpdateDecision.none);
  });

  test('build igual à mínima não bloqueia', () {
    expect(decide(minBuild: 100), UpdateDecision.none);
  });

  test('build abaixo da mínima bloqueia', () {
    expect(decide(minBuild: 101), UpdateDecision.required);
  });

  test('fora da Play (sem resposta), abaixo da mínima também bloqueia', () {
    expect(decide(minBuild: 101, playHasUpdate: null), UpdateDecision.required);
  });

  test('a Play sem versão nova vira recomendada', () {
    expect(
      decide(minBuild: 101, playHasUpdate: false),
      UpdateDecision.recommended,
    );
  });

  test('abaixo da recomendada, recomenda', () {
    expect(decide(recommendedBuild: 110), UpdateDecision.recommended);
    expect(decide(recommendedBuild: 100), UpdateDecision.none);
  });

  test('a recomendada vista não volta para o mesmo valor', () {
    expect(decide(recommendedBuild: 110, seen: 110), UpdateDecision.none);
  });

  test('a recomendada vista volta para um valor maior', () {
    expect(
      decide(recommendedBuild: 120, seen: 110),
      UpdateDecision.recommended,
    );
  });

  test('a mínima que virou recomendada é um valor novo', () {
    expect(
      UpdatePolicy.recommendedTarget(minBuild: 130, recommendedBuild: 110),
      130,
    );
    expect(
      decide(
        minBuild: 130,
        recommendedBuild: 110,
        seen: 110,
        playHasUpdate: false,
      ),
      UpdateDecision.recommended,
    );
  });
}
