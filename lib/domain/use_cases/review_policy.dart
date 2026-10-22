import '../models/review_state.dart';

/// Quando pedir a avaliação da Play (In-App Review), direto e sem olhar
/// nota (E1.26, item 5).
abstract final class ReviewPolicy {
  /// Concluir a 3ª aula ou ganhar o 5º final, o que vier primeiro.
  static const lessons = 3;
  static const wins = 5;

  /// Dias de uso: entre a primeira abertura e hoje.
  static const minDays = 3;

  /// No máximo 3 pedidos na vida, com 60 dias entre eles.
  static const maxRequests = 3;
  static const gapDays = 60;

  /// Quanto tempo depois de um revés (derrota, erro, anúncio) ainda não pede.
  static const setbackWindow = Duration(minutes: 2);

  /// A espera depois de a tela de concluída estar visível e parada.
  static const delay = Duration(milliseconds: 1500);

  /// [available] é falso no F-Droid e sem Play (`isAvailable`).
  static bool shouldAsk({
    required DateTime now,
    required ReviewState state,
    required ReviewSession session,
    required int lessonsCompleted,
    required int endgamesWon,
    required bool available,
  }) {
    if (!available) return false;
    if (lessonsCompleted < lessons && endgamesWon < wins) return false;
    final firstOpen = state.firstOpen;
    if (firstOpen == null || _days(firstOpen, now) < minDays) return false;
    if (state.requests >= maxRequests) return false;
    final last = state.lastRequest;
    if (last != null && _days(last, now) < gapDays) return false;
    if (session.surveySeen) return false;
    final setback = session.lastSetback;
    if (setback != null && now.difference(setback) < setbackWindow) {
      return false;
    }
    return true;
  }

  /// Dias de calendário entre [from] e [to].
  static int _days(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
