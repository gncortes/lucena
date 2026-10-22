import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../use_cases/game_rules.dart';
import 'app_links.dart';
import 'clock.dart';
import 'endgame_position.dart';
import 'game_setup.dart';
import 'maia_level.dart';

part 'challenge_link.freezed.dart';

/// O desafio que viaja num link (`playlucena.com/p/<código>?fen=...`): a
/// posição, o objetivo, o lado, o adversário, o relógio e se a configuração
/// fica travada. Quem abre joga a mesma partida contra a máquina.
@freezed
abstract class ChallengeLink with _$ChallengeLink {
  const factory ChallengeLink({
    /// A posição de início.
    required String fen,
    @Default(PositionGoal.win) PositionGoal goal,

    /// O id da posição no catálogo (para o histórico). Nulo: personalizada.
    String? positionId,

    /// O lado de quem joga o desafio.
    required Side userSide,

    /// Só `maia` ou `stockfish`: o desafio é sempre contra a máquina.
    @Default(OpponentKind.maia) OpponentKind opponent,

    /// O nível do Maia. Nulo: o sugerido pelo rating de quem abre.
    int? level,

    /// O tempo dos dois lados. Nulo: sem relógio.
    TimeControl? clock,

    /// Às cegas, sem ver as peças.
    @Default(false) bool blind,

    /// Desafio fechado: dá para ver os dados, não para trocar.
    @Default(false) bool locked,

    /// O que a E1.16 conta por post (`utm_source`, `utm_medium`,
    /// `utm_campaign`, `utm_content`): passa de quem mandou para quem abre.
    /// O link criado no app leva `utm_source=app` (E1.03 §9).
    @Default(<String, String>{}) Map<String, String> utm,

    /// Quantas vezes o link foi repassado (`g`, E1.03 §9): 0 no nosso post,
    /// 1 no link de quem nunca chegou por link, e assim por diante. Fica fora
    /// do código.
    @Default(0) int generation,
  }) = _ChallengeLink;

  const ChallengeLink._();

  /// Os parâmetros que o link carrega, em ordem fixa (o código sai dela).
  static const keys = [
    'fen',
    'goal',
    'pos',
    'side',
    'opp',
    'lvl',
    'clock',
    'blind',
    'lock',
  ];

  /// O parâmetro do Stockfish no link (`opp=sf`).
  static const stockfishCode = 'sf';

  static const _utmKeys = [
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
  ];

  /// O parâmetro da geração no link.
  static const generationKey = 'g';

  /// Os parâmetros do link, sem os `utm_*`.
  Map<String, String> get params => {
    'fen': fen,
    'goal': goal.code,
    'pos': ?positionId,
    'side': userSide.name,
    'opp': opponent == OpponentKind.stockfish ? stockfishCode : 'maia',
    if (opponent == OpponentKind.maia && level != null) 'lvl': '$level',
    if (clock != null) 'clock': clock!.code,
    if (blind) 'blind': '1',
    if (locked) 'lock': '1',
  };

  /// O código curto do link (5 letras e números), tirado dos parâmetros: o
  /// mesmo desafio dá sempre o mesmo código.
  String get code {
    var hash = 0x811c9dc5;
    for (final unit
        in keys.map((key) => '$key=${params[key] ?? ''}').join('&').codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    const alphabet =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final out = StringBuffer();
    for (var i = 0; i < 5; i++) {
      out.write(alphabet[hash % alphabet.length]);
      hash ~/= alphabet.length;
    }
    return out.toString();
  }

  /// O endereço do desafio: `https://playlucena.com/p/<código>?...`.
  Uri get uri => AppLinks.uri('/${AppLinks.challengeSegment}/$code', {
    ...params,
    if (generation > 0) generationKey: '$generation',
    for (final entry in utm.entries)
      if (_utmKeys.contains(entry.key)) entry.key: entry.value,
  });

  /// O link que a pessoa manda de [screen] (`criar_desafio`, `fim_partida`...),
  /// na geração [generation]: marcado como criado no app.
  ChallengeLink sharedFrom(String screen, {required int generation}) =>
      copyWith(
        utm: {
          'utm_source': 'app',
          'utm_medium': 'compartilhar',
          'utm_campaign': screen,
        },
        generation: generation,
      );

  /// O endereço curto, como a tela mostra (`playlucena.com/p/k7Qe2`).
  String get shortAddress =>
      '${AppLinks.host}/${AppLinks.challengeSegment}/$code';

  /// O mesmo desafio sem a trava (a Nova partida preenchida) ou com ela.
  ChallengeLink withLock({required bool locked}) => copyWith(locked: locked);

  /// Lê o desafio de [uri]. Nulo se não for um link de desafio ou se a
  /// posição for inválida. O código do caminho não é conferido: quem manda é
  /// a configuração.
  static ChallengeLink? tryParse(Uri uri) {
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.isEmpty || segments.first != AppLinks.challengeSegment) {
      return null;
    }
    final query = uri.queryParameters;
    final fen = query['fen'];
    if (fen == null) return null;
    final position = GameRules.fromFen(fen);
    if (position == null) return null;
    final opponent = query['opp'] == stockfishCode
        ? OpponentKind.stockfish
        : OpponentKind.maia;
    final level = int.tryParse(query['lvl'] ?? '');
    // Num link escrito à mão o `+` do relógio chega como espaço.
    final clock = TimeControl.tryParse(query['clock']?.replaceAll(' ', '+'));
    return ChallengeLink(
      fen: fen,
      goal: PositionGoal.fromCode(query['goal']) ?? PositionGoal.win,
      positionId: query['pos'],
      userSide: Side.values.asNameMap()[query['side']] ?? position.turn,
      opponent: opponent,
      level: opponent == OpponentKind.maia && level != null
          ? MaiaLevels.nearest(level)
          : null,
      clock: clock,
      blind: query['blind'] == '1',
      locked: query['lock'] == '1',
      utm: {
        for (final key in _utmKeys)
          if (query[key] != null) key: query[key]!,
      },
      generation: int.tryParse(query[generationKey] ?? '') ?? 0,
    );
  }
}
