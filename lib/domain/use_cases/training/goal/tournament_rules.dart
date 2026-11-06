import '../../../models/training/training_state.dart';
import '../../../models/training/training_plan.dart';
import '../training_date.dart';
import 'goal_limits.dart';

/// Primeira data aceita para o torneio: amanhã.
String earliestTournamentDate(String today) =>
    trainingDate(civilDate(today).add(const Duration(days: 1)));

bool isValidTournamentDate(String? date, String today) =>
    date != null && date.compareTo(today) > 0;

/// Dias que faltam; negativo depois do torneio.
int daysUntil(String today, String date) =>
    DateTime.utc(
          civilDate(date).year,
          civilDate(date).month,
          civilDate(date).day,
        )
        .difference(
          DateTime.utc(
            civilDate(today).year,
            civilDate(today).month,
            civilDate(today).day,
          ),
        )
        .inDays;

enum TournamentPhase { before, day, after }

TournamentPhase tournamentPhase(String today, String date) {
  final c = today.compareTo(date);
  return c < 0
      ? TournamentPhase.before
      : c == 0
      ? TournamentPhase.day
      : TournamentPhase.after;
}

/// Registrar só a partir do dia seguinte ao torneio (G24).
bool canRegisterTournament(String today, String date) =>
    today.compareTo(date) > 0;

/// Datas aceitas no registro: de 2 anos atrás até hoje (G6).
({String first, String last}) registerDateRange(String today) {
  final d = civilDate(today);
  return (
    first: trainingDate(DateTime(d.year - registerWindowYears, d.month, d.day)),
    last: today,
  );
}

bool isValidRegisterDate(String date, String today) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return false;
  final range = registerDateRange(today);
  return date.compareTo(range.first) >= 0 && date.compareTo(range.last) <= 0;
}

String addDays(String date, int days) =>
    trainingDate(civilDate(date).add(Duration(days: days)));

/// Dias de estudo do plano entre [from] (inclusive) e [to] (exclusivo).
int studyDaysBetween(TrainingPlan plan, String from, String to) {
  var count = 0;
  for (var d = from; d.compareTo(to) < 0; d = addDays(d, 1)) {
    if (plan.studiesOn(civilDate(d))) count++;
  }
  return count;
}

/// Minutos de estudo até o torneio: tempo por dia vezes os dias marcados (H-TRE-03).
int studyMinutesUntil(TrainingPlan plan, String from, String to) =>
    studyDaysBetween(plan, from, to) * plan.minutes;

/// O aviso local do dia seguinte ao torneio (H-TRE-14): às 9h, uma vez, só
/// enquanto o desempenho não foi registrado e a hora ainda não passou.
({DateTime at, String name})? tournamentPush(
  TrainingState state,
  DateTime now,
) {
  final objective = state.objective;
  final date = objective?.tournamentDate;
  if (objective == null || !objective.hasTournament || date == null) {
    return null;
  }
  if (state.tournaments.any((t) => t.date == date)) return null;
  final day = DateTime.parse(addDays(date, 1));
  final at = DateTime(day.year, day.month, day.day, 9);
  if (!at.isAfter(now)) return null;
  return (at: at, name: objective.tournamentName);
}
