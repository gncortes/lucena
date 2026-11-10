import 'dart:async';

import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/domain/models/platform_rating.dart';

/// Um Lichess que devolve o que o teste mandar, sem navegador.
class FakeLichessRepository implements LichessRepository {
  FakeLichessRepository({this.rating, this.failure, this.pending});

  /// O que a conexão devolve; com [failure], ela falha.
  PlatformRating? rating;
  LichessFailure? failure;

  /// A volta que abriu o app (partida fria).
  PlatformRating? pending;

  /// Com [hold], [connect] espera até [cancel] ou [complete].
  bool hold = false;
  bool connected = false;
  int connects = 0;
  int disconnects = 0;
  Completer<PlatformRating>? _held;

  void complete() => _held?.complete(_result());

  @override
  Future<PlatformRating> connect() {
    connects++;
    if (hold) return (_held = Completer<PlatformRating>()).future;
    return Future.sync(_result);
  }

  PlatformRating _result() {
    final failure = this.failure;
    if (failure != null) throw LichessException(failure);
    connected = true;
    return rating ??
        PlatformRating(
          user: 'DrNykterstein',
          readAt: DateTime.utc(2026, 11, 9),
        );
  }

  @override
  void cancel() {
    final held = _held;
    _held = null;
    if (held != null && !held.isCompleted) {
      held.completeError(const LichessException(LichessFailure.cancelled));
    }
  }

  @override
  Future<PlatformRating?> resume() async {
    final value = pending;
    pending = null;
    if (value != null) connected = true;
    return value;
  }

  @override
  Future<PlatformRating> account() => Future.sync(_result);

  @override
  Future<PlatformRating?> lastRead() async => connected ? rating : null;

  /// Com valor, o próximo desconectar falha (e a conexão fica).
  Object? disconnectError;

  @override
  Future<void> disconnect() async {
    final error = disconnectError;
    if (error != null) {
      disconnectError = null;
      throw error;
    }
    disconnects++;
    connected = false;
  }

  @override
  Future<bool> isConnected() async => connected;

  /// O token que o servidor recebe; os testes trocam para simular revogado.
  String token = 'token-falso-do-lichess';

  @override
  Future<String?> accessToken() async => connected ? token : null;
}
