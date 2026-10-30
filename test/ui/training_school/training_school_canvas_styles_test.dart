import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_part_header.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../course_guide/course_guide_catalog_layout_test.dart' as guide;

void main() {
  testWidgets(
    'School module progress uses Canvas typography and neutral track',
    (tester) async {
      setPhoneSize(tester, const Size(412, 917));
      final cubit = await guide.pumpGuide(
        tester,
        config: TrainingCourseConfig.escola,
      );
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: const [],
      );
      addTearDown(settings.close);
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: Scaffold(body: TrainingProgressTab(onTheme: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.byKey(TrainingKeys.moduleRow('omega'));
      final theme = Theme.of(tester.element(row));
      for (final label in ['Capítulo omega', '3 de 3']) {
        final text = tester.widget<Text>(
          find.descendant(of: row, matching: find.text(label)),
        );
        expect(text.style?.fontSize, 14);
        expect(text.style?.height, closeTo(20 / 14, .005));
        expect(text.style?.fontWeight, FontWeight.w500);
        expect(
          text.style?.color,
          label == '3 de 3'
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
        );
      }
      final bar = find.descendant(
        of: row,
        matching: find.byType(LinearProgressIndicator),
      );
      final indicator = tester.widget<LinearProgressIndicator>(bar);
      expect(indicator.backgroundColor, theme.colorScheme.outlineVariant);
      expect(
        indicator.color ??
            Theme.of(tester.element(bar)).progressIndicatorTheme.color ??
            Theme.of(tester.element(bar)).colorScheme.primary,
        theme.colorScheme.primary,
      );
      expect(indicator.value, 1);
      expect(tester.getSize(bar).height, 6);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'School expanded catalog has one uppercase section without count',
    (tester) async {
      setPhoneSize(tester, const Size(412, 917));
      await guide.pumpGuide(tester, config: TrainingCourseConfig.escola);
      final section = find.text('MÓDULO 1 · CAPÍTULO OMEGA');
      expect(section, findsOneWidget);
      expect(find.text('Módulo 1 · Capítulo omega'), findsNothing);
      expect(find.byType(CoursePartHeader), findsNothing);
      expect(find.text('3 de 3'), findsNothing);
      final text = tester.widget<Text>(section);
      expect(text.style?.fontSize, 12);
      expect(text.style?.height, 20 / 12);
      expect(text.style?.fontWeight, FontWeight.w500);
      expect(
        text.style?.color,
        Theme.of(tester.element(section)).colorScheme.onSurfaceVariant,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Pilares shows chapter heading and direct lesson rows', (
    tester,
  ) async {
    setPhoneSize(tester, const Size(412, 917));
    await guide.pumpGuide(tester);
    final header = tester.widget<CoursePartHeader>(
      find.byType(CoursePartHeader).first,
    );
    expect(header.label, 'Capítulo 1');
    expect(header.title, 'Capítulo omega');
    expect(header.count, isNull);
    expect(find.text('MÓDULO 1 · CAPÍTULO OMEGA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
