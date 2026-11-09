import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/store/store_listing_repository.dart';
import '../../ui/settings/view_models/settings_account_cubit.dart';

/// A conta na linha da pessoa das Configurações.
SettingsAccountCubit createSettingsAccountCubit(BuildContext context) =>
    SettingsAccountCubit(context.read<AccountRepository>());

/// "Avaliar o app": abre a página do app na loja.
Future<void> openStoreListing(BuildContext context) =>
    context.read<StoreListingRepository>().open();
