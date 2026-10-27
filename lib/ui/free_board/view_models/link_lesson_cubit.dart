import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/campaign/campaign_repository.dart';
import '../../../data/repositories/campaign/linked_lesson_catalog.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/campaign.dart';
import '../../../domain/models/challenge_link.dart';
import '../../../domain/models/linked_lesson.dart';
import '../../../domain/use_cases/link_lesson_rules.dart';

/// A aula oferecida no fim do desafio de um link de campanha (T84): conta a
/// oferta vista e tocada e decide se o convite de conta vem antes da aula.
/// O estado é `true` enquanto confere a aula e a conta depois do toque.
class LinkLessonCubit extends Cubit<bool> {
  LinkLessonCubit({
    required this.link,
    required this._accounts,
    required this._catalog,
    required this._campaigns,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(false);

  /// O desafio, com a aula ligada.
  final ChallengeLink link;

  final AccountRepository _accounts;
  final LinkedLessonCatalog _catalog;
  final CampaignRepository _campaigns;
  final AnalyticsRepository _analytics;

  LinkLessonOffer? _seen;

  /// A aula do link. Nula: o link não traz aula (o cubit não é criado).
  LinkedLesson? get lesson => link.lesson;

  Campaign get _campaign => Campaign.fromChallenge(link);

  /// A oferta apareceu no fim: conta uma vez por destaque.
  void seen(LinkLessonOffer offer) {
    if (offer == LinkLessonOffer.none || _seen == offer) return;
    _seen = offer;
    unawaited(
      _analytics.log(
        AnalyticsEvents.campanhaOfertaVista(_campaign, destaque: offer.code),
      ),
    );
  }

  /// Tocou na oferta: o próximo passo. Grava a campanha (a aula concluída
  /// depois conta para ela). A aula que não abre não pede conta.
  Future<LinkLessonStep> tapped(LinkLessonOffer offer) async {
    final lesson = this.lesson;
    if (lesson == null) return LinkLessonStep.unavailable;
    emit(true);
    unawaited(
      _analytics.log(
        AnalyticsEvents.campanhaOfertaTocada(_campaign, destaque: offer.code),
      ),
    );
    await _campaigns.remember(_campaign);
    final step = LinkLessonRules.next(
      available: await _catalog.available(lesson),
      hasAccount: _accounts.current != null,
    );
    // O convite vem antes: o login que vier dele conta como `feito` (o
    // AccountCubit consome a marca).
    if (step == LinkLessonStep.invite) await _campaigns.markInvited();
    if (step == LinkLessonStep.lesson) {
      unawaited(
        _analytics.log(
          AnalyticsEvents.campanhaCadastro(_campaign, resposta: 'ja_tem_conta'),
        ),
      );
    }
    if (!isClosed) emit(false);
    return step;
  }

  /// A resposta ao convite antes da aula: [accepted] Google ou e-mail. "Agora
  /// não" tira a marca do convite: um login de outro dia não conta para ele.
  Future<void> inviteAnswered({required bool accepted}) async {
    if (!accepted) await _campaigns.takeInvited();
    await _analytics.log(
      AnalyticsEvents.campanhaCadastro(
        _campaign,
        resposta: accepted ? 'aceitou' : 'agora_nao',
      ),
    );
  }
}
