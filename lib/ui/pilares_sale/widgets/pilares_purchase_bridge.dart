import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../view_models/pilares_purchase_watch_cubit.dart';

/// Abre as telas da compra por cima do app (Curso liberado, Assinatura
/// encerrada)
/// e consulta a loja ao voltar do segundo plano (H-VEN-05/06/10).
class PilaresPurchaseBridge extends StatefulWidget {
  const PilaresPurchaseBridge({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<PilaresPurchaseBridge> createState() => _PilaresPurchaseBridgeState();
}

class _PilaresPurchaseBridgeState extends State<PilaresPurchaseBridge> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () =>
        unawaited(context.read<PilaresPurchaseWatchCubit>().resumed()),
  );

  /// O Curso liberado pedido durante a entrada na conta.
  String? _pending;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    widget.router.routerDelegate.addListener(_routeChanged);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_routeChanged);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<PilaresPurchaseWatchCubit, PurchaseWatchState>(
        listenWhen: (a, b) => a.id != b.id,
        listener: (context, state) => switch (state.screen) {
          // Concluída toma o lugar de tudo: voltar dela vai ao Início.
          PurchaseScreen.done => widget.router.go(D2Paths.pilaresPurchaseDone),
          PurchaseScreen.ended => unawaited(
            widget.router.push(D2Paths.pilaresSubscriptionEnded),
          ),
          // O curso dado pelo servidor vem por cima; o X volta (H-R5-62).
          PurchaseScreen.gift => _unlocked(D2Paths.pilaresGiftDone),
          PurchaseScreen.granted => _unlocked(D2Paths.pilaresPurchaseDone),
          null => null,
        },
        child: widget.child,
      );

  // O `uri` da pilha fica na base quando a tela é empilhada (push).
  String get _top =>
      widget.router.routerDelegate.currentConfiguration.last.matchedLocation;

  // A entrada na conta termina com `go`, que limpa a pilha: a tela empilhada
  // durante ela sumiria (r3). Espera a entrada acabar.
  bool get _signingIn =>
      _top == Routes.accountEnter || _top.startsWith('${Routes.accountEnter}/');

  void _routeChanged() {
    final path = _pending;
    if (path == null || _signingIn) return;
    _pending = null;
    // O router ainda está aplicando o `go`: um push agora se perde.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unlocked(path);
    });
  }

  // O toque no push do presente já abre o Curso liberado (H-R5-63): não
  // empilha outro sobre ele nem sobre "Abrindo o seu presente…". O visto só
  // é marcado com a tela aberta.
  void _unlocked(String path) {
    if (_signingIn) {
      _pending = path;
      return;
    }
    if (!const {
      D2Paths.pilaresGiftOpening,
      D2Paths.pilaresGiftDone,
      D2Paths.pilaresPurchaseDone,
    }.contains(_top)) {
      unawaited(widget.router.push(path));
    }
    unawaited(context.read<PilaresPurchaseWatchCubit>().unlockedShown());
  }
}
