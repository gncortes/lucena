import 'dart:async';

import '../data/repositories/analytics/analytics_repository.dart';
import '../data/repositories/campaign/campaign_repository.dart';
import '../data/repositories/campaign/linked_lesson_catalog.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/campaign.dart';
import '../domain/models/linked_lesson.dart';
import 'routes.dart';

/// Para onde vai a entrada da aula de um link de campanha
/// (`/aula/<id>`, `/escola/<id>`, T84): a aula, se abre e há conta; nulo
/// (fica na rota, que mostra o convite de conta) sem conta; a regra de
/// sempre (a trilha ou a Escola), com o `aula_indisponivel`, se a aula não
/// abre. O `campanha_aula_aberta` só sai com conta.
Future<String?> linkedLessonRedirect(
  LinkedLesson lesson, {
  required bool hasAccount,
  required LinkedLessonCatalog catalog,
  required CampaignRepository campaigns,
  required AnalyticsRepository analytics,
}) async {
  final available = await catalog.available(lesson);
  if (available && !hasAccount) return null;
  final active = await campaigns.active();
  final campaign = active != null && active.lesson == lesson
      ? active
      : Campaign(lesson: lesson);
  if (hasAccount) {
    unawaited(
      analytics.log(
        AnalyticsEvents.campanhaAulaAberta(campaign, disponivel: available),
      ),
    );
  }
  if (!available) {
    unawaited(analytics.log(AnalyticsEvents.aulaIndisponivel(origem: 'link')));
  }
  return Routes.linkedLesson(lesson, available: available);
}
