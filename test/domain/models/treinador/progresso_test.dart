import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/progresso.dart';

ResultadoExercicio _r(
  int n, {
  bool acertou = true,
  int tentativas = 1,
  bool viuSolucao = false,
}) => ResultadoExercicio(
  n: n,
  acertou: acertou,
  pontos: acertou ? 10 : 0,
  tentativas: tentativas,
  viuSolucao: viuSolucao,
);

void main() {
  group('ProgressoPartida.resultados do servidor (primeiras)', () {
    test('de primeira só com uma tentativa e sem a solução', () {
      final p = ProgressoPartida.vazio
          .com(_r(1))
          .com(_r(2, tentativas: 2))
          .com(_r(3, acertou: false, tentativas: 3, viuSolucao: true));
      expect(p.toRemoto()['resultados'], {'1': true, '2': false, '3': false});
    });

    test('gravado uma vez: refazer e acertar depois não muda', () {
      final primeira = ProgressoPartida.vazio.com(
        _r(1, acertou: false, viuSolucao: true),
      );
      final refeito = primeira.recomecar().com(_r(1));
      expect(refeito.feitos, 1);
      expect(refeito.acertos, 1);
      expect(refeito.toRemoto()['resultados'], {'1': false});
    });

    test('recomeçar zera a rodada e guarda a análise vista', () {
      final p = ProgressoPartida.vazio.com(_r(1)).comAnaliseVista();
      final r = p.recomecar();
      expect(r.feitos, 0);
      expect(r.viuAnalise, isTrue);
      expect(r.primeiras, {1: true});
    });
  });

  group('viuAnalise', () {
    test('só vai ao servidor quando verdadeiro', () {
      expect(
        ProgressoPartida.vazio.toRemoto().containsKey('viuAnalise'),
        isFalse,
      );
      expect(
        ProgressoPartida.vazio.comAnaliseVista().toRemoto()['viuAnalise'],
        isTrue,
      );
    });

    test('marcar a análise mantém os resultados e o espelho', () {
      const remoto = ProgressoPartida(
        feitosRemoto: 3,
        acertosRemoto: 2,
        pontosRemoto: 20,
      );
      final p = remoto.comAnaliseVista();
      expect((p.feitos, p.acertos, p.pontos), (3, 2, 20));
    });
  });

  group('json', () {
    test('o do aparelho volta igual (também depois de fechar o app)', () {
      final p = ProgressoPartida.vazio
          .com(_r(1))
          .com(_r(2, acertou: false, viuSolucao: true))
          .comAnaliseVista();
      final lido = ProgressoPartida.fromJson(
        jsonDecode(jsonEncode(p.toJson())),
      );
      expect(lido.resultados.map((r) => r.n), [1, 2]);
      expect(lido.primeiras, {1: true, 2: false});
      expect(lido.viuAnalise, isTrue);
      expect(lido.acertos, 1);
    });

    test('o espelho do servidor lê resultados em mapa', () {
      final lido = ProgressoPartida.fromJson({
        'feitos': 2,
        'acertos': 1,
        'pontos': 10,
        'resultados': {'1': true, '2': false, 'x': true, '3': 'sim'},
        'viuAnalise': true,
      });
      expect(lido.resultados, isEmpty);
      expect(lido.primeiras, {1: true, 2: false});
      expect(lido.feitos, 2);
      expect(lido.viuAnalise, isTrue);
    });
  });
}
