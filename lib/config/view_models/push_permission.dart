import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/push/push_repository.dart';
import '../../ui/course_guide/view_models/push_permission_cubit.dart';

/// A permissão de avisos com o push do [context]; sem push na árvore (teste de
/// tela), o aviso não aparece.
PushPermissionCubit createPushPermissionCubit(BuildContext context) {
  PushRepository? push;
  try {
    push = context.read<PushRepository>();
  } on ProviderNotFoundException {
    push = null;
  }
  return PushPermissionCubit(push);
}
