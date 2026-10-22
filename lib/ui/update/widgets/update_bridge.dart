import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/update_policy.dart';
import '../../../routing/routes.dart';
import '../../core/keys/update_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/update_cubit.dart';

/// Abre a atualização recomendada quando a pessoa está na home (nunca no
/// meio de partida, aula ou exercício) e avisa quando a versão nova baixou
/// com a tela já fechada.
class UpdateBridge extends StatefulWidget {
  const UpdateBridge({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  State<UpdateBridge> createState() => _UpdateBridgeState();
}

class _UpdateBridgeState extends State<UpdateBridge> {
  StreamSubscription<UpdateState>? _states;
  bool _noticeShown = false;

  @override
  void initState() {
    super.initState();
    _states = context.read<UpdateCubit>().stream.listen(_changed);
    widget.router.routerDelegate.addListener(_maybeRecommend);
    _maybeRecommend();
  }

  @override
  void didUpdateWidget(UpdateBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router == widget.router) return;
    oldWidget.router.routerDelegate.removeListener(_maybeRecommend);
    widget.router.routerDelegate.addListener(_maybeRecommend);
  }

  @override
  void dispose() {
    unawaited(_states?.cancel());
    widget.router.routerDelegate.removeListener(_maybeRecommend);
    super.dispose();
  }

  // A tela do topo, empilhada ou não (o `uri` fica na de baixo do push).
  String get _location {
    final delegate = widget.router.routerDelegate;
    if (delegate.currentConfiguration.isEmpty) return '';
    return delegate.state.matchedLocation;
  }

  void _changed(UpdateState state) {
    _maybeRecommend();
    if (state.ready && !_noticeShown) _notifyReady();
  }

  void _maybeRecommend() {
    final cubit = context.read<UpdateCubit>();
    final state = cubit.state;
    if (state.decision != UpdateDecision.recommended || state.shown) return;
    if (_location != Routes.home) return;
    unawaited(cubit.recommendedShown());
    // Fora da notificação do roteador, que não aceita navegar dentro dela.
    unawaited(
      Future.microtask(() {
        if (mounted) unawaited(widget.router.push(Routes.updateRecommended));
      }),
    );
  }

  // Na própria tela, o botão já virou "Pronto. Reiniciar o Lucena".
  void _notifyReady() {
    if (_location == Routes.updateRecommended) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _noticeShown = true;
    final cubit = context.read<UpdateCubit>();
    messenger.showSnackBar(
      SnackBar(
        key: UpdateKeys.readyNotice,
        duration: const Duration(days: 1),
        content: GestureDetector(
          onTap: cubit.restart,
          child: Text(context.l10n.updateReadyRestart),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
