import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';

void main() {
  test('T85 mantém rótulos de tentativa e textos aprovados em PT-BR', () async {
    final t = await AppLocalizations.delegate.load(const Locale('pt'));
    expect(t.loadErrorRetry, 'Tentar novamente');
    expect(t.lessonRetry, 'Tentar novamente');
    expect(t.featuredFindRetry, 'Tentar novamente');
    expect(t.speedrunRetry, 'Tentar novamente');
    expect(t.loadErrorEngineTitle, 'Erro ao iniciar a partida');
    expect(t.lessonMissing, 'Este capítulo não está disponível.');
    expect(t.exerciseMissing, 'Este exercício não está disponível.');
    expect(
      t.lessonSaveRetry,
      'Não foi possível salvar o progresso. Tente novamente.',
    );
    expect(
      t.practiceSolutionUnavailable,
      'Não foi possível mostrar a solução. Tente novamente.',
    );
    expect(t.surveyThanks, 'Obrigado pela sua opinião.');
    expect(
      t.trainingPlanSaveError,
      'Não foi possível salvar. Tente novamente.',
    );
    expect(
      t.trainingExerciseSaveError,
      'Não foi possível salvar. Tente novamente.',
    );
    expect(
      t.learningAnalysisSaveError,
      'Não foi possível salvar. Tente novamente.',
    );
    expect(
      t.trainingDownloadChapterError,
      'Não foi possível baixar o capítulo. Tente novamente.',
    );
    expect(
      t.trainingDownloadCourseError,
      'Não foi possível baixar o curso. Tente novamente.',
    );
    expect(
      t.accountDeleteFailed,
      'Não foi possível excluir a conta. Tente novamente.',
    );
    expect(
      t.accountPhotoFailed,
      'Não foi possível enviar a foto. Tente novamente.',
    );
    expect(
      t.removeAdsError,
      'Não foi possível concluir a compra. Tente novamente mais tarde.',
    );
  });
}
