import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/locked_chapter_redirect.dart';

void main() {
  const offer = D2Paths.pilaresOffer;

  test('capítulo 2 por rota ou link na demo vai para a oferta', () {
    for (final path in [
      '/training/pilares/chapter/pilares.c2',
      '/endgames/pilares.c3.parte/roteiro?part=1',
      '/training/pilares/chapter/pilares.c12',
    ]) {
      expect(
        lockedChapterRedirect(Uri.parse(path), CourseAccess.demo),
        offer,
        reason: path,
      );
    }
  });

  test('assinatura vencida conta como demo', () {
    expect(
      lockedChapterRedirect(
        Uri.parse('/training/pilares/chapter/pilares.c2'),
        CourseAccess.subscriptionEnded,
      ),
      offer,
    );
  });

  test('capítulo 1 e comprador abrem', () {
    expect(
      lockedChapterRedirect(
        Uri.parse('/training/pilares/chapter/pilares.c1'),
        CourseAccess.demo,
      ),
      isNull,
    );
    expect(
      lockedChapterRedirect(
        Uri.parse('/training/pilares/chapter/pilares.c2'),
        CourseAccess.owned,
      ),
      isNull,
    );
    expect(
      lockedChapterRedirect(Uri.parse('/home'), CourseAccess.demo),
      isNull,
    );
  });

  test('não redireciona a própria oferta', () {
    expect(lockedChapterRedirect(Uri.parse(offer), CourseAccess.demo), isNull);
  });
}
