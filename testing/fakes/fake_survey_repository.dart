import 'package:lucena/data/repositories/survey/survey_repository.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/now.dart';

import 'fake_now.dart';

/// Em memória: rascunhos e respostas por [SurveyKind].
class FakeSurveyRepository implements SurveyRepository {
  FakeSurveyRepository({Now? now, Map<SurveyKind, SurveyResponse>? responses})
    : _now = now ?? FakeNow(DateTime.utc(2026, 1, 1, 12)),
      responses = responses ?? {};

  final Now _now;
  final Map<SurveyKind, SurveyDraft> drafts = {};
  final Map<SurveyKind, SurveyResponse> responses;

  /// Quantas vezes a resposta foi gravada.
  int saves = 0;

  @override
  Future<SurveyDraft?> loadDraft(SurveyKind kind) async => drafts[kind];

  @override
  Future<void> saveDraft(SurveyDraft draft) async => drafts[draft.kind] = draft;

  @override
  Future<SurveyResponse?> loadResponse(SurveyKind kind) async =>
      responses[kind];

  @override
  Future<SurveyResponse> saveResponse(
    SurveyKind kind,
    SurveyAnswers answers,
  ) async {
    saves++;
    final response = SurveyResponse(
      kind: kind,
      answers: answers.cleaned,
      answeredAt: _now(),
    );
    responses[kind] = response;
    drafts.remove(kind);
    return response;
  }
}
