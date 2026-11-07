import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/firebase/crash_report_service.dart';

class _FakeCrashReports implements CrashReportService {
  bool? enabled;
  final flutterErrors = <FlutterErrorDetails>[];
  final errors = <Object>[];

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> flutterError(FlutterErrorDetails details) async =>
      flutterErrors.add(details);

  @override
  Future<void> fatalError(Object error, StackTrace stack) async =>
      errors.add(error);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? flutterHandler;
  late ErrorCallback? platformHandler;

  setUp(() {
    flutterHandler = FlutterError.onError;
    platformHandler = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = flutterHandler;
    PlatformDispatcher.instance.onError = platformHandler;
  });

  test('ligado: falha de tela e falha solta chegam ao relatório', () async {
    final reports = _FakeCrashReports();
    var previous = 0;
    FlutterError.onError = (_) => previous++;

    await startCrashReports(reports, enabled: true);
    final details = FlutterErrorDetails(exception: StateError('tela'));
    FlutterError.onError!(details);
    final handled = PlatformDispatcher.instance.onError!(
      StateError('solta'),
      StackTrace.empty,
    );

    expect(reports.enabled, isTrue);
    expect(reports.flutterErrors, [details]);
    expect(reports.errors.single, isA<StateError>());
    expect(handled, isTrue);
    // O tratamento de antes continua: o erro segue aparecendo no log.
    expect(previous, 1);
  });

  test('desligado (F-Droid, E2E, depuração): nada é capturado', () async {
    final reports = _FakeCrashReports();
    final before = FlutterError.onError;

    await startCrashReports(reports, enabled: false);

    expect(reports.enabled, isFalse);
    expect(FlutterError.onError, same(before));
    expect(PlatformDispatcher.instance.onError, same(platformHandler));
  });

  test('o relatório que falha não derruba o tratamento', () async {
    final reports = _BrokenCrashReports();
    await startCrashReports(reports, enabled: true);

    FlutterError.onError!(FlutterErrorDetails(exception: StateError('tela')));
    final handled = PlatformDispatcher.instance.onError!(
      StateError('solta'),
      StackTrace.empty,
    );
    await Future<void>.delayed(Duration.zero);

    expect(handled, isTrue);
  });
}

class _BrokenCrashReports extends _FakeCrashReports {
  @override
  Future<void> flutterError(FlutterErrorDetails details) async =>
      throw StateError('sem canal');

  @override
  Future<void> fatalError(Object error, StackTrace stack) async =>
      throw StateError('sem canal');
}
