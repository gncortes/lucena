import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analysis/analysis_repository.dart';
import '../../../data/repositories/analysis/learning_analysis_repository.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/models/learning_analysis.dart';
import '../../../domain/use_cases/game_rules.dart';

class LearningAnalysisState {
  const LearningAnalysisState({
    required this.session,
    this.settings = const LearningAnalysisSettings(),
    this.lines = const [],
    this.loading = false,
    this.ready = false,
    this.saveFailed = false,
  });
  final LearningAnalysisSession session;
  final LearningAnalysisSettings settings;
  final List<EngineLine> lines;
  final bool loading;
  final bool ready;
  final bool saveFailed;
  LearningAnalysisState copyWith({
    LearningAnalysisSession? session,
    LearningAnalysisSettings? settings,
    List<EngineLine>? lines,
    bool? loading,
    bool? ready,
    bool? saveFailed,
  }) => LearningAnalysisState(
    session: session ?? this.session,
    settings: settings ?? this.settings,
    lines: lines ?? this.lines,
    loading: loading ?? this.loading,
    ready: ready ?? this.ready,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

class LearningAnalysisCubit extends Cubit<LearningAnalysisState> {
  LearningAnalysisCubit({
    required this.launch,
    required this.repository,
    required this.engine,
  }) : super(
         LearningAnalysisState(session: LearningAnalysisSession.start(launch)),
       );
  final LearningAnalysisLaunch launch;
  final LearningAnalysisRepository repository;
  final AnalysisRepository engine;
  int _request = 0;
  Future<void> _writes = Future.value();
  bool _retryScheduled = false;
  Timer? _retry;

  Future<void> load() async {
    try {
      final saved = await repository.load(launch.id);
      final settings = await repository.settings();
      if (isClosed) return;
      emit(
        state.copyWith(
          session: saved ?? state.session,
          settings: settings,
          ready: true,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(ready: true, saveFailed: true));
    }
    unawaited(_analyse());
  }

  void select(int index) {
    if (!state.ready || index < 0 || index >= state.session.nodes.length) {
      return;
    }
    emit(
      state.copyWith(
        session: state.session.select(index),
        lines: const [],
        loading: false,
      ),
    );
    _save();
    unawaited(_analyse());
  }

  void first() => select(0);
  void previous() =>
      select(state.session.current.parent ?? state.session.selected);
  void next() {
    final children = state.session.children(state.session.selected);
    if (children.isNotEmpty) select(children.first);
  }

  void last() {
    var index = state.session.selected;
    while (state.session.children(index).isNotEmpty) {
      index = state.session.children(index).first;
    }
    select(index);
  }

  bool play(String uci) {
    if (!state.ready) return false;
    final position = GameRules.fromFen(state.session.current.fen)!;
    if (GameRules.endOf(position) != null) return false;
    final move = Move.parse(uci);
    final played = move == null ? null : GameRules.play(position, move);
    if (played == null) return false;
    final session = state.session;
    final existing = session
        .children(session.selected)
        .where((i) => session.nodes[i].uci == uci)
        .firstOrNull;
    if (existing != null) {
      select(existing);
    } else {
      final nodes = [
        ...session.nodes,
        LearningAnalysisNode(
          fen: played.position.fen,
          parent: session.selected,
          uci: uci,
          san: played.san,
        ),
      ];
      emit(
        state.copyWith(
          session: LearningAnalysisSession(
            nodes: nodes,
            selected: nodes.length - 1,
          ),
          lines: const [],
          loading: false,
        ),
      );
      _save();
      unawaited(_analyse());
    }
    return true;
  }

  Future<void> confirmSettings(LearningAnalysisSettings settings) async {
    if (settings.lines < 1 || settings.lines > 3) return;
    emit(state.copyWith(settings: settings, lines: const [], loading: false));
    _save();
    unawaited(_analyse());
    await _writes;
  }

  void _save() {
    final session = state.session;
    final settings = state.settings;
    _writes = _writes.then((_) async {
      try {
        await repository.save(launch.id, session);
        await repository.saveSettings(settings);
        if (!isClosed) emit(state.copyWith(saveFailed: false));
      } on Object {
        if (isClosed) return;
        emit(state.copyWith(saveFailed: true));
        if (!_retryScheduled) {
          _retryScheduled = true;
          _retry = Timer(const Duration(seconds: 1), () {
            _retryScheduled = false;
            if (!isClosed && state.saveFailed) _save();
          });
        }
      }
    });
  }

  Future<void> _analyse() async {
    final request = ++_request;
    if (!state.settings.showEngine) return;
    final position = GameRules.fromFen(state.session.current.fen)!;
    if (GameRules.endOf(position) != null) return;
    emit(state.copyWith(loading: true));
    try {
      final lines = await engine.analyse(
        position,
        depth: 18,
        lines: state.settings.lines,
        urgent: true,
        preemptible: true,
        time: const Duration(seconds: 2),
      );
      if (!isClosed && request == _request) {
        emit(state.copyWith(lines: List.unmodifiable(lines), loading: false));
      }
    } on Object {
      if (!isClosed && request == _request) {
        emit(state.copyWith(lines: const [], loading: false));
      }
    }
  }

  @override
  Future<void> close() {
    _request++;
    _retry?.cancel();
    return super.close();
  }
}
