import 'dart:convert';

import 'package:lucena/data/repositories/blind/blind_log_repository.dart';

/// As medições na memória.
class FakeBlindLogRepository implements BlindLogRepository {
  final attempts = <BlindAttempt>[];

  @override
  Future<void> add(BlindAttempt attempt) async => attempts.add(attempt);

  @override
  Future<List<BlindAttempt>> all() async => attempts;

  @override
  Future<String> export() async =>
      jsonEncode([for (final a in attempts) a.toJson()]);

  @override
  Future<void> clear() async => attempts.clear();
}
