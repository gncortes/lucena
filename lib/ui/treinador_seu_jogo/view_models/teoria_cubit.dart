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
    this.passo,
  });

  final TeoriaStatus status;
  final PartidaTreinador? partida;

  /// O lance da teoria tocado (mostra a linha e o tabuleiro no fim dela).
  final String? escolhido;

  /// Quantos lances da linha tocada estão no tabuleiro (nulo: todos).
  final int? passo;

  /// Os lances da linha que aparecem no tabuleiro agora.
  int get passoAtual => (passo ?? linha.length).clamp(0, linha.length);

  TeoriaPartida? get teoria => partida?.teoria;

  /// O lance que ele jogou ali (SAN inglesa), se a partida tem os lances.
  String? get jogado {
    final p = partida, t = teoria;
    if (p == null || t == null || t.lance >= p.lances.length) return null;
    return p.lances[t.lance].san;
  }

  CandidatoTeoria? get candidato =>
      teoria?.candidatos.where((c) => c.san == escolhido).firstOrNull;

  /// A posição em que ele saiu da teoria (nula se o FEN não abre).
  Position? get _saida {
    final t = teoria;
    if (t == null) return null;
    try {
      return Chess.fromSetup(Setup.parseFen(t.fen));
    } on Object {
      return null;
    }
  }

  /// A linha do lance tocado (começa nele), só até o primeiro lance ilegal:
  /// a lista e o tabuleiro mostram os mesmos lances.
  List<String> get linha {
    final c = candidato;
    if (c == null) return const [];
    final sans = c.linha.isEmpty ? [c.san] : c.linha;
    final saida = _saida;
    if (saida == null) return sans;
    Position pos = saida;
    final legais = <String>[];
    for (final san in sans) {
      final move = pos.parseSan(san);
      if (move == null) break;
      pos = pos.play(move);
      legais.add(san);
    }
    return legais;
  }

  /// O meio-lance da partida marcado na lista: sem lance tocado, a jogada
  /// dele; com a linha tocada no começo (passo 0), o lance antes da saída.
  /// Nulo quando o marcado é um lance da linha.
  int? get marcadoNaPartida {
    final t = teoria;
    if (t == null) return null;
    if (candidato != null && passoAtual > 0) return null;
    final ply = candidato == null && _jogadoNaSaida != null
        ? t.lance
        : t.lance - 1;
    return ply < 0 ? null : ply;
  }

  /// O lance da linha tocada marcado na lista (o último no tabuleiro).
  int? get marcadoNaLinha =>
      candidato != null && passoAtual > 0 ? passoAtual - 1 : null;

  /// A jogada dele, se é legal na posição da saída.
  Move? get _jogadoNaSaida {
    final san = jogado;
    return san == null ? null : _saida?.parseSan(san);
  }

  /// O tabuleiro anda com o lance marcado na lista: sem toque, a posição
  /// depois da jogada dele; com a linha tocada, a linha até o passo atual
  /// (no passo 0, a posição da saída). O destaque é o lance marcado.
  ({String fen, Move? lance}) get tabuleiro {
    final t = teoria;
    if (t == null) return (fen: kInitialFEN, lance: null);
    final saida = _saida;
    if (saida == null) return (fen: t.fen, lance: null);
    if (candidato == null) {
      final dele = _jogadoNaSaida;
      if (dele != null) return (fen: saida.play(dele).fen, lance: dele);
      return (fen: saida.fen, lance: _ultimoDaPartida());
    }
    Position pos = saida;
    Move? ultimo = _ultimoDaPartida();
    for (final san in linha.take(passoAtual)) {
      final move = pos.parseSan(san)!;
      pos = pos.play(move);
      ultimo = move;
    }
    return (fen: pos.fen, lance: ultimo);
  }

  /// O último lance da partida antes de ele sair da teoria (o destaque do
  /// tabuleiro na posição da saída).
  Move? _ultimoDaPartida() {
    final p = partida, t = teoria;
    if (p == null || t == null || t.lance < 1 || t.lance > p.lances.length) {
      return null;
    }
    try {
      final antes = t.lance == 1 ? kInitialFEN : p.lances[t.lance - 2].fen;
      return Chess.fromSetup(Setup.parseFen(antes))
          .parseSan(p.lances[t.lance - 1].san);
    } on Object {
      return null;
    }
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
            passo: ainda ? state.passo : null,
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

  /// Mostra [passo] lances da linha tocada (0 = a posição em que saiu).
  void irPara(int passo) {
    if (state.status != TeoriaStatus.pronta || state.escolhido == null) return;
    emit(
      TeoriaState(
        status: state.status,
        partida: state.partida,
        escolhido: state.escolhido,
        passo: passo.clamp(0, state.linha.length),
      ),
    );
  }

  void anterior() => irPara(state.passoAtual - 1);

  /// Sem lance tocado, avança para a linha do mais jogado.
  void proximo() {
    if (state.escolhido == null) {
      final primeiro = state.teoria?.candidatos.firstOrNull;
      if (primeiro != null) escolher(primeiro.san);
      return;
    }
    irPara(state.passoAtual + 1);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
