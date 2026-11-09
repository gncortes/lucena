import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/treinador/treinador_preferencias.dart';
import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';

enum FaseExercicio {
  carregando,

  /// A partida não existe, não está pronta ou não tem exercícios.
  indisponivel,

  /// Sem rede (ou o servidor demorou): dá para tentar de novo.
  offline,
  jogando,
  acertou,
  errou,
  solucao,

  /// Os exercícios acabaram: a tela de pontuação.
  fim,
}

/// Os exercícios de uma partida analisada, um por vez.
final class TreinadorExercicioState {
  const TreinadorExercicioState({
    this.fase = FaseExercicio.carregando,
    this.partida,
    this.progresso = ProgressoPartida.vazio,
    this.indice = 0,
    this.tentativas = 1,
    this.fen,
    this.ultimoLance,
    this.salvando = false,
  });

  final FaseExercicio fase;
  final PartidaTreinador? partida;
  final ProgressoPartida progresso;

  /// 0 a N-1.
  final int indice;
  final int tentativas;

  /// A posição no tabuleiro agora (depois do lance jogado, se houver).
  final String? fen;
  final String? ultimoLance;
  final bool salvando;

  List<ExercicioTreinador> get exercicios => partida?.exercicios ?? const [];
  int get total => exercicios.length;
  ExercicioTreinador? get exercicio =>
      indice < total ? exercicios[indice] : null;
  bool get ultimo => indice >= total - 1;

  TreinadorExercicioState copyWith({
    FaseExercicio? fase,
    PartidaTreinador? partida,
    ProgressoPartida? progresso,
    int? indice,
    int? tentativas,
    String? fen,
    String? Function()? ultimoLance,
    bool? salvando,
  }) => TreinadorExercicioState(
    fase: fase ?? this.fase,
    partida: partida ?? this.partida,
    progresso: progresso ?? this.progresso,
    indice: indice ?? this.indice,
    tentativas: tentativas ?? this.tentativas,
    fen: fen ?? this.fen,
    ultimoLance: ultimoLance == null ? this.ultimoLance : ultimoLance(),
    salvando: salvando ?? this.salvando,
  );
}

final class TreinadorExercicioCubit extends Cubit<TreinadorExercicioState> {
  TreinadorExercicioCubit({
    required this.id,
    required this.repository,
    required this.preferencias,
    this.refazer = false,
  }) : super(const TreinadorExercicioState());

  final String id;
  final TreinadorRepository repository;
  final TreinadorPreferencias preferencias;

  /// "Refazer os exercícios": começa do 1 e zera a rodada (o que foi de
  /// primeira e a análise vista ficam).
  final bool refazer;

  /// "Tentar de novo" da tela sem conexão.
  Future<void> recarregar() {
    _emit(state.copyWith(fase: FaseExercicio.carregando));
    return load();
  }

  Future<void> load() async {
    try {
      final PartidaTreinador? partida;
      try {
        partida = await repository
            .partida(id)
            .firstWhere((p) => p == null || p.pronta)
            .timeout(const Duration(seconds: 20));
      } on StateError {
        // O fluxo terminou sem partida: ela não existe.
        return _emit(state.copyWith(fase: FaseExercicio.indisponivel));
      }
      if (partida == null || partida.exercicios.isEmpty) {
        return _emit(state.copyWith(fase: FaseExercicio.indisponivel));
      }
      var progresso = await repository.progresso(id);
      // Refazer só grava com o primeiro resultado: sair antes deixa a
      // partida no resumo, como estava.
      if (refazer) progresso = progresso.recomecar();
      final total = partida.exercicios.length;
      final proximo = progresso.proximo(total);
      if (proximo == null) {
        return _emit(
          state.copyWith(
            partida: partida,
            progresso: progresso,
            indice: total - 1,
            fase: FaseExercicio.fim,
          ),
        );
      }
      final tentativas = await preferencias.tentativas(
        id,
        partida.exercicios[proximo - 1].n,
      );
      _emit(
        _abrir(
          state.copyWith(partida: partida, progresso: progresso),
          proximo - 1,
          tentativas: tentativas,
        ),
      );
    } on Object {
      // Timeout ou falha de leitura: sem conexão, não "não encontrada".
      _emit(state.copyWith(fase: FaseExercicio.offline));
    }
  }

  TreinadorExercicioState _abrir(
    TreinadorExercicioState base,
    int indice, {
    int tentativas = 1,
  }) => base.copyWith(
    indice: indice,
    tentativas: tentativas,
    fen: base.exercicios[indice].fen,
    ultimoLance: () => null,
    fase: FaseExercicio.jogando,
  );

  void _emit(TreinadorExercicioState s) {
    if (!isClosed) emit(s);
  }

  /// O lance do aluno no tabuleiro.
  Future<void> jogar(String uci) async {
    final exercicio = state.exercicio;
    if (state.fase != FaseExercicio.jogando || exercicio == null) return;
    final depois = _depois(exercicio.fen, uci);
    if (depois == null) return;
    if (exercicio.aceita(uci)) {
      unawaited(preferencias.esquecerTentativas(id));
      _emit(
        state.copyWith(
          fase: FaseExercicio.acertou,
          fen: depois,
          ultimoLance: () => uci,
        ),
      );
      await _salvar(
        ResultadoExercicio(
          n: exercicio.n,
          acertou: true,
          pontos: TreinadorRegras.pontos(
            tentativas: state.tentativas,
            viuSolucao: false,
          ),
          tentativas: state.tentativas,
        ),
      );
    } else {
      // O erro já conta: fechar à força aqui reabre na tentativa seguinte.
      unawaited(
        preferencias.salvarTentativas(id, exercicio.n, state.tentativas + 1),
      );
      _emit(
        state.copyWith(
          fase: FaseExercicio.errou,
          fen: depois,
          ultimoLance: () => uci,
        ),
      );
    }
  }

  /// "Tentar novamente": volta à posição e conta mais uma tentativa.
  void tentarDeNovo() {
    final exercicio = state.exercicio;
    if (state.fase != FaseExercicio.errou || exercicio == null) return;
    _emit(
      state.copyWith(
        fase: FaseExercicio.jogando,
        tentativas: state.tentativas + 1,
        fen: exercicio.fen,
        ultimoLance: () => null,
      ),
    );
  }

  /// "Ver a solução": mostra o lance certo e vale 0 ponto.
  Future<void> verSolucao() async {
    final exercicio = state.exercicio;
    if (exercicio == null ||
        (state.fase != FaseExercicio.errou &&
            state.fase != FaseExercicio.jogando)) {
      return;
    }
    unawaited(preferencias.esquecerTentativas(id));
    _emit(
      state.copyWith(
        fase: FaseExercicio.solucao,
        fen: exercicio.fen,
        ultimoLance: () => null,
      ),
    );
    await _salvar(
      ResultadoExercicio(
        n: exercicio.n,
        acertou: false,
        pontos: 0,
        tentativas: state.tentativas,
        viuSolucao: true,
      ),
    );
  }

  /// "Próximo exercício" ou "Ver a pontuação".
  void proximo() {
    if (state.fase != FaseExercicio.acertou &&
        state.fase != FaseExercicio.solucao) {
      return;
    }
    if (state.ultimo) {
      _emit(state.copyWith(fase: FaseExercicio.fim));
    } else {
      _emit(_abrir(state, state.indice + 1));
    }
  }

  Future<void> _salvar(ResultadoExercicio resultado) async {
    final progresso = state.progresso.com(resultado);
    _emit(state.copyWith(progresso: progresso, salvando: true));
    try {
      await repository.salvarProgresso(id, progresso);
    } on Object {
      // O repositório guarda no aparelho antes do servidor; a falha do
      // espelho remoto não volta o exercício.
    }
    _emit(state.copyWith(salvando: false));
  }

  static String? _depois(String fen, String uci) {
    final posicao = GameRules.fromFen(fen);
    final lance = Move.parse(uci);
    if (posicao == null || lance == null) return null;
    return GameRules.play(posicao, lance)?.position.fen;
  }
}
