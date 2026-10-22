import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';

/// A chave "Ajudar a melhorar o Lucena" (E1.03 §3.26). O estado é nulo até a
/// primeira leitura terminar.
class AnalyticsOptInCubit extends Cubit<bool?> {
  AnalyticsOptInCubit(this._analytics) : super(null);

  final AnalyticsRepository _analytics;

  Future<void> load() async => emit(await _analytics.enabled());

  /// Liga ou desliga as estatísticas. O estado muda na hora; o
  /// `privacidade_analytics` sai do repositório.
  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    emit(enabled);
    await _analytics.setEnabled(enabled);
  }
}
