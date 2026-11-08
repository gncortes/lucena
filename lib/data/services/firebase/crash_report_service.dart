import 'dart:async';
import 'dart:ui' show ErrorCallback;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// O relatório de falhas em campo.
abstract interface class CrashReportService {
  Future<void> setEnabled(bool value);
  Future<void> flutterError(FlutterErrorDetails details);
  Future<void> fatalError(Object error, StackTrace stack);
}

CrashReportService? _activeReports;
CrashReportService? _configuredReports;
FlutterExceptionHandler? _installedFlutterHandler;
ErrorCallback? _installedPlatformHandler;

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
  _configuredReports = reports;
  _activeReports = null;
  await setCrashReportsEnabled(enabled);
}

/// Applies the analytics repository's loaded opt-in/team policy without
/// stacking handlers when the switch changes repeatedly.
Future<void> setCrashReportsEnabled(bool enabled) async {
  final reports = _configuredReports;
  if (!enabled) _activeReports = null;
  if (reports == null) return;
  await reports.setEnabled(enabled);
  if (!enabled) return;
  _activeReports = reports;
  if (_installedFlutterHandler == null ||
      !identical(FlutterError.onError, _installedFlutterHandler)) {
    final previous = FlutterError.onError;
    _installedFlutterHandler = (details) {
      previous?.call(details);
      final active = _activeReports;
      if (active != null) {
        unawaited(active.flutterError(details).catchError(_ignore));
      }
    };
    FlutterError.onError = _installedFlutterHandler;
  }
  if (_installedPlatformHandler == null ||
      !identical(
        PlatformDispatcher.instance.onError,
        _installedPlatformHandler,
      )) {
    final previous = PlatformDispatcher.instance.onError;
    _installedPlatformHandler = (error, stack) {
      final active = _activeReports;
      if (active == null) return previous?.call(error, stack) ?? false;
      unawaited(active.fatalError(error, stack).catchError(_ignore));
      return true;
    };
    PlatformDispatcher.instance.onError = _installedPlatformHandler;
  }
}

// Falha ao relatar não pode virar outra falha a relatar.
void _ignore(Object _) {}
