import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../../data/repositories/treinador/treinador_preferencias.dart';
import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../data/services/firebase/treinador_service.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';

/// O pedido de análise feito nesta tela.
enum PedidoAnalise {
  nenhum,
  enviando,

  /// O grátis passou das 3 análises da semana: a saída é o plano.
  cota,

  /// O assinante passou do teto do mês ou o Treinador está desligado.
  recusado,
  falhou,
}

/// Uma partida do Treinador: início, espera da análise, erro e resumo.
final class TreinadorPartidaState {
  const TreinadorPartidaState({
    this.carregando = true,
    this.falhou = false,
    this.partida,
    this.acesso = false,
    this.pedido = PedidoAnalise.nenhum,
    this.inicioAnalise,
    this.exerciciosPrevistos,
  });

  final bool carregando;
  final bool falhou;

  /// Nula depois de carregar: a partida não existe (ou é de outra conta).
  final PartidaTreinador? partida;
  final bool acesso;
  final PedidoAnalise pedido;

  /// Quando a análise começou neste aparelho (para a porcentagem da espera).
  final DateTime? inicioAnalise;

  /// Quantos exercícios a análise gera (`config.exerciciosPorPartida`); nulo
  /// até a config chegar.
  final int? exerciciosPrevistos;

  bool get naoEncontrada => !carregando && !falhou && partida == null;

  TreinadorPartidaState copyWith({
    bool? carregando,
    bool? falhou,
    PartidaTreinador? Function()? partida,
    bool? acesso,
    PedidoAnalise? pedido,
    DateTime? Function()? inicioAnalise,
    int? exerciciosPrevistos,
  }) => TreinadorPartidaState(
    carregando: carregando ?? this.carregando,
    falhou: falhou ?? this.falhou,
    partida: partida == null ? this.partida : partida(),
    acesso: acesso ?? this.acesso,
    pedido: pedido ?? this.pedido,
    inicioAnalise: inicioAnalise == null ? this.inicioAnalise : inicioAnalise(),
    exerciciosPrevistos: exerciciosPrevistos ?? this.exerciciosPrevistos,
  );
}

final class TreinadorPartidaCubit extends Cubit<TreinadorPartidaState> {
  TreinadorPartidaCubit({
    required this.id,
    required this.repository,
    required this.grants,
    required this.preferencias,
    required this.now,
  }) : super(const TreinadorPartidaState());

  final String id;
  final TreinadorRepository repository;
  final CourseGrantsRepository grants;
  final TreinadorPreferencias preferencias;
  final Now now;

  StreamSubscription<PartidaTreinador?>? _partida;
  StreamSubscription<Object?>? _grants;

  Future<void> load() async {
    final inicio = await preferencias.inicioDaAnalise(id);
    if (isClosed) return;
    emit(
      state.copyWith(
        inicioAnalise: () => inicio,
        acesso: TreinadorRegras.temAcesso(grants.current, now()),
      ),
    );
    _grants ??= grants.changes.listen((g) {
      if (!isClosed) {
        emit(state.copyWith(acesso: TreinadorRegras.temAcesso(g, now())));
      }
    });
    _ouvir();
    unawaited(_lerConfig());
  }

  /// Sem a config, a tela usa o padrão do modelo.
  Future<void> _lerConfig() async {
    try {
      final config = await repository.config();
      if (!isClosed) {
        emit(state.copyWith(exerciciosPrevistos: config.exerciciosPorPartida));
      }
    } on Object {
      // O cartão "Como funciona" mostra o número padrão.
    }
  }

  void _ouvir() {
    _partida?.cancel();
    _partida = repository
        .partida(id)
        .listen(
          (p) => unawaited(_chegou(p)),
          onError: (_) {
            if (!isClosed) {
              emit(state.copyWith(carregando: false, falhou: true));
            }
          },
        );
  }

  // Emite já e grava depois: se a partida mudar no meio da gravação, o
  // estado novo não é passado para trás pelo antigo.
  Future<void> _chegou(PartidaTreinador? p) async {
    if (isClosed) return;
    var inicio = state.inicioAnalise;
    Future<void>? gravar;
    // Só a análise rodando conta tempo: na fila a barra não anda (a fila do
    // grátis pode durar horas) e a porcentagem não mente.
    if (p != null && p.status == StatusPartida.analisando && inicio == null) {
      inicio = now();
      gravar = preferencias.marcarInicio(id, inicio);
    } else if (p != null &&
        p.status != StatusPartida.analisando &&
        inicio != null) {
      inicio = null;
      gravar = preferencias.esquecerInicio(id);
    }
    emit(
      state.copyWith(
        carregando: false,
        falhou: false,
        partida: () => p,
        inicioAnalise: () => inicio,
      ),
    );
    await gravar;
  }

  void tentarDeNovo() {
    emit(state.copyWith(carregando: true, falhou: false));
    _ouvir();
  }

  /// Pede a análise (partida nova, ou "Tentar de novo" de um erro).
  Future<bool> analisar() => _pedir(avisar: false);

  /// "Me avise quando terminar": o servidor manda o aviso mesmo no limite de
  /// um por hora. Falha aqui não prende a pessoa na espera.
  Future<void> meAvise() async {
    try {
      await repository.analisar(id, avisar: true);
    } on Object {
      // A análise segue; sem o aviso, a partida aparece pronta na lista.
    }
  }

  Future<bool> _pedir({required bool avisar}) async {
    if (state.pedido == PedidoAnalise.enviando) return false;
    emit(state.copyWith(pedido: PedidoAnalise.enviando));
    try {
      await repository.analisar(id, avisar: avisar);
      if (isClosed) return true;
      // A partida pode ter ficado pronta antes de o servidor responder.
      if (state.partida?.pronta ?? false) {
        emit(state.copyWith(pedido: PedidoAnalise.nenhum));
        return true;
      }
      // O início da contagem vem do status `analisando` (ver `_chegou`).
      emit(state.copyWith(pedido: PedidoAnalise.nenhum));
      return true;
    } on TreinadorCallException catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          pedido: e.cota
              ? PedidoAnalise.cota
              : e.code == 'permission-denied'
              ? PedidoAnalise.recusado
              : PedidoAnalise.falhou,
        ),
      );
      return false;
    } on Object {
      if (!isClosed) emit(state.copyWith(pedido: PedidoAnalise.falhou));
      return false;
    }
  }

  /// A recusa ou a falha já foi mostrada.
  void pedidoVisto() => emit(state.copyWith(pedido: PedidoAnalise.nenhum));

  @override
  Future<void> close() async {
    await _partida?.cancel();
    await _grants?.cancel();
    await super.close();
  }
}

/// A porcentagem da espera: anda depressa no começo e para perto de 95%
/// até a partida ficar pronta (a análise leva de 1 a 5 minutos).
abstract final class PorcentagemDaEspera {
  static const teto = 95;
  static const constante = Duration(seconds: 90);

  static int de(DateTime? inicio, DateTime agora) {
    if (inicio == null) return 0;
    final t = agora.difference(inicio).inMilliseconds;
    if (t <= 0) return 0;
    final fracao = 1 - math.exp(-t / constante.inMilliseconds);
    return (teto * fracao).floor().clamp(0, teto);
  }
}
