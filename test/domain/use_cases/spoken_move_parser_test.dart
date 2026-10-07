import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/spoken_move_parser.dart';

void main() {
  Position at(String fen) => GameRules.fromFen(fen)!;

  // Dama e rei contra rei, com peão e cavalo para os outros casos.
  final queen = at('8/8/8/4k3/8/8/4P3/3QK1N1 w - - 0 1');
  // Duas torres que vão a f3 (a3 e h3), o rei branco pode rocar.
  final rooks = at('4k3/8/8/8/8/R6R/8/4K2R w K - 0 1');
  // Peão na sétima, pronto para promover; cavalo preto para capturar em e5.
  final pawn = at('4k3/1P6/8/4n3/8/3N4/8/4K3 w - - 0 1');

  // A notação sem o xeque, para a tabela ficar legível.
  String? san(SpokenParse parse) => parse is SpokenMove
      ? parse.move.san.replaceAll(RegExp('[+#]'), '')
      : null;

  group('normalização', () {
    const cases = {
      'Torre efe três': 'torre f3',
      'TORRE f 3': 'torre f3',
      'torre ff3': 'torre f3',
      'rei é quatro': 'rei e4',
      'peão dê quatro': 'peao d4',
      'torre de a para f3': 'torre de a para f3',
      'cavalo toma e5': 'cavalo toma e5',
      'Bê sete, bê oito, dama!': 'b7 b8 dama',
      'aga um': 'h1',
    };
    cases.forEach((text, normal) {
      test('"$text" → "$normal"', () {
        expect(SpokenMoveParser.normalize(text), normal);
      });
    });
  });

  group('lances', () {
    final cases = <String, (Position, List<String>, String?)>{
      'rei e peça e casa': (queen, ['rei f2'], 'Kf2'),
      'dama por extenso': (queen, ['dama dê quatro'], 'Qd4'),
      'rainha vale dama': (queen, ['rainha d4'], 'Qd4'),
      'peão sem a peça dita': (queen, ['e4'], 'e4'),
      'peão dito': (queen, ['peão e3'], 'e3'),
      'cavalo': (queen, ['cavalo f3'], 'Nf3'),
      'casa sem peça e sem peão: a peça que vai lá': (queen, ['f3'], 'Nf3'),
      'captura': (pawn, ['cavalo toma e5'], 'Nxe5'),
      'captura sem "toma"': (pawn, ['cavalo e5'], 'Nxe5'),
      'promoção à dama': (pawn, ['b8 dama'], 'b8=Q'),
      'promoção sem peça: dama': (pawn, ['b8'], 'b8=Q'),
      'promoção a cavalo': (pawn, ['b8 cavalo'], 'b8=N'),
      'roque pequeno': (rooks, ['roque pequeno'], 'O-O'),
      'roque curto': (rooks, ['roque curto'], 'O-O'),
      'origem por coluna': (rooks, ['torre de a para f3'], 'Raf3'),
      'origem colada': (rooks, ['torre a f3'], 'Raf3'),
      'origem pela casa': (rooks, ['torre h3 f3'], 'Rhf3'),
      'ruído no destino': (rooks, ['torre ff3'], null),
      'nada de xadrez': (queen, ['bom dia'], null),
      'rei na casa de f2': (queen, ['rei na casa de f2'], 'Kf2'),
      'abreviado e colado pelo reconhecedor': (
        queen,
        ['rf2', 'reff2', 'RF 2'],
        'Kf2',
      ),
      'abreviado com espaço': (queen, ['RF 2'], 'Kf2'),
      'cavalo abreviado': (queen, ['cf3'], 'Nf3'),
      'rei na casa f2': (queen, ['rei na casa f2'], 'Kf2'),
      'rei vai para f2': (queen, ['rei vai para f2'], 'Kf2'),
      'mover o rei para f2': (queen, ['mover o rei para f2'], 'Kf2'),
      'rei para a casa efe dois': (queen, ['rei para a casa efe dois'], 'Kf2'),
      'dama em d4': (queen, ['dama em d4'], 'Qd4'),
      'peão para e4': (queen, ['peão para e4'], 'e4'),
      'cavalo pega e5': (pawn, ['cavalo pega e5'], 'Nxe5'),
      'cavalo tomando e5': (pawn, ['cavalo tomando e5'], 'Nxe5'),
      'a primeira alternativa que serve': (
        queen,
        ['bom dia', 'rei f2', 'rei d2'],
        'Kf2',
      ),
    };
    cases.forEach((name, data) {
      final (position, alternatives, expected) = data;
      test(name, () {
        expect(san(SpokenMoveParser.parse(alternatives, position)), expected);
      });
    });
  });

  group('ambiguidade', () {
    test('duas torres para f3: pergunta qual', () {
      final parse = SpokenMoveParser.parse(['torre efe três'], rooks);
      expect(parse, isA<SpokenAmbiguous>());
      expect(
        (parse as SpokenAmbiguous).options.map((m) => m.san),
        unorderedEquals(['Raf3', 'Rhf3']),
      );
    });

    test('a resposta: a coluna, a fileira ou a casa de onde sai', () {
      final options = (SpokenMoveParser.parse([
        'torre f3',
      ], rooks) as SpokenAmbiguous).options;
      for (final (answer, expected) in [
        ('a de a', 'Raf3'),
        ('a de aga', 'Rhf3'),
        ('h3', 'Rhf3'),
      ]) {
        expect(
          san(SpokenMoveParser.parse([answer], rooks, among: options)),
          expected,
          reason: answer,
        );
      }
    });

    test('uma alternativa clara vence uma ambígua anterior', () {
      expect(
        san(SpokenMoveParser.parse(['torre f3', 'torre a f3'], rooks)),
        'Raf3',
      );
    });
  });

  group('comandos', () {
    const cases = {
      'repetir': BlindCommand.repeat,
      'Repete, por favor': BlindCommand.repeat,
      'posição': BlindCommand.position,
      'desisto': BlindCommand.resign,
      'sim': BlindCommand.yes,
      'Isso, pode jogar': BlindCommand.yes,
      'não': BlindCommand.no,
      'cancela': BlindCommand.no,
    };
    cases.forEach((text, command) {
      test(text, () {
        final parse = SpokenMoveParser.parse([text], queen);
        expect(parse, isA<SpokenCommand>());
        expect((parse as SpokenCommand).command, command);
      });
    });
  });

  test('"não, torre..." é um lance, não um "não"', () {
    final parse = SpokenMoveParser.parse(['não, rei f2'], queen);
    expect(san(parse), 'Kf2');
  });

  group('lance bem dito, mas impossível nesta posição', () {
    final cases = <String, (Position, List<String>, String)>{
      'o rei longe da casa': (queen, ['rei de três'], 'Kd3'),
      'peça que não existe': (queen, ['torre f3'], 'Rf3'),
      'com origem e captura': (rooks, ['torre de a toma b5'], 'Raxb5'),
      'roque sem direito': (queen, ['roque grande'], 'O-O-O'),
      'promoção impossível': (queen, ['e8 dama'], 'e8=Q'),
    };
    cases.forEach((name, data) {
      final (position, alternatives, expected) = data;
      test(name, () {
        final parse = SpokenMoveParser.parse(alternatives, position);
        expect(parse, isA<SpokenIllegal>());
        expect((parse as SpokenIllegal).san, expected);
      });
    });

    test('um lance possível em outra alternativa vence o impossível', () {
      final parse = SpokenMoveParser.parse(['rei de três', 'rei f2'], queen);
      expect(san(parse), 'Kf2');
    });

    test('sem casa de destino não é lance', () {
      expect(SpokenMoveParser.parse(['rei'], queen), isA<SpokenUnknown>());
    });
  });

  group('lance digitado', () {
    final cases = <String, (Position, String, String, String?)>{
      'notação em português': (queen, 'Cf3', 'pt', 'Nf3'),
      'dama em português': (queen, 'Dd4', 'pt', 'Qd4'),
      'rei em português': (queen, 'Rf2', 'pt', 'Kf2'),
      'notação em inglês': (queen, 'Nf3', 'en', 'Nf3'),
      'com xeque e espaços': (queen, ' Dd4+ ', 'pt', 'Qd4'),
      'coordenadas': (queen, 'e2e4', 'pt', 'e4'),
      'coordenadas com hífen': (queen, 'g1-f3', 'pt', 'Nf3'),
      'peão': (queen, 'e3', 'pt', 'e3'),
      'captura': (pawn, 'Cxe5', 'pt', 'Nxe5'),
      'promoção sem =': (pawn, 'b8D', 'pt', 'b8=Q'),
      'promoção em coordenadas, sem peça: dama': (pawn, 'b7b8', 'pt', 'b8=Q'),
      'roque com zeros': (rooks, '0-0', 'pt', 'O-O'),
      'palavras da voz': (queen, 'cavalo f3', 'pt', 'Nf3'),
      'peça em minúscula': (queen, 'rf2', 'pt', 'Kf2'),
      'casa em maiúscula': (queen, 'RF2', 'pt', 'Kf2'),
      'tudo em minúscula, dama': (queen, 'dd4', 'pt', 'Qd4'),
      'cavalo em minúscula': (queen, 'cf3', 'pt', 'Nf3'),
      'peão continua peão': (queen, 'e4', 'pt', 'e4'),
    };
    cases.forEach((name, data) {
      final (position, text, language, expected) = data;
      test(name, () {
        expect(
          san(SpokenMoveParser.parseTyped(text, position, language: language)),
          expected,
        );
      });
    });

    test('impossível: ilegal; serve para duas peças: ambíguo', () {
      expect(
        SpokenMoveParser.parseTyped('Rd5', queen, language: 'pt'),
        isA<SpokenIllegal>(),
      );
      expect(SpokenMoveParser.parseTyped('e2e5', queen), isA<SpokenIllegal>());
      expect(
        SpokenMoveParser.parseTyped('Tf3', rooks, language: 'pt'),
        isA<SpokenAmbiguous>(),
      );
    });
  });

  group('fonética do português (o que o reconhecedor escreve)', () {
    // Rei em e4, peão em f4 (o peão vai a f5 e o rei também): o caso do
    // log, em que "Hey F5" virava peão.
    final kingAndPawn = at('7k/8/8/8/4KP2/8/8/8 w - - 0 1');
    // Peças de todo tipo: dama d1, torre a1, bispo c1, cavalo b1, rei e1.
    final pieces = at('7k/8/8/8/8/8/8/RNBQK3 w Q - 0 1');

    final cases = <String, (Position, List<String>, String)>{
      // O caso real: "Hey F5" na frente, "rei F5" na segunda.
      'log: [Hey F5, rei F5, rei F cinco]': (
        kingAndPawn,
        ['Hey F5', 'rei F5', 'rei F cinco'],
        'Kf5',
      ),
      'o "r" com som de "h": hei': (kingAndPawn, ['Hei f5'], 'Kf5'),
      'hay': (kingAndPawn, ['hay f5'], 'Kf5'),
      'ray': (kingAndPawn, ['Ray F5'], 'Kf5'),
      'rey': (kingAndPawn, ['rey f5'], 'Kf5'),
      're': (kingAndPawn, ['re f5'], 'Kf5'),
      'rei com "é" no lugar do "e"': (kingAndPawn, ['rei é cinco'], 'Ke5'),
      'peão dito vence o rei': (kingAndPawn, ['peão f5'], 'f5'),
      'pião': (kingAndPawn, ['pião f5'], 'f5'),
      'casa sozinha é peão': (kingAndPawn, ['f5'], 'f5'),
      'dama: dana': (pieces, ['dana d4'], 'Qd4'),
      'dama: drama': (pieces, ['drama d4'], 'Qd4'),
      'rainha com "h"': (pieces, ['hainha d4'], 'Qd4'),
      'torre: tohe': (pieces, ['tohe a5'], 'Ra5'),
      'torre: tore': (pieces, ['tore a5'], 'Ra5'),
      'torre: torres': (pieces, ['torres a5'], 'Ra5'),
      'bispo: bispu': (pieces, ['bispu e3'], 'Be3'),
      'bispo: vispo': (pieces, ['vispo e3'], 'Be3'),
      'cavalo: cavalu': (pieces, ['cavalu c3'], 'Nc3'),
      'cavalo: cabalo': (pieces, ['cabalo c3'], 'Nc3'),
      'cavaleiro': (pieces, ['cavaleiro c3'], 'Nc3'),
      'letra falada: efe': (kingAndPawn, ['rei efe cinco'], 'Kf5'),
      'letra falada: efi': (kingAndPawn, ['rei efi cinco'], 'Kf5'),
      'letra falada: dê': (pieces, ['dama dê quatro'], 'Qd4'),
      'letra falada: di': (pieces, ['dama di quatro'], 'Qd4'),
      'letra falada: agá': (pieces, ['dama agá cinco'], 'Qh5'),
      'número: treis': (pieces, ['bispo é treis'], 'Be3'),
      'número: sinco': (kingAndPawn, ['rei efe sinco'], 'Kf5'),
      'abreviado: rg5 (log)': (kingAndPawn, ['rf5', 'reff5', 'RF 5'], 'Kf5'),
      'frase longa: rei vai para a casa efe cinco': (
        kingAndPawn,
        ['rei vai para a casa efe cinco'],
        'Kf5',
      ),
      'com palavra desconhecida na frente, e a peça dita depois': (
        kingAndPawn,
        ['olha f5', 'rei f5'],
        'Kf5',
      ),
    };
    cases.forEach((name, data) {
      final (position, alternatives, expected) = data;
      test(name, () {
        expect(san(SpokenMoveParser.parse(alternatives, position)), expected);
      });
    });

    test('a peça dita mas impossível vence o palpite de peão', () {
      // O rei em e4 não chega a f6: com a peça dita, o app mostra "rei f6"
      // (e avisa que é ilegal), não um peão.
      final parse = SpokenMoveParser.parse(['Hey F6', 'rei F6'], kingAndPawn);
      expect(parse, isA<SpokenIllegal>());
      expect((parse as SpokenIllegal).san, 'Kf6');
    });
  });
}
