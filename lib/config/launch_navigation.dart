import 'dart:async';

import 'package:go_router/go_router.dart';

import '../data/repositories/analytics/analytics_opening.dart';
import '../data/repositories/deep_link/deep_link_repository.dart';
import '../domain/models/campaign.dart';
import '../domain/models/linked_lesson.dart';
import '../domain/models/push_alert.dart';
import '../domain/use_cases/resolve_launch_destination.dart';
import '../routing/frentes/d2_routes.dart';
import '../routing/push_route.dart';
import '../routing/routes.dart';
import 'dependencies.dart';

/// O que o app abre por cima da primeira tela: o erro do link inválido, o
/// presente e a tela do aviso tocado com o app fechado, e os links e avisos
/// que chegam com o app aberto.
class LaunchNavigation {
  LaunchNavigation(
    this._dependencies, {
    required this._analytics,
    required this._router,
    required this._mounted,
  });

  final Dependencies _dependencies;
  final AnalyticsOpening _analytics;
  final GoRouter? Function() _router;
  final bool Function() _mounted;

  // Os desafios que chegam por link com o app aberto.
  StreamSubscription<Uri>? _links;

  // Os avisos de push tocados com o app em segundo plano.
  StreamSubscription<PushOpening>? _pushLinks;

  /// A primeira tela [destination] acabou de ganhar o roteador.
  Future<void> opened(LaunchDestination destination) async {
    if (destination.invalidLinkOnTop) _openInvalidLink();
    _listen();
    final pushOpening = destination.facts.pushOpening;
    if (pushOpening != null) unawaited(_analytics.pushOpened(pushOpening));
    switch (destination.followUp) {
      case LaunchFollowUp.gift:
        if (!_giftOnStack) unawaited(_router()?.push(_giftRoute(pushOpening)!));
      case LaunchFollowUp.pushedScreen:
        await _openPushed(pushOpening!.link!);
      case LaunchFollowUp.none:
        break;
    }
  }

  // Espera o roteador montar a retomada antes de empilhar o erro.
  void _openInvalidLink() {
    final router = _router()!;
    void openInvalid() {
      if (!_mounted() || router.routerDelegate.currentConfiguration.isEmpty) {
        return;
      }
      router.routerDelegate.removeListener(openInvalid);
      router.push(Routes.invalidLink);
    }

    router.routerDelegate.addListener(openInvalid);
    openInvalid();
  }

  void _listen() {
    final deepLinks = _dependencies.deepLinkRepository;
    _links ??= deepLinks.openedUris.listen((uri) {
      final link = deepLinks.parse(uri);
      if (link != null) unawaited(_analytics.opened(link));
      final lessonLink = LessonLink.tryParse(uri);
      if (lessonLink != null) {
        unawaited(
          _analytics.campaignOpened(Campaign.fromLessonLink(lessonLink)),
        );
      }
      final route = Routes.appLink(uri);
      if (route != null) _router()?.push(route);
    });
    // Um aviso pode trazer o link de um desafio ou o de uma tela (final do
    // dia, aula, final ou torneio).
    _pushLinks ??= _dependencies.pushRepository.opened.listen((opening) {
      unawaited(_analytics.pushOpened(opening));
      // O presente abre por cima da tela atual (H-R5-63).
      if (_giftRoute(opening) case final route?) {
        if (!_giftOnStack) unawaited(_router()?.push(route));
        return;
      }
      final uri = opening.link;
      // Sem link: o toque só traz o app para a frente.
      if (uri == null) return;
      final link = deepLinks.parse(uri);
      if (link != null) {
        unawaited(_analytics.opened(link));
        _router()?.push(Routes.challenge(link));
      } else {
        unawaited(_openPushed(uri));
      }
    });
  }

  // O acesso chegou ao vivo antes do toque: o Curso liberado (ou a abertura
  // dele) já está na pilha e não sai outro.
  bool get _giftOnStack =>
      _router()?.routerDelegate.currentConfiguration.matches.any(
        (match) => const {
          D2Paths.pilaresGiftOpening,
          D2Paths.pilaresGiftDone,
          D2Paths.pilaresPurchaseDone,
        }.contains(match.matchedLocation),
      ) ??
      false;

  // O toque no push do presente: "Abrindo o seu presente…" (H-R5-63).
  static String? _giftRoute(PushOpening? opening) =>
      opening != null && opening.isGift
      ? D2Paths.giftOpening(
          course: opening.course!,
          uid: opening.uid,
          account: opening.account,
        )
      : null;

  // A tela do link do aviso; sem destino, o usuário fica onde está: trocar a
  // pilha tiraria da partida e apagaria a retomada.
  Future<void> _openPushed(Uri uri) async {
    final route = await pushRoute(
      uri,
      // O idioma só muda o título da aula, que o toque não usa.
      pausedLesson: () => _dependencies.remindersRepository.pausedLesson('pt'),
    );
    if (!_mounted()) return;
    if (route != null) _router()?.push(route);
  }

  void dispose() {
    unawaited(_links?.cancel());
    unawaited(_pushLinks?.cancel());
  }
}
