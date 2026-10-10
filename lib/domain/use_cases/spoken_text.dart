import 'wiki_markup.dart';

/// Converte a notação dos lances que aparece nas falas em texto que o
/// sintetizador lê bem: `Tf3` vira "torre f3", `Cxe5+` vira "cavalo toma e5,
/// xeque". Só o que vai para a voz muda; o texto na tela fica como está.
///
/// Fala português, inglês e espanhol; nos outros idiomas o texto vai como
/// veio.
abstract final class SpokenText {
  /// [text] pronto para falar em [language] (`pt`, `en`, `es`, `pt-BR`).
  static String speakable(String text, String language) =>
      utterance(text, language).text;

  /// Um lance em notação algébrica em inglês, como o motor e o `dartchess`
  /// escrevem (`Rf3` é torre), pronto para falar em [language]: "torre f3".
  static String san(String san, String language) {
    final code = language.split(RegExp('[-_]')).first.toLowerCase();
    final letters = _sanLetters[code];
    if (letters == null) return san;
    final local = san.replaceAllMapped(
      RegExp('[KQRBN]'),
      (m) => letters[m[0]!]!,
    );
    return speakable(local, language);
  }

  /// As letras das peças em cada idioma, a partir das do inglês.
  static const _sanLetters = {
    'pt': {'K': 'R', 'Q': 'D', 'R': 'T', 'B': 'B', 'N': 'C'},
    'en': {'K': 'K', 'Q': 'Q', 'R': 'R', 'B': 'B', 'N': 'N'},
    'es': {'K': 'R', 'Q': 'D', 'R': 'T', 'B': 'A', 'N': 'C'},
  };

  /// [text] pronto para falar, com o caminho de volta: de uma posição no
  /// texto falado para a posição no texto da tela.
  /// A marcação dos nomes (`{{Andersson|ulf-andersson}}`) sai: só o texto
  /// visível é falado.
  static SpokenUtterance utterance(String marked, String language) {
    final text = WikiMarkup.plain(marked);
    final words = _words[language.split(RegExp('[-_]')).first.toLowerCase()];
    if (words == null) return SpokenUtterance._(text, const []);
    final pieces = words.pieces.keys.join();
    final piece = '[$pieces]';
    final move = RegExp(
      // Roque.
      r'(?<![\w-])(?:(O-O-O|0-0-0)|(O-O|0-0))([+#])?(?![\w-])'
      // Lance de peça: peça, origem (coluna, fileira ou casa), captura,
      // destino, xeque.
      '|(?<![\\w])($piece)([a-h]?[1-8]?)(x)?([a-h][1-8])([+#])?(?![\\w])'
      // Lance de peão: captura e/ou promoção, xeque.
      '|(?<![\\w])(?:([a-h])x)?([a-h][1-8])(?:=($piece))?([+#])?'
      r'(?![\w=])',
    );
    final out = StringBuffer();
    final anchors = <_Anchor>[];
    var last = 0;
    for (final m in move.allMatches(text)) {
      final spoken = _say(m, words);
      if (spoken == m[0]) continue;
      out.write(text.substring(last, m.start));
      anchors.add(
        _Anchor(out.length, m.start, out.length + spoken.length, m.end),
      );
      out.write(spoken);
      last = m.end;
    }
    out.write(text.substring(last));
    return SpokenUtterance._(out.toString(), anchors);
  }

  static String _say(RegExpMatch m, _Words words) {
    final long = m[1];
    final short = m[2];
    if (long != null || short != null) {
      return _join(
        long != null ? words.castleLong : words.castleShort,
        _check(words, m[3]),
      );
    }
    final pieceLetter = m[4];
    if (pieceLetter != null) {
      final name = words.pieces[pieceLetter]!;
      final from = m[5]!;
      final dest = m[7]!;
      final action = m[6] != null
          ? '$name ${words.takes} $dest'
          : from.isNotEmpty
          ? words.fromTo(name, from, dest)
          : '$name $dest';
      return _join(action, _check(words, m[8]));
    }
    final dest = m[10]!;
    final promotion = m[11];
    final check = m[12];
    final fromFile = m[9];
    // Uma casa sozinha ("e4") fica como está.
    if (fromFile == null && promotion == null && check == null) {
      return m[0]!;
    }
    var action = fromFile != null ? '$fromFile ${words.takes} $dest' : dest;
    if (promotion != null) {
      action = '$action, ${words.promotes(words.pieces[promotion]!)}';
    }
    return _join(action, _check(words, check));
  }

  static String? _check(_Words words, String? mark) => switch (mark) {
    '+' => words.check,
    '#' => words.mate,
    _ => null,
  };

  static String _join(String action, String? check) =>
      check == null ? action : '$action, $check';

  static final _words = {
    'pt': _Words(
      pieces: const {
        'K': 'rei',
        'R': 'rei',
        'D': 'dama',
        'T': 'torre',
        'B': 'bispo',
        'C': 'cavalo',
      },
      takes: 'toma',
      check: 'xeque',
      mate: 'xeque-mate',
      castleShort: 'roque pequeno',
      castleLong: 'roque grande',
      fromTo: (piece, from, to) => '$piece de $from para $to',
      promotes: (piece) => 'promove a $piece',
    ),
    'en': _Words(
      pieces: const {
        'K': 'king',
        'Q': 'queen',
        'R': 'rook',
        'B': 'bishop',
        'N': 'knight',
      },
      takes: 'takes',
      check: 'check',
      mate: 'checkmate',
      castleShort: 'castles kingside',
      castleLong: 'castles queenside',
      fromTo: (piece, from, to) => '$piece from $from to $to',
      promotes: (piece) => 'promotes to a $piece',
    ),
    'es': _Words(
      pieces: const {
        'R': 'rey',
        'D': 'dama',
        'T': 'torre',
        'A': 'alfil',
        'C': 'caballo',
      },
      takes: 'captura',
      check: 'jaque',
      mate: 'jaque mate',
      castleShort: 'enroque corto',
      castleLong: 'enroque largo',
      fromTo: (piece, from, to) => '$piece de $from a $to',
      promotes: (piece) => 'corona $piece',
    ),
  };
}

/// O texto que vai para a voz e o caminho de volta para o texto da tela.
class SpokenUtterance {
  const SpokenUtterance._(this.text, this._anchors);

  /// O que o sintetizador fala.
  final String text;
  final List<_Anchor> _anchors;

  /// A posição no texto da tela que corresponde a [spoken], uma posição em
  /// [text]. Dentro de um lance convertido, proporcional.
  int displayOffset(int spoken) {
    var shift = 0;
    for (final a in _anchors) {
      if (spoken < a.spokenStart) break;
      if (spoken < a.spokenEnd) {
        final part = (spoken - a.spokenStart) / (a.spokenEnd - a.spokenStart);
        return a.displayStart +
            (part * (a.displayEnd - a.displayStart)).round();
      }
      shift = a.displayEnd - a.spokenEnd;
    }
    return spoken + shift;
  }
}

class _Anchor {
  const _Anchor(
    this.spokenStart,
    this.displayStart,
    this.spokenEnd,
    this.displayEnd,
  );

  final int spokenStart;
  final int displayStart;
  final int spokenEnd;
  final int displayEnd;
}

class _Words {
  const _Words({
    required this.pieces,
    required this.takes,
    required this.check,
    required this.mate,
    required this.castleShort,
    required this.castleLong,
    required this.fromTo,
    required this.promotes,
  });

  final Map<String, String> pieces;
  final String takes;
  final String check;
  final String mate;
  final String castleShort;
  final String castleLong;
  final String Function(String piece, String from, String to) fromTo;
  final String Function(String piece) promotes;
}
