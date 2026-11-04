import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/device/device_settings_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/load_failure.dart';

class PrivacyState {
  const PrivacyState({this.ready = false, this.account, this.failure});

  final bool ready;
  final LoadFailure? failure;

  /// A conta de agora (nula: sem conta).
  final Account? account;

  /// "Baixar meus dados" e "Excluir minha conta" só com conta.
  bool get hasAccount => account != null;

  @override
  bool operator ==(Object other) =>
      other is PrivacyState &&
      other.ready == ready &&
      other.failure == failure &&
      other.account == account;

  @override
  int get hashCode => Object.hash(ready, account, failure);
}

/// Privacidade e dados (H-CON-20): acompanha a conta e abre as telas de
/// permissão do sistema.
class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit({required this._accounts, required this._device})
    : super(const PrivacyState());

  final AccountRepository _accounts;
  final DeviceSettingsRepository _device;
  StreamSubscription<Account?>? _subscription;

  Future<void> load() async {
    try {
      _subscription ??= _accounts.changes.listen(_show, onError: _failed);
      _show(_accounts.current);
    } on Object catch (error, stack) {
      _failed(error, stack);
    }
  }

  void _show(Account? account) {
    if (isClosed) return;
    emit(PrivacyState(ready: true, account: account));
  }

  /// Gap 3: a leitura falha e a tela mostra o erro padrão.
  void _failed(Object error, StackTrace stack) {
    debugPrint('privacy load failed: $error');
    reportHandledError(error, stack);
    if (isClosed) return;
    emit(
      PrivacyState(
        ready: state.ready,
        account: state.account,
        failure: LoadFailure.generic,
      ),
    );
  }

  Future<void> openNotifications() => _device.openNotifications();

  Future<void> openMicrophone() => _device.openAppPermissions();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
