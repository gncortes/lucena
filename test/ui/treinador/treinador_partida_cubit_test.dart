import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/treinador/treinador_preferencias.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/treinador/view_models/treinador_partida_cubit.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

/// Um repositório em que o pedido de análise espera o teste soltar.
class _RepoComPortao extends FakeTreinadorRepository {
  _RepoComPortao()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      );

  final portao = Completer<void>();

  @override
  Future<void> analisar(String id, {bool avisar = true}) async {
    await portao.future;
    return super.analisar(id, avisar: avisar);
  }
}

/// Um repositório cujo pedido de análise falha com um erro qualquer.
class _RepoQueQuebra extends FakeTreinadorRepository {
  _RepoQueQuebra()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      );

  @override
  Future<void> analisar(String id, {bool avisar = true}) =>
      Future.error(StateError('sem rede'));
}

/// Um repositório cuja leitura da partida falha.
class _RepoComErro extends FakeTreinadorRepository {
  _RepoComErro() : super(conta: TreinadorFixtures.conta);

  bool falhar = true;

  @override
  Stream<PartidaTreinador?> partida(String id) =>
      falhar ? Stream.error(StateError('sem rede')) : super.partida(id);
}

/// Preferências em que gravar espera o teste soltar.
class _PrefsComPortao extends MemoriaPreferencias {
  final portao = Completer<void>();

  @override
  Future<void> setString(String key, String value) async {
    await portao.future;
    return super.setString(key, value);
  }
}

void main() {
  const idNova = 'lichess_DeF67890';
  const idAnalisando = 'lichess_GhI13579';

  late TreinadorBed bed;

  TreinadorPartidaCubit criar(
    String id, {
    TreinadorBed? b,
    FakeTreinadorRepository? repo,
  }) {
    final base = b ?? bed;
    final c = TreinadorPartidaCubit(
      id: id,
      repository: repo ?? base.repo,
      grants: base.grants,
      preferencias: base.preferencias,
      now: base.now,
    );
    addTearDown(c.close);
    return c;
  }

  setUp(() => bed = TreinadorBed());

  group('load', () {
    test('partida pronta: carrega e mostra os exercícios', () async {
      final c = criar(TreinadorFixtures.idTiago);
      expect(c.state.carregando, isTrue);
      await c.load();
      await pumpEventQueue();
      expect(c.state.carregando, isFalse);
      expect(c.state.partida?.pronta, isTrue);
      expect(c.state.partida?.exercicios, hasLength(4));
      expect(c.state.naoEncontrada, isFalse);
      expect(c.state.inicioAnalise, isNull);
    });

    test('partida que não existe: naoEncontrada', () async {
      final c = criar('lichess_naoExiste');
      await c.load();
      await pumpEventQueue();
      expect(c.state.naoEncontrada, isTrue);
      expect(c.state.partida, isNull);
    });

    test('sem plano: acesso falso; com plano: verdadeiro', () async {
      final sem = criar(idNova);
      await sem.load();
      expect(sem.state.acesso, isFalse);

      final b = TreinadorBed(grants: comPlano());
      final com = criar(idNova, b: b);
      await com.load();
      expect(com.state.acesso, isTrue);
    });

    test(
      'o plano comprado enquanto a tela está aberta chega ao estado',
      () async {
        final c = criar(idNova);
        await c.load();
        bed.grants.current = comPlano();
        await pumpEventQueue();
        expect(c.state.acesso, isTrue);
      },
    );

    test('falha de leitura: falhou; tentar de novo recupera', () async {
      final repo = _RepoComErro();
      repo.partidasAtuais = TreinadorFixtures.lista();
      final c = criar(idNova, repo: repo);
      await c.load();
      await pumpEventQueue();
      expect(c.state.falhou, isTrue);
      expect(c.state.carregando, isFalse);
      expect(c.state.naoEncontrada, isFalse);

      repo.falhar = false;
      c.tentarDeNovo();
      expect(c.state.carregando, isTrue);
      await pumpEventQueue();
      expect(c.state.falhou, isFalse);
      expect(c.state.partida?.id, idNova);
    });

    test('fechar durante a carga não emite depois', () async {
      final c = criar(idNova);
      final carga = c.load();
      await c.close();
      await carga;
      expect(c.isClosed, isTrue);
    });
  });

  group('pedir a análise', () {
    test(
      'fila, analisando e pronta: o início é marcado e depois esquecido',
      () async {
        final c = criar(idNova);
        await c.load();
        await pumpEventQueue();
        expect(c.state.partida?.status, StatusPartida.nova);

        final pedido = c.analisar();
        expect(c.state.pedido, PedidoAnalise.enviando);
        expect(await pedido, isTrue);
        await pumpEventQueue();

        expect(bed.repo.pedidosAnalise, [(idNova, false)]);
        expect(c.state.pedido, PedidoAnalise.nenhum);
        expect(c.state.partida?.status, StatusPartida.analisando);
        expect(c.state.inicioAnalise, bed.now());
        expect(
          await bed.preferencias.inicioDaAnalise(idNova),
          bed.now().toUtc(),
        );

        // O servidor termina a análise.
        bed.repo.porPartida(
          comStatus(
            TreinadorFixtures.lista().firstWhere((p) => p.id == idNova),
            StatusPartida.pronta,
          ),
        );
        await pumpEventQueue();
        expect(c.state.partida?.status, StatusPartida.pronta);
        expect(c.state.inicioAnalise, isNull);
        expect(await bed.preferencias.inicioDaAnalise(idNova), isNull);
      },
    );

    test('na fila do servidor: também conta como em andamento', () async {
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      bed.repo.porPartida(
        comStatus(
          TreinadorFixtures.lista().firstWhere((p) => p.id == idNova),
          StatusPartida.naFila,
        ),
      );
      await pumpEventQueue();
      expect(c.state.partida?.status, StatusPartida.naFila);
      expect(c.state.inicioAnalise, isNotNull);
    });

    test('reabrir a tela em análise mantém o início de onde estava', () async {
      final inicio = bed.now().subtract(const Duration(seconds: 90));
      await bed.preferencias.marcarInicio(idAnalisando, inicio);
      final c = criar(idAnalisando);
      await c.load();
      await pumpEventQueue();
      expect(c.state.inicioAnalise, inicio);
      expect(PorcentagemDaEspera.de(c.state.inicioAnalise, bed.now()), 60);
    });

    test(
      'partida já em análise sem início salvo: começa a contar agora',
      () async {
        final c = criar(idAnalisando);
        await c.load();
        await pumpEventQueue();
        expect(c.state.partida?.status, StatusPartida.analisando);
        expect(c.state.inicioAnalise, bed.now());
        expect(
          await bed.preferencias.inicioDaAnalise(idAnalisando),
          bed.now().toUtc(),
        );
      },
    );

    test('segundo pedido enquanto envia é ignorado', () async {
      final repo = _RepoComPortao();
      final b = TreinadorBed(repo: repo);
      final c = criar(idNova, b: b);
      await c.load();
      await pumpEventQueue();

      final primeiro = c.analisar();
      expect(await c.analisar(), isFalse);
      repo.portao.complete();
      expect(await primeiro, isTrue);
      expect(repo.pedidosAnalise, hasLength(1));
    });

    test('cota do grátis esgotada: pedido vira cota', () async {
      bed.repo
        ..falhaAnalisar = 'permission-denied'
        ..motivoAnalisar = 'cota';
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      expect(await c.analisar(), isFalse);
      expect(c.state.pedido, PedidoAnalise.cota);
      expect(c.state.inicioAnalise, isNull);
      expect(await bed.preferencias.inicioDaAnalise(idNova), isNull);
    });

    test('teto do mês do assinante: recusado', () async {
      bed.repo
        ..falhaAnalisar = 'permission-denied'
        ..motivoAnalisar = 'teto';
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      expect(await c.analisar(), isFalse);
      expect(c.state.pedido, PedidoAnalise.recusado);
    });

    test('permission-denied sem motivo: recusado', () async {
      bed.repo.falhaAnalisar = 'permission-denied';
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      await c.analisar();
      expect(c.state.pedido, PedidoAnalise.recusado);
    });

    test('outro código do servidor: falhou', () async {
      bed.repo.falhaAnalisar = 'unavailable';
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      expect(await c.analisar(), isFalse);
      expect(c.state.pedido, PedidoAnalise.falhou);
    });

    test('erro qualquer (sem rede): falhou', () async {
      final repo = _RepoQueQuebra();
      final c = criar(idNova, repo: repo);
      await c.load();
      await pumpEventQueue();
      expect(await c.analisar(), isFalse);
      expect(c.state.pedido, PedidoAnalise.falhou);
    });

    test('pedidoVisto limpa a recusa e deixa pedir de novo', () async {
      bed.repo.falhaAnalisar = 'unavailable';
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      await c.analisar();
      expect(c.state.pedido, PedidoAnalise.falhou);
      c.pedidoVisto();
      expect(c.state.pedido, PedidoAnalise.nenhum);

      bed.repo.falhaAnalisar = null;
      expect(await c.analisar(), isTrue);
      expect(bed.repo.pedidosAnalise, hasLength(2));
    });

    test('partida em erro: tentar de novo pede a análise outra vez', () async {
      final erro = comStatus(
        TreinadorFixtures.lista().firstWhere((p) => p.id == idNova),
        StatusPartida.erro,
        erroMotivo: 'timeout',
      );
      bed.repo.porPartida(erro);
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      expect(c.state.partida?.status, StatusPartida.erro);
      expect(c.state.partida?.podeRefazer, isTrue);

      expect(await c.analisar(), isTrue);
      await pumpEventQueue();
      expect(c.state.partida?.status, StatusPartida.analisando);
    });

    test('analisar com o fake que conclui: termina pronta', () async {
      bed.repo.analisarConclui = true;
      final c = criar(idNova);
      await c.load();
      await pumpEventQueue();
      expect(await c.analisar(), isTrue);
      await pumpEventQueue();
      expect(c.state.partida?.status, StatusPartida.pronta);
      expect(c.state.partida?.exercicios, isNotEmpty);
    });

    // BUG (treinador_partida_cubit.dart, _pedir): se a partida já ficou pronta
    // antes de analisar() voltar, o início é gravado depois e a espera nunca
    // zera (a tela mostra "Carregando" só em andamento, mas a pref fica).
    test(
      'pedido que volta depois da partida pronta não deixa início preso',
      () async {
        bed.repo.analisarConclui = true;
        final c = criar(idNova);
        await c.load();
        await pumpEventQueue();
        await c.analisar();
        await pumpEventQueue();
        expect(c.state.partida?.status, StatusPartida.pronta);
        expect(c.state.inicioAnalise, isNull);
        expect(await bed.preferencias.inicioDaAnalise(idNova), isNull);
      },
    );

    // BUG (treinador_partida_cubit.dart, _chegou): o evento "analisando"
    // espera a gravação do início e pode emitir depois do evento "pronta".
    test('eventos seguidos analisando e pronta terminam em pronta', () async {
      final prefs = _PrefsComPortao();
      final b = TreinadorBed(prefs: prefs);
      final c = criar(idNova, b: b);
      await c.load();
      await pumpEventQueue();

      b.repo.porPartida(
        comStatus(
          TreinadorFixtures.lista().firstWhere((p) => p.id == idNova),
          StatusPartida.analisando,
        ),
      );
      await pumpEventQueue();
      b.repo.porPartida(
        comStatus(
          TreinadorFixtures.lista().firstWhere((p) => p.id == idNova),
          StatusPartida.pronta,
        ),
      );
      await pumpEventQueue();
      prefs.portao.complete();
      await pumpEventQueue();
      expect(c.state.partida?.status, StatusPartida.pronta);
    });
  });

  group('me avise quando terminar', () {
    test('pede de novo com aviso ligado, sem mexer no estado', () async {
      final c = criar(idAnalisando);
      await c.load();
      await pumpEventQueue();
      final antes = c.state.pedido;
      await c.meAvise();
      expect(bed.repo.pedidosAnalise, [(idAnalisando, true)]);
      expect(c.state.pedido, antes);
    });

    test('a falha do pedido não chega à tela', () async {
      bed.repo.falhaAnalisar = 'permission-denied';
      final c = criar(idAnalisando);
      await c.load();
      await pumpEventQueue();
      await c.meAvise();
      expect(c.state.pedido, PedidoAnalise.nenhum);
    });

    test('erro qualquer também é engolido', () async {
      final c = criar(idAnalisando, repo: _RepoQueQuebra());
      await c.load();
      await pumpEventQueue();
      await expectLater(c.meAvise(), completes);
    });
  });

  group('PorcentagemDaEspera', () {
    final inicio = DateTime.utc(2026, 11, 9, 12);

    test('sem início: 0', () {
      expect(PorcentagemDaEspera.de(null, inicio), 0);
    });

    test('no instante do início ou antes: 0', () {
      expect(PorcentagemDaEspera.de(inicio, inicio), 0);
      expect(
        PorcentagemDaEspera.de(
          inicio,
          inicio.subtract(const Duration(seconds: 5)),
        ),
        0,
      );
    });

    test('anda depressa no começo', () {
      final p = PorcentagemDaEspera.de(
        inicio,
        inicio.add(const Duration(seconds: 10)),
      );
      expect(p, inInclusiveRange(9, 12));
    });

    test('com 90 s está em 60%', () {
      expect(
        PorcentagemDaEspera.de(inicio, inicio.add(const Duration(seconds: 90))),
        60,
      );
    });

    test('nunca passa do teto de 95%', () {
      expect(
        PorcentagemDaEspera.de(inicio, inicio.add(const Duration(hours: 3))),
        PorcentagemDaEspera.teto,
      );
    });

    test('só cresce com o tempo', () {
      var anterior = -1;
      for (var s = 0; s <= 600; s += 15) {
        final p = PorcentagemDaEspera.de(
          inicio,
          inicio.add(Duration(seconds: s)),
        );
        expect(p, greaterThanOrEqualTo(anterior));
        anterior = p;
      }
    });
  });

  test('o início da análise usa a chave do aparelho esperada', () async {
    await bed.preferencias.marcarInicio(idNova, bed.now());
    expect(
      bed.memoria.valores[TreinadorPreferencias.inicioKey(idNova)],
      isNotNull,
    );
  });
}
