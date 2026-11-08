import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/account.dart';
import '../../core/widgets/load_error.dart';
import '../view_models/account_cubit.dart';

/// Criar a conta sem internet (H-CON-09): a tela de erro padrão por cima da
/// entrada, com "Tentar novamente" (repete a entrada) e "Voltar" (volta a
/// ela). Outra falha na nova tentativa troca para o erro genérico.
class AccountFailureGate extends StatelessWidget {
  const AccountFailureGate({required this.child, this.message, super.key});

  final Widget child;

  /// O texto do caso sem rede; nulo: o padrão do erro sem internet.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final failure = context.select(
      (AccountCubit cubit) => cubit.state.screenFailure,
    );
    if (failure == null) return child;
    final cubit = context.read<AccountCubit>();
    final offline = failure == AccountFailure.network;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cubit.dismissFailure();
      },
      child: LoadErrorScreen(
        kind: offline ? LoadErrorKind.offline : LoadErrorKind.generic,
        message: offline ? message : null,
        onAction: cubit.retry,
        onBack: cubit.dismissFailure,
      ),
    );
  }
}
