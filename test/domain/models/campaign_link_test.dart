import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/routing/routes.dart';

const _fen = '8/8/8/4k3/8/8/4K3/4Q3 w - - 0 1';

Uri _uri(String path) => Uri.parse('https://playlucena.com$path');

void main() {
  group('link de desafio (T84)', () {
    test('o link antigo, sem aula, segue igual e fora do funil', () {
      final link = ChallengeLink.tryParse(
        _uri('/p/x?fen=${Uri.encodeQueryComponent(_fen)}&goal=win'),
      )!;
      expect(link.lesson, isNull);
      expect(link.isCampaign, isFalse);
      expect(link.uri.queryParameters.containsKey('aula'), isFalse);
    });

    test('`aula` e `utm_*` entram no link e não mudam o código', () {
      final old = ChallengeLink.tryParse(
        _uri('/p/x?fen=${Uri.encodeQueryComponent(_fen)}&goal=win'),
      )!;
      final link = ChallengeLink.tryParse(
        _uri(
          '/p/x?fen=${Uri.encodeQueryComponent(_fen)}&goal=win'
          '&aula=rook.lucena&utm_source=instagram&utm_campaign=torre-engana',
        ),
      )!;
      expect(link.lesson, const LinkedLesson.endgame('rook.lucena'));
      expect(link.utm['utm_campaign'], 'torre-engana');
      expect(link.isCampaign, isTrue);
      expect(link.code, old.code);
      // Ida e volta: o endereço gerado traz a aula.
      expect(ChallengeLink.tryParse(link.uri)!.lesson, link.lesson);
    });

    test(
      '`escola` liga uma aula da Escola; `aula` vence quando vêm os dois',
      () {
        final base = '/p/x?fen=${Uri.encodeQueryComponent(_fen)}';
        expect(
          ChallengeLink.tryParse(_uri('$base&escola=pawn.intro'))!.lesson,
          const LinkedLesson.school('pawn.intro'),
        );
        expect(
          ChallengeLink.tryParse(_uri('$base&escola=a&aula=b'))!.lesson,
          const LinkedLesson.endgame('b'),
        );
        expect(ChallengeLink.tryParse(_uri('$base&aula=%20'))!.lesson, isNull);
      },
    );

    test('o link repassado pelo app só entra no funil pela aula', () {
      final link = ChallengeLink(fen: _fen, userSide: Side.white);
      expect(link.sharedFrom('fim_partida', generation: 1).isCampaign, isFalse);
      expect(
        link
            .copyWith(lesson: const LinkedLesson.endgame('rook.lucena'))
            .sharedFrom('fim_partida', generation: 1)
            .isCampaign,
        isTrue,
      );
    });
  });

  group('link só de aula', () {
    test('lê /aula/<id> e /escola/<id> com os utm', () {
      final link = LessonLink.tryParse(
        _uri('/aula/rook.lucena?utm_source=instagram&utm_campaign=lucena'),
      )!;
      expect(link.lesson, const LinkedLesson.endgame('rook.lucena'));
      expect(link.utm, {'utm_source': 'instagram', 'utm_campaign': 'lucena'});
      expect(
        LessonLink.tryParse(_uri('/escola/pawn.intro'))!.lesson,
        const LinkedLesson.school('pawn.intro'),
      );
    });

    test('recusa outro caminho e outro domínio', () {
      expect(LessonLink.tryParse(_uri('/aula')), isNull);
      expect(LessonLink.tryParse(_uri('/aula/a/b')), isNull);
      expect(LessonLink.tryParse(_uri('/p/x')), isNull);
      expect(
        LessonLink.tryParse(Uri.parse('https://example.com/aula/x')),
        isNull,
      );
    });

    test('o app abre o link só de aula na própria rota', () {
      expect(
        Routes.appLink(_uri('/aula/rook.lucena?utm_source=instagram')),
        '/aula/rook.lucena?utm_source=instagram',
      );
    });
  });

  group('rotas da aula ligada', () {
    test('a entrada e o destino conforme a aula está liberada', () {
      const endgame = LinkedLesson.endgame('rook.lucena');
      const school = LinkedLesson.school('pawn.intro');
      expect(Routes.linkedLessonEntry(endgame), '/aula/rook.lucena');
      expect(Routes.linkedLessonEntry(school), '/escola/pawn.intro');
      expect(
        Routes.linkedLesson(endgame),
        Routes.endgameLesson('rook.lucena', origin: 'link'),
      );
      expect(Routes.linkedLesson(endgame, available: false), Routes.endgames);
      expect(Routes.linkedLesson(school, available: false), Routes.school);
    });

    test('o fim da conta aberta pelo convite vai para a aula', () {
      expect(Routes.afterAccount('/aula/rook.lucena'), '/aula/rook.lucena');
      expect(Routes.afterAccount('game'), Routes.home);
      expect(Routes.afterAccount('//example.com'), Routes.goal);
    });
  });

  group('campanha', () {
    test('ida e volta em JSON', () {
      const campaign = Campaign(
        utm: {'utm_source': 'instagram'},
        code: 'k7Qe2',
        lesson: LinkedLesson.school('pawn.intro'),
      );
      expect(Campaign.fromJson(campaign.toJson()), campaign);
      expect(campaign.kind, 'desafio');
      expect(const Campaign().kind, 'aula');
      expect(Campaign.fromJson('x'), isNull);
    });
  });
}
