import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/treinador/abertura_no_curso.dart';
import 'package:lucena/domain/use_cases/treinador/abertura_no_pilares.dart';
import 'package:lucena/domain/use_cases/treinador/resumo_seu_jogo.dart';

import '../../../../testing/treinador_fixtures.dart';
import '../../../../testing/treinador_seu_jogo_fixtures.dart';

void main() {
  ResumoSeuJogo resumo({int n = 60, Ritmo? ritmo}) => resumirSeuJogo(
    partidas: SeuJogoFixtures.partidas(n),
    estatisticas: SeuJogoFixtures.estatisticas(),
    agora: SeuJogoFixtures.agora,
    ritmo: ritmo,
  );

  group('resumirSeuJogo', () {
    test('60 partidas: precisão, aproveitamento e variação', () {
      final r = resumo();
      expect(r.partidas, 60);
      expect(r.poucas, isFalse);
      expect(r.precisao, 75);
      expect(r.variacaoPrecisao, 0);
      expect(r.aproveitamento.vitorias, 30);
      expect(r.aproveitamento.empates, 15);
      expect(r.aproveitamento.derrotas, 15);
      expect(r.aproveitamento.porcento, 63);
      expect(r.brancas.partidas, 30);
      expect(r.pretas.partidas, 30);
    });

    test('erros por fase contam só os lances dele', () {
      final r = resumo();
      expect(r.errosPorFase[FaseDoJogo.abertura], 60);
      expect(r.errosPorFase[FaseDoJogo.finalDaPartida], 15);
      expect(r.errosPorFase[FaseDoJogo.meio], 0);
      expect(r.faseMaisErros, FaseDoJogo.abertura);
    });

    test('filtro de ritmo vale para todos os números', () {
      final r = resumo(ritmo: Ritmo.blitz);
      expect(r.partidas, 20);
      expect(r.ritmos.keys, [Ritmo.blitz]);
      expect(resumo().ritmos[Ritmo.bullet]?.partidas, 20);
    });

    test('temas ordenados pelo número de posições, da mais recente', () {
      final r = resumo();
      expect(r.temas.map((t) => t.tema), ['garfo', 'final_torres']);
      expect(r.temas.first.posicoes.first.partida.id, SeuJogoFixtures.id(0));
    });

    test('tema com partida fora do filtro some', () {
      // garfo está nas partidas 0, 2, 4, 6 e 8; bullet são as de i % 3 == 2.
      final r = resumo(ritmo: Ritmo.bullet);
      expect(r.temas.map((t) => t.tema), ['garfo', 'final_torres']);
      expect(r.temas.first.posicoes.map((p) => p.partida.id), [
        SeuJogoFixtures.id(2),
        SeuJogoFixtures.id(8),
      ]);
    });

    test('foco na abertura: a saída repetida em metade das partidas', () {
      final foco = resumo().foco;
      expect(foco, isA<FocoAbertura>());
      final a = (foco! as FocoAbertura).abertura;
      expect(a.nome, 'Defesa Caro-Kann');
      expect(a.curso?.parte, 2);
      final s = a.saida!;
      expect((s.lance, s.san, s.pretas, s.vezes), (5, 'c5', true, 20));
      expect(s.partidaRecente, SeuJogoFixtures.id(1));
    });

    test('sem saída repetida, o foco vai ao tema com 3 posições', () {
      final partidas = [
        for (final p in SeuJogoFixtures.partidas())
          if (p.cor == CorPartida.brancas) p,
      ];
      final r = resumirSeuJogo(
        partidas: partidas,
        estatisticas: SeuJogoFixtures.estatisticas(),
        agora: SeuJogoFixtures.agora,
      );
      expect((r.foco! as FocoTema).tema.tema, 'garfo');
    });

    test('8 semanas, a atual sem partida', () {
      final semanas = resumo().precisaoSemanas;
      expect(semanas, hasLength(8));
      expect(semanas.last, isNull);
      expect(semanas[6], isNotNull);
    });

    test('poucas partidas abaixo de 10', () {
      expect(resumo(n: 9).poucas, isTrue);
      expect(resumo(n: 10).poucas, isFalse);
    });

    test('nenhuma partida pronta: sem precisão e sem foco', () {
      final r = resumirSeuJogo(
        partidas: [TreinadorFixtures.tiago(status: 'analisando')],
        estatisticas: EstatisticasTreinador.vazia,
        agora: SeuJogoFixtures.agora,
      );
      expect(r.partidas, 0);
      expect(r.precisao, isNull);
      expect(r.foco, isNull);
      expect(r.faseMaisErros, isNull);
    });
  });

  group('faseDoLance', () {
    test('final com até 6 peças, abertura até o lance 12', () {
      expect(
        faseDoLance(80, TreinadorFixtures.fenFinal),
        FaseDoJogo.finalDaPartida,
      );
      expect(faseDoLance(22, SeuJogoFixtures.fenAbertura), FaseDoJogo.abertura);
      expect(faseDoLance(24, SeuJogoFixtures.fenAbertura), FaseDoJogo.meio);
    });
  });

  group('slotDaAbertura', () {
    test('o curso ligado pelo servidor vence', () {
      expect(
        slotDaAbertura(
          eco: 'A00',
          nome: 'Qualquer',
          cor: CorPartida.brancas,
          curso: const CursoLigado(id: 'pilares.ab3.slav3', parte: 3),
        ),
        'slav',
      );
    });

    test('pela faixa de ECO e pela cor', () {
      String? slot(String eco, CorPartida cor, [String nome = '']) =>
          slotDaAbertura(eco: eco, nome: nome, cor: cor);
      expect(slot('B12', CorPartida.pretas), 'caroKann');
      expect(slot('D15', CorPartida.pretas), 'slav');
      expect(slot('B35', CorPartida.pretas), 'dragon');
      expect(slot('E97', CorPartida.pretas), 'kingsIndian');
      expect(slot('B12', CorPartida.brancas), isNull);
      expect(slot('D02', CorPartida.brancas, 'Sistema Londres'), 'london');
      expect(slot('C50', CorPartida.brancas, 'Giuoco Piano'), isNull);
    });
  });

  group('aberturaNoPilares', () {
    TrainingLesson licao(String id) =>
        TrainingLesson(id: id, kind: TrainingLessonKind.opening, title: id);
    final resources = TrainingResources(
      lessons: [
        licao('pilares.ab1.caroKann1'),
        licao('pilares.ab1.slav1'),
        licao('pilares.ab2.caroKann2'),
        licao('pilares.ab3.caroKann3'),
      ],
    );

    test('partes na ordem do curso, destaque na primeira por fazer', () {
      final a = aberturaNoPilares(
        slot: 'caroKann',
        resources: resources,
        estado: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'teste',
          completedLessons: const {'pilares.ab1.caroKann1': '2026-11-01'},
        ),
      )!;
      expect(a.partes.map((p) => p.numero), [1, 2, 3]);
      expect(a.destaque.licao.id, 'pilares.ab2.caroKann2');
      expect(a.perfil, 'solido');
      expect(a.todasFeitas, isFalse);
    });

    test('a parte do servidor vence a primeira por fazer', () {
      final a = aberturaNoPilares(
        slot: 'caroKann',
        resources: resources,
        parteDoServidor: 3,
      )!;
      expect(a.destaque.numero, 3);
    });

    test('abertura fora do curso: null', () {
      expect(aberturaNoPilares(slot: 'dragon', resources: resources), isNull);
    });
  });
}
