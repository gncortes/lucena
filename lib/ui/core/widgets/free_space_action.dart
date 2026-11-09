import 'package:flutter/material.dart';

import '../../../config/view_models/free_space.dart';

/// "Liberar espaço" do erro de falta de espaço: abre o armazenamento do
/// celular nos ajustes do sistema. Nulo fora do Android (o botão some).
VoidCallback? freeSpaceAction(BuildContext context) {
  if (Theme.of(context).platform != TargetPlatform.android) return null;
  return openStorageSettings;
}
