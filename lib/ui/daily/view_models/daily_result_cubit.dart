import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/daily/daily_final_repository.dart';
import '../../../domain/models/daily_final.dart';

/// O resultado de um dia: a primeira tentativa gravada e o final dele (o
/// objetivo muda o título do empate).
class DailyResultState {
  const DailyResultState({this.ready = false, this.daily, this.record});

  final bool ready;
  final DailyFinal? daily;

  /// Nulo: o dia ainda não foi jogado até o fim.
  final DailyRecord? record;
}

class DailyResultCubit extends Cubit<DailyResultState> {
  DailyResultCubit({required this.date, required this._daily})
    : super(const DailyResultState());

  /// O dia (`aaaa-mm-dd`).
  final String date;
  final DailyFinalRepository _daily;

  Future<void> load() async {
    final day = DateTime.parse(date);
    final daily = await _daily.of(day);
    final record = await _daily.record(day);
    if (isClosed) return;
    emit(DailyResultState(ready: true, daily: daily, record: record));
  }
}
