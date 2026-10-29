import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/campaign.dart';
import '../../../domain/models/challenge_link.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/linked_lesson.dart';
import '../../../domain/models/push_alert.dart';
import '../../../domain/use_cases/analytics_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../account/account_repository.dart';
import '../activity/activity_repository.dart';
import '../campaign/campaign_repository.dart';
import '../endgames/endgame_progress_repository.dart';
import '../profile/profile_repository.dart';
import '../push/push_repository.dart';
import '../school/school_progress_repository.dart';
import 'analytics_repository.dart';

/// O que o Analytics faz na abertura do app (E1.03): liga ou desliga a
/// coleta, grava a origem da 1ª abertura, conta o link que abriu o app e
/// acerta as propriedades que dá para ler do aparelho.
class AnalyticsOpening {
  const AnalyticsOpening(
    this._analytics, {
    required this.account,
    required this.push,
    required this.school,
    required this.endgames,
    required this.activity,
    required this.now,
    required this.country,
    this.profile,
    this.campaigns,
    this.schoolLessons = const {},
  });

  final AnalyticsRepository _analytics;
  final AccountRepository account;
  final PushRepository push;
  final SchoolProgressRepository school;
  final EndgameProgressRepository endgames;
  final ActivityRepository activity;
  final Now now;

  /// O perfil, para o `lichess_vinculado` (conta e Lichess ligados).
  final ProfileRepository? profile;

  /// A campanha do link de post que abriu o app (T84), para o funil.
  final CampaignRepository? campaigns;

  /// O país da região do celular (ISO de 2 letras), sem permissão.
  final String? Function() country;

  /// As aulas da Escola que aparecem (para saber se ela foi concluída).
  final Set<String> schoolLessons;

  /// Na partida fria: [link] é o desafio que abriu o app (por link ou por
  /// aviso); [lessonLink], o link só de aula (T84); [pushed] diz que o app
  /// abriu por um aviso; [fromReferrer], que o link veio da instalação pela
  /// Play (deferred deep link).
  Future<void> launched({
    ChallengeLink? link,
    LessonLink? lessonLink,
    bool pushed = false,
    bool fromReferrer = false,
  }) async {
    await _analytics.start();
    final utm = link?.utm ?? lessonLink?.utm;
    final installedNow = await _analytics.recordOrigin(
      first: pushed
          ? 'push'
          : utm != null
          ? 'link'
          : 'loja',
      source: utm == null
          ? null
          : AnalyticsRules.campaignValue(utm, 'utm_source'),
      campaign: utm == null
          ? null
          : AnalyticsRules.campaignValue(utm, 'utm_campaign'),
      post: utm == null
          ? null
          : AnalyticsRules.campaignValue(utm, 'utm_content'),
      link: utm == null ? null : AnalyticsRules.linkOrigin(utm['utm_source']),
    );
    if (link != null) {
      await opened(
        link,
        installedNow: installedNow,
        fromReferrer: fromReferrer,
      );
    } else if (lessonLink != null) {
      await campaignOpened(
        Campaign.fromLessonLink(lessonLink),
        installedNow: installedNow,
        fromReferrer: fromReferrer,
      );
    }
    await syncTraits();
  }

  /// Um link de desafio abriu o app (ou chegou com ele aberto). O de post
  /// (ou com aula) também entra no funil de campanha.
  Future<void> opened(
    ChallengeLink link, {
    bool installedNow = false,
    bool fromReferrer = false,
  }) async {
    await _analytics.log(
      AnalyticsEvents.linkOpened(link, installedNow: installedNow),
    );
    await _analytics.rememberLink(
      LinkTrail(code: link.code, generation: link.generation),
    );
    if (link.isCampaign) {
      await campaignOpened(
        Campaign.fromChallenge(link),
        installedNow: installedNow,
        fromReferrer: fromReferrer,
      );
    }
  }

  /// O link de campanha [campaign] abriu o app: grava a campanha (o link mais
  /// novo vence) e conta o `campanha_link_aberto` e, se veio da Play, o
  /// `campanha_instalacao`.
  Future<void> campaignOpened(
    Campaign campaign, {
    bool installedNow = false,
    bool fromReferrer = false,
  }) async {
    await campaigns?.remember(campaign);
    if (fromReferrer) {
      await _analytics.log(AnalyticsEvents.campanhaInstalacao(campaign));
    }
    await _analytics.log(
      AnalyticsEvents.campanhaLinkAberto(campaign, installedNow: installedNow),
    );
  }

  /// Tocou num aviso: [channel] `push` ou `local`; [path] diz o tipo.
  Future<void> alertOpened(String path, {required String channel}) => _analytics
      .log(AnalyticsEvents.avisoAberto(canal: channel, tipo: alertType(path)));

  /// Tocou num push: o `aviso_aberto` pelo caminho e, se veio do painel
  /// (tem `pushId`), o `push_aberto`.
  Future<void> pushOpened(PushOpening opening) async {
    await alertOpened(opening.link?.path ?? '', channel: 'push');
    final id = opening.pushId;
    if (id == null) return;
    await _analytics.log(
      AnalyticsEvents.pushAberto(pushId: id, pais: opening.country),
    );
  }

  /// `dia|aulas|torneios|novidades`, pelo caminho do aviso.
  static String alertType(String path) {
    final first = Uri.parse(path).pathSegments.firstOrNull;
    return switch (first) {
      'daily' => 'dia',
      'lesson' || 'endgame-lesson' || 'endgames' => 'aulas',
      'featured' => 'torneios',
      _ => 'novidades',
    };
  }

  /// As propriedades lidas do aparelho: país, aviso, conta, Lichess
  /// vinculado, Escola, aulas de finais e sequência.
  Future<void> syncTraits() async {
    await _analytics.setTrait(
      AnalyticsTrait.country,
      AnalyticsRules.countryOrNone(country()),
    );
    if (push.available) {
      await _analytics.setTrait(
        AnalyticsTrait.alertsAllowed,
        AnalyticsRules.yesNo(await push.permitted()),
      );
    }
    await _analytics.setTrait(
      AnalyticsTrait.account,
      accountTrait(account.current),
    );
    if (profile case final profile?) {
      final lichess = (await profile.load()).lichessUser;
      await _analytics.setTrait(
        AnalyticsTrait.lichessLinked,
        AnalyticsRules.yesNo(account.current != null && lichess != null),
      );
    }
    await _analytics.setTrait(
      AnalyticsTrait.school,
      schoolTrait(await school.load(), schoolLessons),
    );
    final lessons = await endgames.load();
    await _analytics.setTrait(
      AnalyticsTrait.endgameLessonsDone,
      AnalyticsRules.lessonsBand(lessonsDone(lessons)),
    );
    await _analytics.setTrait(
      AnalyticsTrait.lessonInProgress,
      AnalyticsRules.yesNo(lessons.ongoing != null),
    );
    final streak = StreakRules.of(await activity.days(), now());
    await _analytics.setTrait(
      AnalyticsTrait.streakBand,
      AnalyticsRules.streakBand(streak.current),
    );
  }

  /// `nenhuma|google|email`.
  static String accountTrait(Account? account) => switch (account?.provider) {
    null => 'nenhuma',
    AccountProvider.google => 'google',
    AccountProvider.email => 'email',
  };

  /// `nao_iniciada|em_andamento|concluida`.
  static String schoolTrait(SchoolProgress progress, Set<String> lessons) {
    if (progress.completed.isEmpty && progress.ongoing == null) {
      return 'nao_iniciada';
    }
    final done = lessons.isNotEmpty && progress.completed.containsAll(lessons);
    return done ? 'concluida' : 'em_andamento';
  }

  static int lessonsDone(EndgameProgress progress) =>
      progress.lessons.values.where((lesson) => lesson.lessonDone).length;
}
