import 'analytics_event_training_test.dart' show trainingAnalyticsSamples;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/analytics_event.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/domain/use_cases/analytics_rules.dart';

const _fen = '8/8/8/8/8/2k5/8/K1Q5 w - - 0 1';

final _link = ChallengeLink(
  fen: _fen,
  userSide: Side.white,
  level: 1400,
  clock: TimeControl.tryParse('300+0'),
);

const _campaign = Campaign(
  utm: {'utm_source': 'instagram', 'utm_campaign': 'torre-engana'},
  code: 'k7Qe2',
  lesson: LinkedLesson.endgame('rook.lucena'),
);

/// Um de cada fábrica, com valores de verdade: é a varredura de dado pessoal
/// e a prova de que todo evento está na tabela.
final _samples = <AnalyticsEvent>[
  ...trainingAnalyticsSamples('pilares'),
  AnalyticsEvents.tutorialBegin(entrada: 'primeira_abertura'),
  AnalyticsEvents.tutorialComplete(pulado: false, passosVistos: 4),
  AnalyticsEvents.objetivoDefinido(objetivo: 'finais', trocado: false),
  AnalyticsEvents.nivelDefinido(via: 'teste', rating: 1450),
  AnalyticsEvents.testeNivelFim(
    resultado: 'concluido',
    rating: 1450,
    tempo: const Duration(minutes: 3),
  ),
  AnalyticsEvents.contaConvite(resposta: 'criar', momento: 'aula_1'),
  AnalyticsEvents.signUp(method: 'google'),
  AnalyticsEvents.login(method: 'email'),
  AnalyticsEvents.contaLichess(acao: 'conectado', rating: 1720),
  AnalyticsEvents.lichessConectado(origem: 'nivel', temConta: false),
  AnalyticsEvents.contaProgressoRecuperado(itens: 12),
  AnalyticsEvents.contaApagada(),
  AnalyticsEvents.linkOpened(
    _link.sharedFrom('criar_desafio', generation: 2),
    installedNow: true,
  ),
  AnalyticsEvents.linkCreated(_link, tela: 'criar_desafio', parent: 'ab12C'),
  AnalyticsEvents.share(
    contentType: 'desafio',
    itemId: _link.code,
    resultado: 'concluido',
    codigo: _link.code,
    geracao: 1,
  ),
  AnalyticsEvents.linkCopiado(
    tela: 'criar_desafio',
    codigo: _link.code,
    geracao: 1,
  ),
  AnalyticsEvents.linkFimAcao(
    acao: 'jogar_de_novo',
    resultado: 'vitoria',
    codigo: _link.code,
    origemLink: 'organico',
  ),
  AnalyticsEvents.campanhaLinkAberto(_campaign, installedNow: true),
  AnalyticsEvents.campanhaInstalacao(_campaign),
  AnalyticsEvents.campanhaDesafioInicio(_campaign),
  AnalyticsEvents.campanhaDesafioFim(
    _campaign,
    resultado: 'derrota',
    conseguiu: false,
  ),
  AnalyticsEvents.campanhaOfertaVista(_campaign, destaque: 'principal'),
  AnalyticsEvents.campanhaOfertaTocada(_campaign, destaque: 'principal'),
  AnalyticsEvents.campanhaCadastro(_campaign, resposta: 'aceitou'),
  AnalyticsEvents.campanhaAulaAberta(_campaign, disponivel: true),
  AnalyticsEvents.campanhaAulaConcluida(_campaign),
  AnalyticsEvents.partidaConfigVista(origem: 'catalogo', posicaoId: 'kq_k'),
  AnalyticsEvents.partidaIniciada(
    modo: 'catalogo',
    posicaoId: 'kq_k',
    meta: 'ganhar',
    lado: 'brancas',
    adversario: 'maia',
    nivel: 1400,
    relogio: '300+0',
    asCegas: false,
  ),
  AnalyticsEvents.partidaPrimeiroLance(
    modo: 'catalogo',
    posicaoId: 'kq_k',
    tempo: const Duration(seconds: 4),
  ),
  AnalyticsEvents.partidaFim(
    modo: 'link',
    posicaoId: 'kq_k',
    meta: 'ganhar',
    adversario: 'stockfish',
    resultado: 'vitoria',
    motivo: 'mate',
    lances: 14,
    tempo: const Duration(minutes: 2),
    estrelas: 3,
    codigo: _link.code,
  ),
  AnalyticsEvents.analiseAberta(origem: 'fim_partida', posicaoId: 'kq_k'),
  AnalyticsEvents.aulaAberta(
    aulaId: 'lucena',
    tipoAula: 'final',
    origem: 'trilha',
    retomada: false,
    primeiraVez: true,
  ),
  AnalyticsEvents.aulaCapituloInicio(
    aulaId: 'lucena',
    capituloId: 'ponte',
    capitulo: 2,
    capitulosTotal: 4,
    tipoAula: 'final',
  ),
  AnalyticsEvents.aulaCapituloFim(
    aulaId: 'lucena',
    capituloId: 'ponte',
    capitulo: 2,
    tempo: const Duration(minutes: 4),
    exercicios: 3,
    erros: 1,
    dicas: 0,
  ),
  AnalyticsEvents.exercicioResultado(
    aulaId: 'lucena',
    capituloId: 'ponte',
    exercicioId: 'ponte_2',
    tipoPasso: 'lance',
    acertou: true,
    tentativas: 1,
    dicas: 0,
    tempo: const Duration(seconds: 20),
  ),
  AnalyticsEvents.aulaTesteInicio(aulaId: 'lucena', exercicios: 5),
  AnalyticsEvents.aulaTesteFim(
    aulaId: 'lucena',
    aprovado: true,
    acertosPrimeira: 4,
    exercicios: 5,
    tentativas: 6,
    tempo: const Duration(minutes: 5),
  ),
  AnalyticsEvents.aulaConcluida(aulaId: 'lucena', tipoAula: 'final'),
  AnalyticsEvents.aulaIndisponivel(origem: 'escola'),
  AnalyticsEvents.aulaSaida(
    aulaId: 'lucena',
    capituloId: 'ponte',
    tempo: const Duration(minutes: 1),
  ),
  AnalyticsEvents.finalAberto(
    finalId: 'kr_kr',
    grupo: 'torre',
    origem: 'catalogo',
    temAula: true,
  ),
  AnalyticsEvents.finalBusca(tamanhoTermo: 5, resultados: 3),
  AnalyticsEvents.finalFiltro(tipo: 'grupo', valor: 'torre', resultados: 9),
  AnalyticsEvents.finalDestaqueAberto(finalId: 'f1', entrada: 'home'),
  AnalyticsEvents.finalDestaqueFiltro(
    tipo: 'ritmo',
    valor: 'classico',
    resultados: 4,
  ),
  AnalyticsEvents.finalDestaqueTorneio(
    torneioId: 'candidatos_2026',
    emAndamento: true,
    entrada: 'home',
  ),
  AnalyticsEvents.finalDestaqueAviso(
    torneioId: 'candidatos_2026',
    ligado: true,
  ),
  AnalyticsEvents.finalDestaqueAcheLance(
    finalId: 'f1',
    acertou: true,
    tentativas: 1,
    dica: false,
    verResposta: false,
  ),
  AnalyticsEvents.finalDestaqueLivrinho(finalId: 'f1', secao: 'ideia'),
  AnalyticsEvents.finalDestaqueConcluido(
    finalId: 'f1',
    acertou: true,
    lances: 8,
  ),
  AnalyticsEvents.saidaExterna(destino: 'wikipedia'),
  AnalyticsEvents.finalDiaAberto(
    entrada: 'home',
    sequencia: 3,
    jaJogouHoje: false,
  ),
  AnalyticsEvents.finalDiaConcluido(
    finalId: 'kp_k',
    data: '2026-10-22',
    acertou: true,
    lances: 9,
    verdes: 7,
    amarelos: 1,
    vermelhos: 1,
    sequencia: 4,
  ),
  AnalyticsEvents.sequenciaVista(sequencia: 4, recorde: 9),
  AnalyticsEvents.sequenciaPerdida(tamanho: 4, recorde: 9, acao: 'jogar'),
  AnalyticsEvents.avisoPedido(resposta: 'permitiu', gatilho: 'sequencia'),
  AnalyticsEvents.avisoChave(tipo: 'dia', ligado: true),
  AnalyticsEvents.avisoAberto(canal: 'push', tipo: 'dia'),
  AnalyticsEvents.pushAberto(pushId: 'p1', pais: 'BR'),
  AnalyticsEvents.perfilRegiaoDefinida(acao: 'confirmou', temEstado: true),
  AnalyticsEvents.questionarioAberto(tipo: 'aula', origem: 'fim_aula'),
  AnalyticsEvents.questionarioPasso(tipo: 'aula', passo: 2, passosTotal: 3),
  AnalyticsEvents.questionarioEnviado(
    tipo: 'aula',
    aulaId: 'lucena',
    nota: 5,
    melhorar: ['ritmo', 'exemplos'],
    temTexto: true,
  ),
  AnalyticsEvents.questionarioDispensado(
    tipo: 'aula',
    passo: 1,
    como: 'fechar',
  ),
  AnalyticsEvents.feedbackEnviado(tipo: 'ideia', tamanho: 120),
  AnalyticsEvents.avaliacaoPedida(numero: 1, gatilho: 'aula_concluida'),
  AnalyticsEvents.avaliacaoPerfilAberto(),
  AnalyticsEvents.anuncioConsentimento(resultado: 'aceito', origem: 'abertura'),
  AnalyticsEvents.anuncioPedido(
    resultado: 'carregado',
    aulaId: 'lucena',
    licoesAbertas: 2,
  ),
  AnalyticsEvents.anuncioVisto(
    aulaId: 'lucena',
    ateOFim: true,
    tempo: const Duration(seconds: 30),
    licoesAbertas: 2,
  ),
  AnalyticsEvents.anuncioRemocao(etapa: 'aberta', origem: 'configuracoes'),
  AnalyticsEvents.purchase(value: 9.9),
  AnalyticsEvents.corridaAquecimento(acao: 'aceitou'),
  AnalyticsEvents.corridaIniciada(tema: 'mate', recorde: 12),
  AnalyticsEvents.corridaProblema(
    problemaId: 'p_12',
    tema: 'mate',
    nivel: 3,
    acertou: true,
    tempo: const Duration(seconds: 9),
    indice: 4,
  ),
  AnalyticsEvents.corridaFim(
    motivo: 'tempo',
    acertos: 12,
    erros: 3,
    tempo: const Duration(minutes: 3),
    nivelMax: 5,
    novoRecorde: false,
  ),
  AnalyticsEvents.atualizacaoVista(
    tipo: 'recomendada',
    buildAtual: 40,
    buildPedido: 42,
  ),
  AnalyticsEvents.atualizacaoAcao(
    tipo: 'recomendada',
    acao: 'atualizar',
    via: 'play_no_app',
  ),
  AnalyticsEvents.privacidadeAnalytics(ligado: false),
  AnalyticsEvents.screenView('/featured/:id'),
];

void main() {
  group('catálogo', () {
    test('tem os 96 eventos (93 do app, com o treino e o funil de campanha da '
        'T84, e 3 da web)', () {
      expect(AnalyticsCatalog.app, hasLength(93));
      expect(AnalyticsCatalog.web, hasLength(3));
      expect(
        AnalyticsCatalog.app.keys.toSet().intersection(
          AnalyticsCatalog.web.keys.toSet(),
        ),
        isEmpty,
      );
    });

    test('nomes e parâmetros dentro dos limites do Firebase', () {
      for (final MapEntry(key: name, value: params) in {
        ...AnalyticsCatalog.app,
        ...AnalyticsCatalog.web,
      }.entries) {
        expect(AnalyticsRules.validName(name), isTrue, reason: name);
        expect(params.length, lessThan(AnalyticsRules.maxParams), reason: name);
        for (final param in params) {
          expect(AnalyticsRules.validName(param), isTrue, reason: param);
        }
      }
    });

    test('as 19 propriedades cabem no nome do Firebase', () {
      expect(AnalyticsTrait.values, hasLength(19));
      for (final trait in AnalyticsTrait.values) {
        expect(
          AnalyticsRules.validName(
            trait.code,
            max: AnalyticsRules.maxTraitNameLength,
          ),
          isTrue,
          reason: trait.code,
        );
      }
    });

    test('toda fábrica sai um evento da tabela, com os parâmetros dela', () {
      final names = {for (final event in _samples) event.name};
      // Os do app, menos os automáticos do Firebase (sem fábrica).
      expect(
        names,
        containsAll(
          AnalyticsCatalog.app.keys.where(
            (name) => name != AnalyticsCatalog.screenView,
          ),
        ),
      );
      for (final event in _samples) {
        final allowed = AnalyticsCatalog.params(event.name)!;
        expect(allowed, containsAll(event.params.keys), reason: event.name);
        expect(AnalyticsRules.sanitize(event.name, event.params), isNotNull);
      }
    });

    test('nada pessoal: nem FEN, nem e-mail, nem texto livre', () {
      for (final event in _samples) {
        final params = AnalyticsRules.sanitize(event.name, event.params)!;
        for (final MapEntry(:key, :value) in params.entries) {
          expect(
            AnalyticsRules.looksPersonal(value),
            isFalse,
            reason: '${event.name}.$key = $value',
          );
        }
      }
    });
  });

  group('link', () {
    test('funil de campanha: utm, código e aula em todo evento', () {
      final event = AnalyticsEvents.campanhaOfertaTocada(
        _campaign,
        destaque: 'secundaria',
      );
      expect(event.params, {
        'tipo': 'desafio',
        'utm_fonte': 'instagram',
        'utm_campanha': 'torre-engana',
        'utm_post': null,
        'codigo': 'k7Qe2',
        'aula_id': 'rook.lucena',
        'tipo_aula': 'finais',
        'destaque': 'secundaria',
      });
      final lessonOnly = AnalyticsEvents.campanhaAulaAberta(
        const Campaign(lesson: LinkedLesson.school('peao.marcha')),
        disponivel: false,
      );
      expect(lessonOnly.params['tipo'], 'aula');
      expect(lessonOnly.params['tipo_aula'], 'escola');
      expect(lessonOnly.params['disponivel'], 'nao');
    });

    test('link_aberto: o link criado no app é orgânico e sem campanha', () {
      final event = AnalyticsEvents.linkOpened(
        _link.sharedFrom('fim_partida', generation: 2),
        installedNow: false,
      );
      expect(event.params['origem_link'], 'organico');
      expect(event.params['geracao'], 2);
      expect(event.params['instalacao'], 'ja_instalado');
      expect(event.params['posicao_id'], startsWith('custom_'));
    });

    test('link_criado sem link pai: codigo_pai nenhum', () {
      final event = AnalyticsEvents.linkCreated(_link, tela: 'criar_desafio');
      expect(event.params['codigo_pai'], AnalyticsRules.none);
      expect(event.params['codigo'], _link.code);
    });
  });
}
