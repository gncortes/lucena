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
  testWidgetsA8('A8: tabuleiro no centro útil e de ponta a ponta', (
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
    debugPrint('A8 find_move fora do centro: ${foraDoCentro(tester)}');
    expectTabuleiroNoCentro(tester);
    // O cartão de cima cabe inteiro acima do tabuleiro, sem rolar.
    final board = maiorTabuleiro(tester);
    final header = tester.getRect(find.byType(Card).first);
    expect(header.bottom, lessThanOrEqualTo(board.top));
    expect(header.top, greaterThanOrEqualTo(80));
  }, pendente360x740: true);
}
