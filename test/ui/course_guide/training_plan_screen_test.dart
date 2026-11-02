import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/widgets/sheet_close_button.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_plan_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  late TrainingScenarioBuilder scenario;
  late FakeTrainingRepository repository;
  late FakePushRepository push;
  late TrainingPlanCubit cubit;
  var saved = 0;
  setUp(() {
    scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    push = FakePushRepository(allowed: true);
    saved = 0;
  });
  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });
  Future<void> show(
    WidgetTester tester, {
    Size size = const Size(412, 917),
  }) async {
    setPhoneSize(tester, size);
    repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: scenario.content},
    );
    cubit = TrainingPlanCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: scenario.now,
      push: push,
    );
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: TrainingPlanScreen(onBack: () {}, onSaved: () => saved++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      150,
      scrollable: find
          .descendant(
            of: find.byKey(TrainingKeys.planScroll),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets(
      'plan scrolls without overflow at $size; days have 40/48 geometry',
      (tester) async {
        await show(tester, size: size);
        for (final minutes in [15, 30, 60, 120, 240]) {
          expect(find.byKey(TrainingKeys.planChip(minutes)), findsOneWidget);
        }
        await tester.tap(find.byKey(TrainingKeys.planChip(240)));
        await tester.pumpAndSettle();
        expect(
          find.text('Quer mais? Ao cumprir a meta, o app oferece dobrar.'),
          findsOneWidget,
        );
        await reveal(tester, TrainingKeys.weekday(0));
        for (var day = 0; day < 7; day++) {
          final target = find.byKey(TrainingKeys.weekday(day));
          expect(tester.getSize(target), const Size(48, 48));
          final circle = find.descendant(
            of: target,
            matching: find.byType(Container),
          );
          expect(tester.getSize(circle.first), const Size(40, 40));
        }
        // Hit the outer edge, outside the 40 dp circle.
        final sunday = tester.getRect(find.byKey(TrainingKeys.weekday(0)));
        await tester.tapAt(sunday.topLeft + const Offset(1, 24));
        await tester.pump();
        expect(cubit.state.draft.weekdays & 1, 1);
        await reveal(tester, TrainingKeys.planSave);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(TrainingKeys.planSave));
        await tester.pumpAndSettle();
        expect(
          saved,
          1,
          reason:
              'saving=${cubit.state.saving} failed=${cubit.state.failed} writes=${repository.writes} ready=${cubit.state.ready}',
        );
        expect(
          (await repository.load(TrainingCourse.pilares)).plan.minutes,
          240,
        );
      },
    );
  }

  for (final size in phoneSizes) {
    testWidgets(
      'permission surface and external close preserve draft at $size',
      (tester) async {
        push.allowed = false;
        await show(tester, size: size);
        cubit.disableReminder();
        await tester.pump();
        final before = cubit.state.draft.toJson();
        await reveal(tester, TrainingKeys.reminderSwitch);
        await tester.tap(find.byKey(TrainingKeys.reminderSwitch));
        await tester.pumpAndSettle();
        final surface = find.byKey(TrainingKeys.permissionDialog);
        expect(tester.getSize(surface).width, size.width - 48);
        expect(
          tester.getRect(surface).center.dy,
          closeTo(size.height / 2, .01),
        );
        expect(tester.widget<Material>(surface).color, Colors.white);
        final allow = find.byKey(TrainingKeys.permissionAllow);
        expect(tester.widget(allow), isA<FilledButton>());
        expect(tester.getSize(allow).height, 48);
        final close = find.byKey(SheetKeys.close);
        expect(tester.getSize(close), const Size(48, 48));
        expect(
          tester.getRect(close).bottom,
          lessThan(tester.getRect(surface).top),
        );
        expect(tester.widget<SheetCloseButton>(close), isNotNull);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(cubit.state.draft.toJson(), before);
        expect(repository.writes, 0);
        expect(push.permissionRequests, 0);
        expect(saved, 0);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('32 dp time chips retain separate 48 dp targets at $size', (
      tester,
    ) async {
      await show(tester, size: size);
      final rects = <Rect>[];
      for (final minutes in [15, 30, 60, 120, 240]) {
        final target = find.byKey(TrainingKeys.planChip(minutes));
        expect(tester.getSize(target).height, 48);
        final chip = find.descendant(
          of: target,
          matching: find.byType(ChoiceChip),
        );
        expect(tester.getSize(chip).height, 32);
        final rect = tester.getRect(target);
        for (final previous in rects) {
          expect(rect.overlaps(previous), isFalse);
        }
        rects.add(rect);
      }
      final last = tester.getRect(find.byKey(TrainingKeys.planChip(240)));
      await tester.tapAt(last.topLeft + const Offset(4, 1));
      await tester.pumpAndSettle();
      expect(cubit.state.draft.minutes, 240);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in phoneSizes) {
    testWidgets(
      'time picker uses 24-hour format and cancels without changes at $size',
      (tester) async {
        await show(tester, size: size);
        await reveal(tester, TrainingKeys.reminderTime);
        expect(find.text('19:00'), findsOneWidget);
        await tester.tap(find.byKey(TrainingKeys.reminderTime));
        await tester.pumpAndSettle();
        final dialog = find.byType(TimePickerDialog);
        expect(dialog, findsOneWidget);
        expect(
          MediaQuery.of(tester.element(dialog)).alwaysUse24HourFormat,
          isTrue,
        );
        expect(find.text('Horário do lembrete'), findsOneWidget);
        final before = cubit.state.draft.toJson();
        final close = find.byKey(SheetKeys.close);
        expect(close, findsOneWidget);
        expect(tester.getSize(close), const Size(48, 48));
        final material = find
            .descendant(of: dialog, matching: find.byType(Material))
            .first;
        expect(
          tester.getRect(close).bottom,
          lessThan(tester.getRect(material).top),
        );
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(cubit.state.draft.toJson(), before);
        expect(repository.writes, 0);
        expect(cubit.state.draft.reminderHour, 19);
        expect(cubit.state.draft.reminderMinute, 0);
      },
    );
  }

  for (final closeWithX in [true, false]) {
    testWidgets(
      'dismiss permission during save leaves the plan unchanged: X=$closeWithX',
      (tester) async {
        push.allowed = false;
        await show(tester);
        final before = cubit.state.draft.toJson();
        await reveal(tester, TrainingKeys.planSave);
        await tester.tap(find.byKey(TrainingKeys.planSave));
        await tester.pumpAndSettle();
        if (closeWithX) {
          await tester.tap(find.byKey(SheetKeys.close));
        } else {
          await tester.tapAt(const Offset(4, 4));
        }
        await tester.pumpAndSettle();
        expect(cubit.state.draft.toJson(), before);
        expect(repository.writes, 0);
        expect(push.permissionRequests, 0);
        expect(saved, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final allow in [false, true]) {
    testWidgets(
      'own permission dialog ${allow ? 'allows' : 'cancels'} before system prompt',
      (tester) async {
        push.allowed = false;
        push.granted = true;
        await show(tester);
        cubit.disableReminder();
        await tester.pump();
        await reveal(tester, TrainingKeys.reminderSwitch);
        await tester.tap(find.byKey(TrainingKeys.reminderSwitch));
        await tester.pumpAndSettle();
        expect(find.byKey(TrainingKeys.permissionDialog), findsOneWidget);
        expect(push.permissionRequests, 0);
        await tester.tap(
          find.byKey(
            allow ? TrainingKeys.permissionAllow : TrainingKeys.permissionLater,
          ),
        );
        await tester.pumpAndSettle();
        expect(push.permissionRequests, allow ? 1 : 0);
        expect(cubit.state.draft.reminderOn, allow);
      },
    );
  }

  testWidgets('default enabled reminder requests own consent on first save', (
    tester,
  ) async {
    push.allowed = false;
    await show(tester);
    await reveal(tester, TrainingKeys.planSave);
    await tester.tap(find.byKey(TrainingKeys.planSave));
    await tester.pumpAndSettle();
    expect(find.byKey(TrainingKeys.permissionDialog), findsOneWidget);
    expect(repository.writes, 0);
    await tester.tap(find.byKey(TrainingKeys.permissionLater));
    await tester.pumpAndSettle();
    expect(saved, 1);
    expect(
      (await repository.load(TrainingCourse.pilares)).plan.reminderOn,
      isFalse,
    );
    expect(push.permissionRequests, 0);
  });

  testWidgets(
    'first save denial stays on plan before continuing without reminder',
    (tester) async {
      push.allowed = false;
      await show(tester);
      await reveal(tester, TrainingKeys.planSave);
      await tester.tap(find.byKey(TrainingKeys.planSave));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TrainingKeys.permissionAllow));
      await tester.pumpAndSettle();
      expect(saved, 0);
      expect(repository.writes, 0);
      await reveal(tester, TrainingKeys.openNotificationSettings);
      expect(find.text('Abrir configurações'), findsOneWidget);
      await reveal(tester, TrainingKeys.planSave);
      await tester.tap(find.byKey(TrainingKeys.planSave));
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect(
        (await repository.load(TrainingCourse.pilares)).plan.reminderOn,
        isFalse,
      );
    },
  );

  testWidgets(
    'denial shows settings card and opens the repository settings action',
    (tester) async {
      push.allowed = false;
      await show(tester);
      cubit.disableReminder();
      await tester.pump();
      await reveal(tester, TrainingKeys.reminderSwitch);
      await tester.tap(find.byKey(TrainingKeys.reminderSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TrainingKeys.permissionAllow));
      await tester.pumpAndSettle();
      await reveal(tester, TrainingKeys.openNotificationSettings);
      expect(find.text('Abrir configurações'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(TrainingKeys.openNotificationSettings))
            .height,
        52,
      );
      await tester.tap(find.byKey(TrainingKeys.openNotificationSettings));
      await tester.pumpAndSettle();
      expect(push.settingsOpened, 1);
      expect(cubit.state.denied, isTrue);
    },
  );

  testWidgets(
    'save disables button until durable completion; error retries the same draft',
    (tester) async {
      await show(tester);
      await tester.tap(find.byKey(TrainingKeys.planChip(15)));
      await reveal(tester, TrainingKeys.planSave);
      repository.writeError = StateError('disk unavailable');
      await tester.tap(find.byKey(TrainingKeys.planSave));
      await tester.pumpAndSettle();
      expect(saved, 0);
      expect(find.byKey(TrainingKeys.planError), findsOneWidget);
      expect(cubit.state.draft.minutes, 15);
      repository.writeError = null;
      final gate = Completer<void>();
      repository.beforeSave = gate.future;
      await reveal(tester, TrainingKeys.planSave);
      await tester.tap(find.byKey(TrainingKeys.planSave));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(TrainingKeys.planSave))
            .onPressed,
        isNull,
      );
      expect(saved, 0);
      gate.complete();
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect((await repository.load(TrainingCourse.pilares)).plan.minutes, 15);
    },
  );
}
