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
/// The host must run tools/capture/t85_capture_server.py on loopback
/// (`E2E_CAPTURE_URL`, padrão 8792).
class TrainingCaptureRobot {
  TrainingCaptureRobot(this.$);
  final PatrolIntegrationTester $;
  final _recordings = <String>{};

  /// Tira o nome do teste que o binding desenha no topo da tela (a faixa
  /// vermelha sobre a app bar): prints e MP4 mostram só o app.
  static Future<void> semFaixaDoTeste(PatrolIntegrationTester $) async {
    final binding = $.tester.binding;
    if (binding is! LiveTestWidgetsFlutterBinding) return;
    // ignore: invalid_use_of_protected_member
    binding.setLabel('');
    for (final view in binding.renderViews) {
      view.markNeedsPaint();
    }
    await $.pump();
  }

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
    final finder = await _interactiveBoard(TrainingKeys.exerciseBoard);
    final board = $.tester.widget<Chessboard>(finder);
    Offset square(String name) => squareCenter(
      $.tester.getRect(finder),
      name,
      orientation: board.orientation,
    );
    await $.tester.tapAt(square(uci.substring(0, 2)));
    await $.pump();
    await $.tester.tapAt(square(uci.substring(2, 4)));
    final result = find.byWidgetPredicate(
      (widget) =>
          widget.key == TrainingKeys.nextGoal ||
          widget.key == TrainingKeys.exercisePracticeRetry,
    );
    await $(result).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> openingMove(String uci) async {
    final finder = await _interactiveBoard(TrainingKeys.openingBoard);
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

  Future<Finder> _interactiveBoard(Key key) async {
    // O preview pode aparecer durante o Hero e antes do carregamento real.
    // tapAt ignora os guards do Patrol; só mede as casas após a chegada e
    // quando o próprio tabuleiro aceita interação.
    await settleRoute(key);
    final finder = find.byKey(key);
    final watch = Stopwatch()..start();
    while (!$.tester.widget<Chessboard>(finder).controller.interactive ||
        finder.hitTestable().evaluate().isEmpty) {
      if (watch.elapsed > const Duration(seconds: 10)) {
        throw TestFailure('T85 board did not become interactive: $key');
      }
      await $.pump(const Duration(milliseconds: 50));
    }
    return finder;
  }

  Future<void> shot(String name, {Key ready = CourseGuideKeys.screen}) async {
    await settleRoute(ready);
    if (find.byKey(TrainingKeys.exerciseBoard).evaluate().isNotEmpty &&
        find.byKey(TrainingKeys.exerciseHint).evaluate().isNotEmpty) {
      expect(
        find.byType(TimeDisplay),
        findsNothing,
        reason: 'T85 Canvas exercise has no timer',
      );
    }
    for (final key in [TrainingKeys.exerciseBoard, TrainingKeys.openingBoard]) {
      final board = find.byKey(key);
      if (board.evaluate().isNotEmpty) {
        final pageKey = key == TrainingKeys.exerciseBoard
            ? TrainingKeys.exercisePage
            : TrainingKeys.openingPage;
        final page = $.tester.getRect(find.byKey(pageKey));
        // Canvas PropV1TreinoExercicioLance2 / medidas_lance: centraliza
        // balão + faixa + tabuleiro + notação, não o tabuleiro isolado.
        var side = page.width;
        var above = 87.0 + 58;
        var spare = 0.0;
        var fits = false;
        for (final option in [(4, 40.0), (3, 40.0), (2, 40.0), (2, 0.0)]) {
          final header = 42 + 22.5 * option.$1 + 58;
          final remaining = page.height - header - side - option.$2;
          if (remaining >= 0) {
            above = header;
            spare = remaining;
            fits = true;
            break;
          }
        }
        if (!fits) side = (page.height - above).clamp(0, double.infinity);
        final rect = $.tester.getRect(board);
        expect(
          rect.width,
          closeTo(side, 0.5),
          reason: 'T85 Canvas native board width: $name',
        );
        expect(
          rect.top,
          closeTo(page.top + spare / 2 + above, 0.5),
          reason: 'T85 Canvas teaching block: $name; board=$rect, page=$page',
        );
      }
    }
    await semFaixaDoTeste($);
    await _request('shot', name);
  }

  /// Await before performing the action whose transition is being captured.
  Future<void> begin(String name) async {
    await $.pumpAndSettle();
    await semFaixaDoTeste($);
    await _request('begin', name);
    _recordings.add(name);
    addTearDown(() async {
      if (_recordings.contains(name)) await end(name);
    });
  }

  Future<void> end(String name, {Key? ready}) async {
    if (ready != null) await settleRoute(ready);
    await _request('end', name);
    _recordings.remove(name);
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
    Object? failure;
    StackTrace? failureStack;
    await $.tester.runAsync(() async {
      const endpoint = String.fromEnvironment(
        'E2E_CAPTURE_URL',
        defaultValue: 'http://10.0.2.2:8792',
      );
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(
          Uri.parse('$endpoint/$action/$artifact'),
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
      } catch (error, stack) {
        // runAsync registra exceções no binding e retorna null. Repassar
        // fora dele interrompe a ação e permite executar o finally.
        failure = error;
        failureStack = stack;
      } finally {
        client.close(force: true);
      }
    });
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, failureStack!);
  }
}
