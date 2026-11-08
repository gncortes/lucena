import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';

/// A faixa de alunos deste emulador (`--dart-define=ALUNO_DE=NN` e
/// `ALUNO_ATE=NN`, padrão 1 a 30): cada emulador fica com uma faixa.
const _from = int.fromEnvironment('ALUNO_DE', defaultValue: 1);
const _to = int.fromEnvironment('ALUNO_ATE', defaultValue: 30);

// Roteiro do QA da R5, item 5 (lado app), no Emulator Suite: 30 alunos
// fazendo lições em ritmos diferentes. Cada aluno conclui de 0 a 4 lições
// (`(n - 1) % 5`) e a sincronização leva o progresso a
// `users/{uid}/progress/summary`, que o painel lê por pessoa. As métricas de
// Cursos, Funil e Retenção vêm do BigQuery (GA4), fora do emulador e com o
// Analytics desligado no E2E.
void main() {
  final lessons = VisibleLessons.endgameLessonIds.toList();
  for (var n = _from; n <= _to; n++) {
    final done = lessons.take((n - 1) % 5).toSet();
    patrolTest('R5 roteiro 5: aluno $n com ${done.length} lições', ($) async {
      final app = EmulatorRobot($);
      final admin = app.admin;
      final email = EmulatorAdmin.student(n);
      final student = await admin.signIn(email, EmulatorAdmin.studentPassword);

      await app.open(
        beforeApp: () => seedEndgameProgress(
          EndgameProgress(
            lessons: {
              for (final id in done)
                id: const EndgameLessonProgress(lessonDone: true),
            },
          ),
        ),
      );
      await app.openProfile();
      await app.signIn(email, EmulatorAdmin.studentPassword);

      await admin.waitFor('users/${student.uid}/progress/summary', (doc) {
        final synced = (doc?['lessons'] as Map?)?.keys.toSet() ?? {};
        return synced.containsAll(done);
      });
      await app.signOut();
    });
  }
}
