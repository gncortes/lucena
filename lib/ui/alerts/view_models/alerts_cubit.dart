import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/alerts/alerts_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/push/push_repository.dart';
import '../../../data/repositories/reminders/reminders_repository.dart';
import '../../../domain/models/alert_settings.dart';
import '../../../domain/use_cases/alerts_rules.dart';

/// Perfil > Avisos (E1.21): as chaves, a hora dos lembretes e o estado da
/// permissão no Android.
class AlertsState {
  const AlertsState({
    this.ready = false,
    this.settings = const AlertSettings(),
    this.permitted = true,
    this.push = true,
    this.country,
    this.state,
  });

  final bool ready;
  final AlertSettings settings;

  /// O Android deixa mostrar avisos.
  final bool permitted;

  /// Há push (Firebase); sem ele, só a chave local.
  final bool push;

  /// O país do Perfil (código ISO), para os torneios da região.
  final String? country;

  /// O estado do Perfil, se houver.
  final String? state;

  int get enabled => settings.enabled(push: push);
  int get total => AlertSettings.total(push: push);

  AlertsState copyWith({AlertSettings? settings, bool? permitted}) =>
      AlertsState(
        ready: ready,
        settings: settings ?? this.settings,
        permitted: permitted ?? this.permitted,
        push: push,
        country: country,
        state: state,
      );
}

/// Vive no app inteiro: ao abrir, acerta os tópicos com as chaves gravadas.
class AlertsCubit extends Cubit<AlertsState> {
  /// [region] é a região do celular, para quando o Perfil ainda não gravou
  /// o país (o [ProfileRepository] grava na primeira leitura do Perfil).
  AlertsCubit({
    required this._alerts,
    required this._push,
    required this._profile,
    this._reminders,
    this._region,
  }) : super(const AlertsState());

  final AlertsRepository _alerts;
  final PushRepository _push;
  final ProfileRepository _profile;
  final RemindersRepository? _reminders;

  Future<bool> _permitted() => _reminders?.permitted() ?? _push.permitted();
  final String? Function()? _region;

  Future<({String? country, String? state})> _place() async {
    final profile = await _profile.load();
    final country = profile.country ?? _region?.call();
    return (
      country: country == null || country.isEmpty
          ? null
          : country.toUpperCase(),
      state: profile.country == null ? null : profile.state,
    );
  }

  Future<void> load() async {
    final settings = await _alerts.load();
    final permitted = await _permitted();
    final place = await _place();
    if (isClosed) return;
    emit(
      AlertsState(
        ready: true,
        settings: settings,
        permitted: permitted,
        push: _push.available,
        country: place.country,
        state: place.state,
      ),
    );
    await _follow();
  }

  /// Relê a permissão (a pessoa voltou dos ajustes do Android).
  Future<void> refresh() async {
    final permitted = await _permitted();
    if (isClosed || permitted == state.permitted) return;
    emit(state.copyWith(permitted: permitted));
  }

  /// Grava na hora e acerta os tópicos.
  Future<void> change(AlertSettings settings) async {
    if (settings == state.settings) return;
    emit(state.copyWith(settings: settings));
    await _alerts.save(settings);
    await _follow();
  }

  /// A hora dos lembretes, em minutos desde a meia-noite.
  Future<void> setReminder(int minutes) =>
      change(state.settings.copyWith(reminderMinutes: minutes));

  /// Os ajustes de notificação do Lucena no Android.
  Future<bool> openSystemSettings() => _push.openSystemSettings();

  /// O país (ou o estado) mudou: relê o Perfil e reinscreve.
  Future<void> regionChanged() async {
    final place = await _place();
    if (isClosed) return;
    emit(
      AlertsState(
        ready: state.ready,
        settings: state.settings,
        permitted: state.permitted,
        push: state.push,
        country: place.country,
        state: place.state,
      ),
    );
    await _follow();
  }

  Future<void> _follow() => _push.follow(
    AlertsRules.topics(
      state.settings,
      country: state.country,
      state: state.state,
    ),
  );
}
