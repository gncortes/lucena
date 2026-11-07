import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/data/services/firebase/analytics_service.dart';
import 'package:lucena/data/services/firebase/crash_report_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/use_cases/analytics_rules.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Analytics extends NoAnalyticsService {
  @override
  bool get available => true;
}

class _Reports implements CrashReportService {
  bool? enabled;
  final flutterErrors = <FlutterErrorDetails>[];
  final fatalErrors = <Object>[];

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> flutterError(FlutterErrorDetails details) async =>
      flutterErrors.add(details);

  @override
  Future<void> fatalError(Object error, StackTrace stack) async =>
      fatalErrors.add(error);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FlutterExceptionHandler? originalFlutter;
  late ErrorCallback? originalPlatform;
  late PreferencesService preferences;
  late _Reports reports;

  setUp(() async {
    originalFlutter = FlutterError.onError;
    originalPlatform = PlatformDispatcher.instance.onError;
    FlutterError.onError = (_) {};
    PlatformDispatcher.instance.onError = (_, _) => false;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesService();
    reports = _Reports();
    await startCrashReports(reports, enabled: true);
  });

  tearDown(() async {
    await startCrashReports(reports, enabled: false);
    FlutterError.onError = originalFlutter;
    PlatformDispatcher.instance.onError = originalPlatform;
  });

  for (final mode in AnalyticsMode.values) {
    for (final optIn in [false, true]) {
      for (final team in [false, true]) {
        test(
          'startup $mode optIn=$optIn team=$team applies the same rule',
          () async {
            await preferences.setBool(
              ServiceAnalyticsRepository.enabledKey,
              value: optIn,
            );
            await preferences.setBool(
              ServiceAnalyticsRepository.teamKey,
              value: team,
            );
            final repository = ServiceAnalyticsRepository(
              _Analytics(),
              preferences,
              mode: mode,
            );
            await repository.start();
            expect(
              reports.enabled,
              AnalyticsRules.collects(mode, optIn: optIn, team: team),
            );
          },
        );
      }
    }
  }

  test(
    'switch and team mode immediately stop and resume crash reporting',
    () async {
      final repository = ServiceAnalyticsRepository(_Analytics(), preferences);
      await repository.start();
      await repository.setEnabled(false);
      expect(reports.enabled, isFalse);
      await repository.setEnabled(true);
      expect(reports.enabled, isTrue);
      await repository.setTeamMode(true);
      expect(reports.enabled, isFalse);
      await repository.setEnabled(false);
      await repository.setTeamMode(false);
      expect(reports.enabled, isFalse);
      await repository.setEnabled(true);
      expect(reports.enabled, isTrue);
    },
  );

  test('disabled collection blocks handled, Flutter and platform reports without duplicating handlers', () async {
    final repository = ServiceAnalyticsRepository(_Analytics(), preferences);
    await repository.start();
    await repository.setEnabled(false);
    reportHandledError(StateError('handled while off'), StackTrace.empty);
    FlutterError.onError!(
      FlutterErrorDetails(exception: StateError('Flutter while off')),
    );
    final handled = PlatformDispatcher.instance.onError!(
      StateError('platform while off'),
      StackTrace.empty,
    );
    await Future<void>.delayed(Duration.zero);
    expect(reports.flutterErrors, isEmpty);
    expect(reports.fatalErrors, isEmpty);
    expect(handled, isFalse);
    await repository.setEnabled(true);
    await repository.setEnabled(false);
    await repository.setEnabled(true);
    FlutterError.onError!(
      FlutterErrorDetails(exception: StateError('Flutter on')),
    );
    PlatformDispatcher.instance.onError!(
      StateError('platform on'),
      StackTrace.empty,
    );
    await Future<void>.delayed(Duration.zero);
    expect(reports.flutterErrors, hasLength(1));
    expect(reports.fatalErrors, hasLength(1));
  });
}
