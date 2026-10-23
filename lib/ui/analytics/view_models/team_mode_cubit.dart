import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';

/// O Modo equipe (E1.03 §10): 7 toques na versão abrem a folha, que já liga
/// a chave "Não contar meu uso".
class TeamModeState {
  const TeamModeState({this.team = false, this.taps = 0});

  final bool team;

  /// Os toques seguidos na versão, até [TeamModeCubit.tapsToOpen].
  final int taps;
}

class TeamModeCubit extends Cubit<TeamModeState> {
  TeamModeCubit(this._analytics) : super(const TeamModeState());

  final AnalyticsRepository _analytics;

  /// Os toques na versão que abrem a folha.
  static const tapsToOpen = 7;

  Future<void> load() async =>
      emit(TeamModeState(team: await _analytics.teamMode(), taps: state.taps));

  /// Um toque na versão. Verdadeiro no 7º: a folha abre e a contagem zera.
  bool tapVersion() {
    final taps = state.taps + 1;
    final opens = taps >= tapsToOpen;
    emit(TeamModeState(team: state.team, taps: opens ? 0 : taps));
    return opens;
  }

  /// A chave da folha. Ligar desliga a coleta e apaga o que o serviço tem.
  Future<void> setTeamMode(bool team) async {
    if (state.team == team) return;
    emit(TeamModeState(team: team, taps: state.taps));
    await _analytics.setTeamMode(team);
  }
}
