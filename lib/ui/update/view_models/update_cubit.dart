import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/config/remote_flags_repository.dart';
import '../../../data/repositories/update/app_update_repository.dart';
import '../../../domain/use_cases/update_policy.dart';

class UpdateState {
  const UpdateState({
    this.decision = UpdateDecision.none,
    this.target = 0,
    this.shown = false,
    this.downloading = false,
    this.ready = false,
  });

  final UpdateDecision decision;

  /// O valor da recomendada que fica como visto ao mostrar a tela.
  final int target;

  /// A recomendada já apareceu nesta abertura.
  final bool shown;

  /// A atualização flexível está baixando.
  final bool downloading;

  /// Baixou: falta reiniciar.
  final bool ready;

  bool get required => decision == UpdateDecision.required;

  UpdateState copyWith({
    UpdateDecision? decision,
    int? target,
    bool? shown,
    bool? downloading,
    bool? ready,
  }) => UpdateState(
    decision: decision ?? this.decision,
    target: target ?? this.target,
    shown: shown ?? this.shown,
    downloading: downloading ?? this.downloading,
    ready: ready ?? this.ready,
  );
}

/// A atualização obrigatória e a recomendada (E1.32 §3), da abertura ao
/// reinício.
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({required this._flags, required this._updates})
    : super(const UpdateState());

  final RemoteFlagsRepository _flags;
  final AppUpdateRepository _updates;
  StreamSubscription<Set<String>>? _changes;
  PlayUpdateInfo _play = const PlayUpdateInfo();
  bool _triedImmediate = false;

  /// Decide com o último valor salvo e busca o novo sem esperar: a primeira
  /// tela nunca fica presa no Remote Config.
  Future<void> start() async {
    await _flags.start();
    _changes ??= _flags.changes.listen((keys) {
      if (keys.any((key) => key.startsWith('update_'))) unawaited(check());
    });
    unawaited(_flags.refresh());
    await check();
  }

  /// Confere de novo (na abertura, numa chave nova, ao voltar ao app).
  Future<void> check() async {
    final build = await _updates.installedBuild();
    final minBuild = _flags.updateMinBuild;
    final recommendedBuild = _flags.updateRecommendedBuild;
    // Em dia: nem pergunta à Play.
    if (build >= minBuild && build >= recommendedBuild) {
      if (!isClosed) emit(state.copyWith(decision: UpdateDecision.none));
      return;
    }
    _play = await _updates.check();
    final seen = await _updates.recommendedSeen();
    final decision = UpdatePolicy.decide(
      build: build,
      minBuild: minBuild,
      recommendedBuild: recommendedBuild,
      seen: seen,
      playHasUpdate: _play.available,
    );
    if (isClosed) return;
    // Já aberta nesta sessão, a recomendada fica como está até fechar.
    if (decision == UpdateDecision.none &&
        state.decision == UpdateDecision.recommended &&
        state.shown) {
      return;
    }
    final target = UpdatePolicy.recommendedTarget(
      minBuild: minBuild,
      recommendedBuild: recommendedBuild,
    );
    emit(
      state.copyWith(
        decision: decision,
        target: target,
        // Um valor maior é outra recomendada: pode aparecer de novo.
        shown: state.shown && target == state.target,
      ),
    );
    // A atualização imediata da Play é a mais curta; a tela nossa fica de
    // reserva atrás dela. Uma vez por abertura.
    if (decision == UpdateDecision.required &&
        _play.immediateAllowed &&
        !_triedImmediate) {
      _triedImmediate = true;
      await _updates.immediate();
    }
  }

  /// A recomendada apareceu: não volta para o mesmo valor.
  Future<void> recommendedShown() async {
    emit(state.copyWith(shown: true));
    await _updates.markRecommendedSeen(state.target);
  }

  /// "Atualizar" da recomendada: baixa pela Play em segundo plano; fora da
  /// Play, abre a página da loja.
  Future<void> updateRecommended() async {
    if (state.downloading || state.ready) return;
    if (!_play.flexibleAllowed) return _updates.openStore();
    emit(state.copyWith(downloading: true));
    final done = await _updates.flexible();
    if (isClosed) return;
    emit(state.copyWith(downloading: false, ready: done));
  }

  /// "Atualizar na Play" da obrigatória.
  Future<void> openStore() => _updates.openStore();

  /// "Pronto. Reiniciar o Lucena": instala o que baixou.
  Future<void> restart() => _updates.completeFlexible();

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
