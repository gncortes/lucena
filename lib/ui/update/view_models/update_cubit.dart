import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/config/remote_flags_repository.dart';
import '../../../data/repositories/update/app_update_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/update_policy.dart';

class UpdateState {
  const UpdateState({
    this.decision = UpdateDecision.none,
    this.target = 0,
    this.shown = false,
    this.downloading = false,
    this.ready = false,
    this.offline = false,
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

  /// Sem internet para atualizar: a tela vira "Sem internet".
  final bool offline;

  bool get required => decision == UpdateDecision.required;

  UpdateState copyWith({
    UpdateDecision? decision,
    int? target,
    bool? shown,
    bool? downloading,
    bool? ready,
    bool? offline,
  }) => UpdateState(
    decision: decision ?? this.decision,
    target: target ?? this.target,
    shown: shown ?? this.shown,
    downloading: downloading ?? this.downloading,
    ready: ready ?? this.ready,
    offline: offline ?? this.offline,
  );
}

/// A atualização obrigatória e a recomendada (E1.32 §3), da abertura ao
/// reinício.
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({
    required this._flags,
    required this._updates,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const UpdateState());

  final RemoteFlagsRepository _flags;
  final AppUpdateRepository _updates;
  final AnalyticsRepository _analytics;
  StreamSubscription<Set<String>>? _changes;
  PlayUpdateInfo _play = const PlayUpdateInfo();
  bool _triedImmediate = false;
  bool _requiredSeen = false;
  int _build = 0;

  // O `via` do E1.03: a Play dentro do app ou a página da loja.
  String get _via => _play.flexibleAllowed ? 'play_no_app' : 'loja';

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
    final build = _build = await _updates.installedBuild();
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
    // A obrigatória sem internet não tem como atualizar: avisa na tela.
    final offline =
        decision == UpdateDecision.required && !await _updates.hasConnection();
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
        offline: offline,
        target: target,
        // Um valor maior é outra recomendada: pode aparecer de novo.
        shown: state.shown && target == state.target,
      ),
    );
    if (decision == UpdateDecision.required && !_requiredSeen) {
      _requiredSeen = true;
      await _analytics.log(
        AnalyticsEvents.atualizacaoVista(
          tipo: 'obrigatoria',
          buildAtual: build,
          buildPedido: minBuild,
        ),
      );
    }
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
    await _analytics.log(
      AnalyticsEvents.atualizacaoVista(
        tipo: 'recomendada',
        buildAtual: _build,
        buildPedido: state.target,
      ),
    );
  }

  /// "Agora não" da recomendada.
  Future<void> recommendedLater() => _analytics.log(
    AnalyticsEvents.atualizacaoAcao(
      tipo: 'recomendada',
      acao: 'agora_nao',
      via: _via,
    ),
  );

  /// "Atualizar" da recomendada: baixa pela Play em segundo plano; fora da
  /// Play, abre a página da loja.
  Future<void> updateRecommended() async {
    if (state.downloading || state.ready) return;
    unawaited(
      _analytics.log(
        AnalyticsEvents.atualizacaoAcao(
          tipo: 'recomendada',
          acao: 'atualizar',
          via: _via,
        ),
      ),
    );
    if (!_play.flexibleAllowed) {
      if (await _updates.hasConnection()) return _updates.openStore();
      if (!isClosed) emit(state.copyWith(offline: true));
      return;
    }
    emit(state.copyWith(downloading: true));
    if (!await _updates.hasConnection()) {
      if (!isClosed) emit(state.copyWith(downloading: false, offline: true));
      return;
    }
    final done = await _updates.flexible();
    if (isClosed) return;
    emit(state.copyWith(downloading: false, ready: done));
  }

  /// "Tentar novamente" das telas sem internet.
  Future<void> retry() async {
    emit(state.copyWith(offline: false));
    await check();
    if (state.decision == UpdateDecision.recommended &&
        !await _updates.hasConnection() &&
        !isClosed) {
      emit(state.copyWith(offline: true));
    }
  }

  /// "Atualizar" da obrigatória.
  Future<void> openStore() async {
    await _analytics.log(
      AnalyticsEvents.atualizacaoAcao(
        tipo: 'obrigatoria',
        acao: 'atualizar',
        via: 'loja',
      ),
    );
    await _updates.openStore();
  }

  /// "Pronto. Reiniciar o Lucena": instala o que baixou.
  Future<void> restart() => _updates.completeFlexible();

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
