import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video.dart';
import 'package:lucena/domain/use_cases/lesson_video_converter.dart';
import 'package:lucena/domain/use_cases/video_timeline.dart';

// Roteiro e falas neutros (o conteúdo real das aulas não entra nos testes).
const _start = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
const _afterE4 = '4k3/8/8/8/4P3/8/8/4K3 b - - 0 1';
const _afterE3 = '4k3/8/8/8/8/4P3/8/4K3 b - - 0 1';
const _afterKd1 = '4k3/8/8/8/8/8/4P3/3K4 b - - 1 1';

Map<String, dynamic> _step(
  String t,
  String fen, [
  Map<String, dynamic>? more,
]) => {'t': t, 'fen': fen, ...?more};

final _script = LessonScript.fromJson({
  'licao': 'teste.licao',
  'parte': 'cap',
  'etapas': [
    {
      'id': 'ideia',
      'exemplos': [
        {
          'id': 'ex1',
          'fen': _start,
          'entrada': [
            _step('rot.e1', _start, {
              'marcas': ['e4', 'e2'],
              'setas': [
                ['e2', 'e4', 'g'],
              ],
            }),
            _step('rot.e2', _start, {
              'marcas': ['e4'],
            }),
          ],
          'pergunta': {
            't': 'rot.p',
            'juiz': 'lista',
            'pecas': ['e2'],
            'certos': ['e2e4'],
            'certo': _step('rot.certo', _afterE4, {'lance': 'e2e4'}),
            'revela': _step('rot.revela', _afterE4, {'lance': 'e2e4'}),
            'alternativos': {
              'e1d1': [
                _step('rot.alt', _afterKd1, {'lance': 'e1d1'}),
              ],
            },
            'erros': {
              'e2e3': [
                _step('rot.err', _afterE3, {'lance': 'e2e3'}),
              ],
            },
            'fora': 'rot.fora',
            'volta': 'rot.volta',
          },
          'linha': [_step('rot.l1', _afterE4)],
        },
      ],
    },
    {
      'id': 'demos',
      'exemplos': [
        {
          'id': 'ex1',
          'fen': _start,
          'vira': true,
          'entrada': [
            _step('rot.d1', _afterE4, {'lance': 'e2e4'}),
          ],
          'pergunta': {
            't': 'rot.dp',
            'certos': ['e8d7'],
            'certo': _step('rot.dcerto', _afterE4),
            'revela': _step('rot.drevela', _afterE4),
          },
        },
      ],
    },
    {
      'id': 'pratica',
      'exemplos': [
        {
          'id': 'ex1',
          'fen': _start,
          'pratica': {'tipo': 'linha', 't': 'rot.pr', 'linha': []},
        },
      ],
    },
  ],
});

const _texts = ScriptTexts({
  'rot.e1': 'Olhe a casa e4 agora, e a e2.',
  'rot.e2': 'De novo: e4.',
  'rot.p': 'Qual é o lance?',
  'rot.certo': 'Isso: o peão anda duas.',
  'rot.revela': 'O lance é e4.',
  'rot.alt': 'Também serve.',
  'rot.err': 'Só uma casa: devagar.',
  'rot.fora': 'Mova o peão.',
  'rot.volta': 'Tente de novo.',
  'rot.l1': 'Como {{Kasparov|garry-kasparov}} faria.',
  'rot.d1': 'Agora o peão anda.',
  'rot.dp': 'E as pretas?',
  'rot.dcerto': 'Certo.',
  'rot.drevela': 'Rei em d7.',
});

LessonVideo _convert({Map<String, VoiceClip> clips = const {}}) =>
    LessonVideoConverter.convert(_script, _texts, language: 'pt', clips: clips);

void main() {
  test('Teoria e Demonstração viram falas na ordem; a prática fica fora', () {
    final video = _convert();
    expect(video.lessonId, 'teste.licao');
    expect(video.partId, 'cap');
    expect(video.lines.map((l) => l.id), [
      'ideia.ex1.e.1',
      'ideia.ex1.e.2',
      'ideia.ex1.p',
      'ideia.ex1.certo.1',
      'ideia.ex1.l.1',
      'demos.ex1.e.1',
      'demos.ex1.p',
      'demos.ex1.certo.1',
    ]);
    expect(video.chapters.map((c) => (c.id, c.stage, c.firstLine, c.flip)), [
      ('ideia.ex1', 'ideia', 0, false),
      ('demos.ex1', 'demos', 5, true),
    ]);
    expect(video.lines.first.text, 'Olhe a casa e4 agora, e a e2.');
    expect(video.lines.first.textKey, 'rot.e1');
  });

  test('a pergunta de lista vira ponto de interação com os ramos', () {
    final video = _convert();
    final gate = video.lines[2].gate!;
    expect(gate.legacy, isFalse);
    expect(gate.pieces, ['e2']);
    expect(gate.right, ['e2e4']);
    expect(gate.rightLines, 1);
    expect(gate.back, 'rot.volta');
    expect(gate.exitFor('e1d1')!.branch, 'ideia.ex1.alt.e1d1');
    expect(gate.exitFor('e1d1')!.after, GateAfter.resume);
    expect(gate.exitFor('e2e3')!.after, GateAfter.retry);
    expect(gate.exitFor('e1f1')!.branch, 'ideia.ex1.fora');
    expect(video.branches.keys, {
      'ideia.ex1.alt.e1d1',
      'ideia.ex1.err.e2e3',
      'ideia.ex1.fora',
      'ideia.ex1.revela',
      'demos.ex1.revela',
    });
    expect(video.branches['ideia.ex1.fora']!.single.board.fen, _start);
    expect(video.branches['ideia.ex1.err.e2e3']!.single.board.move, 'e2e3');
  });

  test('pergunta com outro juiz fica marcada para o fluxo atual', () {
    final gate = _convert().lines[6].gate!;
    expect(gate.legacy, isTrue);
    // Sem `fora` próprio e sem `ini.fora` nas falas: sem ramo de fora.
    expect(gate.outside, isNull);
  });

  test('lance fora usa a fala genérica quando a pergunta não tem a dela', () {
    final video = LessonVideoConverter.convert(
      _script,
      const ScriptTexts({'ini.fora': 'Esse lance não.'}),
      language: 'pt',
    );
    expect(video.lines[6].gate!.outside, 'demos.ex1.fora');
    expect(video.branches['demos.ex1.fora']!.single.text, 'Esse lance não.');
  });

  test('o exemplo que começa com lance parte da posição dele', () {
    final first = _convert().lines[5];
    expect(first.board.move, 'e2e4');
    expect(first.board.from, _start);
    expect(first.board.jump, isFalse);
    // O primeiro passo sem lance corta para a posição.
    expect(_convert().lines.first.board.jump, isTrue);
  });

  test('a marca nova aparece na palavra que cita a casa; a que continua, '
      'desde o começo', () {
    final video = _convert();
    final first = video.lines.first;
    expect(first.marks.map((m) => (m.square, m.fromWord)), [
      ('e4', 3),
      ('e2', 7),
    ]);
    expect(video.lines[1].marks.single.fromWord, isNull);
    expect(first.arrows, [const ScriptArrow('e2', 'e4', 'g')]);
  });

  test('sem áudio: sem arquivo, tempo de leitura e palavras repartidas', () {
    final video = _convert();
    expect(video.hasAudio, isFalse);
    final line = video.lines.first;
    expect(line.audio, isNull);
    expect(line.words, hasLength(line.text.split(' ').length));
    expect(line.words.last.to, line.voice);
    final timeline = VideoTimeline.layout(video.lines);
    expect(
      timeline.lines.first.voiceLength,
      VideoTimeline.readingTime(line.text),
    );
    expect(
      timeline.lines.first.end - timeline.lines.first.voiceEnd,
      LessonVideoConverter.pauses['ideia'],
    );
    expect(
      timeline.lines[5].end - timeline.lines[5].voiceEnd,
      LessonVideoConverter.pauses['demos'],
    );
  });

  test('com áudio: arquivo pela chave do texto e palavras do alinhador', () {
    const text = 'Qual é o lance?';
    final key = LessonVideoConverter.audioKey('pt', 'viktor', text);
    final video = _convert(
      clips: {
        key: VoiceClip.fromJson({
          'ms': 1500,
          'palavras': [
            {'texto': 'Qual', 'ini': 0, 'fim': 300},
            {'texto': 'é', 'ini': 300, 'fim': 500},
            {'texto': 'o', 'ini': 500, 'fim': 600},
            {'texto': 'lance', 'ini': 600, 'fim': 1500},
          ],
        }),
      },
    );
    final question = video.lines[2];
    expect(question.audio, 'audio/pt/viktor/$key.opus');
    expect(question.voice, const Duration(milliseconds: 1500));
    expect(question.words.map((w) => text.substring(w.start, w.end)), [
      'Qual',
      'é',
      'o',
      'lance',
    ]);
    expect(video.hasAudio, isTrue);
    expect(video.lines.first.audio, isNull);
  });

  test('a chave do áudio muda com o texto, o idioma e a voz', () {
    final a = LessonVideoConverter.audioKey('pt', 'viktor', 'Olá');
    expect(a, hasLength(16));
    expect(LessonVideoConverter.audioKey('pt', 'viktor', 'Olá'), a);
    expect(LessonVideoConverter.audioKey('en', 'viktor', 'Olá'), isNot(a));
    expect(LessonVideoConverter.audioKey('pt', 'outra', 'Olá'), isNot(a));
    expect(LessonVideoConverter.audioKey('pt', 'viktor', 'Olá!'), isNot(a));
  });

  test('o nome marcado sai do texto e vira link da legenda', () {
    final line = _convert().lines[4];
    expect(line.text, 'Como Kasparov faria.');
    expect(line.links.single.key, 'garry-kasparov');
    expect(
      line.text.substring(line.links.single.start, line.links.single.end),
      'Kasparov',
    );
  });

  test('fala sem texto usa a chave e não quebra', () {
    final video = LessonVideoConverter.convert(
      _script,
      ScriptTexts.empty,
      language: 'pt',
    );
    expect(video.lines.first.text, 'rot.e1');
  });

  test('a etapa recortada monta a linha do tempo só dela', () {
    final demos = _convert().stage('demos');
    expect(demos.lines.first.id, 'demos.ex1.e.1');
    final timeline = VideoTimeline.layout(demos.lines);
    expect(timeline.frameAt(Duration.zero).fen, _afterE4);
    expect(timeline.reachable(timeline.total, {}), timeline.lines[1].voiceEnd);
  });
}
