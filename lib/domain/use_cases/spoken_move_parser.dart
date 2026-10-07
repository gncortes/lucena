import 'package:dartchess/dartchess.dart';

/// Os comandos de voz do modo às cegas, além dos lances.
enum BlindCommand {
  /// Repetir o último lance do adversário.
  repeat,

  /// Ler as peças de cada lado.
  position,

  /// Desistir da partida.
  resign,

  /// "Sim": confirma o lance proposto.
  yes,

  /// "Não": descarta o lance proposto.
  no,
}

/// Um lance legal com a notação dele (`Tf3`, `O-O`).
typedef SanMove = ({Move move, String san});

/// O que o jogador falou, entendido.
sealed class SpokenParse {
  const SpokenParse();
}

/// Um lance legal, um só.
class SpokenMove extends SpokenParse {
  const SpokenMove(this.move);

  final SanMove move;

  @override
  String toString() => 'lance ${move.san}';
}

/// Mais de um lance legal cabe no que foi dito ("torre f3" com duas torres
/// que vão a f3): o app pergunta qual.
class SpokenAmbiguous extends SpokenParse {
  const SpokenAmbiguous(this.options);

  final List<SanMove> options;

  @override
  String toString() => 'ambíguo ${[for (final o in options) o.san]}';
}

/// Um comando ("repetir", "posição", "desistir").
class SpokenCommand extends SpokenParse {
  const SpokenCommand(this.command);

  final BlindCommand command;

  @override
  String toString() => 'comando ${command.name}';
}

/// Um lance bem dito, mas impossível nesta posição ("rei d3" com o rei
/// longe): o app mostra o que entendeu e, confirmado, avisa que é ilegal.
class SpokenIllegal extends SpokenParse {
  const SpokenIllegal(this.san);

  /// O lance dito, em notação (em inglês): `Kd3`, `O-O`, `e8=Q`.
  final String san;

  @override
  String toString() => 'ilegal $san';
}

/// Nada que se entenda: o app pede para repetir.
class SpokenUnknown extends SpokenParse {
  const SpokenUnknown();

  @override
  String toString() => 'não entendido';
}

/// Entende um lance falado, sem IA: normaliza o texto do reconhecedor (letras
/// e números por extenso, peças, "toma", roques) e procura entre os lances
/// legais da posição os que cabem no que foi dito. Entre as alternativas do
/// reconhecedor, vence a mais segura (um lance com a peça dita), e no empate
/// a mais provável.
///
/// Por enquanto em português.
abstract final class SpokenMoveParser {
  /// O que [alternatives] (do reconhecedor, da mais provável para a menos)
  /// quer dizer em [position]. Com [among], só esses lances valem (a
  /// resposta a "qual torre?").
  static SpokenParse parse(
    List<String> alternatives,
    Position position, {
    List<SanMove>? among,
  }) {
    final legal = among ?? legalMoves(position);
    // Cada alternativa vira um candidato com uma nota; vence a menor nota
    // (empate: a alternativa que o reconhecedor achou mais provável). Um
    // lance com a peça dita vence o palpite de peão de uma frase com palavra
    // desconhecida ("rei F5" vence "Hey F5" lido como peão).
    final candidates = <(int, int, SpokenParse)>[];
    for (final (index, alternative) in alternatives.indexed) {
      final text = normalize(alternative);
      if (among == null) {
        final command = _command(text);
        if (command != null) {
          candidates.add((0, index, SpokenCommand(command)));
          continue;
        }
      }
      final sure = _sure(text);
      final found = _match(text, legal, position, answering: among != null);
      if (found.length == 1) {
        candidates.add((sure ? 0 : 2, index, SpokenMove(found.single)));
        continue;
      }
      if (found.length > 1) {
        candidates.add((sure ? 1 : 3, index, SpokenAmbiguous(found)));
        continue;
      }
      if (among != null) continue;
      // O reconhecedor às vezes escreve o lance abreviado e colado
      // ("rg5", "RG 5", "cf3"): vale como a notação digitada.
      final compact = alternative.replaceAll(RegExp(r'\s+'), '');
      if (RegExp(r'^[A-Za-z]{1,2}x?[A-Ha-h][1-8]$').hasMatch(compact)) {
        final typed = parseTyped(compact, position, words: false);
        final rank = switch (typed) {
          SpokenMove() => 0,
          SpokenAmbiguous() => 1,
          SpokenIllegal() => 4,
          _ => null,
        };
        if (rank != null) {
          candidates.add((rank, index, typed));
          continue;
        }
      }
      final said = describe(text);
      if (said != null) {
        // Impossível: com a peça dita, ainda é a melhor pista do que foi
        // falado.
        candidates.add((sure ? 4 : 5, index, SpokenIllegal(said)));
      }
    }
    if (candidates.isEmpty) return const SpokenUnknown();
    candidates.sort((x, y) {
      final byRank = x.$1.compareTo(y.$1);
      return byRank != 0 ? byRank : x.$2.compareTo(y.$2);
    });
    return candidates.first.$3;
  }

  /// O texto (normalizado) só tem o que se espera de um lance: peças,
  /// casas, letras, números, capturas e palavras de ligação. Uma palavra
  /// desconhecida ("hey" virou peça, mas "ola" não) torna o palpite fraco.
  static bool _sure(String text) {
    for (final word in text.split(' ')) {
      if (word.isEmpty) continue;
      if (_pieces.containsKey(word) ||
          _captures.contains(word) ||
          _fillers.contains(word) ||
          const {
            'roque',
            'pequeno',
            'grande',
            'curto',
            'longo',
          }.contains(word) ||
          RegExp(r'^[a-h]?[1-8]?$').hasMatch(word) ||
          RegExp(r'^[a-h][1-8]$').hasMatch(word)) {
        continue;
      }
      return false;
    }
    return true;
  }

  /// O lance que [text] (já normalizado) descreve, em notação, sem olhar se
  /// é possível: a peça, a origem dita, a captura, o destino e a promoção.
  /// Nulo se não há um lance no texto (falta o destino).
  static String? describe(String text) {
    final words = text.split(' ');
    if (words.contains('roque')) {
      return words.any(const {'grande', 'longo'}.contains) ? 'O-O-O' : 'O-O';
    }
    Role? role;
    Role? promotion;
    final squares = <String>[];
    String? fromFile;
    String? fromRank;
    var capture = false;
    for (final word in words) {
      final piece = _pieces[word];
      if (piece != null) {
        if (squares.isNotEmpty || role != null) {
          promotion = piece;
        } else {
          role = piece;
        }
      } else if (_captures.contains(word)) {
        capture = true;
      } else if (Square.parse(word) != null && word.length == 2) {
        squares.add(word);
      } else if (RegExp(r'^[a-h]$').hasMatch(word)) {
        fromFile = word;
      } else if (RegExp(r'^[1-8]$').hasMatch(word)) {
        fromRank = word;
      }
    }
    if (squares.isEmpty) return null;
    final to = squares.last;
    final from = squares.length > 1
        ? squares[squares.length - 2]
        : '${fromFile ?? ''}${fromRank ?? ''}';
    final letter = switch (role) {
      Role.king => 'K',
      Role.queen => 'Q',
      Role.rook => 'R',
      Role.bishop => 'B',
      Role.knight => 'N',
      Role.pawn || null => '',
    };
    final promoted = switch (promotion) {
      Role.queen => '=Q',
      Role.rook => '=R',
      Role.bishop => '=B',
      Role.knight => '=N',
      _ => '',
    };
    return '$letter$from${capture ? 'x' : ''}$to$promoted';
  }

  /// O lance digitado: a notação no idioma ([language]: `Cf3` em pt, `Nf3`
  /// em en), as coordenadas (`e2e4`, `e7e8q`) ou as mesmas palavras da voz
  /// ("cavalo f3").
  static SpokenParse parseTyped(
    String text,
    Position position, {
    String language = 'pt',
    bool words = true,
  }) {
    // Do jeito que veio, e com a peça em maiúscula e a casa em minúscula
    // ("rf4", "RF4" → "Rf4"): o primeiro que der um lance vale.
    final trimmed = text.trim();
    final variants = {
      trimmed,
      if (trimmed.length > 1)
        trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase(),
    };
    SpokenParse? fallback;
    for (final variant in variants) {
      final parse = _parseTyped(
        variant,
        position,
        language: language,
        words: words,
      );
      if (parse is SpokenMove || parse is SpokenAmbiguous) return parse;
      if (parse is SpokenIllegal && fallback is! SpokenIllegal) {
        fallback = parse;
      }
      fallback ??= parse;
    }
    return fallback!;
  }

  static SpokenParse _parseTyped(
    String text,
    Position position, {
    required String language,
    required bool words,
  }) {
    final typed = text.trim().replaceAll(RegExp(r'[\s+#!?]'), '');
    if (typed.isEmpty) return const SpokenUnknown();
    final legal = legalMoves(position);
    // Coordenadas: e2e4, e7e8q.
    final uci = RegExp(r'^([a-h][1-8])-?([a-h][1-8])([qrbn])?$')
        .firstMatch(typed.toLowerCase());
    if (uci != null) {
      final move = Move.parse('${uci[1]}${uci[2]}${uci[3] ?? ''}');
      for (final m in legal) {
        if (m.move == move ||
            (uci[3] == null &&
                m.move is NormalMove &&
                (m.move as NormalMove).from == (move as NormalMove).from &&
                (m.move as NormalMove).to == move.to &&
                (m.move as NormalMove).promotion == Role.queen)) {
          return SpokenMove(m);
        }
      }
      return SpokenIllegal('${uci[1]}${uci[2]}');
    }
    // Notação: as letras das peças no idioma viram as do inglês.
    final code = language.split(RegExp('[-_]')).first.toLowerCase();
    final letters = _typedLetters[code] ?? const {};
    final english = typed
        .replaceAll('0', 'O')
        .replaceAllMapped(RegExp('^[A-Z]'), (m) {
          final letter = m[0]!;
          if (letter == 'O') return letter;
          return letters[letter] ?? letter;
        })
        // Promoção sem o "=" (e8D) e com a peça em minúscula (e8=d), nas
        // letras do idioma.
        .replaceAllMapped(RegExp(r'([a-h][18])=?([A-Za-z])$'), (m) {
          final upper = m[2]!.toUpperCase();
          return '${m[1]}=${letters[upper] ?? upper}';
        });
    for (final m in legal) {
      final bare = m.san.replaceAll(RegExp('[+#]'), '');
      // Peão sem promoção dita: a dama.
      if (bare == english || bare == '$english=Q') return SpokenMove(m);
    }
    if (RegExp(r'^([KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](=[QRBN])?|O-O(-O)?)$')
        .hasMatch(english)) {
      // Notação curta que serve para mais de uma peça (Rf3 com duas torres).
      final matches = [
        for (final m in legal)
          if (_sameTarget(m, english)) m,
      ];
      if (matches.length > 1) return SpokenAmbiguous(matches);
      return SpokenIllegal(english);
    }
    // As palavras da voz ("cavalo f3").
    return words ? parse([text], position) : const SpokenUnknown();
  }

  static bool _sameTarget(SanMove m, String english) {
    final bare = m.san.replaceAll(RegExp('[+#]'), '');
    final piece = RegExp('^[KQRBN]').firstMatch(english)?.group(0) ?? '';
    final target = RegExp(r'[a-h][1-8](=[QRBN])?$').firstMatch(english)?[0];
    if (target == null || !bare.startsWith(piece)) return false;
    if (piece.isEmpty && RegExp('^[KQRBN]').hasMatch(bare)) return false;
    return bare.endsWith(target);
  }

  /// As letras das peças digitadas em cada idioma, para as do inglês.
  static const _typedLetters = {
    'pt': {'R': 'K', 'D': 'Q', 'T': 'R', 'B': 'B', 'C': 'N', 'K': 'K'},
    'es': {'R': 'K', 'D': 'Q', 'T': 'R', 'A': 'B', 'C': 'N'},
  };

  /// Os lances legais de [position], com a notação de cada um. A promoção
  /// aparece uma vez para cada peça; o roque, uma vez só.
  static List<SanMove> legalMoves(Position position) {
    final out = <SanMove>[];
    final seen = <String>{};
    for (final MapEntry(key: from, value: targets) in makeLegalMoves(
      position,
    ).entries) {
      final pawn = position.board.roleAt(from) == Role.pawn;
      for (final to in targets) {
        final promotes = pawn && SquareSet.backranks.has(to);
        final moves = promotes
            ? [
                for (final role in const [
                  Role.queen,
                  Role.rook,
                  Role.bishop,
                  Role.knight,
                ])
                  NormalMove(from: from, to: to, promotion: role),
              ]
            : [NormalMove(from: from, to: to)];
        for (final move in moves) {
          final san = position.makeSan(move).$2;
          if (seen.add(san)) out.add((move: move, san: san));
        }
      }
    }
    return out;
  }

  /// O texto em minúsculas, sem acentos e sem pontuação, com letras e
  /// números por extenso trocados pelos caracteres ("efe três" → "f 3") e as
  /// casas juntadas ("f 3" → "f3").
  static String normalize(String text) {
    var t = _strip(text.toLowerCase());
    t = t.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    // Letras repetidas coladas num número: "ff3" → "f3".
    t = t.replaceAllMapped(
      RegExp(r'\b([a-h])\1+([1-8])\b'),
      (m) => '${m[1]}${m[2]}',
    );
    final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final out = <String>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final next = i + 1 < words.length ? words[i + 1] : null;
      final number = _numbers[word];
      if (number != null) {
        out.add(number);
        continue;
      }
      final letter = _letters[word];
      // "de" e "e" são também palavras do português: só valem como letra
      // antes de um número ("de 4", "e quatro").
      if (letter != null) {
        final beforeNumber =
            next != null &&
            (_numbers.containsKey(next) || RegExp(r'^[1-8]$').hasMatch(next));
        if (!_ambiguousLetters.contains(word) || beforeNumber) {
          out.add(letter);
          continue;
        }
      }
      out.add(word);
    }
    // "f 3" → "f3".
    return out
        .join(' ')
        .replaceAllMapped(
          RegExp(r'\b([a-h]) ([1-8])\b'),
          (m) => '${m[1]}${m[2]}',
        );
  }

  static BlindCommand? _command(String text) {
    final words = text.split(' ').toSet();
    if (words.intersection(const {'repetir', 'repete', 'repita'}).isNotEmpty) {
      return BlindCommand.repeat;
    }
    if (words.intersection(const {'posicao', 'pecas'}).isNotEmpty) {
      return BlindCommand.position;
    }
    if (words.intersection(const {
      'desistir',
      'desisto',
      'abandono',
    }).isNotEmpty) {
      return BlindCommand.resign;
    }
    // "Sim" e "não" só sem casa no meio ("não, torre f3" é outro lance).
    if (!RegExp(r'[a-h][1-8]').hasMatch(text)) {
      if (words.intersection(const {
        'sim',
        'confirma',
        'confirmo',
        'isso',
        'pode',
        'joga',
      }).isNotEmpty) {
        return BlindCommand.yes;
      }
      if (words.intersection(const {'nao', 'cancela', 'errado'}).isNotEmpty) {
        return BlindCommand.no;
      }
    }
    return null;
  }

  static List<SanMove> _match(
    String text,
    List<SanMove> legal,
    Position position, {
    required bool answering,
  }) {
    final words = text.split(' ');
    // Roques.
    if (words.contains('roque')) {
      final long = words.any(const {'grande', 'longo'}.contains);
      final short = words.any(const {'pequeno', 'curto'}.contains);
      // "Roque" sozinho: o pequeno, se houver; senão o grande.
      final sans = long
          ? const ['O-O-O']
          : short
          ? const ['O-O']
          : const ['O-O', 'O-O-O'];
      for (final san in sans) {
        final found = [
          for (final m in legal)
            if (m.san.replaceAll(RegExp('[+#]'), '') == san) m,
        ];
        if (found.isNotEmpty) return found;
      }
      return const [];
    }
    Role? role;
    Role? promotion;
    final squares = <Square>[];
    String? fromFile;
    String? fromRank;
    var capture = false;
    for (final word in words) {
      final piece = _pieces[word];
      if (piece != null) {
        // Peça depois da casa de destino: a promoção ("e8 dama").
        if (squares.isNotEmpty || role != null) {
          promotion = piece;
        } else {
          role = piece;
        }
        continue;
      }
      if (_captures.contains(word)) {
        capture = true;
        continue;
      }
      final square = Square.parse(word);
      if (square != null && word.length == 2) {
        squares.add(square);
        continue;
      }
      if (RegExp(r'^[a-h]$').hasMatch(word)) {
        fromFile = word;
        continue;
      }
      if (RegExp(r'^[1-8]$').hasMatch(word)) fromRank = word;
    }
    // A resposta a "qual torre?": basta a casa, a coluna ou a fileira de
    // onde ela sai.
    if (answering) {
      return [
        for (final m in legal)
          if (_fromMatches(m.move, squares.lastOrNull, fromFile, fromRank)) m,
      ];
    }
    if (squares.isEmpty) return const [];
    final to = squares.last;
    final from = squares.length > 1 ? squares[squares.length - 2] : null;
    bool fits(SanMove m, {required Role? as, required bool useFile}) {
      final move = m.move;
      if (move is! NormalMove || move.to != to) return false;
      final f = move.from;
      if (as != null && position.board.roleAt(f) != as) return false;
      if (from != null && f != from) return false;
      if (useFile && fromFile != null && f.file.name != fromFile) return false;
      if (fromRank != null && f.rank.name != fromRank) return false;
      // Sem peça dita na promoção, a dama.
      final promoted = move.promotion;
      if (promoted != null && promoted != (promotion ?? Role.queen)) {
        return false;
      }
      return true;
    }

    // Sem peça dita, um peão ("e4"); se nenhum peão vai lá, qualquer peça.
    // A coluna solta ("torre a f3") vale como origem; se não couber, pode
    // ter sido só a preposição ("a").
    for (final as in role != null ? [role] : const [Role.pawn, null]) {
      for (final useFile in const [true, false]) {
        var found = [
          for (final m in legal)
            if (fits(m, as: as, useFile: useFile)) m,
        ];
        if (capture && found.length > 1) {
          final captures = [
            for (final m in found)
              if (m.san.contains('x')) m,
          ];
          if (captures.isNotEmpty) found = captures;
        }
        if (found.isNotEmpty) return found;
      }
    }
    return const [];
  }

  static bool _fromMatches(
    Move move,
    Square? square,
    String? file,
    String? rank,
  ) {
    if (move is! NormalMove) return false;
    final from = move.from;
    if (square != null) return from == square;
    if (file != null && from.file.name != file) return false;
    if (rank != null && from.rank.name != rank) return false;
    return file != null || rank != null;
  }

  static String _strip(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final out = StringBuffer();
    for (final char in text.split('')) {
      final i = from.indexOf(char);
      out.write(i < 0 ? char : to[i]);
    }
    return out.toString();
  }

  static const _numbers = {
    'um': '1',
    'uma': '1',
    'hum': '1',
    'dois': '2',
    'duas': '2',
    'tres': '3',
    'treis': '3',
    'quatro': '4',
    'cuatro': '4',
    'cinco': '5',
    'sinco': '5',
    'seis': '6',
    'meia': '6',
    'sete': '7',
    'oito': '8',
    'oitu': '8',
  };

  /// As letras das colunas pelo nome falado ("bê", "efe", "agá"), com o
  /// que o reconhecedor costuma escrever no lugar.
  static const _letters = {
    'a': 'a',
    'ah': 'a',
    'be': 'b',
    'bi': 'b',
    've': 'b',
    'ce': 'c',
    'se': 'c',
    'si': 'c',
    'de': 'd',
    'di': 'd',
    'dei': 'd',
    'e': 'e',
    'eh': 'e',
    'ei': 'e',
    'efe': 'f',
    'efi': 'f',
    'ef': 'f',
    'fe': 'f',
    'ge': 'g',
    'je': 'g',
    'gi': 'g',
    'ji': 'g',
    'aga': 'h',
    'haga': 'h',
    'ha': 'h',
  };

  /// Letras que também são palavras do português (ou outra coisa): só valem
  /// como letra antes de um número.
  static const _ambiguousLetters = {
    'a',
    'ah',
    'de',
    'di',
    'dei',
    'e',
    'eh',
    'ei',
    'se',
    'si',
    've',
    'fe',
    'ha',
  };

  /// As peças, com o que o reconhecedor costuma escrever no lugar delas.
  /// No português do Brasil o "r" do começo e o "rr" soam como "h" ("rei"
  /// vira "hei", "hey", "hay"; "torre" vira "tohe"); o "o" final soa "u"
  /// ("bispu", "cavalu"); o "ão" vira "ao", "am", "on".
  static const _pieces = {
    // Rei.
    'rei': Role.king,
    'reis': Role.king,
    're': Role.king,
    'rey': Role.king,
    'rrei': Role.king,
    'hei': Role.king,
    'hey': Role.king,
    'hay': Role.king,
    'ray': Role.king,
    'rai': Role.king,
    'hai': Role.king,
    'he': Role.king,
    'hy': Role.king,
    'reih': Role.king,
    'king': Role.king,
    // Dama.
    'dama': Role.queen,
    'damas': Role.queen,
    'dana': Role.queen,
    'danna': Role.queen,
    'drama': Role.queen,
    'dam': Role.queen,
    'damma': Role.queen,
    'rainha': Role.queen,
    'hainha': Role.queen,
    'rainhas': Role.queen,
    'queen': Role.queen,
    // Torre.
    'torre': Role.rook,
    'torres': Role.rook,
    'tore': Role.rook,
    'torri': Role.rook,
    'tohe': Role.rook,
    'tohi': Role.rook,
    'torra': Role.rook,
    'torro': Role.rook,
    'tori': Role.rook,
    'touro': Role.rook,
    'tor': Role.rook,
    'rook': Role.rook,
    // Bispo.
    'bispo': Role.bishop,
    'bispos': Role.bishop,
    'bispu': Role.bishop,
    'bisco': Role.bishop,
    'bisp': Role.bishop,
    'vispo': Role.bishop,
    'pispo': Role.bishop,
    'bispa': Role.bishop,
    'bishop': Role.bishop,
    // Cavalo.
    'cavalo': Role.knight,
    'cavalos': Role.knight,
    'cavalu': Role.knight,
    'cavala': Role.knight,
    'caval': Role.knight,
    'cavaleiro': Role.knight,
    'cabalo': Role.knight,
    'kavalo': Role.knight,
    'knight': Role.knight,
    // Peão.
    'peao': Role.pawn,
    'peoes': Role.pawn,
    'piao': Role.pawn,
    'peon': Role.pawn,
    'piam': Role.pawn,
    'peam': Role.pawn,
    'piaum': Role.pawn,
    'pawn': Role.pawn,
  };

  /// Palavras de ligação: não dizem nada do lance, mas não o atrapalham
  /// ("rei na casa de f6", "mover o cavalo para e5").
  static const _fillers = {
    'na',
    'no',
    'nas',
    'nos',
    'casa',
    'de',
    'do',
    'da',
    'para',
    'pra',
    'pro',
    'vai',
    'vou',
    'ir',
    'mover',
    'move',
    'mova',
    'movo',
    'joga',
    'jogar',
    'jogo',
    'o',
    'a',
    'os',
    'as',
    'em',
    'ao',
    'e',
    'lance',
    'meu',
    'minha',
    'com',
  };

  static const _captures = {
    'toma',
    'tomando',
    'captura',
    'capturando',
    'come',
    'comendo',
    'pega',
    'pegando',
    'por',
    'x',
    'xis',
  };
}
