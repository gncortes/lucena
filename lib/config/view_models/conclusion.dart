import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/account/account_invite_repository.dart';
import '../../data/repositories/account/account_repository.dart';
import '../../ui/conclusion/view_models/conclusion_invite_cubit.dart';

/// O convite da conta no fim da partida. Sem [AccountInviteRepository] acima
/// (uma tela montada sozinha num teste), nunca convida.
ConclusionInviteCubit createConclusionInviteCubit(BuildContext context) {
  final AccountInviteRepository invite;
  try {
    invite = context.read<AccountInviteRepository>();
  } on ProviderNotFoundException {
    return ConclusionInviteCubit();
  }
  return ConclusionInviteCubit(
    accounts: context.read<AccountRepository>(),
    invite: invite,
  );
}
