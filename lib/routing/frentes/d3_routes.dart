import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/training/course_training_repository.dart'
    as course_training;
import '../../domain/use_cases/now.dart';
import '../../ui/school_graduation/view_models/school_graduation_cubit.dart';
import '../../ui/school_graduation/widgets/school_graduation_screen.dart';
import '../route_names.dart';
import '../router.dart' show appRoute;

/// Telas novas da frente D3 (Abertura + Início + Iniciante, T85). A frente registra as rotas na
/// lista [d3Routes] com `appRoute(name: RouteNames.x, path: D3Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D3Paths {
  /// Entrar sem conta, o portão da Escola (H-ESC-18).
  static const schoolGate = '/school/gate';

  /// Formatura da Escola (H-ESC-22).
  static const schoolGraduation = '/school/graduation';
}

final List<RouteBase> d3Routes = [
  // Formatura da Escola (H-ESC-22): o diploma depois da última lição.
  appRoute(
    name: RouteNames.schoolGraduation,
    path: D3Paths.schoolGraduation,
    builder: (context, state) => BlocProvider(
      create: (context) => SchoolGraduationCubit(
        repository: context.read<course_training.TrainingRepository>(),
        now: context.read<Now>(),
      )..load(),
      child: const SchoolGraduationScreen(),
    ),
  ),
];
