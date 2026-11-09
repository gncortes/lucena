import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/coach/view_models/coach_analysis_cubit.dart';

import '../../../testing/fakes/fake_coach_repository.dart';

void main() {
  test('partida que existe: pronta e marca a análise como vista', () async {
    final repo = FakeCoachRepository.withData();
    final id = (await repo.games().first).first.id;
    final cubit = CoachAnalysisCubit(repository: repo, id: id);

    await cubit.load();

    expect(cubit.state.status, CoachAnalysisStatus.ready);
    expect(cubit.state.game?.id, id);
    expect((await repo.progress(id)).sawAnalysis, isTrue);
    await cubit.close();
  });

  test('partida que não existe: não encontrada', () async {
    final cubit = CoachAnalysisCubit(
      repository: FakeCoachRepository.withData(),
      id: 'lichess_naoExiste',
    );

    await cubit.load();

    expect(cubit.state.status, CoachAnalysisStatus.notFound);
    expect(cubit.state.game, isNull);
    await cubit.close();
  });
}
