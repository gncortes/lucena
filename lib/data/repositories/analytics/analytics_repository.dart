import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/analytics_rules.dart';
import '../../services/firebase/analytics_service.dart';
import '../../services/preferences_service.dart';

/// O último link pelo qual a pessoa chegou (E1.03 §9): preenche a `geracao`
/// e o `codigo_pai` do próximo link que ela criar.
class LinkTrail {
  const LinkTrail({required this.code, required this.generation});

  final String code;
  final int generation;

  /// A geração do link que a pessoa cria agora: a do que a trouxe mais 1, ou
  /// 1 se ela não chegou por link.
  static int next(LinkTrail? from) => from == null ? 1 : from.generation + 1;
}

/// As estatísticas de uso (E1.03). Os view models só falam com este
/// repositório; o que sai, quando sai e para quem é decidido aqui.
abstract class AnalyticsRepository {
  /// Lê as chaves do aparelho e liga ou desliga a coleta. Chamado na abertura.
  Future<void> start();

  /// Se este build mede alguma coisa (F-Droid, debug e Patrol: não).
  bool get measures;

  /// A chave "Ajudar a melhorar o Lucena" (ligada por padrão).
  Future<bool> enabled();

  Future<void> setEnabled(bool enabled);

  /// O Modo equipe (§10): o uso deste aparelho não conta e os anúncios são
  /// de teste.
  Future<bool> teamMode();

  Future<void> setTeamMode(bool team);

  Future<void> log(AnalyticsEvent event);

  /// Grava a propriedade só quando o valor muda.
  Future<void> setTrait(AnalyticsTrait trait, String value);

  /// A origem da 1ª abertura (`origem_*`), uma vez só. Verdadeiro: era a 1ª
  /// abertura e a origem foi gravada agora.
  Future<bool> recordOrigin({
    required String first,
    String? source,
    String? campaign,
    String? post,
    String? link,
  });

  /// A `origem_primeira` gravada na 1ª abertura (o `origin` do feedback).
  /// Nula antes dela.
  Future<String?> origin();

  Future<LinkTrail?> lastLink();

  Future<void> rememberLink(LinkTrail link);

  /// O `screen_view` da rota (só o nome, nunca o id).
  Future<void> screen(String route);

  /// O consentimento do UMP (E1.25) no Consent Mode.
  Future<void> setConsent({required bool analytics, required bool ads});
}

/// Sem estatística nenhuma (testes e builds sem Firebase).
class NoAnalyticsRepository implements AnalyticsRepository {
  const NoAnalyticsRepository();

  @override
  Future<void> start() async {}

  @override
  bool get measures => false;

  @override
  Future<bool> enabled() async => true;

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<bool> teamMode() async => false;

  @override
  Future<void> setTeamMode(bool team) async {}

  @override
  Future<void> log(AnalyticsEvent event) async {}

  @override
  Future<void> setTrait(AnalyticsTrait trait, String value) async {}

  @override
  Future<bool> recordOrigin({
    required String first,
    String? source,
    String? campaign,
    String? post,
    String? link,
  }) async => false;

  @override
  Future<String?> origin() async => null;

  @override
  Future<LinkTrail?> lastLink() async => null;

  @override
  Future<void> rememberLink(LinkTrail link) async {}

  @override
  Future<void> screen(String route) async {}

  @override
  Future<void> setConsent({required bool analytics, required bool ads}) async {}
}

class ServiceAnalyticsRepository implements AnalyticsRepository {
  ServiceAnalyticsRepository(
    this._service,
    this._preferences, {
    this.mode = AnalyticsMode.normal,
  });

  static const enabledKey = 'analytics.v1.enabled';
  static const teamKey = 'analytics.v1.team';
  static const originKey = 'analytics.v1.origin';
  static const lastLinkKey = 'analytics.v1.last_link';
  static const traitsKey = 'analytics.v1.traits';

  final AnalyticsService _service;
  final PreferencesService _preferences;
  final AnalyticsMode mode;

  bool _enabled = true;
  bool _team = false;
  Map<String, String> _traits = {};
  late final Future<void> _loaded = _load();

  Future<void> _load() async {
    _enabled = await _preferences.getBool(enabledKey) ?? true;
    _team = await _preferences.getBool(teamKey) ?? false;
    final saved = await _preferences.getString(traitsKey);
    if (saved != null) {
      _traits = (jsonDecode(saved) as Map<String, dynamic>).cast();
    }
  }

  bool get _collects =>
      _service.available &&
      AnalyticsRules.collects(mode, optIn: _enabled, team: _team);

  @override
  bool get measures => mode != AnalyticsMode.off && _service.available;

  @override
  Future<void> start() async {
    await _loaded;
    await _safely(() => _service.setCollectionEnabled(_collects));
  }

  @override
  Future<bool> enabled() async {
    await _loaded;
    return _enabled;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _loaded;
    if (enabled == _enabled) return;
    if (!enabled) {
      // O último evento conta que a pessoa desligou; depois, nada mais sai.
      await log(AnalyticsEvents.privacidadeAnalytics(ligado: false));
      _enabled = false;
      await _stop();
    } else {
      _enabled = true;
      await _safely(() => _service.setCollectionEnabled(_collects));
      await log(AnalyticsEvents.privacidadeAnalytics(ligado: true));
    }
    await _preferences.setBool(enabledKey, value: enabled);
  }

  @override
  Future<bool> teamMode() async {
    await _loaded;
    return _team;
  }

  @override
  Future<void> setTeamMode(bool team) async {
    await _loaded;
    if (team == _team) return;
    _team = team;
    await _preferences.setBool(teamKey, value: team);
    if (team) {
      await _stop();
    } else {
      await _safely(() => _service.setCollectionEnabled(_collects));
    }
  }

  /// Desliga a coleta, zera os dados do aparelho e esquece as propriedades
  /// enviadas (se voltar a ligar, vão de novo).
  Future<void> _stop() async {
    await _safely(() => _service.setCollectionEnabled(false));
    await _safely(_service.resetData);
    _traits = {};
    await _preferences.remove(traitsKey);
  }

  @override
  Future<void> log(AnalyticsEvent event) async {
    await _loaded;
    if (!_collects) return;
    final params = AnalyticsRules.sanitize(event.name, {
      ...event.params,
      if (mode == AnalyticsMode.internal)
        AnalyticsCatalog.trafficType: 'internal',
    });
    if (params == null) {
      debugPrint('Evento fora das regras do Analytics: ${event.name}');
      return;
    }
    await _safely(() => _service.logEvent(event.name, params));
  }

  @override
  Future<void> setTrait(AnalyticsTrait trait, String value) async {
    await _loaded;
    if (!_collects) return;
    final cut = AnalyticsRules.traitValue(trait.code, value);
    if (cut == null || _traits[trait.code] == cut) return;
    _traits[trait.code] = cut;
    await _safely(() => _service.setUserProperty(trait.code, cut));
    await _preferences.setString(traitsKey, jsonEncode(_traits));
  }

  @override
  Future<bool> recordOrigin({
    required String first,
    String? source,
    String? campaign,
    String? post,
    String? link,
  }) async {
    if (await _preferences.getString(originKey) != null) return false;
    await _preferences.setString(originKey, first);
    await setTrait(AnalyticsTrait.firstOrigin, first);
    await setTrait(AnalyticsTrait.originSource, source ?? 'direto');
    await setTrait(AnalyticsTrait.originCampaign, campaign ?? 'direto');
    await setTrait(AnalyticsTrait.originPost, post ?? AnalyticsRules.none);
    await setTrait(AnalyticsTrait.originLink, link ?? AnalyticsRules.none);
    return true;
  }

  @override
  Future<String?> origin() => _preferences.getString(originKey);

  @override
  Future<LinkTrail?> lastLink() async {
    final saved = await _preferences.getString(lastLinkKey);
    if (saved == null) return null;
    final json = jsonDecode(saved) as Map<String, dynamic>;
    return LinkTrail(
      code: json['code'] as String,
      generation: json['generation'] as int,
    );
  }

  @override
  Future<void> rememberLink(LinkTrail link) => _preferences.setString(
    lastLinkKey,
    jsonEncode({'code': link.code, 'generation': link.generation}),
  );

  @override
  Future<void> screen(String route) => log(AnalyticsEvents.screenView(route));

  @override
  Future<void> setConsent({required bool analytics, required bool ads}) =>
      _safely(() => _service.setConsent(analytics: analytics, ads: ads));

  /// O Analytics nunca derruba uma tela: o erro só vai para o log.
  static Future<void> _safely(Future<void> Function() call) async {
    try {
      await call();
    } on Object catch (error) {
      debugPrint('Analytics: $error');
    }
  }
}
