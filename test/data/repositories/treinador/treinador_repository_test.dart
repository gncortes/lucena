import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/treinador/treinador_repository.dart';
import 'package:lucena/data/services/firebase/treinador_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_treinador_repository.dart';
import '../../../../testing/treinador_fixtures.dart';

void main() {
  late FakeTreinadorService service;
  late StreamController<String?> uids;
  String? uid;

  CloudTreinadorRepository abrir() => CloudTreinadorRepository(
    service,
    PreferencesService(),
    uids: uids.stream,
    currentUid: () => uid,
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = FakeTreinadorService()
      ..partidas['u1'] = TreinadorFixtures.listaJson();
    uids = StreamController<String?>.broadcast();
    uid = 'u1';
  });

  tearDown(() => uids.close());

  test('lista as partidas da mais nova', () async {
    final lista = await abrir().partidas().first;
    expect(lista, hasLength(5));
    expect(lista.first.adversario.nome, 'Tiago_Rook');
    expect(
      lista.map((p) => p.jogadaEm).toList(),
      [for (final p in lista) p.jogadaEm]..sort((a, b) => b.compareTo(a)),
    );
  });

  test('sem conta do Lucena: vazio e ligar dá semLogin', () async {
    uid = null;
    final repo = abrir();
    expect(await repo.partidas().first, isEmpty);
    expect(await repo.conta().first, isNull);
    await expectLater(
      repo.ligarConta(Plataforma.lichess, 'x'),
      throwsA(
        isA<LigarContaException>().having(
          (e) => e.falha,
          'falha',
          FalhaLigarConta.semLogin,
        ),
      ),
    );
  });

  test('ligar a conta chama a Function e traduz o erro', () async {
    final repo = abrir();
    await repo.ligarConta(Plataforma.chesscom, '  gabriel ');
    expect(service.chamadas.single.$1, TreinadorFunctions.ligarConta);
    expect(service.chamadas.single.$2, {
      'plataforma': 'chesscom',
      'usuario': 'gabriel',
    });
    for (final (code, falha) in [
      ('not-found', FalhaLigarConta.naoExiste),
      ('permission-denied', FalhaLigarConta.semPlano),
      ('unavailable', FalhaLigarConta.semResposta),
    ]) {
      service.erroChamada = code;
      await expectLater(
        repo.ligarConta(Plataforma.lichess, 'x'),
        throwsA(
          isA<LigarContaException>().having((e) => e.falha, 'falha', falha),
        ),
      );
    }
  });

  test(
    'o progresso fica no aparelho, chega à tela e vai ao servidor',
    () async {
      final repo = abrir();
      final id = TreinadorFixtures.idTiago;
      final emitidos = <ProgressoPartida?>[];
      final sub = repo.partida(id).listen((p) => emitidos.add(p?.progresso));
      await pumpEventQueue();
      final pr = ProgressoPartida.vazio.com(
        const ResultadoExercicio(n: 1, acertou: true, pontos: 3),
      );
      await repo.salvarProgresso(id, pr);
      await pumpEventQueue();
      expect(emitidos.last?.feitos, 1);
      expect(service.progressosGravados.single.$3, {
        'feitos': 1,
        'acertos': 1,
        'pontos': 3,
      });
      await sub.cancel();

      // Fechar e abrir o app: o progresso volta do aparelho.
      final reaberto = abrir();
      expect((await reaberto.progresso(id)).proximo(4), 2);
    },
  );

  test('sem nada no aparelho: usa o espelho do servidor', () async {
    final id = TreinadorFixtures.idTiago;
    service.partidas['u1']![id] = {
      ...TreinadorFixtures.tiagoJson(),
      'progresso': {'feitos': 4, 'acertos': 2, 'pontos': 6},
    };
    final pr = await abrir().progresso(id);
    expect(pr.completo(4), isTrue);
    expect(pr.acertos, 2);
  });

  test('trocar de conta troca as partidas', () async {
    final repo = abrir();
    final emitidos = <int>[];
    final sub = repo.partidas().listen((l) => emitidos.add(l.length));
    await pumpEventQueue();
    uid = 'u2';
    uids.add('u2');
    await pumpEventQueue();
    expect(emitidos, [5, 0]);
    await sub.cancel();
  });

  test('analisar pede à Function com o aviso', () async {
    await abrir().analisar('lichess_DeF67890', avisar: false);
    expect(service.chamadas.single.$1, TreinadorFunctions.analisar);
    expect(service.chamadas.single.$2, {
      'partida': 'lichess_DeF67890',
      'avisar': false,
    });
  });

  test('config e modelos ilegíveis caem no padrão', () async {
    final repo = abrir();
    expect((await repo.config()).exerciciosPorPartida, 4);
    service.configDoc = {'exerciciosPorPartida': 2};
    expect((await repo.config()).exerciciosPorPartida, 2);
    expect(await repo.modelos('B12'), isEmpty);
  });

  test('o fake leva a partida até pronta', () async {
    final fake = FakeTreinadorRepository.comDados()..analisarConclui = true;
    await fake.analisar('lichess_DeF67890');
    final p = await fake.partida('lichess_DeF67890').first;
    expect(p!.pronta, isTrue);
    expect(p.adversario.nome, 'lmatos88');
    expect(p.exercicios, hasLength(4));
  });
}
