import 'package:flutter_bloc/flutter_bloc.dart';

/// Há aula de final liberada? Nulo enquanto lê: as telas que recomendam o
/// curso esperam a resposta e, sem ela, não o mostram.
class CourseAvailabilityCubit extends Cubit<bool?> {
  CourseAvailabilityCubit(this._available) : super(null);

  final Future<bool> Function() _available;

  Future<void> load() async {
    final available = await _available();
    if (!isClosed) emit(available);
  }
}
