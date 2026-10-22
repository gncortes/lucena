import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/domain/models/ads_state.dart';
import 'package:lucena/ui/core/ads/lesson_gate.dart';
import 'package:lucena/ui/core/keys/ads_keys.dart';

import '../../../../testing/test_app.dart';

/// Decide sempre o mesmo, para a tela conferir só o caminho.
class _AdsAnswering extends NoAdsRepository {
  const _AdsAnswering(this.outcome);

  final AdOutcome outcome;

  @override
  Future<AdOutcome> beforeLesson({
    required String lessonId,
    required LessonKind kind,
  }) async => outcome;
}

void main() {
  Future<List<String>> pumpGate(WidgetTester tester, AdOutcome outcome) async {
    final opened = <String>[];
    await tester.pumpWidget(
      TestApp(
        adsRepository: _AdsAnswering(outcome),
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => LessonGate.open(
                context,
                lessonId: 'opposition',
                kind: LessonKind.endgame,
                open: () => opened.add('opposition'),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('sem anúncio, a lição abre direto', (tester) async {
    final opened = await pumpGate(tester, AdOutcome.none);
    expect(find.byKey(AdsKeys.fakeInterstitial), findsNothing);
    expect(opened, ['opposition']);
  });

  testWidgets('o anúncio falso aparece e a lição abre ao fechar', (
    tester,
  ) async {
    final opened = await pumpGate(tester, AdOutcome.showInApp);
    expect(find.byKey(AdsKeys.fakeInterstitial), findsOneWidget);
    expect(opened, isEmpty);
    await tester.tap(find.byKey(AdsKeys.fakeClose));
    await tester.pumpAndSettle();
    expect(find.byKey(AdsKeys.fakeInterstitial), findsNothing);
    expect(opened, ['opposition']);
  });
}
