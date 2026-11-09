import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/data_export/data_export_repository.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/privacy/view_models/data_export_cubit.dart';

/// "Baixar seus dados?" da conta [uid].
DataExportCubit createDataExportCubit(
  BuildContext context, {
  required String uid,
}) => DataExportCubit(
  uid: uid,
  exports: context.read<DataExportRepository>(),
  analytics: context.analytics,
);
