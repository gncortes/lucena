import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/campaign/linked_lesson_catalog.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/link_lesson_rules.dart';
import 'package:lucena/ui/account/view_models/account_cubit.dart';
import 'package:lucena/ui/free_board/view_models/link_lesson_cubit.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_race_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';

/// Um catálogo que responde o que o teste mandar.
class _Catalog implements LinkedLessonCatalog {
  LinkedLessonInfo? lessonInfo;
  final languages = <String>[];

  @override
  Future<LinkedLessonInfo?> info(LinkedLesson lesson, String language) async {
    languages.add(language);
    return lessonInfo;
  }

  bool value = true;

  @override
  Future<bool> available(LinkedLesson lesson) async => value;
}

const _lesson = LinkedLesson.endgame('rook.lucena');

final _link = ChallengeLink(
  fen: '8/8/8/4k3/8/8/4K3/4Q3 w - - 0 1',
  userSide: Side.white,
  lesson: _lesson,
  utm: const {'utm_source': 'instagram', 'utm_campaign': 'torre-engana'},
);

void main() {
  late FakeAnalyticsRepository analytics;
  late MemoryCampaignRepository campaigns;
  late FakeAccountRepository accounts;
  late _Catalog catalog;

  setUp(() {
    analytics = FakeAnalyticsRepository();
    campaigns = MemoryCampaignRepository();
    accounts = FakeAccountRepository();
    catalog = _Catalog();
  });

  LinkLessonCubit cubit() {
    final cubit = LinkLessonCubit(
      campaign: Campaign.fromChallenge(_link),
      accounts: accounts,
      catalog: catalog,
      campaigns: campaigns,
      analytics: analytics,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('a oferta vista conta uma vez por destaque, com a campanha', () {
    final c = cubit()
      ..seen(LinkLessonOffer.none)
      ..seen(LinkLessonOffer.primary)
      ..seen(LinkLessonOffer.primary);
    expect(c.lesson, _lesson);
    final params = analytics.eventsNamed('campanha_oferta_vista').single.params;
    expect(params['destaque'], 'principal');
    expect(params['utm_campanha'], 'torre-engana');
    expect(params['aula_id'], 'rook.lucena');
    expect(params['tipo'], 'desafio');
  });

  test(
    'sem conta: convite antes da aula, e o login dele conta como feito',
    () async {
      final c = cubit();
      final step = await c.tapped(LinkLessonOffer.primary);
      expect(step, LinkLessonStep.invite);
      expect(c.state.busy, isFalse);
      expect(await campaigns.active(), Campaign.fromChallenge(_link));
      expect(analytics.eventsNamed('campanha_oferta_tocada'), hasLength(1));

      await c.inviteAnswered(accepted: true);
      expect(
        analytics.eventsNamed('campanha_cadastro').single.params['resposta'],
        'aceitou',
      );

      // O login que vem do convite fecha o cadastro da campanha.
      final account = AccountCubit(
        accounts,
        analytics: analytics,
        moment: 'pos_desafio_link',
        campaigns: campaigns,
      );
      addTearDown(account.close);
      await account.signInWithEmail('ana@example.com', 'senha-forte');
      await pumpEventQueue();
      expect(
        analytics
            .eventsNamed('campanha_cadastro')
            .map((event) => event.params['resposta']),
        ['aceitou', 'feito'],
      );
      expect(await campaigns.takeInvited(), isFalse);
    },
  );

  for (final (offer, code) in [
    (LinkLessonOffer.primary, 'principal'),
    (LinkLessonOffer.secondary, 'secundaria'),
  ]) {
    test('folha da aula ($code), sem conta: "Criar conta" grava a campanha, '
        'marca o convite e conta tocada e aceitou', () async {
      final c = cubit();
      final step = await c.accept(offer);
      expect(step, LinkLessonStep.invite);
      expect(c.state.busy, isFalse);
      expect(campaigns.invited, isTrue);
      expect(await campaigns.active(), Campaign.fromChallenge(_link));
      expect(
        analytics
            .eventsNamed('campanha_oferta_tocada')
            .single
            .params['destaque'],
        code,
      );
      expect(
        analytics.eventsNamed('campanha_cadastro').single.params['resposta'],
        'aceitou',
      );
    });

    test('folha da aula ($code), com conta: "Ver a aula" conta só '
        'ja_tem_conta', () async {
      accounts.account = const Account(
        uid: 'u1',
        provider: AccountProvider.google,
      );
      final c = cubit();
      expect(await c.accept(offer), LinkLessonStep.lesson);
      expect(campaigns.invited, isFalse);
      expect(
        analytics.eventsNamed('campanha_cadastro').single.params['resposta'],
        'ja_tem_conta',
      );
    });
  }

  test('loadInfo: o título, o módulo e a posição da aula, uma vez', () async {
    const info = LinkedLessonInfo(
      kind: LinkedLessonKind.endgame,
      title: 'Posição de Lucena',
      module: 'Finais de torre',
      fen: '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
    );
    catalog.lessonInfo = info;
    final c = cubit();
    await c.loadInfo('pt');
    await c.loadInfo('pt');
    expect(c.state.info, info);
    expect(catalog.languages, ['pt']);
  });

  test('loadInfo: a aula sem texto deixa a folha sem o cartão', () async {
    final c = cubit();
    await c.loadInfo('pt');
    expect(c.state.info, isNull);
  });

  test('"Agora não" tira a marca do convite', () async {
    final c = cubit();
    await c.tapped(LinkLessonOffer.secondary);
    await c.inviteAnswered(accepted: false);
    expect(campaigns.invited, isFalse);
    expect(
      analytics.eventsNamed('campanha_cadastro').single.params['resposta'],
      'agora_nao',
    );
  });

  test('com conta: a aula direto', () async {
    accounts.account = const Account(
      uid: 'u1',
      provider: AccountProvider.google,
    );
    final step = await cubit().tapped(LinkLessonOffer.secondary);
    expect(step, LinkLessonStep.lesson);
    expect(
      analytics.eventsNamed('campanha_cadastro').single.params['resposta'],
      'ja_tem_conta',
    );
    expect(campaigns.invited, isFalse);
  });

  test(
    'check: a aula que não abre registra aula_indisponivel uma vez',
    () async {
      catalog.value = false;
      final c = cubit();
      await c.check();
      await c.check();
      expect(c.state.available, isFalse);
      expect(
        analytics.eventsNamed('aula_indisponivel').single.params['origem'],
        'link',
      );
    },
  );

  test('check: a aula que abre fica disponível, sem evento', () async {
    final c = cubit();
    await c.check();
    expect(c.state.available, isTrue);
    expect(analytics.eventsNamed('aula_indisponivel'), isEmpty);
  });

  test('aula indisponível: sem convite', () async {
    catalog.value = false;
    final step = await cubit().tapped(LinkLessonOffer.primary);
    expect(step, LinkLessonStep.unavailable);
    expect(analytics.eventsNamed('campanha_cadastro'), isEmpty);
    expect(campaigns.invited, isFalse);
  });

  test('a aula da campanha concluída fecha o funil uma vez', () async {
    await campaigns.remember(Campaign.fromChallenge(_link));
    final now = FakeNow(DateTime(2026, 10, 27, 9));
    Future<void> finish(String id) async {
      final cubit = LessonFinishedCubit(
        kind: SurveyKind.endgames,
        lessonId: id,
        nextId: null,
        school: FakeLessonRepository(),
        endgames: FakeEndgameLessonRepository(),
        race: FakeRaceRepository(now: now),
        analytics: analytics,
        campaigns: campaigns,
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      await pumpEventQueue();
    }

    await finish('outra.aula');
    expect(analytics.eventsNamed('campanha_aula_concluida'), isEmpty);
    await finish('rook.lucena');
    expect(
      analytics.eventsNamed('campanha_aula_concluida').single.params['aula_id'],
      'rook.lucena',
    );
    expect(await campaigns.active(), isNull);
    await finish('rook.lucena');
    expect(analytics.eventsNamed('campanha_aula_concluida'), hasLength(1));
  });
}
