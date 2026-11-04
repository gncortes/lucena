import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/pilares_access.dart';

void main() {
  final day = DateTime(2026, 11, 2);

  group('H-VEN-16: um estado de acesso para o app todo', () {
    test('demo: só o Capítulo 1, com anúncio', () {
      const access = PilaresAccess();
      expect(access.owns, isFalse);
      expect(access.chapterUnlocked(1), isTrue);
      expect(access.chapterUnlocked(2), isFalse);
      expect(access.chapterUnlocked(20), isFalse);
      expect(access.lessonNeedsAd, isTrue);
    });

    for (final kind in [
      PilaresAccessKind.lifetime,
      PilaresAccessKind.monthlyActive,
      PilaresAccessKind.monthlyGrace,
    ]) {
      test('${kind.name}: os 20 capítulos e nenhum anúncio', () {
        final access = PilaresAccess(kind: kind);
        expect(access.owns, isTrue);
        expect(
          [for (var n = 1; n <= 20; n++) access.chapterUnlocked(n)],
          [for (var n = 1; n <= 20; n++) true],
        );
        expect(access.lessonNeedsAd, isFalse);
      });
    }

    test('assinatura encerrada: volta à demo e avisa uma vez', () {
      final access = PilaresAccess(
        kind: PilaresAccessKind.monthlyActive,
        since: day,
        renewsAt: DateTime(2026, 12, 2),
      ).ended();
      expect(access.kind, PilaresAccessKind.monthlyEnded);
      expect(access.owns, isFalse);
      expect(access.chapterUnlocked(2), isFalse);
      expect(access.showEnded, isTrue);
      expect(access.copyWith(endedSeen: true).showEnded, isFalse);
      // Encerrar de novo não reabre o aviso.
      expect(access.copyWith(endedSeen: true).ended().showEnded, isFalse);
    });

    test('sem internet, a cópia mantém a assinatura até a renovação', () {
      final access = PilaresAccess(
        kind: PilaresAccessKind.monthlyActive,
        since: day,
        renewsAt: DateTime(2026, 12, 2),
      );
      expect(access.offline(DateTime(2026, 12, 1)).owns, isTrue);
      expect(access.offline(DateTime(2026, 12, 4)).owns, isTrue);
      expect(
        access.offline(DateTime(2026, 12, 6)).kind,
        PilaresAccessKind.monthlyEnded,
      );
      const lifetime = PilaresAccess(kind: PilaresAccessKind.lifetime);
      expect(lifetime.offline(DateTime(2040)).owns, isTrue);
    });

    test('a carência vale até o prazo de regularizar', () {
      final access = PilaresAccess(
        kind: PilaresAccessKind.monthlyGrace,
        renewsAt: DateTime(2026, 12, 2),
        graceUntil: DateTime(2026, 12, 9),
      );
      expect(access.offline(DateTime(2026, 12, 10)).owns, isTrue);
      expect(access.offline(DateTime(2026, 12, 13)).owns, isFalse);
    });

    test('a cópia guardada volta igual; a ilegível vira demo', () {
      final access = PilaresAccess(
        kind: PilaresAccessKind.monthlyGrace,
        since: day,
        renewsAt: DateTime(2026, 12, 2),
        graceUntil: DateTime(2026, 12, 9),
        source: PilaresSource.site,
        endedSeen: true,
      );
      expect(PilaresAccess.fromJson(access.toJson()), access);
      expect(
        PilaresAccess.fromJson(const {'kind': 'removeAds'}),
        const PilaresAccess(),
      );
    });
  });
}
