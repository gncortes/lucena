// Simulação do teste de nível (T52, Parte 4.5).
//
// Uso (na raiz do repositório):
//   dart run tools/placement/simulate.dart                 (mapa e banco SINTÉTICOS)
//   dart run tools/placement/simulate.dart --skills assets/placement/skills.json \
//       --items assets/placement/items.json                (mapa e banco reais)
//   ... --count 2000 --seed 7                              (mais jogadores, outra semente)
//   ... --grid                                             (grade de a e b)
//   ... --a 1.5 --b 0.3                                    (outro a e b)
//
// Sai um relatório em Markdown no terminal (o que vai para
// `docs/spikes/T52-simulacao.md`).
import 'dart:convert';
import 'dart:io' as io;

import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/use_cases/placement_engine.dart';

import 'simulation.dart';
import 'synthetic.dart';

void main(List<String> args) {
  String? option(String name) {
    final index = args.indexOf('--$name');
    return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
  }

  final skillsPath = option('skills');
  final itemsPath = option('items');
  final synthetic = skillsPath == null || itemsPath == null;
  final skills = SkillMap.fromJson(
    synthetic
        ? syntheticSkillsJson()
        : jsonDecode(io.File(skillsPath).readAsStringSync())
              as Map<String, dynamic>,
  );
  final bank = PlacementBank.fromJson(
    synthetic
        ? syntheticItemsJson()
        : jsonDecode(io.File(itemsPath).readAsStringSync())
              as Map<String, dynamic>,
  );
  final count = int.tryParse(option('count') ?? '') ?? 1000;
  final seed = int.tryParse(option('seed') ?? '') ?? 2026;
  final base = PlacementTuning.standard;
  final tuning = PlacementTuning(
    a: double.tryParse(option('a') ?? '') ?? base.a,
    b: double.tryParse(option('b') ?? '') ?? base.b,
  );

  final out = io.stdout;
  out.writeln(
    synthetic
        ? '> Mapa e banco **sintéticos** (`tools/placement/synthetic.dart`).'
        : '> Mapa `$skillsPath`, banco `$itemsPath`.',
  );
  out.writeln(
    '> ${skills.nodes.length} nós, ${bank.items.length} perguntas, '
    '$count jogadores por tipo, semente $seed.',
  );
  out.writeln();

  if (args.contains('--grid')) {
    out.writeln(
      '| a | b | faixa exata | certa ou vizinha | desatento vizinha | '
      'RMSE | lacuna no roteiro | falso "já domina" | 1ª resposta | '
      'confirmação |',
    );
    out.writeln('|---|---|---|---|---|---|---|---|---|---|');
    for (final a in [1.0, 1.25, 1.5, 1.75, 2.0]) {
      for (final b in [0.1, 0.2, 0.3, 0.4, 0.6]) {
        final report = simulate(
          skills: skills,
          bank: bank,
          schoolLessons: schoolLessons,
          endgameLessons: endgameLessons,
          tuning: PlacementTuning(a: a, b: b),
          count: count,
          seed: seed,
        );
        out.writeln(
          '| $a | $b | ${_pct(report.rasch.exactRate)} | '
          '${_pct(report.rasch.neighborRate)} | '
          '${_pct(report.careless.neighborRate)} | '
          '${report.rasch.rmse.round()} | ${_pct(report.gapRate)} | '
          '${_pct(report.falseSkipRate)} | '
          '${report.meanFirstJump.round()} | '
          '${report.meanConfirmationMove.round()} |',
        );
      }
    }
    return;
  }

  final report = simulate(
    skills: skills,
    bank: bank,
    schoolLessons: schoolLessons,
    endgameLessons: endgameLessons,
    tuning: tuning,
    count: count,
    seed: seed,
  );
  out.writeln(
    'Parâmetros: a = ${tuning.a}, b = ${tuning.b}, '
    'randomesque k = ${tuning.randomesque}, corte do intervalo = '
    '${tuning.intervalCut}.',
  );
  out.writeln();
  out.writeln('| Métrica | Meta | Resultado |');
  out.writeln('|---|---|---|');
  out.writeln(
    '| Faixa certa ou vizinha (Rasch) | ≥ 90% | '
    '${_pct(report.rasch.neighborRate)} |',
  );
  out.writeln(
    '| Faixa exatamente certa (Rasch) | ≥ 60% | '
    '${_pct(report.rasch.exactRate)} |',
  );
  out.writeln(
    '| Faixa certa ou vizinha (desatento) | ≥ 90% | '
    '${_pct(report.careless.neighborRate)} |',
  );
  out.writeln(
    '| Faixa exatamente certa (desatento) | — | '
    '${_pct(report.careless.exactRate)} |',
  );
  out.writeln(
    '| Lacuna forçada no roteiro | ≥ 90% | ${_pct(report.gapRate)} |',
  );
  for (final kind in gapScenarios.keys) {
    final total = report.gapTotals[kind] ?? 0;
    final nodes = report.gapNodes[kind] ?? 0;
    final deep = report.deepTotals[kind] ?? 0;
    out.writeln(
      '| · ${kind.name}: no roteiro / por nó / lacuna confirmada / '
      'faixa ≤ θ − 2 no roteiro | — | '
      '${_rate(report.gapHits[kind], total)} / '
      '${_rate(report.gapNodeHits[kind], nodes)} / '
      '${_rate(report.gapConfirmed[kind], nodes)} / '
      '${_rate(report.deepHits[kind], deep)} (n = $deep) |',
    );
  }
  out.writeln(
    '| Falso "já domina" (pela faixa do nó) | ≤ 5% | '
    '${_pct(report.falseSkipRate)} |',
  );
  for (final kind in report.skippedByKind.keys) {
    final total = report.skippedByKind[kind]!;
    out.writeln(
      '| · ${kind.name}: falso "já domina" | — | '
      '${_pct((report.falseByKind[kind] ?? 0) / total)} |',
    );
  }
  out.writeln(
    '| · dos falsos, confirmados por acerto direto | — | '
    '${_pct(report.falseSkipped == 0 ? 0 : report.falseConfirmed / report.falseSkipped)} |',
  );
  out.writeln(
    '| Falso "já domina" (pela mediana das perguntas do nó) | — | '
    '${_pct(report.falseSkipStrictRate)} |',
  );
  out.writeln(
    '| Acerta tudo / erra tudo | ≥ expert / beginner | '
    '${report.allRight?.name} / ${report.allWrong?.name} |',
  );
  out.writeln(
    '| Perguntas diferentes ao refazer | ≥ 40% | ${_pct(report.exposure)} |',
  );
  out.writeln(
    '| θ andou na 1ª resposta (média) | 200 a 400 | '
    '${report.meanFirstJump.round()} |',
  );
  out.writeln(
    '| θ andou por resposta na confirmação (média) | < 50 | '
    '${report.meanConfirmationMove.round()} |',
  );
  out.writeln(
    '| RMSE / viés (Rasch) | — | ${report.rasch.rmse.round()} / '
    '${report.rasch.meanBias.round()} |',
  );
  out.writeln(
    '| Intervalo: largura média / contém o θ verdadeiro | — | '
    '${report.rasch.meanWidth.round()} / ${_pct(report.rasch.coverage)} |',
  );
  out.writeln();
  out.writeln('Todas as metas: ${report.passes ? 'sim' : 'NÃO'}');
  out.writeln();
  out.writeln('θ verdadeiro × θ estimado (Rasch puro):');
  out.writeln();
  out.writeln('```');
  out.write(asciiPlot(report.points));
  out.writeln('```');
  if (!report.passes) io.exitCode = 1;
}

String _pct(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _rate(int? hits, int total) =>
    total == 0 ? '—' : _pct((hits ?? 0) / total);
