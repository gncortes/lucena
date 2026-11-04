import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/frentes/d2_routes.dart';
import '../view_models/pilares_purchase_watch_cubit.dart';

/// Abre as telas da compra por cima do app (Concluída, Assinatura encerrada)
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

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
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
          null => null,
        },
        child: widget.child,
      );
}
