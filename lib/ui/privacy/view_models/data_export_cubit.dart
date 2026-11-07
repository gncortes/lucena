import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/data_export/data_export_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/analytics_event.dart';

/// Os quadros da folha "Baixar seus dados?" (H-CON-21); [cancelled] fecha.
enum DataExportStep { ask, downloading, ready, error, cancelled }

class DataExportState {
  const DataExportState({this.step = DataExportStep.ask, this.path});

  final DataExportStep step;

  /// O arquivo pronto ([DataExportStep.ready]).
  final String? path;

  @override
  bool operator ==(Object other) =>
      other is DataExportState && other.step == step && other.path == path;

  @override
  int get hashCode => Object.hash(step, path);
}

/// Baixar meus dados: pergunta → Baixando → pronto ou erro. Cancelar (ou
/// fechar a folha) durante Baixando descarta o arquivo quando ele chegar.
class DataExportCubit extends Cubit<DataExportState> {
  DataExportCubit({
    required this._uid,
    required this._exports,
    required this._analytics,
  }) : super(const DataExportState());

  final String _uid;
  final DataExportRepository _exports;
  final AnalyticsRepository _analytics;

  /// Cada Baixar ganha um número; um resultado de tentativa antiga não vale.
  int _attempt = 0;
  bool _cancelled = false;

  Future<void> download() async {
    final attempt = ++_attempt;
    _cancelled = false;
    emit(const DataExportState(step: DataExportStep.downloading));
    final String path;
    try {
      path = await _exports.download(_uid);
    } on Object catch (error, stack) {
      if (attempt != _attempt || _cancelled) return;
      debugPrint('data export failed: $error');
      reportHandledError(error, stack);
      _log('erro');
      if (!isClosed) emit(const DataExportState(step: DataExportStep.error));
      return;
    }
    if (attempt != _attempt || _cancelled || isClosed) {
      await _exports.discard(path);
      return;
    }
    _log('ok');
    emit(DataExportState(step: DataExportStep.ready, path: path));
  }

  /// "Cancelar": fecha a folha; durante Baixando, nada fica salvo.
  void cancel() {
    if (state.step == DataExportStep.downloading) {
      _cancelled = true;
      _log('cancelado');
    }
    if (!isClosed) emit(const DataExportState(step: DataExportStep.cancelled));
  }

  Future<void> open() async {
    if (state.path case final path?) await _exports.open(path);
  }

  void _log(String result) {
    _analytics.log(AnalyticsEvents.dadosBaixados(resultado: result));
  }

  @override
  Future<void> close() {
    if (state.step == DataExportStep.downloading && !_cancelled) {
      _cancelled = true;
      _log('cancelado');
    }
    return super.close();
  }
}
