import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/domain/use_cases/install_referrer_rules.dart';
import 'package:lucena/domain/use_cases/link_lesson_rules.dart';

const _fen = '8/8/8/4k3/8/8/4K3/4Q3 w - - 0 1';

void main() {
  final plain = ChallengeLink(fen: _fen, userSide: Side.white);
  final withLesson = plain.copyWith(
    lesson: const LinkedLesson.endgame('rook.lucena'),
  );

  group('oferta do fim', () {
    test('sem aula ligada ou com a partida aberta: nenhuma', () {
      expect(
        LinkLessonRules.offer(plain, fulfilled: false),
        LinkLessonOffer.none,
      );
      expect(
        LinkLessonRules.offer(null, fulfilled: true),
        LinkLessonOffer.none,
      );
      expect(
        LinkLessonRules.offer(withLesson, fulfilled: null),
        LinkLessonOffer.none,
      );
    });

    test('não conseguiu: principal; conseguiu: secundária', () {
      expect(
        LinkLessonRules.offer(withLesson, fulfilled: false),
        LinkLessonOffer.primary,
      );
      expect(
        LinkLessonRules.offer(withLesson, fulfilled: true),
        LinkLessonOffer.secondary,
      );
      expect(LinkLessonOffer.primary.code, 'principal');
      expect(LinkLessonOffer.secondary.code, 'secundaria');
    });
  });

  group('passo depois do toque', () {
    test('aula indisponível não pede conta', () {
      for (final hasAccount in [true, false]) {
        expect(
          LinkLessonRules.next(available: false, hasAccount: hasAccount),
          LinkLessonStep.unavailable,
        );
      }
    });

    test('sem conta: convite; com conta: a aula', () {
      expect(
        LinkLessonRules.next(available: true, hasAccount: false),
        LinkLessonStep.invite,
      );
      expect(
        LinkLessonRules.next(available: true, hasAccount: true),
        LinkLessonStep.lesson,
      );
    });
  });

  group('referrer da Play', () {
    final challenge =
        '/p/x?fen=${Uri.encodeQueryComponent(_fen)}&aula=rook.lucena'
        '&utm_source=instagram';

    test('caminho, endereço inteiro e link= codificado', () {
      expect(InstallReferrerRules.link(challenge)?.path, '/p/x');
      expect(
        InstallReferrerRules.link(
          'https://playlucena.com/aula/rook.lucena?utm_source=instagram',
        )?.path,
        '/aula/rook.lucena',
      );
      final nested = InstallReferrerRules.link(
        'utm_source=google-play&link='
        '${Uri.encodeQueryComponent('https://playlucena.com$challenge')}',
      );
      expect(ChallengeLink.tryParse(nested!)!.lesson?.id, 'rook.lucena');
    });

    test('instalação orgânica, outro domínio e desafio inválido: nulo', () {
      for (final referrer in [
        null,
        '',
        'utm_source=google-play&utm_medium=organic',
        'https://example.com/aula/x',
        '/p/x?fen=invalida',
        '/inexistente',
        'link=link%3Dx',
      ]) {
        expect(InstallReferrerRules.link(referrer), isNull, reason: referrer);
      }
    });
  });
}
