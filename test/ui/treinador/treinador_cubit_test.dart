import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/treinador/treinador_regras.dart';
import 'package:lucena/ui/treinador/view_models/treinador_cubit.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

/// Um repositório cujas leituras falham (sem rede na primeira vez).
class _RepoComErro extends FakeTreinadorRepository {
  _RepoComErro()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
        estatisticas: TreinadorFixtures.estatisticas(),
      );

  bool falhar = true;

  @override
  Stream<List<PartidaTreinador>> partidas() =>
      falhar ? Stream.error(StateError('sem rede')) : super.partidas();
}

void main() {
  late TreinadorBed bed;
  late TreinadorCubit cubit;

  TreinadorCubit criar(TreinadorBed b) {
    final c = TreinadorCubit(
      repository: b.repo,
      grants: b.grants,
      preferencias: b.preferencias,
      now: b.now,
    );
    addTearDown(c.close);
    return c;
  }

  setUp(() {
    bed = TreinadorBed();
    cubit = criar(bed);
  });

  test('começa carregando, sem conta e sem plano', () {
    expect(cubit.state.carregando, isTrue);
    expect(cubit.state.semConta, isFalse);
    expect(cubit.state.acesso, isFalse);
  });

  group('load', () {
    test(
      'com conta e partidas: lista da mais nova para a mais antiga',
      () async {
        await cubit.load();
        await pumpEventQueue();
        final s = cubit.state;
        expect(s.carregando, isFalse);
        expect(s.falhou, isFalse);
        expect(s.conta, TreinadorFixtures.conta);
        expect(s.partidas, hasLength(5));
        expect(s.ultima?.id, TreinadorFixtures.idTiago);
        expect(s.semConta, isFalse);
      },
    );

    test('sem conta ligada: semConta', () async {
      bed = TreinadorBed(repo: FakeTreinadorRepository());
      cubit = criar(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.semConta, isTrue);
      expect(cubit.state.partidas, isEmpty);
      expect(cubit.state.ultima, isNull);
    });

    test('conta ligada e sem partidas: lista vazia, sem carregar', () async {
      bed = TreinadorBed(
        repo: FakeTreinadorRepository(conta: TreinadorFixtures.conta),
      );
      cubit = criar(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.carregando, isFalse);
      expect(cubit.state.semConta, isFalse);
      expect(cubit.state.partidas, isEmpty);
    });

    test('sem plano: acesso falso', () async {
      await cubit.load();
      expect(cubit.state.acesso, isFalse);
    });

    test('com plano: acesso verdadeiro', () async {
      bed = TreinadorBed(grants: comPlano());
      cubit = criar(bed);
      await cubit.load();
      expect(cubit.state.acesso, isTrue);
    });

    test('o plano comprado depois chega sem recarregar', () async {
      await cubit.load();
      expect(cubit.state.acesso, isFalse);
      bed.grants.current = comPlano();
      await pumpEventQueue();
      expect(cubit.state.acesso, isTrue);
    });

    test('o plano que acaba tira o acesso', () async {
      bed = TreinadorBed(grants: comPlano());
      cubit = criar(bed);
      await cubit.load();
      bed.grants.current = CourseGrants.empty;
      await pumpEventQueue();
      expect(cubit.state.acesso, isFalse);
    });

    test('partida nova do servidor entra na lista', () async {
      await cubit.load();
      await pumpEventQueue();
      final nova = comStatus(
        TreinadorFixtures.lista()[1],
        StatusPartida.pronta,
      );
      bed.repo.porPartida(nova);
      await pumpEventQueue();
      expect(
        cubit.state.partidas.firstWhere((p) => p.id == nova.id).pronta,
        isTrue,
      );
    });

    test('conta ligada depois: sai de semConta', () async {
      bed = TreinadorBed(repo: FakeTreinadorRepository());
      cubit = criar(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.semConta, isTrue);
      bed.repo.contaAtual = TreinadorFixtures.conta;
      await pumpEventQueue();
      expect(cubit.state.semConta, isFalse);
      expect(cubit.state.conta?.usuario, TreinadorFixtures.usuario);
    });
  });

  group('falha de leitura', () {
    test('falhou, sem carregar; tentar de novo recupera', () async {
      final repo = _RepoComErro();
      bed = TreinadorBed(repo: repo);
      cubit = criar(bed);
      await cubit.load();
      await pumpEventQueue();
      expect(cubit.state.falhou, isTrue);
      expect(cubit.state.carregando, isFalse);

      repo.falhar = false;
      cubit.tentarDeNovo();
      expect(cubit.state.carregando, isTrue);
      expect(cubit.state.falhou, isFalse);
      await pumpEventQueue();
      expect(cubit.state.falhou, isFalse);
      expect(cubit.state.carregando, isFalse);
      expect(cubit.state.partidas, hasLength(5));
    });
  });

  group('filtros', () {
    setUp(() async {
      await cubit.load();
      await pumpEventQueue();
    });

    test(
      'filtrar por ritmo reduz a lista filtrada, não a lista toda',
      () async {
        await cubit.filtrar(const FiltroPartidas(ritmo: Ritmo.rapida));
        expect(cubit.state.filtradas.map((p) => p.id), [
          'lichess_DeF67890',
          'lichess_MnO11223',
        ]);
        expect(cubit.state.partidas, hasLength(5));
      },
    );

    test('filtrar por resultado', () async {
      await cubit.filtrar(const FiltroPartidas(resultado: Resultado.empate));
      expect(cubit.state.filtradas.map((p) => p.id), ['lichess_GhI13579']);
    });

    test('ritmo e resultado juntos sem partida: lista vazia', () async {
      await cubit.filtrar(
        const FiltroPartidas(ritmo: Ritmo.bullet, resultado: Resultado.vitoria),
      );
      expect(cubit.state.filtradas, isEmpty);
    });

    test('limparFiltros volta a todas', () async {
      await cubit.filtrar(const FiltroPartidas(ritmo: Ritmo.bullet));
      await cubit.limparFiltros();
      expect(cubit.state.filtro.vazio, isTrue);
      expect(cubit.state.filtradas, hasLength(5));
    });

    test('o filtro fica salvo no aparelho', () async {
      const filtro = FiltroPartidas(ritmo: Ritmo.blitz);
      await cubit.filtrar(filtro);
      expect(await bed.preferencias.filtro(), filtro);
    });

    test('limpar o filtro apaga o que estava salvo', () async {
      await cubit.filtrar(const FiltroPartidas(ritmo: Ritmo.blitz));
      await cubit.limparFiltros();
      expect(await bed.preferencias.filtro(), FiltroPartidas.todos);
      expect(bed.memoria.valores, isEmpty);
    });

    test('reabrir o cubit traz o filtro salvo', () async {
      const filtro = FiltroPartidas(
        ritmo: Ritmo.blitz,
        resultado: Resultado.derrota,
      );
      await cubit.filtrar(filtro);

      final outro = criar(bed);
      await outro.load();
      await pumpEventQueue();
      expect(outro.state.filtro, filtro);
      expect(outro.state.filtradas.map((p) => p.id), [
        TreinadorFixtures.idTiago,
      ]);
    });
  });

  test('fechar o cubit durante a carga não emite depois', () async {
    final c = criar(bed);
    final carga = c.load();
    await c.close();
    await carga;
    await pumpEventQueue();
    expect(c.isClosed, isTrue);
  });
}
