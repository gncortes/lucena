import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';

enum TeoriaStatus { carregando, pronta, semTeoria, erro }

final class TeoriaState {
  const TeoriaState({
    this.status = TeoriaStatus.carregando,
    this.partida,
    this.escolhido,
  });

  final TeoriaStatus status;
  final PartidaTreinador? partida;

  /// O lance da teoria tocado (mostra a linha e o tabuleiro no fim dela).
  final String? escolhido;

  TeoriaPartida? get teoria => partida?.teoria;

  /// O lance que ele jogou ali (SAN inglesa), se a partida tem os lances.
  String? get jogado {
    final p = partida, t = teoria;
    if (p == null || t == null || t.lance >= p.lances.length) return null;
    return p.lances[t.lance].san;
  }

  CandidatoTeoria? get candidato =>
      teoria?.candidatos.where((c) => c.san == escolhido).firstOrNull;

  /// A linha do lance tocado (começa nele), só com os lances legais.
  List<String> get linha {
    final c = candidato;
    if (c == null) return const [];
    return c.linha.isEmpty ? [c.san] : c.linha;
  }

  /// O tabuleiro: no fim da linha tocada ou, sem toque, na posição em que ele
  /// saiu da teoria. O lance é o último da linha.
  ({String fen, Move? lance}) get tabuleiro {
    final t = teoria;
    if (t == null) return (fen: kInitialFEN, lance: null);
    Position pos;
    try {
      pos = Chess.fromSetup(Setup.parseFen(t.fen));
    } on Object {
      return (fen: t.fen, lance: null);
    }
    Move? ultimo;
    for (final san in linha) {
      final move = pos.parseSan(san);
      if (move == null) break;
      pos = pos.play(move);
      ultimo = move;
    }
    return (fen: pos.fen, lance: ultimo);
  }
}

/// A tela da teoria de uma partida: ouve a partida e guarda o lance tocado
/// (tocar de novo solta).
class TeoriaCubit extends Cubit<TeoriaState> {
  TeoriaCubit({required this._repository, required this.partidaId})
    : super(const TeoriaState());

  final TreinadorRepository _repository;
  final String partidaId;
  StreamSubscription<PartidaTreinador?>? _sub;

  void load() {
    unawaited(_sub?.cancel());
    if (state.status == TeoriaStatus.erro) emit(const TeoriaState());
    _sub = _repository.partida(partidaId).listen(
      (p) {
        final teoria = p?.teoria;
        if (p == null || teoria == null || teoria.candidatos.isEmpty) {
          emit(TeoriaState(status: TeoriaStatus.semTeoria, partida: p));
          return;
        }
        final ainda = teoria.candidatos.any((c) => c.san == state.escolhido);
        emit(
          TeoriaState(
            status: TeoriaStatus.pronta,
            partida: p,
            escolhido: ainda ? state.escolhido : null,
          ),
        );
      },
      onError: (Object _) => emit(const TeoriaState(status: TeoriaStatus.erro)),
    );
  }

  void escolher(String san) {
    if (state.status != TeoriaStatus.pronta) return;
    emit(
      TeoriaState(
        status: state.status,
        partida: state.partida,
        escolhido: san == state.escolhido ? null : san,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
