import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_ad/course_access_repository.dart';
import 'package:lucena/data/repositories/lesson_ad/course_grants_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_grants.dart';
import '../../../../testing/fakes/fake_now.dart';

/// H-R5-61: o curso abre pela compra ou pelo `acessos/{uid}` do servidor.
void main() {
  final now = FakeNow(DateTime.utc(2026, 11, 6, 12));
  late FakeCourseGrantsService service;
  late PreferencesService preferences;
  late StreamController<String?> uids;
  String? uid;
  late CloudCourseGrantsRepository grants;

  Map<String, Object?> doc({
    String origin = 'presente',
    String plan = 'vitalicio',
    DateTime? until,
    DateTime? revoked,
    DateTime? given,
    DateTime? seen,
  }) => {
    'cursos': {
      pilaresCourseId: {
        'origem': origin,
        'plano': plan,
        'dadoPor': 'admin',
        'dadoEm': given ?? DateTime.utc(2026, 11, 5),
        'ate': ?until,
        'revogadoEm': ?revoked,
        'pais': 'BR',
      },
    },
    if (seen != null) 'vistos': {pilaresCourseId: seen},
  };

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now.value = DateTime.utc(2026, 11, 6, 12);
    service = FakeCourseGrantsService();
    preferences = PreferencesService();
    uids = StreamController<String?>.broadcast();
    uid = 'u1';
    grants = CloudCourseGrantsRepository(
      service,
      preferences,
      uids: uids.stream,
      currentUid: () => uid,
      now: now,
    );
  });

  tearDown(() async {
    await grants.dispose();
    await uids.close();
  });

  ServerCourseAccessRepository access([
    CourseAccessRepository base = const _Fixed(CourseAccess.demo),
  ]) => ServerCourseAccessRepository(base, grants, now: now);

  group('compra × presente × revogado', () {
    test('sem documento: vale o que a loja diz', () async {
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.demo);
      expect(
        access(const _Fixed(CourseAccess.owned)).access,
        CourseAccess.owned,
      );
      expect(
        access(const _Fixed(CourseAccess.subscriptionEnded)).access,
        CourseAccess.subscriptionEnded,
      );
    });

    for (final origin in ['presente', 'compra', 'pagoPorFora']) {
      test('$origin abre o curso', () async {
        service.docs['u1'] = doc(origin: origin);
        await grants.start();
        await settle();
        expect(access().access, CourseAccess.owned);
        expect(grants.current.courses[pilaresCourseId]!.origin.wire, origin);
      });
    }

    test('presente sobre assinatura vencida abre o curso', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      expect(
        access(const _Fixed(CourseAccess.subscriptionEnded)).access,
        CourseAccess.owned,
      );
    });

    test('revogado fecha na próxima sincronização', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      final repo = access();
      final seen = <CourseAccess>[];
      final sub = repo.changes.listen(seen.add);
      expect(repo.access, CourseAccess.owned);

      service.put('u1', doc(revoked: DateTime.utc(2026, 11, 6, 13)));
      await settle();
      expect(repo.access, CourseAccess.demo);
      expect(seen, [CourseAccess.demo]);
      await sub.cancel();
    });

    test('revogado não tira a compra feita na loja', () async {
      service.docs['u1'] = doc(revoked: DateTime.utc(2026, 11, 6));
      await grants.start();
      await settle();
      expect(
        access(const _Fixed(CourseAccess.owned)).access,
        CourseAccess.owned,
      );
    });

    test('mensal com prazo fecha quando vence', () async {
      service.docs['u1'] = doc(
        plan: 'mensal',
        until: DateTime.utc(2026, 12, 6),
      );
      await grants.start();
      await settle();
      final repo = access();
      expect(repo.access, CourseAccess.owned);
      now.value = DateTime.utc(2026, 12, 6);
      expect(repo.access, CourseAccess.demo);
    });

    test('curso dado de novo depois de revogado volta a abrir', () async {
      service.docs['u1'] = doc(revoked: DateTime.utc(2026, 11, 6));
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.demo);
      service.put('u1', doc(given: DateTime.utc(2026, 11, 6, 12)));
      await settle();
      expect(access().access, CourseAccess.owned);
    });

    test('origem desconhecida é ignorada', () async {
      service.docs['u1'] = doc(origin: 'outra');
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.demo);
    });
  });

  group('sem rede', () {
    test('vale a última cópia da conta', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      await grants.dispose();

      service.online = false;
      grants = CloudCourseGrantsRepository(
        service,
        preferences,
        uids: uids.stream,
        currentUid: () => uid,
        now: now,
      );
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.owned);
      expect(await grants.synced(timeout: Duration.zero), isFalse);
    });

    test('sem cópia e sem rede: o que a loja diz', () async {
      service.online = false;
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.demo);
    });

    test('a rede volta e o curso dado chega', () async {
      service.online = false;
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      final repo = access();
      final seen = <CourseAccess>[];
      final sub = repo.changes.listen(seen.add);
      service.reconnect('u1');
      await settle();
      expect(repo.access, CourseAccess.owned);
      expect(seen, [CourseAccess.owned]);
      expect(await grants.synced(timeout: Duration.zero), isTrue);
      await sub.cancel();
    });

    test('regra recusa ler: fica a cópia, sem erro', () async {
      service.deny = true;
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.demo);
    });
  });

  group('conta', () {
    test('sem conta: nada do servidor', () async {
      uid = null;
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      expect(grants.current, CourseGrants.empty);
      expect(access().access, CourseAccess.demo);
    });

    test('trocar de conta não leva o curso da outra', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.owned);

      uid = 'u2';
      uids.add('u2');
      await settle();
      await settle();
      expect(access().access, CourseAccess.demo);

      uid = null;
      uids.add(null);
      await settle();
      expect(access().access, CourseAccess.demo);
    });

    test('entrar na conta abre o curso dado a ela', () async {
      uid = null;
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      expect(access().access, CourseAccess.demo);
      uid = 'u1';
      uids.add('u1');
      await settle();
      await settle();
      expect(access().access, CourseAccess.owned);
    });
  });

  group('vistos', () {
    test('não visto até marcar; grava no servidor', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      expect(grants.current.unseen(pilaresCourseId, now()), isTrue);

      await grants.markSeen(pilaresCourseId);
      await settle();
      expect(grants.current.unseen(pilaresCourseId, now()), isFalse);
      expect(service.seenWrites.single.$2, pilaresCourseId);
    });

    test('dado de novo depois de visto: aparece outra vez', () async {
      service.docs['u1'] = doc(
        given: DateTime.utc(2026, 11, 6, 13),
        seen: DateTime.utc(2026, 11, 5),
      );
      await grants.start();
      await settle();
      expect(grants.current.unseen(pilaresCourseId, now()), isTrue);
    });

    test('sem curso no documento não grava (regra recusa criar)', () async {
      await grants.start();
      await settle();
      await grants.markSeen(pilaresCourseId);
      expect(service.seenWrites, isEmpty);
    });

    test('sem rede: marca local e a cópia guarda', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      service.online = false;
      await grants.markSeen(pilaresCourseId);
      await settle();
      expect(grants.current.unseen(pilaresCourseId, now()), isFalse);
      expect(
        await preferences.getString(CloudCourseGrantsRepository.cacheKey('u1')),
        contains('vistos'),
      );
    });

    test('o servidor sem o visto não desfaz o local', () async {
      service.docs['u1'] = doc();
      await grants.start();
      await settle();
      service.online = false;
      await grants.markSeen(pilaresCourseId);
      service.reconnect('u1');
      await settle();
      expect(grants.current.unseen(pilaresCourseId, now()), isFalse);
    });
  });

  test('NoPurchaseRepository segue com o curso aberto (V1)', () {
    final repo = ServerCourseAccessRepository(
      const FullCourseAccessRepository(),
      const NoCourseGrantsRepository(),
      now: now,
    );
    expect(repo.access, CourseAccess.owned);
    expect(const NoPurchaseRepository(), isA<PurchaseRepository>());
  });
}

final class _Fixed implements CourseAccessRepository {
  const _Fixed(this.access);

  @override
  final CourseAccess access;

  @override
  Stream<CourseAccess> get changes => const Stream.empty();
}
