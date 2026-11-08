import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analysis/learning_analysis_repository.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/learning_analysis.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/learning_analysis_keys.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/learning_analysis/view_models/learning_analysis_cubit.dart';
import 'package:lucena/ui/learning_analysis/widgets/learning_analysis_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import 'analysis_test_support.dart';
import 'learning_analysis_screen_test.dart' show analysisRoot, analysisMoves;

const fixturePath = String.fromEnvironment('T85_ANALYSIS_FIXTURE');
const capturePath = String.fromEnvironment('T85_ANALYSIS_CAPTURE');

Map<String, dynamic> _component(Map<String, dynamic> data, String name) =>
    (data['imports'] as List)
        .cast<Map<String, dynamic>>()
        .where((p) => p['name'] == name)
        .firstOrNull ??
    {};

// Canvas lines are a controlled fake, never evidence of the native engine.
List<EngineLine> _lines(String encoded, Position position) => [
  for (final line in encoded.split('|').take(2)) _line(line, position),
];
EngineLine _line(String encoded, Position position) {
  final parts = encoded.split(';');
  final score = parts.first.replaceAll('−', '-').replaceAll(',', '.');
  final moves = <String>[];
  var current = position;
  for (var token in parts.last.split(' ')) {
    if (RegExp(r'^\d+\.').hasMatch(token)) continue;
    const letters = {'R': 'K', 'D': 'Q', 'T': 'R', 'B': 'B', 'C': 'N'};
    if (letters.containsKey(token[0])) {
      token = '${letters[token[0]]}${token.substring(1)}';
    }
    NormalMove? found;
    for (final entry in current.legalMoves.entries) {
      for (final to in entry.value.squares) {
        final move = NormalMove(from: entry.key, to: to);
        final played = GameRules.play(current, move);
        if (played?.san == token) found = move;
      }
    }
    if (found == null) break;
    moves.add(found.uci);
    current = GameRules.play(current, found)!.position;
  }
  return EngineLine(
    score: score.startsWith('#')
        ? EngineScore(mate: int.parse(score.substring(1)))
        : EngineScore(centipawns: (double.parse(score) * 100).round()),
    moves: moves,
  );
}

void main() {
  final fixture = io.File(fixturePath);
  if (fixturePath.isEmpty || !fixture.existsSync()) {
    test(
      'private Canvas capture fixtures optional on public CI',
      () {},
      skip: true,
    );
    return;
  }
  setUp(initializeAnalysisPreferences);
  setUpAll(Goldens.loadFonts);
  final data = (jsonDecode(fixture.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  for (final snapshot in data) {
    final id = snapshot['id'] as String;
    testWidgets('Canvas analysis $id', (tester) async {
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(412, 917)
          ..padding = const FakeViewPadding(top: 52, bottom: 32)
          ..viewPadding = const FakeViewPadding(top: 52, bottom: 32);
        addTearDown(tester.view.reset);
        final engine = ControlledAnalysisEngine();
        final cubit = LearningAnalysisCubit(
          launch: const LearningAnalysisLaunch(
            fen: analysisRoot,
            moves: analysisMoves,
            orientation: Side.black,
          ),
          repository: LearningAnalysisRepository(AnalysisMemoryPreferences()),
          engine: engine,
        );
        await cubit.load();
        addTearDown(cubit.close);
        if (id.endsWith('Inicio')) cubit.first();
        if (id.endsWith('Voltou')) cubit.select(1);
        if (id.endsWith('Meio')) cubit.select(2);
        if (id.endsWith('Variante')) {
          cubit.first();
          expect(cubit.play('g3g2'), isTrue);
        }
        if (id.endsWith('SemMotor')) {
          await cubit.confirmSettings(
            const LearningAnalysisSettings(showEngine: false),
          );
        }
        final fen = _component(snapshot, 'CompTabuleiro')['fen'] as String;
        expect(cubit.state.session.current.fen, GameRules.fromFen(fen)!.fen);
        final encoded = _component(snapshot, 'CompMotor')['linhas'] as String?;
        if (encoded != null) {
          engine.requests.last.result.complete(
            _lines(encoded, GameRules.fromFen(fen)!),
          );
        }
        final boundary = GlobalKey();
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: TestApp(
              locale: const Locale('pt'),
              settingsCubit: settings,
              child: BlocProvider.value(
                value: cubit,
                child: const LearningAnalysisScreen(engineName: 'Stockfish 17'),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => ChessgroundImages.instance.loadAll(
            PieceStyle.cburnett.assets,
            devicePixelRatio: 1,
          ),
        );
        await tester.pumpAndSettle();
        if (id.endsWith('Ajustes')) {
          await tester.tap(find.byKey(LearningAnalysisKeys.settings));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        if (capturePath.isNotEmpty) {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = io.File('$capturePath/$id.png');
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
