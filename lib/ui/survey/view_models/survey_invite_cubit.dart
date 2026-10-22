import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/survey/survey_repository.dart';
import '../../../domain/models/survey.dart';
import '../../../domain/use_cases/survey_rules.dart';

/// Se o convite de [kind] aparece: enquanto não há resposta enviada.
class SurveyInviteCubit extends Cubit<bool> {
  SurveyInviteCubit({required this.kind, required this.surveys}) : super(false);

  final SurveyKind kind;
  final SurveyRepository surveys;

  /// Lê de novo (ao abrir e ao voltar do questionário).
  Future<void> load() async {
    final response = await surveys.loadResponse(kind);
    if (isClosed) return;
    emit(SurveyRules.shouldInvite(hasResponse: response != null));
  }
}
