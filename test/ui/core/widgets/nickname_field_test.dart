import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/widgets/nickname_field.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('campo do apelido: rótulo no alto, dica, limite e callback', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? last;
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: NicknameField(
            controller: controller,
            label: 'Apelido',
            hint: 'Jogador',
            onChanged: (v) => last = v,
            autocorrect: false,
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byKey(CoreKeys.nicknameField));
    expect(
      field.decoration!.floatingLabelBehavior,
      FloatingLabelBehavior.always,
    );
    expect(field.autocorrect, isFalse);
    expect(find.text('Jogador'), findsOneWidget);
    expect(tester.getSize(find.byKey(CoreKeys.nicknameField)).height, 56);
    await tester.enterText(
      find.byKey(CoreKeys.nicknameField),
      'x' * (UserProfile.maxNicknameLength + 5),
    );
    expect(controller.text.length, UserProfile.maxNicknameLength);
    expect(last, controller.text);
  });

  testWidgets('a tela passa a key dela', (tester) async {
    const key = Key('minha');
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: NicknameField(
            controller: TextEditingController(),
            label: 'Apelido',
            hint: 'Jogador',
            fieldKey: key,
          ),
        ),
      ),
    );
    expect(find.byKey(key), findsOneWidget);
  });
}
