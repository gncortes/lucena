import 'dart:async';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/training/training_analytics.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/push/push_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_plan.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';

final class TrainingPlanState {
  const TrainingPlanState({
    this.draft = const TrainingPlan(),
    this.loading = true,
    this.ready = false,
    this.saving = false,
    this.permissionBusy = false,
    this.failed = false,
    this.editing = false,
    this.permissionGranted = false,
    this.denied = false,
  });
  final TrainingPlan draft;
  final bool loading, saving, permissionBusy, failed, editing, ready;
  final bool permissionGranted, denied;
  bool get busy => loading || saving || permissionBusy || !ready;
  TrainingPlanState copyWith({
    TrainingPlan? draft,
    bool? loading,
    bool? saving,
    bool? permissionBusy,
    bool? failed,
    bool? editing,
    bool? permissionGranted,
    bool? denied,
    bool? ready,
  }) => TrainingPlanState(
    draft: draft ?? this.draft,
    loading: loading ?? this.loading,
    ready: ready ?? this.ready,
    saving: saving ?? this.saving,
    permissionBusy: permissionBusy ?? this.permissionBusy,
    failed: failed ?? this.failed,
    editing: editing ?? this.editing,
    permissionGranted: permissionGranted ?? this.permissionGranted,
    denied: denied ?? this.denied,
  );
}

/// Owns a draft until the repository confirms the durable write. The callback
/// lets the coordinator replan reminders without exposing a service to the UI.
final class TrainingPlanCubit extends Cubit<TrainingPlanState> {
  TrainingPlanCubit({
    required this.repository,
    required this.config,
    required this.now,
    this.analytics = const NoAnalyticsRepository(),
    this.trainingAnalytics,
    this.beforeLoad,
    required this.push,
    this.afterSave,
  }) : super(const TrainingPlanState());
  final Future<void> Function()? beforeLoad;
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final AnalyticsRepository analytics;
  final TrainingAnalytics? trainingAnalytics;
  Future<void> _log(AnalyticsEvent event) {
    unawaited(
      Future<void>.sync(() => analytics.log(event)).catchError((Object _) {}),
    );
    return Future<void>.value();
  }

  final PushRepository push;
  final Future<void> Function(TrainingState)? afterSave;

  Future<void> load() async {
    if (state.saving || state.permissionBusy) return;
    emit(state.copyWith(loading: true, failed: false));
    try {
      await beforeLoad?.call();
      final saved = await repository.load(config.course);
      final granted = await push.permitted();
      if (isClosed) return;
      emit(
        TrainingPlanState(
          draft: saved.onboardingDone
              ? saved.plan.copyWith(
                  reminderOn: saved.plan.reminderOn && granted,
                )
              : saved.plan.copyWith(minutes: config.defaultMinutes),
          loading: false,
          ready: true,
          editing: saved.onboardingDone,
          permissionGranted: granted,
          denied: saved.onboardingDone && saved.plan.reminderOn && !granted,
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(loading: false, failed: true));
    }
  }

  void selectMinutes(int minutes) {
    if (state.busy) return;
    config.option(minutes);
    emit(
      state.copyWith(
        draft: state.draft.copyWith(minutes: minutes),
        failed: false,
      ),
    );
  }

  void toggleWeekday(int day) {
    if (state.busy || day < 0 || day > 6) return;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          weekdays: state.draft.weekdays ^ (1 << day),
        ),
        failed: false,
      ),
    );
  }

  void setTime(int hour, int minute) {
    if (state.busy) return;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(reminderHour: hour, reminderMinute: minute),
        failed: false,
      ),
    );
  }

  void disableReminder() {
    if (state.busy) return;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(reminderOn: false),
        failed: false,
      ),
    );
  }

  /// False means that the view must ask for the user's own-dialog consent.
  /// This check never opens the operating system permission prompt.
  Future<bool> enableReminder() async {
    if (state.busy) return false;
    emit(state.copyWith(permissionBusy: true, failed: false));
    try {
      final granted = await push.permitted();
      if (isClosed) return false;
      emit(
        state.copyWith(
          permissionBusy: false,
          permissionGranted: granted,
          denied: granted ? false : state.denied,
          draft: state.draft.copyWith(reminderOn: granted),
        ),
      );
      return granted;
    } on Object {
      if (!isClosed) emit(state.copyWith(permissionBusy: false, failed: true));
      return false;
    }
  }

  /// Called when the app's permission explanation is declined.
  Future<void> declinePermission() => _log(
    AnalyticsEvents.avisoPedido(resposta: 'agora_nao', gatilho: 'treino'),
  );

  Future<void> allowPermission() async {
    if (state.busy) return;
    emit(state.copyWith(permissionBusy: true, failed: false));
    try {
      final granted = await push.requestPermission();
      await _log(
        AnalyticsEvents.avisoPedido(
          resposta: granted ? 'permitiu' : 'negou_sistema',
          gatilho: 'treino',
        ),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            permissionBusy: false,
            permissionGranted: granted,
            denied: !granted,
            draft: state.draft.copyWith(reminderOn: granted),
          ),
        );
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(permissionBusy: false, failed: true));
    }
  }

  Future<void> openSettings() async {
    if (state.busy) return;
    emit(state.copyWith(permissionBusy: true, failed: false));
    try {
      final opened = await push.openSystemSettings();
      if (!isClosed) {
        emit(state.copyWith(permissionBusy: false, failed: !opened));
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(permissionBusy: false, failed: true));
    }
  }

  /// Also called on lifecycle resume after the system settings screen.
  Future<void> refreshPermission() async {
    if (state.busy) return;
    try {
      final granted = await push.permitted();
      if (!isClosed) {
        emit(
          state.copyWith(
            permissionGranted: granted,
            draft: state.denied && granted
                ? state.draft.copyWith(reminderOn: true)
                : state.draft,
            denied: !granted && state.denied,
          ),
        );
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(failed: true));
    }
  }

  Future<bool> save() async {
    if (state.busy) return false;
    final draft = state.draft;
    // The view must resolve the permission consent before persisting an enabled reminder.
    if (draft.reminderOn && !state.permissionGranted) return false;
    emit(state.copyWith(saving: true, failed: false));
    try {
      final resources = await repository.resources(config.course);
      final saved = await repository.update(config.course, (current) {
        final changed = current.copyWith(plan: draft, onboardingDone: true);
        return current.onboardingDone
            ? changed
            : BuildDayGoals(now, config)(changed, resources);
      });
      await _log(
        AnalyticsEvents.treinoPlanoAlterado(
          curso: config.course.name,
          minutos: draft.minutes,
          dias: draft.weekdayMask.split('').where((d) => d == '1').length,
          diasMascara: draft.weekdayMask,
          lembrete: draft.reminderOn,
          hora: draft.reminderHour,
          primeiraVez: !state.editing,
        ),
      );
      await _log(
        AnalyticsEvents.avisoChave(tipo: 'treino', ligado: draft.reminderOn),
      );
      await afterSave?.call(saved);
      if (!isClosed) emit(state.copyWith(saving: false, editing: true));
      return true;
    } on Object {
      if (!isClosed) emit(state.copyWith(saving: false, failed: true));
      return false;
    }
  }
}
