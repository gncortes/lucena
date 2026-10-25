import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analytics/analytics_opening.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/analytics_event.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/push_alert.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_activity_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_push_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';

final _link = ChallengeLink(
  fen: '8/8/8/4k3/8/8/4K3/4Q3 w - - 0 1',
  userSide: Side.white,
);

void main() {
  late FakeAnalyticsRepository analytics;
  late FakeAccountRepository account;
  late FakePushRepository push;

  setUp(() {
    analytics = FakeAnalyticsRepository();
    account = FakeAccountRepository();
    push = FakePushRepository(allowed: true);
  });

  AnalyticsOpening opening({String? country = 'br'}) {
    final now = FakeNow(DateTime(2026, 10, 22));
    return AnalyticsOpening(
      analytics,
      account: account,
      push: push,
      school: FakeSchoolProgressRepository(),
      endgames: FakeEndgameProgressRepository(),
      activity: FakeActivityRepository(now: now),
      now: now,
      country: () => country,
    );
  }

  test('abertura pela loja: origem loja, direto e sem link', () async {
    await opening().launched();

    expect(analytics.started, isTrue);
    expect(analytics.traits[AnalyticsTrait.firstOrigin], 'loja');
    expect(analytics.traits[AnalyticsTrait.originSource], 'direto');
    expect(analytics.traits[AnalyticsTrait.originLink], 'nenhum');
    expect(analytics.eventsNamed('link_aberto'), isEmpty);
  });

  test('link de post nosso: a campanha vira a origem', () async {
    final link = _link.copyWith(
      utm: {
        'utm_source': 'Instagram',
        'utm_campaign': 'lancamento',
        'utm_content': 'reels_1',
      },
    );
    await opening().launched(link: link);

    expect(analytics.traits[AnalyticsTrait.firstOrigin], 'link');
    expect(analytics.traits[AnalyticsTrait.originSource], 'instagram');
    expect(analytics.traits[AnalyticsTrait.originCampaign], 'lancamento');
    expect(analytics.traits[AnalyticsTrait.originPost], 'reels_1');
    expect(analytics.traits[AnalyticsTrait.originLink], 'nosso');
    final opened = analytics.eventsNamed('link_aberto').single;
    expect(opened.params['instalacao'], 'recem_instalado');
  });

  test('link criado no app: orgânico, fora da campanha', () async {
    final link = _link.sharedFrom('criar_desafio', generation: 2);
    await opening().launched(link: link);

    expect(analytics.traits[AnalyticsTrait.originSource], 'direto');
    expect(analytics.traits[AnalyticsTrait.originCampaign], 'direto');
    expect(analytics.traits[AnalyticsTrait.originLink], 'organico');
    final opened = analytics.eventsNamed('link_aberto').single;
    expect(opened.params['origem_link'], 'organico');
    // O próximo desafio que a pessoa mandar é a 3ª geração.
    expect(analytics.trail?.code, link.code);
    expect(analytics.trail?.generation, 2);
  });

  test('já instalado: o link conta, a origem não muda', () async {
    analytics.firstOpen = false;
    await opening().launched(link: _link);

    expect(analytics.traits.containsKey(AnalyticsTrait.firstOrigin), isFalse);
    final opened = analytics.eventsNamed('link_aberto').single;
    expect(opened.params['instalacao'], 'ja_instalado');
  });

  test('aberto por aviso: origem push', () async {
    await opening().launched(pushed: true);
    expect(analytics.traits[AnalyticsTrait.firstOrigin], 'push');
  });

  test('as propriedades do aparelho', () async {
    account.account = const Account(
      uid: 'u1',
      email: 'ana@example.com',
      provider: AccountProvider.google,
    );
    await opening(country: 'São Paulo').launched();

    expect(analytics.traits[AnalyticsTrait.country], 'nenhum');
    expect(analytics.traits[AnalyticsTrait.alertsAllowed], 'sim');
    expect(analytics.traits[AnalyticsTrait.account], 'google');
    expect(analytics.traits[AnalyticsTrait.school], 'nao_iniciada');
    expect(analytics.traits[AnalyticsTrait.endgameLessonsDone], '0');
    expect(analytics.traits[AnalyticsTrait.lessonInProgress], 'nao');
    expect(analytics.traits[AnalyticsTrait.streakBand], '0');
    // O e-mail nunca vira propriedade.
    expect(analytics.traits.values, isNot(contains('ana@example.com')));
  });

  test('o tipo do aviso sai do caminho', () {
    expect(AnalyticsOpening.alertType('/daily'), 'dia');
    expect(AnalyticsOpening.alertType('/endgame-lesson/lucena'), 'aulas');
    expect(AnalyticsOpening.alertType('/featured/42'), 'torneios');
    expect(AnalyticsOpening.alertType('/'), 'novidades');
  });

  test(
    'push do painel tocado: aviso_aberto e push_aberto com o país',
    () async {
      await opening().pushOpened(
        PushOpening(
          link: Uri.parse('/featured/tournament/7'),
          pushId: 'p1',
          country: 'BR',
        ),
      );

      expect(
        analytics.eventsNamed('aviso_aberto').single.params['canal'],
        'push',
      );
      final pushed = analytics.eventsNamed('push_aberto').single;
      expect(pushed.params, {'push_id': 'p1', 'pais': 'BR'});
    },
  );

  test('push sem pushId (de antes do painel): só aviso_aberto', () async {
    await opening().pushOpened(PushOpening(link: Uri.parse('/daily')));

    expect(analytics.eventsNamed('aviso_aberto'), hasLength(1));
    expect(analytics.eventsNamed('push_aberto'), isEmpty);
  });
}
