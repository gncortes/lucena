/// O que o pedido de avaliação da Play guarda (E1.26): o dia da primeira
/// abertura, quantos pedidos foram feitos e quando foi o último.
class ReviewState {
  const ReviewState({this.firstOpen, this.requests = 0, this.lastRequest});

  factory ReviewState.fromJson(Map<String, Object?> json) => ReviewState(
    firstOpen: _date(json['firstOpen']),
    requests: json['requests'] is int ? json['requests'] as int : 0,
    lastRequest: _date(json['lastRequest']),
  );

  final DateTime? firstOpen;
  final int requests;
  final DateTime? lastRequest;

  /// Mais um pedido em [at].
  ReviewState requested(DateTime at) => ReviewState(
    firstOpen: firstOpen,
    requests: requests + 1,
    lastRequest: at,
  );

  ReviewState withFirstOpen(DateTime at) =>
      ReviewState(firstOpen: at, requests: requests, lastRequest: lastRequest);

  Map<String, Object?> toJson() => {
    'firstOpen': ?firstOpen?.toIso8601String(),
    'requests': requests,
    'lastRequest': ?lastRequest?.toIso8601String(),
  };
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// O que vale só nesta sessão (em memória): se a pessoa viu um questionário
/// e quando foi o último revés (derrota, erro ou anúncio).
class ReviewSession {
  const ReviewSession({this.surveySeen = false, this.lastSetback});

  final bool surveySeen;
  final DateTime? lastSetback;
}
