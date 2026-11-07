import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:patrol/patrol.dart';

import 'script_lesson_robot.dart';

/// Joga uma lição do Pilares inteira como o aluno que sabe a resposta. Lê o
/// índice e os roteiros do servidor de conteúdo local
/// (`lucena-utils/conteudo/dev.py serve`, porta 8791), o mesmo do
/// `--dart-define=CONTENT_URL`.
class PilaresLessonRobot {
  PilaresLessonRobot(this.$);

  final PatrolIntegrationTester $;

  Future<dynamic> fetchJson(String path) => $.tester.runAsync(() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('http://10.0.2.2:8791/assets/$path'),
      );
      final response = await request.close();
      return jsonDecode(await response.transform(utf8.decoder).join());
    } finally {
      client.close();
    }
  });

  String placement(String fen) => fen.split(' ').first;

  /// Joga a lição inteira como um aluno que sabe a resposta: Continuar,
  /// "Ver a resposta" nas perguntas e os lances do roteiro nas práticas.
  Future<void> playLesson(
    String lessonId, {
    Future<void> Function()? onPractice,
  }) async {
    var practiceMarked = false;
    final parts = lessonId.split('.');
    final index = await fetchJson(
      'courses/${parts[0]}/index.json',
    ) as Map<String, dynamic>;
    final names = <String>{};
    for (final part in index['partes'] as List<dynamic>) {
      for (final chapter
          in (part as Map<String, dynamic>)['capitulos'] as List<dynamic>) {
        for (final aula
            in (chapter as Map<String, dynamic>)['aulas'] as List<dynamic>) {
          final id = (aula as Map<String, dynamic>)['id'] as String;
          if (id.startsWith('${parts[0]}.${parts[1]}.')) names.add(id);
        }
      }
    }
    final practices = <Map<String, dynamic>>[];
    for (final id in names) {
      final p = id.split('.');
      final script = await fetchJson(
        'lessons/roteiros/${p[0]}.${p[1]}/${p[2]}.json',
      );
      if (script is! Map<String, dynamic>) continue;
      for (final stage in script['etapas'] as List<dynamic>) {
        for (final ex
            in (stage as Map<String, dynamic>)['exemplos'] as List<dynamic>? ??
                const []) {
          if ((ex as Map<String, dynamic>)['pratica'] != null) {
            practices.add(ex);
          }
        }
      }
    }
    final lesson = ScriptLessonRobot($);
    List<dynamic> line = const [];
    var step = 0;
    var stuck = 0;
    for (var i = 0; i < 600; i++) {
      if (find.byKey(LessonFinishedKeys.screen).evaluate().isNotEmpty) return;
      if (find.byKey(LessonScriptKeys.screen).evaluate().isEmpty) {
        await $.pump(const Duration(milliseconds: 100));
        continue;
      }
      final state = lesson.state;
      if (!practiceMarked && onPractice != null && state.stageId == 'pratica') {
        practiceMarked = true;
        await onPractice();
      }
      if (state.phase == ScriptPhase.praticaVez && !state.machineThinking) {
        for (final ex in practices) {
          if (placement(ex['fen'] as String) == placement(state.fen)) {
            final practice = ex['pratica'] as Map<String, dynamic>;
            line = practice['linha'] as List<dynamic>? ?? const [];
            step = 0;
            if (practice['tipo'] == 'toque') {
              for (final target
                  in practice['alvos'] as List<dynamic>? ?? const []) {
                await lesson.tapSquare(target as String);
              }
            }
          }
        }
        if (step < line.length) {
          final uci =
              ((line[step] as Map<String, dynamic>)['certos'] as List<dynamic>)
                      .first
                  as String;
          step++;
          await lesson.settle(8);
          await lesson.move(uci.substring(0, 2), uci.substring(2, 4));
          await lesson.settle(10);
          continue;
        }
        if (++stuck > 40) {
          fail(
            'prática sem saída $lessonId stage=${state.stageId} '
            'fen=${state.fen} step=$step/${line.length} '
            'practices=${practices.map((e) => placement(e['fen'] as String)).toList()}',
          );
        }
      }
      if (find.byKey(LessonScriptKeys.primary).evaluate().isNotEmpty) {
        await $.tester.tap(find.byKey(LessonScriptKeys.primary));
        await lesson.settle(6);
      } else if (find.byKey(LessonScriptKeys.nextPart).evaluate().isNotEmpty) {
        await $.tester.tap(find.byKey(LessonScriptKeys.nextPart));
        await lesson.settle(6);
      } else if (find
          .byKey(LessonScriptKeys.showAnswer)
          .evaluate()
          .isNotEmpty) {
        await lesson.settle(10);
        await $.tester.tap(find.byKey(LessonScriptKeys.showAnswer));
        await lesson.settle(6);
      } else {
        await lesson.settle(5);
      }
    }
    fail('a lição $lessonId não terminou');
  }
}
