import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/data/repositories/treinador/treinador_preferencias.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/treinador/view_models/treinador_exercicio_cubit.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

/// O salvar progresso falha (o espelho do servidor fora do ar).
class _RepoSemSalvar extends FakeTreinadorRepository {
  _RepoSemSalvar()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: [TreinadorFixtures.tiago()],
      );

  @override
  Future<void> salvarProgresso(String id, ProgressoPartida progresso) =>
      Future.error(StateError('sem rede'));
}

void main() {
  const id = TreinadorFixtures.idTiago;
  // Soluções dos quatro exercícios da fixture.
  const certos = ['d3h7', 'f7f6', 'h5g3', 'b8c8'];

  late FakeTreinadorRepository repo;

  FakeTreinadorRepository novoRepo({
    List<PartidaTreinador>? partidas,
    ProgressoPartida? salvo,
  }) {
    final r = FakeTreinadorRepository(
      conta: TreinadorFixtures.conta,
      partidas: partidas ?? [TreinadorFixtures.tiago()],
    );
    return r;
  }

  TreinadorExercicioCubit criar({
    FakeTreinadorRepository? r,
    bool refazer = false,
    String partida = id,
  }) {
    final c = TreinadorExercicioCubit(
      id: partida,
      repository: r ?? repo,
      preferencias: TreinadorPreferencias(MemoriaPreferencias()),
      refazer: refazer,
    );
    addTearDown(c.close);
    return c;
  }

  Future<TreinadorExercicioCubit> aberto({bool refazer = false}) async {
    final c = criar(refazer: refazer);
    await c.load();
    return c;
  }

  setUp(() => repo = novoRepo());

  group('load', () {
    test('partida pronta: abre o primeiro exercício, jogando', () async {
      final c = await aberto();
      expect(c.state.fase, FaseExercicio.jogando);
      expect(c.state.indice, 0);
      expect(c.state.total, 4);
      expect(c.state.fen, TreinadorFixtures.fenGrego);
      expect(c.state.tentativas, 1);
      expect(c.state.progresso.feitos, 0);
      expect(c.state.ultimoLance, isNull);
    });

    test('partida que não existe: indisponível', () async {
      final c = criar(partida: 'lichess_nao');
      await c.load();
      expect(c.state.fase, FaseExercicio.indisponivel);
    });

    test('partida pronta sem exercícios: indisponível', () async {
      repo = novoRepo(partidas: [TreinadorFixtures.tiago(exercicios: 0)]);
      final c = await aberto();
      expect(c.state.fase, FaseExercicio.indisponivel);
    });

    test('espera a partida ficar pronta e abre quando chega', () async {
      repo = novoRepo(
        partidas: [TreinadorFixtures.tiago(status: 'analisando')],
      );
      final c = criar();
      final carga = c.load();
      await pumpEventQueue();
      expect(c.state.fase, FaseExercicio.carregando);

      repo.porPartida(TreinadorFixtures.tiago());
      await carga;
      expect(c.state.fase, FaseExercicio.jogando);
    });

    testWidgets('partida que nunca fica pronta: offline em 8 s', (
      tester,
    ) async {
      repo = novoRepo(
        partidas: [TreinadorFixtures.tiago(status: 'analisando')],
      );
      final c = criar();
      unawaited(c.load());
      await tester.pump(const Duration(seconds: 7));
      expect(c.state.fase, FaseExercicio.carregando);
      await tester.pump(const Duration(seconds: 2));
      expect(c.state.fase, FaseExercicio.offline);
    });

    test('fechar à força depois de errar guarda a tentativa', () async {
      final prefs = TreinadorPreferencias(MemoriaPreferencias());
      TreinadorExercicioCubit novo() {
        final c = TreinadorExercicioCubit(
          id: id,
          repository: repo,
          preferencias: prefs,
        );
        addTearDown(c.close);
        return c;
      }

      final c = novo();
      await c.load();
      final pos = GameRules.fromFen(c.state.exercicio!.fen)!;
      // O primeiro lance legal que não é a solução.
      final uci = [
        for (final e in GameRules.legalMoves(pos).entries)
          for (final to in e.value) NormalMove(from: e.key, to: to).uci,
      ].firstWhere((u) => !c.state.exercicio!.aceita(u));
      await c.jogar(uci);
      expect(c.state.fase, FaseExercicio.errou);

      // Fechou à força: abre de novo, e o acerto já vale a tentativa 2.
      final reaberto = novo();
      await reaberto.load();
      expect(reaberto.state.tentativas, 2);
      await reaberto.jogar(certos[0]);
      expect(reaberto.state.progresso.resultados.single.pontos, 1);
      expect(await prefs.tentativas(id, 1), 1);
    });

    test('retoma do exercício seguinte ao último feito', () async {
      await repo.salvarProgresso(
        id,
        const ProgressoPartida().com(
          const ResultadoExercicio(n: 1, acertou: true, pontos: 3),
        ),
      );
      final c = await aberto();
      expect(c.state.fase, FaseExercicio.jogando);
      expect(c.state.indice, 1);
      expect(c.state.fen, c.state.exercicios[1].fen);
      expect(c.state.progresso.feitos, 1);
    });

    test('tudo feito: abre direto na pontuação (fim)', () async {
      var p = const ProgressoPartida();
      for (var n = 1; n <= 4; n++) {
        p = p.com(ResultadoExercicio(n: n, acertou: true, pontos: 3));
      }
      await repo.salvarProgresso(id, p);
      final c = await aberto();
      expect(c.state.fase, FaseExercicio.fim);
      expect(c.state.progresso.acertos, 4);
      expect(c.state.indice, 3);
    });

    test('refazer: começa do 1 e só grava com o primeiro resultado', () async {
      var p = const ProgressoPartida();
      for (var n = 1; n <= 4; n++) {
        p = p.com(ResultadoExercicio(n: n, acertou: true, pontos: 3));
      }
      await repo.salvarProgresso(id, p);
      final c = await aberto(refazer: true);
      expect(c.state.fase, FaseExercicio.jogando);
      expect(c.state.indice, 0);
      expect(c.state.progresso.feitos, 0);
      // Sair agora deixa a partida no resumo.
      expect((await repo.progresso(id)).feitos, 4);
      await c.verSolucao();
      expect((await repo.progresso(id)).feitos, 1);
    });
  });

  group('jogar', () {
    test(
      'lance certo: acertou, tabuleiro na posição depois do lance',
      () async {
        final c = await aberto();
        await c.jogar('d3h7');
        expect(c.state.fase, FaseExercicio.acertou);
        expect(c.state.ultimoLance, 'd3h7');
        expect(c.state.fen, isNot(TreinadorFixtures.fenGrego));
        expect(c.state.progresso.feitos, 1);
        expect(c.state.progresso.acertos, 1);
        expect(c.state.progresso.pontos, 3);
        expect(c.state.salvando, isFalse);
      },
    );

    test('acerto salva o progresso no repositório', () async {
      final c = await aberto();
      await c.jogar('d3h7');
      final salvo = await repo.progresso(id);
      expect(salvo.feitos, 1);
      expect(salvo.resultados.single.n, 1);
      expect(salvo.resultados.single.pontos, 3);
    });

    test('lance errado: errou, nada salvo ainda', () async {
      final c = await aberto();
      await c.jogar('a2a3');
      expect(c.state.fase, FaseExercicio.errou);
      expect(c.state.ultimoLance, 'a2a3');
      expect(c.state.progresso.feitos, 0);
      expect((await repo.progresso(id)).feitos, 0);
    });

    test('lance ilegal ou sem sentido é ignorado', () async {
      final c = await aberto();
      await c.jogar('e2e7');
      expect(c.state.fase, FaseExercicio.jogando);
      await c.jogar('lixo');
      expect(c.state.fase, FaseExercicio.jogando);
    });

    test('depois de acertar, outro lance não conta', () async {
      final c = await aberto();
      await c.jogar('d3h7');
      await c.jogar('a2a3');
      expect(c.state.fase, FaseExercicio.acertou);
      expect(c.state.progresso.feitos, 1);
    });

    test('lance aceito alternativo também acerta', () async {
      final c = await aberto();
      final aceitos = c.state.exercicio!.aceitos;
      if (aceitos.isEmpty) return;
      await c.jogar(aceitos.first);
      expect(c.state.fase, FaseExercicio.acertou);
    });
  });

  group('tentar de novo', () {
    test('errou: volta à posição e conta mais uma tentativa', () async {
      final c = await aberto();
      await c.jogar('a2a3');
      c.tentarDeNovo();
      expect(c.state.fase, FaseExercicio.jogando);
      expect(c.state.tentativas, 2);
      expect(c.state.fen, TreinadorFixtures.fenGrego);
      expect(c.state.ultimoLance, isNull);
    });

    test('acertar na segunda tentativa vale 1 ponto', () async {
      final c = await aberto();
      await c.jogar('a2a3');
      c.tentarDeNovo();
      await c.jogar('d3h7');
      expect(c.state.progresso.pontos, 1);
      expect(c.state.progresso.acertos, 1);
      expect(c.state.progresso.resultados.single.tentativas, 2);
    });

    test('só vale depois de errar', () async {
      final c = await aberto();
      c.tentarDeNovo();
      expect(c.state.tentativas, 1);
      expect(c.state.fase, FaseExercicio.jogando);
    });
  });

  group('ver a solução', () {
    test('depois de errar: mostra a solução e vale 0', () async {
      final c = await aberto();
      await c.jogar('a2a3');
      await c.verSolucao();
      expect(c.state.fase, FaseExercicio.solucao);
      expect(c.state.fen, TreinadorFixtures.fenGrego);
      expect(c.state.progresso.feitos, 1);
      expect(c.state.progresso.acertos, 0);
      expect(c.state.progresso.pontos, 0);
      final r = c.state.progresso.resultados.single;
      expect(r.viuSolucao, isTrue);
      expect(r.acertou, isFalse);
    });

    test('direto, sem errar antes (jogando)', () async {
      final c = await aberto();
      await c.verSolucao();
      expect(c.state.fase, FaseExercicio.solucao);
      expect(c.state.progresso.pontos, 0);
    });

    test('ver a solução salva o progresso', () async {
      final c = await aberto();
      await c.verSolucao();
      expect((await repo.progresso(id)).resultados.single.viuSolucao, isTrue);
    });

    test('não vale depois de acertar', () async {
      final c = await aberto();
      await c.jogar('d3h7');
      await c.verSolucao();
      expect(c.state.fase, FaseExercicio.acertou);
      expect(c.state.progresso.acertos, 1);
    });
  });

  group('próximo', () {
    test(
      'depois de acertar abre o exercício seguinte, zerando tentativas',
      () async {
        final c = await aberto();
        await c.jogar('a2a3');
        c.tentarDeNovo();
        await c.jogar('d3h7');
        c.proximo();
        expect(c.state.fase, FaseExercicio.jogando);
        expect(c.state.indice, 1);
        expect(c.state.tentativas, 1);
        expect(c.state.fen, c.state.exercicios[1].fen);
        expect(c.state.ultimoLance, isNull);
      },
    );

    test('depois da solução também avança', () async {
      final c = await aberto();
      await c.verSolucao();
      c.proximo();
      expect(c.state.indice, 1);
      expect(c.state.fase, FaseExercicio.jogando);
    });

    test('não avança jogando nem errado', () async {
      final c = await aberto();
      c.proximo();
      expect(c.state.indice, 0);
      await c.jogar('a2a3');
      c.proximo();
      expect(c.state.indice, 0);
      expect(c.state.fase, FaseExercicio.errou);
    });

    test('no último, vai para a pontuação (fim)', () async {
      final c = await aberto();
      for (var i = 0; i < 4; i++) {
        await c.jogar(certos[i]);
        expect(
          c.state.fase,
          FaseExercicio.acertou,
          reason: 'exercício ${i + 1}',
        );
        c.proximo();
      }
      expect(c.state.fase, FaseExercicio.fim);
      expect(c.state.progresso.feitos, 4);
      expect(c.state.progresso.acertos, 4);
      expect(c.state.progresso.pontos, 12);
      expect(c.state.progresso.completo(4), isTrue);
    });

    test('mistura de acertos, erro e solução soma os pontos certos', () async {
      final c = await aberto();
      await c.jogar('d3h7'); // 3
      c.proximo();
      await c.jogar('a7a6'); // errado
      c.tentarDeNovo();
      await c.jogar('f7f6'); // 1
      c.proximo();
      await c.verSolucao(); // 0
      c.proximo();
      await c.jogar('b8c8'); // 3
      c.proximo();
      expect(c.state.fase, FaseExercicio.fim);
      expect(c.state.progresso.pontos, 7);
      expect(c.state.progresso.acertos, 3);
      expect(c.state.progresso.feitos, 4);
    });
  });

  group('progresso salvo', () {
    test('reabrir o cubit depois de salvar mostra o progresso novo', () async {
      final c = await aberto();
      await c.jogar('d3h7');
      c.proximo();
      await c.jogar('f7f6');
      await c.close();

      final outro = await aberto();
      expect(outro.state.fase, FaseExercicio.jogando);
      expect(outro.state.indice, 2);
      expect(outro.state.progresso.feitos, 2);
      expect(outro.state.progresso.pontos, 6);
    });

    test('o espelho da lista ouve o progresso salvo', () async {
      final c = await aberto();
      await c.jogar('d3h7');
      final p = await repo.partidas().first;
      expect(p.single.progresso?.feitos, 1);
    });

    test('falha ao salvar não derruba o exercício', () async {
      final c = criar(r: _RepoSemSalvar());
      await c.load();
      await c.jogar('d3h7');
      expect(c.state.fase, FaseExercicio.acertou);
      expect(c.state.progresso.feitos, 1);
      expect(c.state.salvando, isFalse);
    });

    test('acertos refeitos no mesmo número substituem o resultado', () async {
      final c = await aberto();
      await c.verSolucao();
      expect(c.state.progresso.resultados, hasLength(1));
      await c.close();
      // refazer zera tudo e o 1 volta a valer 3.
      final de = await aberto(refazer: true);
      await de.jogar('d3h7');
      expect(de.state.progresso.resultados, hasLength(1));
      expect(de.state.progresso.pontos, 3);
    });
  });

  test('fechar durante a carga não emite depois', () async {
    final c = criar();
    final carga = c.load();
    await c.close();
    await carga;
    expect(c.isClosed, isTrue);
  });
}
