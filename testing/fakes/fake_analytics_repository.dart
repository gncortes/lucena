import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/domain/models/analytics_event.dart';

/// Um Analytics que só anota: os eventos, as propriedades e as chaves.
class FakeAnalyticsRepository implements AnalyticsRepository {
  FakeAnalyticsRepository({
    this.optIn = true,
    this.team = false,
    this.trail,
    this.firstOpen = true,
  });

  bool optIn;
  bool team;

  /// O último link aberto.
  LinkTrail? trail;

  /// O que [recordOrigin] responde da próxima vez.
  bool firstOpen;

  final List<AnalyticsEvent> events = [];
  final Map<AnalyticsTrait, String> traits = {};
  final List<String> screens = [];
  ({bool analytics, bool ads})? consent;
  int resets = 0;
  bool started = false;

  /// Os eventos com o nome [name], na ordem em que saíram.
  List<AnalyticsEvent> eventsNamed(String name) =>
      events.where((event) => event.name == name).toList();

  /// Os nomes, na ordem.
  List<String> get names => [for (final event in events) event.name];

  @override
  Future<void> start() async => started = true;

  @override
  bool get measures => true;

  @override
  Future<bool> enabled() async => optIn;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled == optIn) return;
    if (!enabled) {
      events.add(AnalyticsEvents.privacidadeAnalytics(ligado: false));
      resets++;
      traits.clear();
    }
    optIn = enabled;
    if (enabled) events.add(AnalyticsEvents.privacidadeAnalytics(ligado: true));
  }

  @override
  Future<bool> teamMode() async => team;

  @override
  Future<void> setTeamMode(bool team) async {
    if (team && !this.team) resets++;
    this.team = team;
  }

  @override
  Future<void> log(AnalyticsEvent event) async => events.add(event);

  @override
  Future<void> setTrait(AnalyticsTrait trait, String value) async =>
      traits[trait] = value;

  @override
  Future<bool> recordOrigin({
    required String first,
    String? source,
    String? campaign,
    String? post,
    String? link,
  }) async {
    if (!firstOpen) return false;
    firstOpen = false;
    traits[AnalyticsTrait.firstOrigin] = first;
    traits[AnalyticsTrait.originSource] = source ?? 'direto';
    traits[AnalyticsTrait.originCampaign] = campaign ?? 'direto';
    traits[AnalyticsTrait.originPost] = post ?? 'nenhum';
    traits[AnalyticsTrait.originLink] = link ?? 'nenhum';
    return true;
  }

  @override
  Future<LinkTrail?> lastLink() async => trail;

  @override
  Future<String?> origin() async => traits[AnalyticsTrait.firstOrigin];

  @override
  Future<void> rememberLink(LinkTrail link) async => trail = link;

  @override
  Future<void> screen(String route) async => screens.add(route);

  @override
  Future<void> setConsent({required bool analytics, required bool ads}) async =>
      consent = (analytics: analytics, ads: ads);
}
