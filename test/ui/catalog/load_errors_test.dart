import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';
import 'package:lucena/ui/catalog/widgets/catalog_screen.dart';
import 'package:lucena/ui/catalog/widgets/category_screen.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';

import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_training_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/test_app.dart';

import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/domain/models/app_language.dart';

import '../../../testing/fakes/fake_settings_repository.dart';

class FailingPositions extends FakePositionsRepository {
  bool fail = true;
  Completer<void>? pending;
  @override
  Future<List<CatalogCategory>> catalog() async {
    await pending?.future;
    if (fail) throw StateError('catalog load');
    return super.catalog();
  }
}

void main() {
  for (final category in [null, 'basic']) {
    testWidgets('catalog $category retries after repository error', (
      tester,
    ) async {
      final positions = FailingPositions();
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      final cubit = CatalogCubit(
        positions,
        FakeTrainingRepository(),
        FakeProgressRepository(),
      );
      addTearDown(cubit.close);
      try {
        await cubit.load(category: category);
      } on Object {
        /* RED: unhandled load. */
      }
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: category == null
                ? const CatalogScreen()
                : CategoryScreen(category: category),
          ),
        ),
      );
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      positions.fail = false;
      final pending = Completer<void>();
      positions.pending = pending;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsNothing);
      expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(LoadErrorKeys.action)).onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(cubit.state.categories, isNotNull);
    });
  }
}
