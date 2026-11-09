import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/treinador/view_models/coach_analysis_cubit.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';

void main() {
  test('partida que existe: pronta e marca a análise como vista', () async {
    final repo = FakeTreinadorRepository.comDados();
    final id = (await repo.partidas().first).first.id;
    final cubit = CoachAnalysisCubit(repository: repo, id: id);

    await cubit.load();

    expect(cubit.state.status, CoachAnalysisStatus.ready);
    expect(cubit.state.game?.id, id);
    expect((await repo.progresso(id)).viuAnalise, isTrue);
    await cubit.close();
  });

  test('partida que não existe: não encontrada', () async {
    final cubit = CoachAnalysisCubit(
      repository: FakeTreinadorRepository.comDados(),
      id: 'lichess_naoExiste',
    );

    await cubit.load();

    expect(cubit.state.status, CoachAnalysisStatus.notFound);
    expect(cubit.state.game, isNull);
    await cubit.close();
  });
}
