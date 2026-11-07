import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/home_shortcut.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/home/widgets/mode_tile.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('o atalho é um cartão #FAFBF9 com contorno 1px #E1E5DF, raio 16 '
      '(H-INI-06)', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        locale: Locale('pt'),
        child: Scaffold(body: ModeTile(shortcut: HomeShortcut.school)),
      ),
    );
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(find.byKey(HomeKeys.schoolButton));
    expect(material.color, AppColors.cardSurface);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.side.color, AppColors.cardOutline);
    expect(shape.side.width, 1);
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(tester.getSize(find.byKey(HomeKeys.schoolButton)).height, 144);
  });
}
