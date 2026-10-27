import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/campaign/campaign_repository.dart';
import '../../../data/repositories/campaign/linked_lesson_catalog.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/campaign.dart';
import '../../../domain/models/linked_lesson.dart';
import '../../../domain/use_cases/link_lesson_rules.dart';

/// A aula de um link de campanha (T84), que só abre com conta: no fim do
/// desafio, conta a oferta vista e tocada e decide se o convite de conta vem
/// antes; no link só de aula, o convite antes da aula.
class LinkLessonCubit extends Cubit<LinkLessonState> {
  LinkLessonCubit({
    required this.campaign,
    required this._accounts,
    required this._catalog,
    required this._campaigns,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const LinkLessonState());

  /// A campanha, com a aula ligada (`Campaign.fromChallenge` no desafio).
  final Campaign campaign;

  final AccountRepository _accounts;
  final LinkedLessonCatalog _catalog;
  final CampaignRepository _campaigns;
  final AnalyticsRepository _analytics;

  LinkLessonOffer? _seen;

  /// A aula do link. Nula: o link não traz aula (o cubit não é criado).
  LinkedLesson? get lesson => campaign.lesson;

  Campaign get _campaign => campaign;

  /// Já entrou numa conta.
  bool get hasAccount => _accounts.current != null;

  /// Confere uma vez se a aula abre (no começo do desafio). A que não abre
  /// não é oferecida no fim e registra `aula_indisponivel(origem: link)`.
  Future<void> check() async {
    final lesson = this.lesson;
    if (lesson == null || state.available != null) return;
    final available = await _catalog.available(lesson);
    if (isClosed) return;
    emit(state.copyWith(available: available));
    if (!available) {
      unawaited(
        _analytics.log(AnalyticsEvents.aulaIndisponivel(origem: 'link')),
      );
    }
  }

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
    emit(state.copyWith(busy: true));
    unawaited(
      _analytics.log(
        AnalyticsEvents.campanhaOfertaTocada(_campaign, destaque: offer.code),
      ),
    );
    await _campaigns.remember(_campaign);
    final step = LinkLessonRules.next(
      available: state.available ?? await _catalog.available(lesson),
      hasAccount: hasAccount,
    );
    if (step == LinkLessonStep.invite) await _campaigns.markInvited();
    if (step == LinkLessonStep.lesson) {
      unawaited(
        _analytics.log(
          AnalyticsEvents.campanhaCadastro(_campaign, resposta: 'ja_tem_conta'),
        ),
      );
    }
    if (!isClosed) emit(state.copyWith(busy: false));
    return step;
  }

  /// O link só de aula, sem conta: o convite abre antes da aula. Grava a
  /// campanha e marca o convite: o login que vier dele conta como `feito` (o
  /// AccountCubit consome a marca).
  Future<void> gateOpened() async {
    await _campaigns.remember(_campaign);
    await _campaigns.markInvited();
  }

  /// A resposta ao convite antes da aula: [accepted] Google ou e-mail. "Agora
  /// não" tira a marca do convite (um login de outro dia não conta para ele)
  /// e a aula não abre.
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

/// O estado da aula do link: [available] nulo enquanto confere; [busy]
/// enquanto confere a conta depois do toque.
final class LinkLessonState {
  const LinkLessonState({this.available, this.busy = false});

  final bool? available;
  final bool busy;

  LinkLessonState copyWith({bool? available, bool? busy}) => LinkLessonState(
    available: available ?? this.available,
    busy: busy ?? this.busy,
  );

  @override
  bool operator ==(Object other) =>
      other is LinkLessonState &&
      other.available == available &&
      other.busy == busy;

  @override
  int get hashCode => Object.hash(available, busy);
}
