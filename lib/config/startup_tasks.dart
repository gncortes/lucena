import 'dart:async';

import '../domain/models/app_links.dart';
import 'ambiente.dart';

import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry, kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import '../data/repositories/analytics/analytics_opening.dart';
import '../data/services/firebase/crash_report_service.dart';
import '../data/services/firebase/firebase_bootstrap.dart';
import '../ui/core/widgets/load_error_fallback.dart';
import '../domain/models/linked_lesson.dart';
import '../domain/use_cases/resolve_launch_destination.dart';
import '../domain/use_cases/visible_lessons.dart';
import 'dependencies.dart';
import 'licencas_legais.dart';

/// O que o app liga antes de montar qualquer tela: a tela de erro de release,
/// as licenças, o Firebase e o relatório de falhas. Devolve se o Firebase
/// subiu.
Future<bool> startPlatform() async {
  if (kReleaseMode) ErrorWidget.builder = buildLoadErrorFallback;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Material Symbols Rounded',
    ], await rootBundle.loadString('assets/fonts/MaterialSymbols-LICENSE.txt'));
  });
  // Os links que o app gera e abre usam o site deste ambiente (A4).
  AppLinks.configure(siteHost: Ambiente.atual().siteHost);
  registrarLicencasLegais();
  final firebase = await startFirebase();
  if (firebase) {
    await startCrashReports(
      FirebaseCrashReportService(),
      // The analytics repository applies opt-in/team policy once loaded.
      enabled: false,
    );
  }
  return firebase;
}

/// Um valor lido antes de montar o app; a falha vai para o relatório e vale
/// o [fallback].
Future<T> launchValue<T>(Future<T> Function() read, T fallback) async {
  try {
    return await read();
  } on Object catch (error, stack) {
    reportHandledError(error, stack);
    return fallback;
  }
}

/// As estatísticas da abertura e dos links (E1.03).
AnalyticsOpening openingAnalytics(Dependencies dependencies) =>
    AnalyticsOpening(
      dependencies.analyticsRepository,
      account: dependencies.accountRepository,
      push: dependencies.pushRepository,
      school: dependencies.schoolProgressRepository,
      endgames: dependencies.endgameProgressRepository,
      activity: dependencies.activityRepository,
      now: dependencies.now,
      profile: dependencies.profileRepository,
      campaigns: dependencies.campaignRepository,
      country: () =>
          WidgetsBinding.instance.platformDispatcher.locale.countryCode,
      schoolLessons: VisibleLessons.schoolLessonIds,
    );

/// As tarefas de início do app: cada uma roda uma vez por sessão (também
/// quando a abertura é repetida depois de uma falha), e a falha dela vai para
/// o relatório sem travar a abertura.
class StartupTasks {
  StartupTasks(this._dependencies, {required this._analytics});

  final Dependencies _dependencies;
  final AnalyticsOpening _analytics;
  final _started = <String>{};
  static const _resolve = ResolveLaunchDestination();

  /// Antes de ler o aviso que abriu o app.
  void beforeLaunch() {
    _once('push', _dependencies.pushRepository.start);
    // Só o último aparelho em que a conta entrou recebe o push dela.
    _once('pushDevice', _dependencies.accountRepository.linkPushDevice);
    // O dia da primeira abertura conta para o pedido de avaliação (E1.26).
    _once('review', _dependencies.reviewRepository.markFirstOpen);
  }

  /// O link (ou o aviso) que abriu o app já é conhecido.
  void launched(LaunchFacts facts) {
    final opened = facts.opened;
    _once(
      'launchAnalytics',
      () => _analytics.launched(
        link: _resolve.link(facts),
        lessonLink: opened == null ? null : LessonLink.tryParse(opened),
        pushed: _resolve.pushed(facts),
        fromReferrer: facts.fromReferrer,
      ),
    );
    // O anúncio (E1.25): sessão nova e, para quem já respondeu "O que você
    // quer fazer?", o consentimento do Google. Quem veio de um link não vê o
    // formulário agora.
    _once(
      'ads',
      () => _dependencies.adsRepository.start(
        fromLink: _resolve.fromLink(facts),
        goalAnswered: facts.onboardingDone || facts.goalAnswered,
      ),
    );
  }

  void _once(String name, Future<void> Function() start) {
    if (!_started.add(name)) return;
    unawaited(
      Future<void>.sync(start).catchError((Object error, StackTrace stack) {
        reportHandledError(error, stack);
      }),
    );
  }
}
