import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/push_alert.dart';

void main() {
  const data = {
    'titulo': 'Final da semana',
    'texto': 'Brancas jogam e ganham',
    'tipo': 'destaque',
    'link': '/featured/tournament/7/game/3',
    'pushId': 'p1',
    'pais': 'BR',
  };

  group('PushAlert.fromData', () {
    test('lê os campos do painel', () {
      final alert = PushAlert.fromData(data)!;

      expect(alert.title, 'Final da semana');
      expect(alert.body, 'Brancas jogam e ganham');
      expect(alert.kind, PushKind.featured);
    });

    test('sem título nem texto não vira notificação', () {
      expect(PushAlert.fromData({'link': '/daily'}), isNull);
    });

    test('usa a parte notification quando os dados não têm texto', () {
      final alert = PushAlert.fromData(
        {'link': '/daily', 'tipo': 'dia'},
        title: 'Final do dia',
        body: 'Novo',
      )!;

      expect(alert.title, 'Final do dia');
    });

    test('tipo desconhecido é livre', () {
      expect(
        PushAlert.fromData({'titulo': 'a', 'tipo': '?'})!.kind,
        PushKind.free,
      );
    });
  });

  test('o id é estável e fica longe dos lembretes', () {
    final a = PushAlert.fromData(data)!;
    final b = PushAlert.fromData({...data, 'titulo': 'outro'})!;

    expect(a.notificationId, b.notificationId);
    expect(
      a.notificationId,
      greaterThanOrEqualTo(PushAlert.firstNotificationId),
    );
  });

  group('payload', () {
    final payload = PushAlert.fromData(data)!.payload;

    test('é de push; rota de lembrete não é', () {
      expect(PushOpening.isPush(payload), isTrue);
      expect(PushOpening.isPush('/daily'), isFalse);
      expect(PushOpening.fromPayload('/daily'), isNull);
    });

    test('o toque abre o link', () {
      expect(
        PushOpening.fromPayload(payload),
        PushOpening(
          link: Uri.parse('/featured/tournament/7/game/3'),
          pushId: 'p1',
          country: 'BR',
        ),
      );
    });
  });

  test('canais por tipo', () {
    const texts = PushTexts(
      tournaments: 'T',
      daily: 'D',
      lessons: 'A',
      news: 'N',
    );
    expect(texts.channel(PushKind.featured).id, 'push_torneios_quieto');
    expect(texts.channel(PushKind.daily).id, 'push_dia_quieto');
    expect(texts.channel(PushKind.lesson).id, 'push_aulas_quieto');
    expect(texts.channel(PushKind.free).id, 'push_novidades_quieto');
  });
}
