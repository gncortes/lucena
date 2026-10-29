import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:patrol/patrol.dart';

import 'home_robot.dart';
import '../../testing/board_gestures.dart';

/// Native frames from the host handshake, after Flutter has settled.
/// The host must run tools/capture/t85_capture_server.py on loopback:8792.
class TrainingCaptureRobot {
  const TrainingCaptureRobot(this.$);
  final PatrolIntegrationTester $;

  Future<void> openGuide({bool escola = false}) async {
    await HomeRobot($).openSettings();
    await $(
      escola
          ? SettingsKeys.escolaTrainingTile
          : SettingsKeys.pilaresTrainingTile,
    ).scrollTo().tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> tab(String name) async {
    await $(CourseGuideKeys.tab(name)).tap();
    await $.pumpAndSettle();
  }

  Future<void> exercise(String theme) async {
    await tab('goals');
    await $(TrainingKeys.goalTile('exercise', theme)).scrollTo().tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> hint() async {
    await $(TrainingKeys.exerciseHint).tap();
    await $.pumpAndSettle();
  }

  Future<void> move(String uci) async {
    final finder = find.byKey(TrainingKeys.exerciseBoard);
    final board = $.tester.widget<Chessboard>(finder);
    Offset square(String name) => squareCenter(
      $.tester.getRect(finder),
      name,
      orientation: board.orientation,
    );
    await $.tester.tapAt(square(uci.substring(0, 2)));
    await $.pump();
    await $.tester.tapAt(square(uci.substring(2, 4)));
    await $(TrainingKeys.nextGoal).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> openingMove(String uci) async {
    final finder = find.byKey(TrainingKeys.openingBoard);
    final board = $.tester.widget<Chessboard>(finder);
    final rect = $.tester.getRect(finder);
    await $.tester.tapAt(
      squareCenter(rect, uci.substring(0, 2), orientation: board.orientation),
    );
    await $.pump();
    await $.tester.tapAt(
      squareCenter(rect, uci.substring(2, 4), orientation: board.orientation),
    );
    await $.pumpAndSettle();
  }

  Future<void> shot(String name, {Key ready = CourseGuideKeys.screen}) async {
    await settleRoute(ready);
    if (find.byKey(TrainingKeys.exerciseBoard).evaluate().isNotEmpty &&
        find.byKey(TrainingKeys.exerciseHint).evaluate().isNotEmpty) {
      expect(
        find.byType(TimeDisplay),
        findsOneWidget,
        reason: 'T85 active exercise keeps its timer visible',
      );
    }
    for (final key in [TrainingKeys.exerciseBoard, TrainingKeys.openingBoard]) {
      final board = find.byKey(key);
      if (board.evaluate().isNotEmpty) {
        final expected =
            $.tester.view.physicalSize.width / $.tester.view.devicePixelRatio;
        expect(
          $.tester.getSize(board).width,
          closeTo(expected, 0.1),
          reason: 'T85 full-width native board: $name',
        );
        final view = $.tester.view;
        final ratio = view.devicePixelRatio;
        final top = view.padding.top / ratio;
        final bottom =
            view.physicalSize.height / ratio - view.padding.bottom / ratio;
        final rect = $.tester.getRect(board);
        expect(
          (rect.center.dy - (top + bottom) / 2).abs(),
          lessThanOrEqualTo(1 / ratio),
          reason:
              'T85 board center including appbar/actions: $name; '
              'board=$rect, useful=[$top,$bottom]',
        );
      }
    }
    await _request('shot', name);
  }

  /// Await before performing the action whose transition is being captured.
  Future<void> begin(String name) async {
    await $.pumpAndSettle();
    await _request('begin', name);
  }

  Future<void> end(String name, {Key? ready}) async {
    if (ready != null) await settleRoute(ready);
    await _request('end', name);
  }

  Future<void> record(
    String name,
    Future<void> Function() action, {
    required Key ready,
  }) async {
    await begin(name);
    try {
      await action();
      await settleRoute(ready);
    } finally {
      await end(name);
    }
  }

  /// A lesson can animate continuously. Only the route/Hero must have landed.
  Future<void> settleRoute(Key ready) async {
    await $(ready).waitUntilVisible();
    final route = ModalRoute.of($.tester.element(find.byKey(ready).first));
    final watch = Stopwatch()..start();
    while (route?.animation?.isCompleted == false) {
      if (watch.elapsed > const Duration(seconds: 10)) {
        throw TestFailure('T85 route did not finish entering: $ready');
      }
      await $.pump();
    }
    await $.pump();
  }

  Future<void> _request(String action, String name) async {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$').hasMatch(name)) {
      throw ArgumentError.value(name, 'name');
    }
    // Retain both required device sizes when the same scenarios run twice.
    final view = $.tester.view;
    final size = view.physicalSize / view.devicePixelRatio;
    final artifact = '$name-${size.width.round()}x${size.height.round()}';
    if (artifact.length > 80) throw ArgumentError.value(name, 'name');
    await $.tester.runAsync(() async {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(
          Uri.parse('http://10.0.2.2:8792/$action/$artifact'),
        );
        final response = await request.close().timeout(
          const Duration(seconds: 60),
        );
        await response.drain<void>();
        if (response.statusCode != HttpStatus.ok) {
          throw StateError(
            'T85 capture $action/$name: HTTP ${response.statusCode}',
          );
        }
      } finally {
        client.close(force: true);
      }
    });
  }
}
