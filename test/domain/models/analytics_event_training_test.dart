import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/analytics_event.dart';
import 'package:lucena/domain/use_cases/analytics_rules.dart';

void main() {
  for (final course in ['pilares', 'escola']) {
    test(
      'curso_cartao_home $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.cursoCartaoHome(
          curso: course,
          estado: 'codigo',
          destino: 'codigo',
        );
        expect(event.name, 'curso_cartao_home');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test('curso_guia_aba $course payload catalogado e sem dados pessoais', () {
      final event = AnalyticsEvents.cursoGuiaAba(
        curso: course,
        aba: 'codigo',
        origem: 'codigo',
      );
      expect(event.name, 'curso_guia_aba');
      expect(event.params['curso'], course);
      expect(
        event.params.keys.every(AnalyticsCatalog.params(event.name)!.contains),
        isTrue,
      );
      expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
      expect(
        event.params.values.any(
          (v) => v != null && AnalyticsRules.looksPersonal(v),
        ),
        isFalse,
      );
    });
    test(
      'treino_meta_inicio $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoMetaInicio(
          curso: course,
          tipo: 'codigo',
          aulaId: 'codigo',
          estrela: 2,
          diaCiclo: 2,
          origem: 'codigo',
          mock: true,
        );
        expect(event.name, 'treino_meta_inicio');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test('treino_meta_fim $course payload catalogado e sem dados pessoais', () {
      final event = AnalyticsEvents.treinoMetaFim(
        curso: course,
        tipo: 'codigo',
        aulaId: 'codigo',
        estrela: 2,
        diaCiclo: 2,
        origem: 'codigo',
        mock: true,
        acertou: true,
        dicas: 2,
        tempoS: 2,
        metasRestantes: 2,
        pontos: 2,
      );
      expect(event.name, 'treino_meta_fim');
      expect(event.params['curso'], course);
      expect(
        event.params.keys.every(AnalyticsCatalog.params(event.name)!.contains),
        isTrue,
      );
      expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
      expect(
        event.params.values.any(
          (v) => v != null && AnalyticsRules.looksPersonal(v),
        ),
        isFalse,
      );
    });
    test(
      'treino_trecho_inicio $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoTrechoInicio(
          curso: course,
          aulaId: 'codigo',
          trecho: 'codigo',
          trechosTotal: 2,
          revisao: true,
          origem: 'codigo',
          mock: true,
        );
        expect(event.name, 'treino_trecho_inicio');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_trecho_fim $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoTrechoFim(
          curso: course,
          aulaId: 'codigo',
          trecho: 'codigo',
          erros: 2,
          toquesVoltar: 2,
          toquesAvancar: 2,
          toquesNotacao: 2,
          tempoS: 2,
          mock: true,
        );
        expect(event.name, 'treino_trecho_fim');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_ciclo_fim $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoCicloFim(
          curso: course,
          aulaId: 'codigo',
          fase: 'codigo',
          nota: 2,
          resultado: 'codigo',
          exerciciosMock: true,
        );
        expect(event.name, 'treino_ciclo_fim');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_ciclo_acao $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoCicloAcao(
          curso: course,
          aulaId: 'codigo',
          acao: 'codigo',
        );
        expect(event.name, 'treino_ciclo_acao');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_aula_extra $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoAulaExtra(
          curso: course,
          aulaId: 'codigo',
          diaFolga: true,
        );
        expect(event.name, 'treino_aula_extra');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_meta_dobrada $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoMetaDobrada(
          curso: course,
          metasNovas: 2,
        );
        expect(event.name, 'treino_meta_dobrada');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_dia_completo $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoDiaCompleto(
          curso: course,
          metas: 2,
          aulasExtra: 2,
          dobrou: true,
        );
        expect(event.name, 'treino_dia_completo');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_plano_alterado $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoPlanoAlterado(
          curso: course,
          minutos: 2,
          dias: 2,
          diasMascara: 'codigo',
          lembrete: true,
          hora: 2,
          primeiraVez: true,
        );
        expect(event.name, 'treino_plano_alterado');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_lembrete_agendado $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoLembreteAgendado(
          curso: course,
          hora: 2,
          metas: 2,
          aulaPendente: true,
        );
        expect(event.name, 'treino_lembrete_agendado');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
    test(
      'treino_lembrete_mostrado $course payload catalogado e sem dados pessoais',
      () {
        final event = AnalyticsEvents.treinoLembreteMostrado(
          curso: course,
          atrasoMin: 2,
        );
        expect(event.name, 'treino_lembrete_mostrado');
        expect(event.params['curso'], course);
        expect(
          event.params.keys.every(
            AnalyticsCatalog.params(event.name)!.contains,
          ),
          isTrue,
        );
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
        expect(
          event.params.values.any(
            (v) => v != null && AnalyticsRules.looksPersonal(v),
          ),
          isFalse,
        );
      },
    );
  }
}

List<AnalyticsEvent> trainingAnalyticsSamples(String course) => [
  AnalyticsEvents.cursoCartaoHome(
    curso: course,
    estado: 'codigo',
    destino: 'codigo',
  ),
  AnalyticsEvents.cursoGuiaAba(curso: course, aba: 'codigo', origem: 'codigo'),
  AnalyticsEvents.treinoMetaInicio(
    curso: course,
    tipo: 'codigo',
    aulaId: 'codigo',
    estrela: 2,
    diaCiclo: 2,
    origem: 'codigo',
    mock: true,
  ),
  AnalyticsEvents.treinoMetaFim(
    curso: course,
    tipo: 'codigo',
    aulaId: 'codigo',
    estrela: 2,
    diaCiclo: 2,
    origem: 'codigo',
    mock: true,
    acertou: true,
    dicas: 2,
    tempoS: 2,
    metasRestantes: 2,
    pontos: 2,
  ),
  AnalyticsEvents.treinoTrechoInicio(
    curso: course,
    aulaId: 'codigo',
    trecho: 'codigo',
    trechosTotal: 2,
    revisao: true,
    origem: 'codigo',
    mock: true,
  ),
  AnalyticsEvents.treinoTrechoFim(
    curso: course,
    aulaId: 'codigo',
    trecho: 'codigo',
    erros: 2,
    toquesVoltar: 2,
    toquesAvancar: 2,
    toquesNotacao: 2,
    tempoS: 2,
    mock: true,
  ),
  AnalyticsEvents.treinoCicloFim(
    curso: course,
    aulaId: 'codigo',
    fase: 'codigo',
    nota: 2,
    resultado: 'codigo',
    exerciciosMock: true,
  ),
  AnalyticsEvents.treinoCicloAcao(
    curso: course,
    aulaId: 'codigo',
    acao: 'codigo',
  ),
  AnalyticsEvents.treinoAulaExtra(
    curso: course,
    aulaId: 'codigo',
    diaFolga: true,
  ),
  AnalyticsEvents.treinoMetaDobrada(curso: course, metasNovas: 2),
  AnalyticsEvents.treinoDiaCompleto(
    curso: course,
    metas: 2,
    aulasExtra: 2,
    dobrou: true,
  ),
  AnalyticsEvents.treinoPlanoAlterado(
    curso: course,
    minutos: 2,
    dias: 2,
    diasMascara: 'codigo',
    lembrete: true,
    hora: 2,
    primeiraVez: true,
  ),
  AnalyticsEvents.treinoLembreteAgendado(
    curso: course,
    hora: 2,
    metas: 2,
    aulaPendente: true,
  ),
  AnalyticsEvents.treinoLembreteMostrado(curso: course, atrasoMin: 2),
];
