import 'dart:async';

import '../data/repositories/analytics/analytics_repository.dart';
import '../data/repositories/campaign/campaign_repository.dart';
import '../data/repositories/campaign/linked_lesson_catalog.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/campaign.dart';
import '../domain/models/linked_lesson.dart';
import 'routes.dart';

/// Para onde vai a entrada da aula de um link de campanha
/// (`/aula/<id>`, `/escola/<id>`, T84): a aula, se abre; senão a regra de
/// sempre (a trilha ou a Escola), com o `aula_indisponivel`. Os dois casos
/// contam o `campanha_aula_aberta`.
Future<String> linkedLessonRedirect(
  LinkedLesson lesson, {
  required LinkedLessonCatalog catalog,
  required CampaignRepository campaigns,
  required AnalyticsRepository analytics,
}) async {
  final available = await catalog.available(lesson);
  final active = await campaigns.active();
  final campaign = active != null && active.lesson == lesson
      ? active
      : Campaign(lesson: lesson);
  unawaited(
    analytics.log(
      AnalyticsEvents.campanhaAulaAberta(campaign, disponivel: available),
    ),
  );
  if (!available) {
    unawaited(analytics.log(AnalyticsEvents.aulaIndisponivel(origem: 'link')));
  }
  return Routes.linkedLesson(lesson, available: available);
}
