import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/seu_jogo_filtro_repository.dart';
import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/resumo_seu_jogo.dart';

enum SeuJogoStatus { carregando, pronto, erro }

final class SeuJogoState {
  const SeuJogoState({
    this.status = SeuJogoStatus.carregando,
    this.ritmo,
    this.partidas = const [],
    this.estatisticas = EstatisticasTreinador.vazia,
    this.resumo,
    this.plataforma,
  });

  final SeuJogoStatus status;

  /// `null` = Todos.
  final Ritmo? ritmo;
  final List<PartidaTreinador> partidas;
  final EstatisticasTreinador estatisticas;
  final ResumoSeuJogo? resumo;

  /// A conta ligada (o "do Lichess" do subtítulo).
  final Plataforma? plataforma;

  SeuJogoState copyWith({
    SeuJogoStatus? status,
    Ritmo? Function()? ritmo,
    List<PartidaTreinador>? partidas,
    EstatisticasTreinador? estatisticas,
    ResumoSeuJogo? resumo,
    Plataforma? Function()? plataforma,
  }) => SeuJogoState(
    status: status ?? this.status,
    ritmo: ritmo != null ? ritmo() : this.ritmo,
    partidas: partidas ?? this.partidas,
    estatisticas: estatisticas ?? this.estatisticas,
    resumo: resumo ?? this.resumo,
    plataforma: plataforma != null ? plataforma() : this.plataforma,
  );
}

/// A aba Seu jogo: ouve as partidas e as estatísticas do Treinador e refaz o
/// resumo a cada mudança ou troca de ritmo.
class SeuJogoCubit extends Cubit<SeuJogoState> {
  SeuJogoCubit({
    required this._repository,
    required this._filtro,
    required this._now,
  }) : super(const SeuJogoState());

  final TreinadorRepository _repository;
  final SeuJogoFiltroRepository _filtro;
  final Now _now;
  final _subs = <StreamSubscription<Object?>>[];
  var _temPartidas = false;

  /// Também é o "Tentar de novo": troca as assinaturas, sem somar outras.
  Future<void> load() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final ritmo = await _filtro.ritmo();
    if (isClosed) return;
    emit(
      state.copyWith(
        ritmo: () => ritmo,
        status: state.status == SeuJogoStatus.erro
            ? SeuJogoStatus.carregando
            : null,
      ),
    );
    _subs
      ..add(
        _repository.conta().listen(
          (c) => emit(state.copyWith(plataforma: () => c?.plataforma)),
          onError: (Object _) {},
        ),
      )
      ..add(
        _repository.estatisticas().listen(
          (e) => _refazer(estatisticas: e),
          onError: (Object _) {},
        ),
      )
      ..add(
        _repository.partidas().listen(
          (p) {
            _temPartidas = true;
            _refazer(partidas: p);
          },
          onError: (Object _) =>
              emit(state.copyWith(status: SeuJogoStatus.erro)),
        ),
      );
  }

  Future<void> escolherRitmo(Ritmo? ritmo) async {
    if (ritmo == state.ritmo) return;
    emit(state.copyWith(ritmo: () => ritmo));
    _refazer();
    await _filtro.definirRitmo(ritmo);
  }

  void _refazer({
    List<PartidaTreinador>? partidas,
    EstatisticasTreinador? estatisticas,
  }) {
    if (isClosed) return;
    final p = partidas ?? state.partidas;
    final e = estatisticas ?? state.estatisticas;
    emit(
      state.copyWith(
        status: _temPartidas ? SeuJogoStatus.pronto : state.status,
        partidas: p,
        estatisticas: e,
        resumo: resumirSeuJogo(
          partidas: p,
          estatisticas: e,
          agora: _now(),
          ritmo: state.ritmo,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
