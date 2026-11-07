import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/feedback_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';

/// O aluno do cenário (`--dart-define=ALUNO=NN`, padrão 4).
const _student = int.fromEnvironment('ALUNO', defaultValue: 4);

// Roteiro do QA da R5, item 6 (lado app), no Emulator Suite: a opinião
// mandada pelo app grava `feedback/{id}` com o aluno, que é o que
// /usuarios/opinioes lista. O app não manda a lição de onde veio: o filtro
// por lição do painel fica sem dado do app.
void main() {
  patrolTest('R5 roteiro 6: opinião do app chega ao painel', ($) async {
    final app = EmulatorRobot($);
    final admin = app.admin;
    final email = EmulatorAdmin.student(_student);
    final student = await admin.signIn(email, EmulatorAdmin.studentPassword);
    // Marca única: acha a opinião desta rodada entre as anteriores.
    final text = 'Ideia de teste ${Random().nextInt(1 << 30)}';

    await app.open();
    await app.openProfile();
    await app.signIn(email, EmulatorAdmin.studentPassword);
    await app.go(Routes.feedback);
    await $(FeedbackKeys.screen).waitUntilVisible();
    await $(FeedbackKeys.kindChip(FeedbackType.idea)).tap();
    await $(FeedbackKeys.text).enterText(text);
    await $(FeedbackKeys.send).tap();
    await $(FeedbackKeys.thanks)
        .waitUntilVisible(timeout: const Duration(seconds: 30));

    final sent = await admin.where('feedback', 'uid', student.uid);
    final entry = sent.where((doc) => doc['text'] == text).toList();
    expect(entry, hasLength(1));
    expect(entry.single['type'], FeedbackType.idea.code);
    expect(entry.single['createdAt'], isA<DateTime>());
  });
}
