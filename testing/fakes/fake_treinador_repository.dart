import 'dart:async';

import 'package:lucena/data/repositories/treinador/treinador_repository.dart';
import 'package:lucena/data/services/firebase/treinador_service.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';

import '../treinador_fixtures.dart';

/// O Treinador em memória, para telas, view models e Patrol.
///
/// - [falhaLigar]: o próximo [ligarConta] falha com esse motivo;
/// - [analisarConclui]: [analisar] leva a partida a `pronta` (com os
///   exercícios de [TreinadorFixtures.tiagoJson]) logo depois de `analisando`;
/// - [falhaAnalisar]: [analisar] lança [TreinadorCallException].
class FakeTreinadorRepository implements TreinadorRepository {
  FakeTreinadorRepository({
    this._conta,
    List<PartidaTreinador>? partidas,
    EstatisticasTreinador? estatisticas,
    this.configAtual = TreinadorConfig.padrao,
    Map<String, List<PartidaModelo>>? modelosPorEco,
  }) : _partidas = [...?partidas],
       _estatisticas = estatisticas ?? EstatisticasTreinador.vazia,
       modelosPorEco = modelosPorEco ?? {};

  /// Conta ligada, as cinco partidas do canvas e as estatísticas.
  factory FakeTreinadorRepository.comDados() => FakeTreinadorRepository(
    conta: TreinadorFixtures.conta,
    partidas: TreinadorFixtures.lista(),
    estatisticas: TreinadorFixtures.estatisticas(),
  );

  TreinadorConta? _conta;
  List<PartidaTreinador> _partidas;
  EstatisticasTreinador _estatisticas;
  TreinadorConfig configAtual;
  final Map<String, List<PartidaModelo>> modelosPorEco;
  final _progressos = <String, ProgressoPartida>{};

  FalhaLigarConta? falhaLigar;
  String? falhaAnalisar;
  bool analisarConclui = false;

  final ligacoes = <(Plataforma, String)>[];
  final pedidosAnalise = <(String, bool)>[];
  final avisosModelos = <bool>[];

  final _mudou = StreamController<void>.broadcast();

  Stream<T> _observar<T>(T Function() ler) async* {
    yield ler();
    yield* _mudou.stream.map((_) => ler());
  }

  void _avisar() => _mudou.add(null);

  PartidaTreinador _comProgresso(PartidaTreinador p) {
    final local = _progressos[p.id];
    return local == null ? p : p.copyWith(progresso: local);
  }

  // Controles do teste.

  set contaAtual(TreinadorConta? valor) {
    _conta = valor;
    _avisar();
  }

  set partidasAtuais(List<PartidaTreinador> valor) {
    _partidas = [...valor];
    _avisar();
  }

  set estatisticasAtuais(EstatisticasTreinador valor) {
    _estatisticas = valor;
    _avisar();
  }

  /// O servidor troca (ou junta) uma partida.
  void porPartida(PartidaTreinador p) {
    _partidas = [
      for (final e in _partidas)
        if (e.id != p.id) e,
      p,
    ]..sort((a, b) => b.jogadaEm.compareTo(a.jogadaEm));
    _avisar();
  }

  // TreinadorRepository.

  @override
  Stream<TreinadorConta?> conta() => _observar(() => _conta);

  @override
  Future<void> ligarConta(Plataforma plataforma, String usuario) async {
    ligacoes.add((plataforma, usuario));
    if (falhaLigar case final falha?) {
      falhaLigar = null;
      throw LigarContaException(falha);
    }
    contaAtual = TreinadorConta(
      plataforma: plataforma,
      usuario: usuario.trim(),
    );
  }

  @override
  Future<void> desligarConta() async => contaAtual = null;

  @override
  Future<void> definirAvisoModelos({required bool ligado}) async {
    avisosModelos.add(ligado);
    if (_conta case final c?) {
      contaAtual = TreinadorConta(
        plataforma: c.plataforma,
        usuario: c.usuario,
        ligadaEm: c.ligadaEm,
        ultimaBusca: c.ultimaBusca,
        avisoModelos: ligado,
      );
    }
  }

  @override
  Stream<List<PartidaTreinador>> partidas() =>
      _observar(() => [for (final p in _partidas) _comProgresso(p)]);

  @override
  Stream<PartidaTreinador?> partida(String id) => _observar(() {
    for (final p in _partidas) {
      if (p.id == id) return _comProgresso(p);
    }
    return null;
  });

  @override
  Future<void> analisar(String id, {bool avisar = true}) async {
    pedidosAnalise.add((id, avisar));
    if (falhaAnalisar case final code?) throw TreinadorCallException(code);
    final atual = _partidas.where((p) => p.id == id).firstOrNull;
    if (atual == null) throw const TreinadorCallException('not-found');
    porPartida(atual.copyWith(status: StatusPartida.analisando));
    if (analisarConclui) {
      final json = {
        ...atual.toJson(),
        ...TreinadorFixtures.tiagoJson(),
        'jogadaEm': atual.jogadaEm.toIso8601String(),
        'adversario': atual.adversario.toJson(),
        'cor': atual.cor.wire,
        'resultado': atual.resultado.wire,
      };
      porPartida(PartidaTreinador.fromJson(id, json)!);
    }
  }

  @override
  Future<ProgressoPartida> progresso(String id) async =>
      _progressos[id] ??
      _partidas.where((p) => p.id == id).firstOrNull?.progresso ??
      ProgressoPartida.vazio;

  @override
  Future<void> salvarProgresso(String id, ProgressoPartida progresso) async {
    _progressos[id] = progresso;
    _avisar();
  }

  @override
  Stream<EstatisticasTreinador> estatisticas() =>
      _observar(() => _estatisticas);

  @override
  Future<TreinadorConfig> config() async => configAtual;

  @override
  Future<List<PartidaModelo>> modelos(String eco) async =>
      modelosPorEco[eco] ?? const [];
}

/// O serviço em memória, para testar o [CloudTreinadorRepository].
class FakeTreinadorService implements TreinadorService {
  final contas = <String, Map<String, Object?>>{};
  final partidas = <String, Map<String, Map<String, Object?>>>{};
  final estatisticas = <String, Map<String, Object?>>{};
  Map<String, Object?>? configDoc;
  final modelosDocs = <String, Map<String, Object?>>{};

  final chamadas = <(String, Map<String, Object?>)>[];
  final progressosGravados = <(String, String, Map<String, Object?>)>[];

  /// Código do `HttpsError` da próxima chamada (nulo: responde bem).
  String? erroChamada;

  final _mudou = StreamController<void>.broadcast();

  Stream<T> _observar<T>(T Function() ler) async* {
    yield ler();
    yield* _mudou.stream.map((_) => ler());
  }

  /// O servidor gravou algo: chega a quem escuta.
  void avisar() => _mudou.add(null);

  @override
  Stream<Map<String, Object?>?> watchConta(String uid) =>
      _observar(() => contas[uid]);

  @override
  Stream<Map<String, Map<String, Object?>>> watchPartidas(
    String uid, {
    int limite = 200,
  }) => _observar(() => {...?partidas[uid]});

  @override
  Stream<Map<String, Object?>?> watchPartida(String uid, String id) =>
      _observar(() => partidas[uid]?[id]);

  @override
  Stream<Map<String, Object?>?> watchEstatisticas(String uid) =>
      _observar(() => estatisticas[uid]);

  @override
  Future<Map<String, Object?>?> readConfig() async => configDoc;

  @override
  Future<Map<String, Object?>?> readModelos(String eco) async =>
      modelosDocs[eco];

  @override
  Future<void> writeProgresso(
    String uid,
    String id,
    Map<String, Object?> progresso,
  ) async {
    progressosGravados.add((uid, id, progresso));
    final doc = partidas[uid]?[id];
    if (doc != null) partidas[uid]![id] = {...doc, 'progresso': progresso};
  }

  @override
  Future<Object?> call(String nome, Map<String, Object?> dados) async {
    chamadas.add((nome, dados));
    if (erroChamada case final code?) {
      erroChamada = null;
      throw TreinadorCallException(code);
    }
    return null;
  }
}
