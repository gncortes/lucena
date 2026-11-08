import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/featured/view_models/find_move_cubit.dart';
import 'package:lucena/ui/featured/widgets/find_move_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_center.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('A8: tabuleiro no centro útil e de ponta a ponta', (
    tester,
  ) async {
    setCentroAparelho(tester);
    final endgame = sampleFeaturedCatalog().endgame('b')!;
    final cubit = FindMoveCubit(
      endgame: endgame,
      progress: FakeFeaturedProgressRepository(),
    );
    addTearDown(cubit.close);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: FindMoveScreen(endgame: endgame),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final board = maiorTabuleiro(tester);
    // De ponta a ponta sempre.
    expect(board.left, closeTo(0, 1));
    expect(board.width, closeTo(centroAparelho.width, 1));
    // No centro útil; só sai dele quando o cartão de cima não cabe no espaço
    // acima do centro, e aí fica colado no cartão (12 dp), sem vão a mais.
    final header = tester.getRect(find.byType(Card).first);
    if ((board.center.dy - centroUtilY).abs() > 1) {
      expect(board.center.dy, greaterThan(centroUtilY));
      expect(board.top - header.bottom, closeTo(12, 1));
    }
  });
}
