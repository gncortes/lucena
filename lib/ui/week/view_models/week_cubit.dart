import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import '../../../data/repositories/week/week_repository.dart';
import '../../../domain/models/week_summary.dart';

/// Sua semana: nulo até o resumo chegar.
class WeekCubit extends Cubit<WeekSummary?> {
  WeekCubit(this._week) : super(null);

  final WeekRepository _week;
  // Keep the public nullable summary API; failures never fabricate week data.
  final failure = ValueNotifier<LoadFailure?>(null);

  Future<void> load() async {
    try {
      final summary = await _week.summary();
      if (isClosed) return;
      emit(summary);
      failure.value = null;
    } on Object catch (error, stack) {
      debugPrint('week load failed: $error');
      reportHandledError(error, stack);
      if (!isClosed) failure.value = LoadFailure.generic;
    }
  }

  @override
  Future<void> close() {
    failure.dispose();
    return super.close();
  }
}
