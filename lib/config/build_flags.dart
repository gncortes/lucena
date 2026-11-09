import 'package:flutter/foundation.dart';

import '../domain/models/training/training_course_config.dart';
import '../domain/use_cases/analytics_rules.dart';
import '../domain/use_cases/visible_lessons.dart';

/// Ligado por `--dart-define=E2E=true` nos cenários Patrol.
const isE2E = bool.fromEnvironment('E2E');

/// O modo das estatísticas deste build (E1.03 §10): `FDROID=true` no build do
/// F-Droid, `ANALYTICS_DEBUG=true` para o DebugView e `CANAL=qa` na QA.
final analyticsMode = AnalyticsRules.mode(
  release: kReleaseMode,
  e2e: isE2E,
  fdroid: const bool.fromEnvironment('FDROID'),
  debugView: const bool.fromEnvironment('ANALYTICS_DEBUG'),
  channel: const String.fromEnvironment('CANAL'),
);

/// A versão do app (`0.3.2-rc.1`), passada pelo CI ao montar o APK assinado.
/// Vazia nos builds locais: aí vale a do aparelho
/// (`Dependencies.installedVersion`).
const appVersion = String.fromEnvironment('APP_VERSION');

/// Os prints de validação (Patrol) comparam a tela com o quadro, que não tem
/// as ferramentas de desenvolvimento: o cenário de prints liga isto.
bool hideDevToolsForPrints = false;

/// As telas de desenvolvimento aparecem nos builds de depuração, nos cenários
/// Patrol e nas candidatas de QA (`-rc`); nunca na versão final.
bool get showsDevTools =>
    !hideDevToolsForPrints &&
    (kDebugMode || isE2E || appVersion.contains('-rc'));

List<TrainingCourseConfig> get activeTrainingCourses => [
  if (showsDevTools) TrainingCourseConfig.pilares,
  if (kDebugMode || isE2E || VisibleLessons.schoolLessonIds.isNotEmpty)
    TrainingCourseConfig.escola,
];
