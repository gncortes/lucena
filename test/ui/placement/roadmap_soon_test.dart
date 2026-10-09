import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/use_cases/placement_roadmap.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:lucena/ui/placement/view_models/placement_cubit.dart';
import 'package:lucena/ui/placement/widgets/placement_result_view.dart';

import '../../../testing/test_app.dart';

/// O roteiro do resultado: aula que ainda não existe aparece com o nome
/// traduzido do final e "em breve", nunca com o id cru.
void main() {
  testWidgets('final "em breve": nome traduzido e selo, sem o id cru', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    final state = PlacementViewState(
      view: PlacementView.result,
      result: PlacementResult(
        theta: 1200,
        low: 1050,
        high: 1350,
        takenAt: DateTime.utc(2026, 10, 9),
        nodes: const {},
      ),
      roadmap: const PlacementRoadmap(
        nodes: ['minor.bishopVsPawns'],
        steps: [
          RoadmapStep(
            node: 'minor.bishopVsPawns',
            lessonId: 'minor.bishopVsPawns',
            school: false,
            soon: true,
          ),
        ],
        skippedSchool: {},
        nextSchool: null,
        endgameBadges: {},
      ),
    );

    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(body: PlacementResultView(state: state)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(PlacementKeys.step(0)),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('minor.bishopVsPawns'), findsNothing);
    // O nome do final aparece uma vez só (sem subtítulo repetido), com o
    // selo.
    expect(find.text('Bispo contra peões'), findsOneWidget);
    expect(find.text('em breve'), findsOneWidget);
  });
}
