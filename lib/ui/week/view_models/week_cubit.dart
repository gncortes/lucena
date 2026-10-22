import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/week/week_repository.dart';
import '../../../domain/models/week_summary.dart';

/// Sua semana: nulo até o resumo chegar.
class WeekCubit extends Cubit<WeekSummary?> {
  WeekCubit(this._week) : super(null);

  final WeekRepository _week;

  Future<void> load() async {
    final summary = await _week.summary();
    if (!isClosed) emit(summary);
  }
}
