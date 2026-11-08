import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';

/// Há aula de final liberada? Nulo enquanto lê: as telas que recomendam o
/// curso esperam a resposta e, sem ela, não o mostram.
class CourseAvailabilityCubit extends Cubit<bool?> {
  CourseAvailabilityCubit(
    this._available, {
    this.reports = const FailureReportRepository(),
  }) : super(null);

  final Future<bool> Function() _available;
  final FailureReportRepository reports;

  Future<void> load() async {
    try {
      final available = await _available();
      if (!isClosed) emit(available);
    } on Object catch (error, stack) {
      reports.record(error, stack);
      if (!isClosed) emit(false);
    }
  }
}
