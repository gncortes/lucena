import 'package:dartchess/dartchess.dart';

/// O material dos dois lados de uma subcategoria, lido do nome dela
/// (`queenVsRookPawn` → dama contra torre e peão). O rei, que os dois lados
/// sempre têm, só aparece no lado que não tem mais nada.
abstract final class SubcategoryMaterial {
  static const _counts = {'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5};

  static const _roles = {
    'queen': Role.queen,
    'rook': Role.rook,
    'bishop': Role.bishop,
    'knight': Role.knight,
    'pawn': Role.pawn,
    'king': Role.king,
  };

  // A ordem em que as peças aparecem, da mais forte para a mais fraca.
  static const _order = [
    Role.king,
    Role.queen,
    Role.rook,
    Role.bishop,
    Role.knight,
    Role.pawn,
  ];

  /// As peças de cada lado. Sem "vs" no nome (subcategorias básicas, como
  /// `twoRooks`), o segundo lado é o rei sozinho.
  static (List<Role>, List<Role>) of(String key) {
    final words = RegExp(r'[A-Z]?[a-z]+')
        .allMatches(key)
        .map((match) => match.group(0)!.toLowerCase())
        .toList();
    final split = words.indexOf('vs');
    final first = split == -1 ? words : words.sublist(0, split);
    final second = split == -1 ? const <String>[] : words.sublist(split + 1);
    return (_side(first), _side(second));
  }

  static List<Role> _side(List<String> words) {
    final roles = <Role>[];
    var count = 1;
    for (final word in words) {
      if (_counts[word] case final value?) {
        count = value;
        continue;
      }
      // Plural: `rooks`, `pawns`.
      final singular = word.endsWith('s')
          ? word.substring(0, word.length - 1)
          : word;
      final role = _roles[singular];
      if (role == null) continue;
      roles.addAll(List.filled(count, role));
      count = 1;
    }
    if (roles.isEmpty) return const [Role.king];
    if (roles.length > 1) roles.remove(Role.king);
    roles.sort((a, b) => _order.indexOf(a).compareTo(_order.indexOf(b)));
    return roles;
  }
}
