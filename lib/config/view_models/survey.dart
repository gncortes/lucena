import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/survey/survey_repository.dart';
import '../../domain/models/survey.dart';
import '../../ui/survey/view_models/survey_invite_cubit.dart';

/// O convite para o questionário de [kind].
SurveyInviteCubit createSurveyInviteCubit(
  BuildContext context, {
  required SurveyKind kind,
}) => SurveyInviteCubit(kind: kind, surveys: context.read<SurveyRepository>());
