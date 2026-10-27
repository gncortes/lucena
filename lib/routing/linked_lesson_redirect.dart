import 'dart:async';

import '../data/repositories/analytics/analytics_repository.dart';
import '../data/repositories/campaign/campaign_repository.dart';
import '../data/repositories/campaign/linked_lesson_catalog.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/campaign.dart';
import '../domain/models/linked_lesson.dart';
import 'routes.dart';

/// Normal content routes share the existing account invitation. Local authoring
/// and tests explicitly disable this policy; catalogs remain browsable.
String? lessonAccountRedirect(
  Uri target, {
  required bool required,
  required bool hasAccount,
}) {
  if (!required || hasAccount) return null;
  final lesson = _normalLesson(target);
  if (lesson == null) return null;
  return Uri(
    path: Routes.linkedLessonEntry(lesson),
    queryParameters: {'retorno': target.toString()},
  ).toString();
}

LinkedLesson? _normalLesson(Uri target) {
  if (target.hasScheme ||
      target.hasAuthority ||
      target.fragment.isNotEmpty ||
      !target.path.startsWith('/')) {
    return null;
  }
  final parts = target.pathSegments;
  if (parts.length >= 2 && parts[0] == 'endgames' && parts[1] != 'challenges') {
    return LinkedLesson(LinkedLessonKind.endgame, parts[1]);
  }
  if (parts.length == 3 && parts[0] == 'school' && parts[2] == 'roteiro') {
    return LinkedLesson(LinkedLessonKind.school, parts[1]);
  }
  return null;
}

/// Only a relative content route for this same lesson can be resumed.
String? lessonReturnDestination(LinkedLesson lesson, String? raw) {
  if (raw == null) return null;
  final target = Uri.tryParse(raw);
  return target != null && _normalLesson(target) == lesson
      ? target.toString()
      : null;
}

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
  String? returnTo,
}) async {
  final available = await catalog.available(lesson);
  if (available && !hasAccount) return null;
  final destination = lessonReturnDestination(lesson, returnTo);
  if (destination != null) {
    return available
        ? destination
        : Routes.linkedLesson(lesson, available: false);
  }
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
