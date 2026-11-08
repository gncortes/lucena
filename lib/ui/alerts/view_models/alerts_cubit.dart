import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import '../../../data/repositories/alerts/alerts_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/push/push_repository.dart';
import '../../../data/repositories/reminders/reminders_repository.dart';
import '../../../domain/models/alert_settings.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/alerts_rules.dart';

/// Configurações > Notificações (E1.21, H-AJU-09): as chaves e o estado da
/// permissão no Android.
class AlertsState {
  const AlertsState({
    this.ready = false,
    this.settings = const AlertSettings(),
    this.permitted = true,
    this.push = true,
    this.country,
    this.state,
    this.language,
    this.failure,
    this.asked = false,
  });

  final bool ready;

  /// A permissão já foi pedida nesta sessão pela tela (Gap 7).
  final bool asked;

  /// A faixa desligada mostra "Permitir": ainda não pedimos nesta sessão.
  bool get canAsk => !permitted && !asked;
  final LoadFailure? failure;
  final AlertSettings settings;

  /// O Android deixa mostrar avisos.
  final bool permitted;

  /// Há push (Firebase); sem ele, só a chave local.
  final bool push;

  /// O país do Perfil (código ISO), para os torneios da região.
  final String? country;

  /// O estado do Perfil, se houver.
  final String? state;

  /// O idioma do app (`pt`, `en`), para o tópico `idioma_<xx>`.
  final String? language;

  int get enabled => settings.enabled(push: push);
  int get total => AlertSettings.total(push: push);

  AlertsState copyWith({
    AlertSettings? settings,
    bool? permitted,
    String? language,
    LoadFailure? failure,
    bool clearFailure = false,
    bool? asked,
  }) => AlertsState(
    ready: ready,
    settings: settings ?? this.settings,
    permitted: permitted ?? this.permitted,
    push: push,
    country: country,
    state: state,
    language: language ?? this.language,
    failure: clearFailure ? null : failure ?? this.failure,
    asked: asked ?? this.asked,
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
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const AlertsState());

  final AnalyticsRepository _analytics;

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
    try {
      await _load();
    } on Object catch (error, stack) {
      _failed(error, stack);
    }
  }

  void _failed(Object error, StackTrace stack) {
    debugPrint('alerts load failed: $error');
    reportHandledError(error, stack);
    if (!isClosed) emit(state.copyWith(failure: LoadFailure.generic));
  }

  Future<void> _load() async {
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
        language: state.language,
        failure: state.failure,
        asked: state.asked,
      ),
    );
    _saved = settings;
    if (await _follow() && !isClosed) emit(state.copyWith(clearFailure: true));
  }

  /// O idioma do app mudou (ou ficou conhecido): reinscreve no `idioma_*`.
  Future<void> languageChanged(String language) async {
    if (isClosed || language == state.language) return;
    emit(state.copyWith(language: language));
    await _follow();
  }

  /// Relê a permissão (a pessoa voltou dos ajustes do Android).
  Future<void> refresh() async {
    try {
      final permitted = await _permitted();
      if (isClosed || permitted == state.permitted) return;
      emit(state.copyWith(permitted: permitted));
    } on Object catch (error, stack) {
      _failed(error, stack);
    }
  }

  /// O que está no disco: a tela volta a ele se a gravação falhar.
  AlertSettings? _saved;

  final _failures = StreamController<void>.broadcast();

  /// Uma chave não foi gravada (Gap 1): a tela já voltou ao valor salvo.
  Stream<void> get saveFailures => _failures.stream;

  /// Grava na hora e acerta os tópicos. Se a gravação falha, a chave volta
  /// ao valor salvo e [saveFailures] avisa.
  Future<void> change(AlertSettings settings) async {
    if (settings == state.settings) return;
    _logSwitches(state.settings, settings);
    emit(state.copyWith(settings: settings));
    try {
      await _alerts.save(settings);
    } on Object catch (error) {
      debugPrint('alerts save failed: $error');
      if (isClosed || state.settings != settings) return;
      emit(state.copyWith(settings: _saved ?? const AlertSettings()));
      _failures.add(null);
      return;
    }
    _saved = settings;
    await _follow();
  }

  /// "Permitir" na faixa desligada (Gap 7): pede a permissão do Android uma
  /// vez por sessão; depois só resta abrir os ajustes do sistema.
  Future<void> requestPermission() async {
    if (!state.canAsk) return;
    emit(state.copyWith(asked: true));
    final bool granted;
    try {
      granted = await _push.requestPermission();
    } on Object catch (error) {
      // Sem resposta do sistema: fica "Abrir configurações".
      debugPrint('alerts permission request failed: $error');
      return;
    }
    unawaited(
      _analytics.log(
        AnalyticsEvents.avisoPedido(
          resposta: granted ? 'permitiu' : 'negou_sistema',
          gatilho: 'avisos',
        ),
      ),
    );
    if (isClosed) return;
    emit(state.copyWith(permitted: granted));
    if (granted) await _follow();
  }

  @override
  Future<void> close() async {
    await _failures.close();
    return super.close();
  }

  // Cada chave que virou: `aviso_chave` (a hora do lembrete não é chave).
  void _logSwitches(AlertSettings before, AlertSettings after) {
    for (final (type, was, now) in [
      ('torneios', before.tournaments, after.tournaments),
      ('dia', before.daily, after.daily),
      ('novidades', before.news, after.news),
      ('aulas', before.lessons, after.lessons),
    ]) {
      if (was == now) continue;
      unawaited(
        _analytics.log(AnalyticsEvents.avisoChave(tipo: type, ligado: now)),
      );
    }
  }

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
        language: state.language,
        asked: state.asked,
      ),
    );
    await _follow();
  }

  // Uma troca de tópicos por vez: a seguinte usa o estado mais novo.
  Future<void> _following = Future.value();

  Future<bool> _follow() async {
    if (!state.ready) return true;
    try {
      _following = _following.then(
        (_) => _push.follow(
          AlertsRules.topics(
            state.settings,
            country: state.country,
            state: state.state,
            language: state.language,
          ),
        ),
      );
      await _following;
      return true;
    } on Object catch (error, stack) {
      _following = Future<void>.value();
      _failed(error, stack);
      return false;
    }
  }
}
