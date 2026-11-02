import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// O relatório de falhas em campo.
abstract interface class CrashReportService {
  Future<void> setEnabled(bool value);
  Future<void> flutterError(FlutterErrorDetails details);
  Future<void> fatalError(Object error, StackTrace stack);
}

CrashReportService? _activeReports;

/// Failures handled by a recoverable screen still belong in the crash report.
void reportHandledError(Object error, StackTrace stack) {
  debugPrint('$error\n$stack');
  unawaited(
    _activeReports
        ?.flutterError(FlutterErrorDetails(exception: error, stack: stack))
        .catchError(_ignore),
  );
}

class FirebaseCrashReportService implements CrashReportService {
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> setEnabled(bool value) =>
      _crashlytics.setCrashlyticsCollectionEnabled(value);

  @override
  Future<void> flutterError(FlutterErrorDetails details) =>
      _crashlytics.recordFlutterError(details);

  @override
  Future<void> fatalError(Object error, StackTrace stack) =>
      _crashlytics.recordError(error, stack, fatal: true);
}

/// Grava a escolha (o SDK a guarda no aparelho) e, ligado, envia ao relatório
/// o que o Flutter e a plataforma não trataram. O tratamento anterior continua.
Future<void> startCrashReports(
  CrashReportService reports, {
  required bool enabled,
}) async {
  await reports.setEnabled(enabled);
  _activeReports = enabled ? reports : null;
  if (!enabled) return;
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    unawaited(reports.flutterError(details).catchError(_ignore));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(reports.fatalError(error, stack).catchError(_ignore));
    return true;
  };
}

// Falha ao relatar não pode virar outra falha a relatar.
void _ignore(Object _) {}
