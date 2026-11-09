import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/alerts/region_prompt_repository.dart';

/// Se a folha da região ainda não foi vista.
Future<bool> regionPromptPending(BuildContext context) =>
    context.read<RegionPromptRepository>().pending();

/// Marca a folha da região como vista, com o repositório do [context] lido
/// já na chamada (a folha fecha antes de marcar).
Future<void> Function() regionPromptDoneAction(BuildContext context) =>
    context.read<RegionPromptRepository>().done;
