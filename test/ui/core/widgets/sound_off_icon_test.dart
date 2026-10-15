import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/sound_off_icon.dart';

void main() {
  testWidgets('segue o tamanho do IconTheme e aceita um tamanho próprio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoundOffIcon(key: Key('tema')),
              SoundOffIcon(key: Key('proprio'), size: 22),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('tema'))), const Size(30, 30));
    expect(
      tester.getSize(find.byKey(const Key('proprio'))),
      const Size(22, 22),
    );
  });
}
