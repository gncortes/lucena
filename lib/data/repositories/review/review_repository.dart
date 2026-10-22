import 'dart:convert';

import '../../../domain/models/review_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/review_policy.dart';
import '../../services/preferences_service.dart';
import '../../services/review_service.dart';

/// O pedido de avaliação da Play (E1.26): o que fica gravado (primeira
/// abertura, pedidos) e o que vale só nesta sessão (questionário visto,
/// último revés).
abstract class ReviewRepository {
  /// Grava o dia da primeira abertura, se ainda não tem.
  Future<void> markFirstOpen();

  /// A pessoa viu ou respondeu o "Sua opinião" ou o "Você pagaria?": nesta
  /// sessão não pede.
  void noteSurveySeen();

  /// Derrota, erro ou anúncio (E1.25 chama ao fechar o anúncio): não pede
  /// logo depois.
  void noteSetback();

  /// Pede a janela se a [ReviewPolicy] deixa; devolve se pediu.
  Future<bool> maybeAsk({
    required int lessonsCompleted,
    required int endgamesWon,
  });

  /// Quantos pedidos já foram feitos (o `numero` da E1.03).
  Future<int> requests();

  /// Perfil > "Avaliar o Lucena": a página na Play, sem contar nos pedidos.
  Future<void> openStoreListing();
}

class LocalReviewRepository implements ReviewRepository {
  LocalReviewRepository(this._preferences, this._service, this._now);

  final PreferencesService _preferences;
  final ReviewService _service;
  final Now _now;

  static const stateKey = 'review.v1.state';

  // Em memória: some quando o app fecha (é a "sessão").
  var _session = const ReviewSession();

  Future<ReviewState> _load() async {
    final raw = await _preferences.getString(stateKey);
    if (raw == null) return const ReviewState();
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?>
          ? ReviewState.fromJson(json)
          : const ReviewState();
    } on FormatException {
      return const ReviewState();
    }
  }

  Future<void> _save(ReviewState state) =>
      _preferences.setString(stateKey, jsonEncode(state.toJson()));

  @override
  Future<void> markFirstOpen() async {
    final state = await _load();
    if (state.firstOpen != null) return;
    await _save(state.withFirstOpen(_now()));
  }

  @override
  void noteSurveySeen() => _session = ReviewSession(
    surveySeen: true,
    lastSetback: _session.lastSetback,
  );

  @override
  void noteSetback() => _session = ReviewSession(
    surveySeen: _session.surveySeen,
    lastSetback: _now(),
  );

  @override
  Future<bool> maybeAsk({
    required int lessonsCompleted,
    required int endgamesWon,
  }) async {
    final state = await _load();
    final now = _now();
    final ask = ReviewPolicy.shouldAsk(
      now: now,
      state: state,
      session: _session,
      lessonsCompleted: lessonsCompleted,
      endgamesWon: endgamesWon,
      available: await _service.isAvailable(),
    );
    if (!ask) return false;
    // Conta antes de pedir: o app não sabe o que a pessoa fez na janela.
    await _save(state.requested(now));
    try {
      await _service.requestReview();
    } on Exception {
      // A Play recusou; o pedido já contou.
    }
    return true;
  }

  @override
  Future<int> requests() async => (await _load()).requests;

  @override
  Future<void> openStoreListing() => _service.openStoreListing();
}

/// Sem Play (F-Droid, testes): nunca pede.
class NoReviewRepository implements ReviewRepository {
  const NoReviewRepository();

  @override
  Future<void> markFirstOpen() async {}

  @override
  void noteSurveySeen() {}

  @override
  void noteSetback() {}

  @override
  Future<bool> maybeAsk({
    required int lessonsCompleted,
    required int endgamesWon,
  }) async => false;

  @override
  Future<int> requests() async => 0;

  @override
  Future<void> openStoreListing() async {}
}
