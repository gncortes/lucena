/// Como o build trata as estatísticas de uso (E1.03 §10).
enum AnalyticsMode {
  /// Nada sai: debug, profile, Patrol e F-Droid.
  off,

  /// Sai marcado com `traffic_type=internal` (QA e debug com DebugView).
  internal,

  /// Sai normal (Play).
  normal,
}

/// As regras puras do Analytics (E1.03): os limites do Firebase, as faixas e
/// os códigos que vão nos parâmetros. Nada de dado pessoal sai daqui.
abstract final class AnalyticsRules {
  /// Limites do Firebase.
  static const maxNameLength = 40;
  static const maxParams = 25;
  static const maxValueLength = 100;
  static const maxTraitNameLength = 24;
  static const maxTraitValueLength = 36;

  static const reservedPrefixes = ['firebase_', 'google_', 'ga_'];
  static final _name = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');

  /// O valor de "sem nada" das propriedades e parâmetros.
  static const none = 'nenhum';

  /// Nome de evento ou parâmetro aceito pelo Firebase.
  static bool validName(String name, {int max = maxNameLength}) =>
      name.length <= max &&
      _name.hasMatch(name) &&
      !reservedPrefixes.any(name.startsWith);

  /// Os parâmetros como o Firebase aceita: sem nulos, `bool` em `sim|nao`,
  /// texto com até 100 caracteres. Nulo: o evento é rejeitado (nome ruim ou
  /// parâmetros demais).
  static Map<String, Object>? sanitize(
    String name,
    Map<String, Object?> params,
  ) {
    if (!validName(name)) return null;
    final out = <String, Object>{};
    for (final MapEntry(:key, :value) in params.entries) {
      if (value == null) continue;
      if (!validName(key)) return null;
      out[key] = switch (value) {
        final bool flag => yesNo(flag),
        final num number => number,
        final Duration time => seconds(time),
        final Object other => _cut(other.toString(), maxValueLength),
      };
    }
    if (out.length > maxParams) return null;
    return out;
  }

  /// O valor da propriedade de usuário, cortado em 36 caracteres. Nulo: nome
  /// que o Firebase não aceita.
  static String? traitValue(String name, String value) =>
      validName(name, max: maxTraitNameLength)
      ? _cut(value, maxTraitValueLength)
      : null;

  static String _cut(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);

  static String yesNo(bool value) => value ? 'sim' : 'nao';

  static int seconds(Duration time) => time.inSeconds;

  /// A faixa do rating: `ate_800`, `800_1199`, `1200_1599`, `1600_1999`,
  /// `2000_mais`; sem rating, `nenhum`.
  static String ratingBand(int? rating) => switch (rating) {
    null => none,
    < 800 => 'ate_800',
    < 1200 => '800_1199',
    < 1600 => '1200_1599',
    < 2000 => '1600_1999',
    _ => '2000_mais',
  };

  /// A faixa da sequência de dias: `0`, `1_2`, `3_6`, `7_13`, `14_mais`.
  static String streakBand(int days) => switch (days) {
    <= 0 => '0',
    <= 2 => '1_2',
    <= 6 => '3_6',
    <= 13 => '7_13',
    _ => '14_mais',
  };

  /// Quantas aulas de finais concluiu: `0`, `1_2`, `3_5`, `6`.
  static String lessonsBand(int count) => switch (count) {
    <= 0 => '0',
    <= 2 => '1_2',
    <= 5 => '3_5',
    _ => '6',
  };

  /// O tamanho do feedback, sem o texto: `ate_50`, `51_200`, `201_500`.
  static String lengthBand(int characters) => switch (characters) {
    <= 50 => 'ate_50',
    <= 200 => '51_200',
    _ => '201_500',
  };

  /// O valor do preço da Play (`R\$ 9,90`, `9.90`), para o `purchase`. Nulo
  /// sem número.
  static double? priceValue(String? price) {
    final digits = price?.replaceAll(RegExp(r'[^0-9,.]'), '') ?? '';
    if (digits.isEmpty) return null;
    // A última vírgula ou ponto é a dos centavos.
    final cut = digits.lastIndexOf(RegExp('[,.]'));
    final whole = cut < 0 ? digits : digits.substring(0, cut);
    final cents = cut < 0 ? '' : digits.substring(cut + 1);
    return double.tryParse(
      '${whole.replaceAll(RegExp('[,.]'), '')}.${cents.isEmpty ? '0' : cents}',
    );
  }

  /// O id da posição: o do catálogo ou `custom_<8 hex do FEN>`. O FEN nunca
  /// sai.
  static String positionId(String? catalogId, String fen) {
    if (catalogId != null && catalogId.isNotEmpty) return catalogId;
    var hash = 0x811c9dc5;
    for (final unit in fen.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 'custom_${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// A UF em maiúsculas, ou `nenhum`. Cidade nunca.
  static String stateOrNone(String? state) {
    final code = state?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : none;
  }

  /// O país (ISO de 2 letras), ou `nenhum`.
  static String countryOrNone(String? country) => stateOrNone(country);

  /// O `utm_source` que o próprio app põe nos links que a pessoa cria.
  static const appSource = 'app';

  /// `organico` para o link criado no app, `nosso` para o que postamos.
  static String linkOrigin(String? utmSource) =>
      utmSource == appSource ? 'organico' : 'nosso';

  /// A fonte de quem chega por um post nosso. O link criado no app não é
  /// campanha: não entra como fonte (`organico` fica em `origem_link`).
  static String? campaignValue(Map<String, String> utm, String key) =>
      utm['utm_source'] == appSource ? null : utm[key]?.toLowerCase();

  /// O modo do build (§10): F-Droid e Patrol nunca medem; fora do release só
  /// com o DebugView pedido; a QA sai marcada como da equipe.
  static AnalyticsMode mode({
    required bool release,
    bool e2e = false,
    bool fdroid = false,
    bool debugView = false,
    String channel = '',
  }) {
    if (fdroid || e2e) return AnalyticsMode.off;
    if (!release) return debugView ? AnalyticsMode.internal : AnalyticsMode.off;
    return channel == 'qa' ? AnalyticsMode.internal : AnalyticsMode.normal;
  }

  /// Se a coleta liga: o build mede, a chave "Ajudar a melhorar o Lucena"
  /// está ligada e o aparelho não está no Modo equipe.
  static bool collects(
    AnalyticsMode mode, {
    required bool optIn,
    required bool team,
  }) => mode != AnalyticsMode.off && optIn && !team;

  static final _fen = RegExp(r'([1-8pnbrqkPNBRQK]{1,8}/){3,}');
  static final _email = RegExp(r'[^\s@]+@[^\s@]+\.[^\s@]+');
  static final _token = RegExp(r'^[A-Za-z0-9._\-]{32,}$');

  /// Se [value] parece dado pessoal: FEN, e-mail, token ou texto livre (mais
  /// de 3 palavras). Os testes varrem todo evento com esta regra.
  static bool looksPersonal(Object value) {
    if (value is! String) return false;
    if (_fen.hasMatch(value) || _email.hasMatch(value)) return true;
    if (_token.hasMatch(value) && value.contains(RegExp(r'\d'))) return true;
    return value.trim().split(RegExp(r'\s+')).length > 3;
  }
}
