import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/challenge_link.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/analytics_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../account/account_repository.dart';
import '../activity/activity_repository.dart';
import '../endgames/endgame_progress_repository.dart';
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
    this.schoolLessons = const {},
  });

  final AnalyticsRepository _analytics;
  final AccountRepository account;
  final PushRepository push;
  final SchoolProgressRepository school;
  final EndgameProgressRepository endgames;
  final ActivityRepository activity;
  final Now now;

  /// O país da região do celular (ISO de 2 letras), sem permissão.
  final String? Function() country;

  /// As aulas da Escola que aparecem (para saber se ela foi concluída).
  final Set<String> schoolLessons;

  /// Na partida fria: [link] é o desafio que abriu o app (por link ou por
  /// aviso); [pushed] diz que o app abriu por um aviso.
  Future<void> launched({ChallengeLink? link, bool pushed = false}) async {
    await _analytics.start();
    final installedNow = await _analytics.recordOrigin(
      first: pushed
          ? 'push'
          : link != null
          ? 'link'
          : 'loja',
      source: link == null
          ? null
          : AnalyticsRules.campaignValue(link.utm, 'utm_source'),
      campaign: link == null
          ? null
          : AnalyticsRules.campaignValue(link.utm, 'utm_campaign'),
      post: link == null
          ? null
          : AnalyticsRules.campaignValue(link.utm, 'utm_content'),
      link: link == null
          ? null
          : AnalyticsRules.linkOrigin(link.utm['utm_source']),
    );
    if (link != null) await opened(link, installedNow: installedNow);
    await syncTraits();
  }

  /// Um link de desafio abriu o app (ou chegou com ele aberto).
  Future<void> opened(ChallengeLink link, {bool installedNow = false}) async {
    await _analytics.log(
      AnalyticsEvents.linkOpened(link, installedNow: installedNow),
    );
    await _analytics.rememberLink(
      LinkTrail(code: link.code, generation: link.generation),
    );
  }

  /// Tocou num aviso: [channel] `push` ou `local`; [path] diz o tipo.
  Future<void> alertOpened(String path, {required String channel}) =>
      _analytics.log(
        AnalyticsEvents.avisoAberto(canal: channel, tipo: alertType(path)),
      );

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

  /// As propriedades lidas do aparelho: país, aviso, conta, Escola, aulas de
  /// finais e sequência.
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
    final done =
        lessons.isNotEmpty && progress.completed.containsAll(lessons);
    return done ? 'concluida' : 'em_andamento';
  }

  static int lessonsDone(EndgameProgress progress) =>
      progress.lessons.values.where((lesson) => lesson.lessonDone).length;
}
