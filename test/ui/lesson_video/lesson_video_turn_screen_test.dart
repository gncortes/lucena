import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/video_turn.dart';
import 'package:lucena/ui/core/keys/lesson_video_keys.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';
import 'package:lucena/ui/lesson_video/widgets/lesson_video_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

/// O roteiro de teste com as perguntas julgadas pelo vídeo (`juiz` = `lista`,
/// sem `livre`), como em `lesson_video_turn_cubit_test.dart`. Pergunta 1:
/// certo d3e4, erro d3d4, fora d3c2.
Map<String, dynamic> _listaJson() {
  final json = scriptJson();
  void walk(Object? node) {
    if (node is Map) {
      final q = node['pergunta'];
      if (q is Map) {
        q
          ..['juiz'] = 'lista'
          ..remove('livre');
      }
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(json);
  return json;
}

void main() {
  late FakeNow now;

  late FakeLessonVideoRepository videos;
  late FakeVideoInterruptionsRepository interruptions;

  setUp(() {
    now = FakeNow(DateTime(2026, 11, 23, 10));
    videos = FakeLessonVideoRepository();
    interruptions = FakeVideoInterruptionsRepository();
  });

  Future<LessonVideoCubit> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final cubit = LessonVideoCubit(
      videos: videos,
      interruptions: interruptions,
      scripts: FakeLessonScriptRepository(
        LessonScript.fromJson(_listaJson()),
        scriptTexts(),
      ),
      now: now,
      lessonId: 'pawns.test',
      partId: 'distant',
      scriptPath: 'roteiro.json',
      autoplay: false,
      ticker: (_, _) => null,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const LessonVideoScreen(title: 'Oposição distante'),
        ),
      ),
    );
    await cubit.start();
    await tester.pump(const Duration(milliseconds: 300));
    return cubit;
  }

  Future<void> toGate(WidgetTester tester, LessonVideoCubit cubit) async {
    cubit.seek(cubit.state.gates.first);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> move(WidgetTester tester, String uci) async {
    final board = tester.getRect(find.byKey(LessonVideoKeys.board));
    await tester.tapAt(squareCenter(board, uci.substring(0, 2)));
    await tester.pump();
    await tester.tapAt(squareCenter(board, uci.substring(2, 4)));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Avança o relógio até o ramo acabar.
  Future<void> finishBranch(WidgetTester tester, LessonVideoCubit cubit) async {
    for (var i = 0; i < 200 && (cubit.state.turn?.inBranch ?? false); i++) {
      now.advance(const Duration(seconds: 1));
      cubit.tick();
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  bool enabled(WidgetTester tester, Key key) =>
      tester.widget<IconButton>(find.byKey(key)).onPressed != null;

  testWidgets('Vídeo 1: fora da sua vez o toque não move peça', (tester) async {
    final cubit = await pump(tester);
    expect(cubit.state.waiting, isFalse);
    expect(find.byKey(LessonVideoKeys.yourMove), findsNothing);
    final before = cubit.state.position;
    await move(tester, 'd3e4');
    expect(cubit.state.position, before);
    expect(cubit.state.frame?.fen, exampleOneFen);
    expect(cubit.state.turn?.last, isNull);
  });

  testWidgets('Vídeo 25: sua vez com contorno, play e ±10 esmaecidos', (
    tester,
  ) async {
    final cubit = await pump(tester);
    await toGate(tester, cubit);
    expect(cubit.state.waiting, isTrue);
    expect(find.byKey(LessonVideoKeys.yourMove), findsOneWidget);
    for (final key in [
      LessonVideoKeys.playPause,
      LessonVideoKeys.back10,
      LessonVideoKeys.forward10,
    ]) {
      expect(enabled(tester, key), isFalse, reason: '$key');
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.38);
    }
    expect(find.byKey(LessonVideoKeys.reveal), findsNothing);
  });

  testWidgets('Vídeo 26: erro → ✗ na casa, a peça volta e espera de novo', (
    tester,
  ) async {
    final cubit = await pump(tester);
    await toGate(tester, cubit);
    await move(tester, 'd3d4');
    expect(cubit.state.turn?.inBranch, isTrue);
    expect(find.byKey(LessonVideoKeys.wrongMark), findsOneWidget);
    expect(find.byKey(LessonVideoKeys.yourMove), findsNothing);
    // Na fala do lance o play pausa/retoma a fala; só o ±10 fica desligado.
    expect(enabled(tester, LessonVideoKeys.playPause), isTrue);
    expect(enabled(tester, LessonVideoKeys.back10), isFalse);
    expect(enabled(tester, LessonVideoKeys.forward10), isFalse);

    // Tocando a dica o tabuleiro não aceita lance.
    await move(tester, 'd4e5');
    expect(cubit.state.turn?.inBranch, isTrue);

    await finishBranch(tester, cubit);
    expect(cubit.state.waiting, isTrue);
    expect(cubit.state.turn?.last, TurnResult.wrong);
    expect(cubit.state.frame?.fen, exampleOneFen, reason: 'a peça volta');
    expect(find.byKey(LessonVideoKeys.yourMove), findsOneWidget);
    final board = tester.getRect(find.byKey(LessonVideoKeys.board));
    final mark = tester.getRect(find.byKey(LessonVideoKeys.wrongMark));
    final d4 = squareCenter(board, 'd4');
    final q = board.width / 8;
    expect(mark.width, 22);
    expect(mark.right, closeTo(d4.dx + q / 2 + 5, 0.5));
    expect(mark.top, closeTo(d4.dy - q / 2 - 5, 0.5));
    expect(find.byKey(LessonVideoKeys.reveal), findsNothing);
  });

  testWidgets('Vídeo 27: "Ver a resposta" a partir do 2º erro', (tester) async {
    final cubit = await pump(tester);
    await toGate(tester, cubit);
    await move(tester, 'd3d4');
    await finishBranch(tester, cubit);
    expect(find.byKey(LessonVideoKeys.reveal), findsNothing);
    await move(tester, 'd3c2');
    await finishBranch(tester, cubit);
    expect(cubit.state.turn?.canReveal, isTrue);
    expect(find.byKey(LessonVideoKeys.reveal), findsOneWidget);
    expect(find.text('Ver a resposta'), findsOneWidget);

    // Desenho de 32 na linha do tempo, à direita: não encosta no tempo, no
    // CC nem no play (o alvo de 48 pode passar por cima do play, que está
    // desabilitado na sua vez).
    final hit = tester.getRect(find.byKey(LessonVideoKeys.reveal));
    final pill = Rect.fromCenter(
      center: hit.center,
      width: hit.width,
      height: 32,
    );
    expect(pill.height, 32);
    expect(
      pill.overlaps(tester.getRect(find.byKey(LessonVideoKeys.time))),
      isFalse,
    );
    expect(
      hit.overlaps(tester.getRect(find.byKey(LessonVideoKeys.captions))),
      isFalse,
    );
    expect(
      pill.bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(LessonVideoKeys.playPause)).top,
      ),
    );
    expect(pill.right, closeTo(412 - 16, 0.5));

    await tester.tap(find.byKey(LessonVideoKeys.reveal));
    await tester.pump();
    expect(cubit.state.turn?.last, TurnResult.revealed);
    expect(find.byKey(LessonVideoKeys.reveal), findsNothing);
  });

  testWidgets('Vídeo 28: acerto → ✓ e o vídeo segue sozinho', (tester) async {
    final cubit = await pump(tester);
    await toGate(tester, cubit);
    await move(tester, 'd3e4');
    expect(find.byKey(LessonVideoKeys.rightMark), findsOneWidget);
    expect(cubit.state.playing, isTrue);
    expect(find.byKey(LessonVideoKeys.yourMove), findsNothing);
  });
}
