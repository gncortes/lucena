import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';

import '../../../../testing/treinador_fixtures.dart';

void main() {
  group('PartidaTreinador', () {
    test('lê a partida pronta do canvas', () {
      final p = TreinadorFixtures.tiago();
      expect(p.pronta, isTrue);
      expect(p.plataforma, 'lichess');
      expect(p.adversario.nome, 'Tiago_Rook');
      expect(p.cor, CorPartida.pretas);
      expect(p.resultado, Resultado.derrota);
      expect(p.ritmo, Ritmo.blitz);
      expect(p.exercicios.map((e) => e.tipo), [
        TipoExercicio.adversario,
        TipoExercicio.profilaxia,
        TipoExercicio.seuMelhor,
        TipoExercicio.decisivo,
      ]);
      expect(p.exercicios.first.aceita('d3h7'), isTrue);
      expect(p.exercicios.first.aceita('e5f6'), isFalse);
      expect(p.teoria!.candidatos.first.san, 'Bf5');
      expect(p.fases.finalDaPartida, 62);
    });

    test('ida e volta pelo JSON', () {
      final p = TreinadorFixtures.tiago();
      final de = PartidaTreinador.fromJson(p.id, p.toJson())!;
      expect(de.toJson(), p.toJson());
    });

    test('sem data ou resultado: ilegível', () {
      expect(PartidaTreinador.fromJson('x', {'resultado': 'vitoria'}), isNull);
      expect(
        PartidaTreinador.fromJson('x', {'jogadaEm': '2026-11-08T10:00:00Z'}),
        isNull,
      );
    });

    test('status desconhecido vira nova; exercício sem FEN sai', () {
      final p = PartidaTreinador.fromJson('x', {
        'jogadaEm': DateTime.utc(2026, 11, 8).millisecondsSinceEpoch,
        'resultado': 'empate',
        'status': '???',
        'exercicios': [
          {'solucao': 'e2e4'},
          {'fen': TreinadorFixtures.fenFinal, 'solucao': 'b8c8'},
        ],
      })!;
      expect(p.status, StatusPartida.nova);
      expect(p.exercicios, hasLength(1));
      expect(p.exercicios.single.n, 2);
    });
  });

  group('ProgressoPartida', () {
    test('conta acertos e pontos e acha o próximo', () {
      var pr = ProgressoPartida.vazio;
      expect(pr.proximo(4), 1);
      pr = pr.com(const ResultadoExercicio(n: 1, acertou: true, pontos: 3));
      pr = pr.com(
        const ResultadoExercicio(
          n: 2,
          acertou: false,
          pontos: 0,
          viuSolucao: true,
        ),
      );
      expect(pr.feitos, 2);
      expect(pr.acertos, 1);
      expect(pr.pontos, 3);
      expect(pr.proximo(4), 3);
      expect(pr.completo(4), isFalse);
      expect(pr.toRemoto(), {
        'feitos': 2,
        'acertos': 1,
        'pontos': 3,
        'resultados': {'1': true, '2': false},
      });
      final de = ProgressoPartida.fromJson(pr.toJson());
      expect(de.feitos, 2);
      expect(de.proximo(4), 3);
    });

    test('só o espelho do servidor: usa os números dele', () {
      final pr = ProgressoPartida.fromJson({
        'feitos': 4,
        'acertos': 3,
        'pontos': 9,
      });
      expect(pr.feitos, 4);
      expect(pr.acertos, 3);
      expect(pr.completo(4), isTrue);
    });
  });

  test('estatísticas do exemplo', () {
    final e = TreinadorFixtures.estatisticas();
    expect(e.partidasAnalisadas, 12);
    expect(e.errosPorFase.total, 18);
    expect(e.errosPorTema['final_de_torres'], hasLength(1));
    expect(e.aberturas.first.saidaTeoria!.lance, 5);
    expect(e.estilo.acertar.single.tema, 'final_de_torres');
    expect(EstatisticasTreinador.fromJson(e.toJson()).toJson(), e.toJson());
  });

  test('config: limita os exercícios de 1 a 6', () {
    expect(
      TreinadorConfig.fromJson({'exerciciosPorPartida': 9})
          .exerciciosPorPartida,
      6,
    );
    expect(TreinadorConfig.fromJson(null).exerciciosPorPartida, 4);
    expect(
      PartidaModelo.listFromJson({
        'modelos': [
          {'fonte': 'torneio', 'titulo': 'Carlsen x Caruana'},
          {'fonte': 'x'},
        ],
      }),
      hasLength(1),
    );
  });

  test('conta ligada', () {
    final c = TreinadorConta.fromJson({
      'plataforma': 'chesscom',
      'usuario': 'gabriel',
      'avisoModelos': true,
    })!;
    expect(c.plataforma, Plataforma.chesscom);
    expect(TreinadorConta.fromJson(c.toJson()), c);
  });
}
