import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/load_failure.dart';
import '../../../domain/models/training/goal/tournament_record.dart';
import '../../../domain/models/training/goal/training_diagnostic.dart';
import '../../../domain/models/training/goal/training_objective.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/goal/diagnostic_test_size.dart';
import '../../../domain/models/training/goal/goal_undo.dart';
import '../../../domain/use_cases/training/goal/goal_actions.dart';
import '../../../domain/use_cases/training/goal/goal_actions.dart' as goal;
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../../domain/use_cases/training/goal/plan_chapters.dart';
import '../../../domain/use_cases/training/goal/plan_status.dart';
import '../../../domain/use_cases/training/goal/tournament_rules.dart';

final class TrainingGoalState {
  const TrainingGoalState({
    this.view,
    this.loading = true,
    this.saving = false,
    this.failed = false,
    this.saveFailed = false,
    this.failure = LoadFailure.generic,
  });
  final GoalView? view;

  /// [failed]: não deu para ler (tela de erro no lugar dos dados).
  /// [saveFailed]: não deu para gravar com os dados já na tela (G9): a tela
  /// fica como estava e mostra o aviso com "Tentar novamente".
  final bool loading, saving, failed, saveFailed;
  final LoadFailure failure;

  TrainingGoalState copyWith({
    GoalView? view,
    bool? loading,
    bool? saving,
    bool? failed,
    bool? saveFailed,
    LoadFailure? failure,
  }) => TrainingGoalState(
    view: view ?? this.view,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    failed: failed ?? this.failed,
    saveFailed: saveFailed ?? this.saveFailed,
    failure: failure ?? this.failure,
  );
}

/// Objetivo, plano, diagnóstico, dia perdido e torneios de um curso. Cada ação
/// grava no repositório antes de a tela seguir; a tela só lê o [GoalView].
final class TrainingGoalCubit extends Cubit<TrainingGoalState> {
  TrainingGoalCubit({
    required this.repository,
    required this.config,
    required this.now,
    this.analytics = const NoAnalyticsRepository(),
    this.afterSave,
    TrainingResources? initialResources,
  }) : _resources = initialResources,
       super(const TrainingGoalState());

  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final AnalyticsRepository analytics;

  /// Chamado depois de gravar (reagenda lembretes e o push do torneio).
  final Future<void> Function(TrainingState)? afterSave;

  TrainingResources? _resources;
  StreamSubscription<TrainingState>? _sub;

  /// Última mudança que não gravou, para "Tentar novamente" (G9).
  TrainingState Function(TrainingState)? _failedChange;

  String get today {
    final d = now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  GoalView? get view => state.view;

  Future<void> load() async {
    if (state.saving) return;
    try {
      final saved = await repository.load(config.course);
      // A tela do curso já leu a lista: não abre os arquivos de novo.
      final resources = _resources ??= await repository.resources(
        config.course,
      );
      if (isClosed) return;
      emit(
        TrainingGoalState(
          view: GoalView.of(saved, resources, today),
          loading: false,
        ),
      );
      _sub ??= repository.changes
          .where((s) => s.course == config.course)
          .listen(_onChanged);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            failed: true,
            failure: LoadFailure.of(error),
          ),
        );
      }
    }
  }

  void _onChanged(TrainingState saved) {
    final resources = _resources;
    if (isClosed || resources == null) return;
    emit(state.copyWith(view: GoalView.of(saved, resources, today)));
  }

  Future<void> _log(AnalyticsEvent event) async {
    try {
      await analytics.log(event);
    } on Object {
      // Análise nunca bloqueia a tela.
    }
  }

  /// Grava uma mudança; devolve false se não gravou. Com dados na tela, a
  /// falha vira [TrainingGoalState.saveFailed] e a tela continua (G9).
  Future<bool> _apply(TrainingState Function(TrainingState) change) async {
    final resources = _resources;
    if (resources == null) return false;
    emit(state.copyWith(saving: true, failed: false, saveFailed: false));
    final TrainingState saved;
    try {
      saved = await repository.update(config.course, change);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      _failedChange = change;
      if (!isClosed) {
        final onScreen = state.view != null;
        emit(
          state.copyWith(
            saving: false,
            failed: !onScreen,
            saveFailed: onScreen,
            failure: LoadFailure.of(error),
          ),
        );
      }
      return false;
    }
    _failedChange = null;
    // Já gravou: o lembrete que falhar não desfaz nem vira erro de gravação (G10).
    try {
      await afterSave?.call(saved);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
    if (isClosed) return true;
    emit(
      TrainingGoalState(
        view: GoalView.of(saved, resources, today),
        loading: false,
      ),
    );
    return true;
  }

  /// "Tentar novamente" do aviso de falha ao gravar.
  Future<bool> retrySave() {
    final change = _failedChange;
    if (change == null) {
      dismissSaveError();
      return Future.value(true);
    }
    return _apply(change);
  }

  /// Fecha o aviso de falha ao gravar sem tentar de novo.
  void dismissSaveError() {
    _failedChange = null;
    if (state.saveFailed && !isClosed) {
      emit(state.copyWith(saveFailed: false));
    }
  }

  // ---- Objetivo ----

  /// Salva "Seu objetivo". A mesma escolha não grava (G3); só o nome não
  /// refaz o plano (G5); trocar guarda o "Desfazer" (G2). A tela pergunta
  /// antes quando [GoalView.confirmChange] é true.
  Future<bool> setObjective({
    required ObjectiveKind kind,
    String? date,
    String name = '',
  }) async {
    if (kind == ObjectiveKind.tournament &&
        !isValidTournamentDate(date, today)) {
      return false;
    }
    final change =
        view?.changeFor(kind: kind, date: date, name: name) ??
        ObjectiveChange.first;
    final objective = TrainingObjective(
      kind: kind,
      setOn: today,
      tournamentDate: kind == ObjectiveKind.tournament ? date : null,
      tournamentName: kind == ObjectiveKind.tournament ? name : '',
    );
    final ok = await _apply((s) => applyObjective(s, objective));
    if (ok &&
        (change == ObjectiveChange.first || change == ObjectiveChange.change)) {
      unawaited(
        _log(
          AnalyticsEvents.treinoObjetivoDefinido(
            curso: config.course.name,
            tipo: kind.name,
            diasAteTorneio: date == null ? null : _daysTo(date),
          ),
        ),
      );
    }
    return ok;
  }

  int _daysTo(String date) => daysUntil(today, date);

  /// "Ficar sem objetivo" (G1). A tela pergunta antes quando
  /// [GoalView.confirmRemove] é true e depois mostra o "Desfazer".
  Future<bool> removeObjective() => _apply(clearObjective);

  /// Muda só o nome do torneio (G5).
  Future<bool> renameObjective(String name) =>
      _apply((s) => goal.renameObjective(s, name));

  /// "Desfazer" do aviso (troca de objetivo, edição ou exclusão de registro).
  Future<bool> undo() => _apply(undoLast);

  /// Guarda a escolha de "Seu objetivo" ainda não salva (fechar à força).
  Future<bool> saveObjectiveChoice(ObjectiveDraft draft) =>
      _apply((s) => saveObjectiveDraft(s, draft));

  Future<bool> clearObjectiveChoice() => _apply(clearObjectiveDraft);

  // ---- Diagnóstico ----

  int testSize() {
    final v = view;
    if (v == null) return 5;
    final capacity = v.hasTournament
        ? v.minutesUntilTournament
        : v.state.plan.minutes * 28;
    return diagnosticTestSize(capacity);
  }

  /// O teste precisa de uma posição por capítulo escolhido, já no aparelho.
  bool testAvailable(int size) {
    final v = view;
    if (v == null) return false;
    final chosen = diagnosticChapters(v.chapters, size);
    return chosen.isNotEmpty && chosen.every((c) => exerciseFor(c.id) != null);
  }

  Future<bool> chooseTest() => _apply((s) {
    final d = s.diagnostic;
    if (d?.method == DiagnosticMethod.test && !d!.finished) return s;
    return startDiagnosticTest(s, planChapters(_resources!), testSize());
  });

  Future<bool> restart() => _apply(restartDiagnostic);

  Future<bool> answerTest(bool correct) =>
      _apply((s) => answerDiagnosticTest(s, correct));

  Future<bool> chooseQuestionnaire() => _apply(startQuestionnaire);

  Future<bool> answerTopic(String partId, TopicLevel level) =>
      _apply((s) => answerQuestionnaire(s, partId, level));

  /// Fecha o diagnóstico e gera o plano.
  Future<bool> finish() =>
      _apply((s) => finishDiagnostic(s, _resources!, today));

  // ---- Plano ----

  Future<bool> replanNow() => _apply((s) => replan(s, _resources!, today));

  Future<bool> undoLastAdjust() => _apply(undoAdjust);

  Future<bool> dismissLateChapters() {
    final keys = [
      for (final l in view?.late ?? const <LateChapter>[])
        lateKey(l.chapter.id, l.week),
    ];
    return _apply((s) => dismissLate(s, keys));
  }

  // ---- Dia perdido ----

  Future<bool> noteMissed() {
    final minutes = view?.minutesNeeded ?? 0;
    return _apply((s) => noteMissedDay(s, today, minutes));
  }

  Future<bool> confirmMissedMore() async {
    final minutes = view?.minutesNeeded ?? 0;
    final ok = await _apply((s) => confirmMoreTime(s, minutes));
    if (ok) {
      unawaited(
        _log(
          AnalyticsEvents.treinoDiaPerdido(
            curso: config.course.name,
            opcao: 'mais_tempo',
          ),
        ),
      );
    }
    return ok;
  }

  Future<bool> confirmMissedKeep() async {
    final resources = _resources!;
    final ok = await _apply((s) => confirmKeepTime(s, resources, today));
    if (ok) {
      unawaited(
        _log(
          AnalyticsEvents.treinoDiaPerdido(
            curso: config.course.name,
            opcao: 'manter',
          ),
        ),
      );
    }
    return ok;
  }

  // ---- Torneio ----

  /// Grava o rascunho a cada campo.
  Future<bool> saveDraft(TournamentDraft draft) =>
      _apply((s) => saveTournamentDraft(s, draft));

  /// "Descartar" o rascunho do registro (G8).
  Future<bool> discardDraft() => _apply(discardTournamentDraft);

  /// Registra o torneio; false se um campo não vale (pontos, rodadas, data)
  /// ou se já há 100 registros ([GoalView.tournamentsFull]).
  Future<bool> register(TournamentDraft draft) async {
    final id = now().microsecondsSinceEpoch.toString();
    final day = today;
    var accepted = false;
    final ok = await _apply((s) {
      final next = registerTournament(s, draft, id, today: day);
      accepted = next != null;
      return next ?? s;
    });
    return ok && accepted;
  }

  /// Corrige um registro (G7); false se um campo não vale.
  Future<bool> editTournament(String id, TournamentDraft draft) async {
    final day = today;
    var accepted = false;
    final ok = await _apply((s) {
      final next = goal.editTournament(s, id, draft, today: day);
      accepted = next != null;
      return next ?? s;
    });
    return ok && accepted;
  }

  /// Apaga um registro (G7); a tela mostra o "Desfazer".
  Future<bool> deleteTournament(String id) async {
    var accepted = false;
    final ok = await _apply((s) {
      final next = goal.deleteTournament(s, id);
      accepted = next != null;
      return next ?? s;
    });
    return ok && accepted;
  }

  /// Grava a edição de um registro a cada campo.
  Future<bool> saveEditDraft(String id, TournamentDraft draft) =>
      _apply((s) => saveTournamentEdit(s, id, draft));

  Future<bool> discardEditDraft() => _apply(discardTournamentEdit);

  /// Escolhe "Só quero melhorar" depois do torneio, ou outro torneio.
  Future<bool> nextGoal({required ObjectiveKind kind, String? date}) =>
      setObjective(kind: kind, date: date);

  TrainingExercise? exerciseFor(String chapterId) {
    final chapter = view?.chapter(chapterId);
    final resources = _resources;
    if (chapter == null || resources == null) return null;
    for (final lesson in chapter.lessonIds) {
      final bank = resources.banks[lesson];
      if (bank != null && bank.isNotEmpty) return bank.first;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
