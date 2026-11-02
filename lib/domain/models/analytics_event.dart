import '../use_cases/analytics_rules.dart';
import 'campaign.dart';
import 'challenge_link.dart';
import 'endgame_position.dart';
import 'game_setup.dart';

/// Um evento do Analytics: o nome e os parâmetros da tabela da E1.03.
///
/// Só sai de [AnalyticsEvents]: o nome e os parâmetros de cada evento ficam
/// num lugar só. Valores são sempre códigos fixos, números ou `sim|nao`;
/// nunca texto digitado, FEN, lance, nome ou e-mail.
class AnalyticsEvent {
  AnalyticsEvent._(this.name, Map<String, Object?> params)
    : params = Map.unmodifiable(params) {
    assert(
      AnalyticsCatalog.params(name) != null,
      'Evento fora da tabela da E1.03: $name',
    );
    assert(
      params.keys.every(AnalyticsCatalog.params(name)!.contains),
      'Parâmetro fora da tabela em $name: ${params.keys}',
    );
  }

  final String name;
  final Map<String, Object?> params;

  @override
  String toString() => 'AnalyticsEvent($name, $params)';
}

/// As 19 propriedades de usuário (E1.03 §1).
enum AnalyticsTrait {
  firstOrigin('origem_primeira'),
  originSource('origem_fonte'),
  originCampaign('origem_campanha'),
  originPost('origem_post'),
  originLink('origem_link'),
  goal('objetivo'),
  levelVia('nivel_via'),
  levelBand('nivel_faixa'),
  mainUse('uso_principal'),
  school('escola'),
  endgameLessonsDone('aulas_finais_concluidas'),
  account('conta'),
  country('pais'),
  state('estado'),
  alertsAllowed('aviso_permitido'),
  lessonInProgress('aula_em_andamento'),
  noAds('sem_anuncios'),
  streakBand('sequencia_faixa'),

  /// `sim|nao`: tem conta no Lucena e o Lichess ligado a ela (T83).
  lichessLinked('lichess_vinculado');

  const AnalyticsTrait(this.code);

  /// O nome no Firebase (até 24 caracteres).
  final String code;
}

/// A tabela da E1.03: cada evento com os parâmetros que aceita.
abstract final class AnalyticsCatalog {
  /// Parâmetro que o repositório põe em todo evento do build de QA e do
  /// DebugView (§10).
  static const trafficType = 'traffic_type';

  /// Os parâmetros de todo evento do funil de campanha (T84).
  static const campaignParams = [
    'tipo', 'utm_fonte', 'utm_campanha', 'utm_post', 'codigo', 'aula_id', //
    'tipo_aula',
  ];

  /// Os eventos do app (incluindo o treino T85).
  static const app = <String, List<String>>{
    // Entrada, perfil e conta.
    'tutorial_begin': ['entrada'],
    'tutorial_complete': ['pulado', 'passos_vistos'],
    'objetivo_definido': ['objetivo', 'trocado'],
    'nivel_definido': ['via', 'faixa', 'provisorio'],
    'teste_nivel_fim': ['resultado', 'faixa', 'tempo_s'],
    'conta_convite': ['resposta', 'momento'],
    'sign_up': ['method'],
    'login': ['method'],
    'conta_lichess': ['acao', 'faixa'],
    'lichess_conectado': ['origem', 'tem_conta'],
    'conta_progresso_recuperado': ['itens'],
    'conta_apagada': [],
    // Link, post e compartilhar.
    'link_aberto': [
      'instalacao', 'codigo', 'origem_link', 'geracao', 'primeira_abertura', //
      'posicao_id', 'meta', 'adversario', 'nivel', 'relogio', 'as_cegas',
      'travado', 'utm_fonte', 'utm_meio', 'utm_campanha', 'utm_post',
    ],
    'link_criado': [
      'codigo', 'tela', 'geracao', 'codigo_pai', 'posicao_id', 'adversario', //
      'nivel', 'relogio', 'as_cegas', 'travado',
    ],
    'share': [
      'content_type', 'item_id', 'method', 'resultado', 'codigo', 'geracao', //
    ],
    'link_copiado': ['tela', 'codigo', 'geracao'],
    'link_fim_acao': ['acao', 'resultado', 'codigo', 'origem_link'],
    // Funil do link de campanha (T84): post → desafio → aula → conta.
    'campanha_link_aberto': [...campaignParams, 'instalacao'],
    'campanha_instalacao': campaignParams,
    'campanha_desafio_inicio': campaignParams,
    'campanha_desafio_fim': [...campaignParams, 'resultado', 'conseguiu'],
    'campanha_oferta_vista': [...campaignParams, 'destaque'],
    'campanha_oferta_tocada': [...campaignParams, 'destaque'],
    'campanha_cadastro': [...campaignParams, 'resposta'],
    'campanha_aula_aberta': [...campaignParams, 'disponivel'],
    'campanha_aula_concluida': campaignParams,
    // Partidas e modos.
    'partida_config_vista': ['origem', 'posicao_id'],
    'partida_iniciada': [
      'modo', 'posicao_id', 'meta', 'lado', 'adversario', 'nivel', 'relogio', //
      'as_cegas', 'travado', 'codigo',
    ],
    'partida_primeiro_lance': ['modo', 'posicao_id', 'tempo_s'],
    'partida_fim': [
      'modo', 'posicao_id', 'meta', 'adversario', 'nivel', 'resultado', //
      'motivo', 'lances', 'tempo_s', 'estrelas', 'codigo',
    ],
    'analise_aberta': ['origem', 'posicao_id'],
    'curso_cartao_home': ['curso', 'estado', 'destino'],
    'curso_guia_aba': ['curso', 'aba', 'origem'],
    'treino_meta_inicio': [
      'curso',
      'tipo',
      'aula_id',
      'estrela',
      'dia_ciclo',
      'origem',
      'mock',
    ],
    'treino_meta_fim': [
      'curso',
      'tipo',
      'aula_id',
      'estrela',
      'dia_ciclo',
      'origem',
      'mock',
      'acertou',
      'dicas',
      'tempo_s',
      'metas_restantes',
      'pontos',
      'fala_erro',
    ],
    'treino_trecho_inicio': [
      'curso',
      'aula_id',
      'trecho',
      'trechos_total',
      'revisao',
      'origem',
      'mock',
    ],
    'treino_trecho_fim': [
      'curso',
      'aula_id',
      'trecho',
      'erros',
      'toques_voltar',
      'toques_avancar',
      'toques_notacao',
      'tempo_s',
      'mock',
    ],
    'treino_ciclo_fim': [
      'curso',
      'aula_id',
      'fase',
      'nota',
      'resultado',
      'exercicios_mock',
    ],
    'treino_ciclo_acao': ['curso', 'aula_id', 'acao'],
    'treino_aula_extra': ['curso', 'aula_id', 'dia_folga'],
    'treino_meta_dobrada': ['curso', 'metas_novas'],
    'treino_dia_completo': ['curso', 'metas', 'aulas_extra', 'dobrou'],
    'treino_plano_alterado': [
      'curso',
      'minutos',
      'dias',
      'dias_mascara',
      'lembrete',
      'hora',
      'primeira_vez',
    ],
    'treino_lembrete_agendado': ['curso', 'hora', 'metas', 'aula_pendente'],
    'treino_lembrete_mostrado': ['curso', 'atraso_min'],
    // Aulas e exercícios.
    'aula_aberta': [
      'aula_id', 'tipo_aula', 'origem', 'retomada', 'primeira_vez', //
    ],
    'aula_capitulo_inicio': [
      'aula_id', 'capitulo_id', 'capitulo', 'capitulos_total', 'tipo_aula', //
    ],
    'aula_capitulo_fim': [
      'aula_id', 'capitulo_id', 'capitulo', 'tempo_s', 'exercicios', 'erros', //
      'dicas',
    ],
    'exercicio_resultado': [
      'aula_id', 'capitulo_id', 'exercicio_id', 'tipo_passo', 'acertou', //
      'tentativas', 'dicas', 'tempo_s',
    ],
    'aula_teste_inicio': ['aula_id', 'exercicios'],
    'aula_teste_fim': [
      'aula_id', 'aprovado', 'acertos_1a_tentativa', 'exercicios', //
      'tentativas', 'tempo_s',
    ],
    'aula_concluida': [
      'aula_id', 'tipo_aula', 'tempo_s', 'erros', 'dicas', 'estrelas', //
      'sessoes', 'origem',
    ],
    // `origem`: `trilha_finais|escola|aula`.
    'aula_indisponivel': ['origem'],
    'aula_saida': [
      'aula_id',
      'capitulo_id',
      'exercicio_id',
      'tempo_s',
      'seg_apos_anuncio', //
    ],
    // Catálogo de finais.
    'final_aberto': ['final_id', 'grupo', 'origem', 'tem_aula'],
    'final_busca': ['tamanho_termo', 'resultados'],
    'final_filtro': ['tipo', 'valor', 'resultados'],
    // Finais em destaque e torneios.
    'final_destaque_aberto': ['final_id', 'torneio_id', 'entrada'],
    'final_destaque_filtro': ['tipo', 'valor', 'resultados'],
    'final_destaque_torneio': ['torneio_id', 'em_andamento', 'entrada'],
    'final_destaque_aviso': ['torneio_id', 'ligado'],
    'final_destaque_ache_lance': [
      'final_id', 'acertou', 'tentativas', 'dica', 'ver_resposta', //
    ],
    'final_destaque_livrinho': ['final_id', 'secao'],
    'final_destaque_concluido': ['final_id', 'torneio_id', 'acertou', 'lances'],
    'saida_externa': ['destino', 'final_id'],
    // Retenção: final do dia, avisos e região.
    'final_dia_aberto': ['entrada', 'sequencia', 'ja_jogou_hoje'],
    'final_dia_concluido': [
      'final_id', 'data', 'acertou', 'lances', 'verdes', 'amarelos', //
      'vermelhos', 'sequencia',
    ],
    'sequencia_vista': ['sequencia', 'recorde'],
    'sequencia_perdida': ['tamanho', 'recorde', 'acao'],
    'aviso_pedido': ['resposta', 'gatilho'],
    'aviso_chave': ['tipo', 'ligado'],
    'aviso_aberto': ['canal', 'tipo'],
    'push_aberto': ['push_id', 'pais'],
    'perfil_regiao_definida': ['acao', 'tem_estado'],
    // Questionários, feedback e avaliação.
    'questionario_aberto': ['tipo', 'origem'],
    'questionario_passo': ['tipo', 'passo', 'passos_total'],
    'questionario_enviado': [
      'tipo', 'aula_id', 'nota', 'interesse', 'melhorar', 'topicos', //
      'dificuldades', 'curso_faixa', 'mensal_faixa', 'tem_texto', 'rever_aula',
    ],
    'questionario_dispensado': ['tipo', 'passo', 'como'],
    'feedback_enviado': ['tipo', 'tamanho_faixa'],
    'avaliacao_pedida': ['numero', 'gatilho'],
    'avaliacao_perfil_aberto': [],
    // Anúncios e compra.
    'anuncio_consentimento': ['resultado', 'origem'],
    'anuncio_pedido': ['resultado', 'aula_id', 'licoes_abertas'],
    'anuncio_visto': ['aula_id', 'ate_o_fim', 'tempo_s', 'licoes_abertas'],
    'anuncio_remocao': ['etapa', 'origem'],
    'purchase': ['value', 'currency', 'item_id'],
    // Corrida de problemas.
    'corrida_aquecimento': ['acao'],
    'corrida_iniciada': ['tema', 'recorde'],
    'corrida_problema': [
      'problema_id', 'tema', 'nivel', 'acertou', 'tempo_s', 'indice', //
    ],
    'corrida_fim': [
      'motivo', 'acertos', 'erros', 'tempo_s', 'nivel_max', 'novo_recorde', //
    ],
    // Versão do app.
    'atualizacao_vista': ['tipo', 'build_atual', 'build_pedido'],
    'atualizacao_acao': ['tipo', 'acao', 'via'],
    // Privacidade.
    'privacidade_analytics': ['ligado'],
  };

  /// Os 3 da página de reserva (stream web, E1.01): o app não os registra.
  static const web = <String, List<String>>{
    'reserva_vista': [
      'utm_fonte', 'codigo', 'origem_link', 'geracao', 'utm_meio', //
      'utm_campanha', 'utm_post', 'navegador_embutido',
    ],
    'reserva_play_clique': [
      'utm_fonte', 'codigo', 'origem_link', 'geracao', 'utm_campanha', //
      'utm_post',
    ],
    'reserva_abrir_app_clique': [
      'utm_fonte', 'codigo', 'origem_link', 'geracao', 'utm_campanha', //
      'utm_post',
    ],
  };

  /// O `screen_view`, que no Flutter não é automático (só o nome da rota).
  static const screenView = 'screen_view';
  static const _screenParams = ['screen_name', 'screen_class'];

  /// Os parâmetros que [name] aceita, ou nulo se não está na tabela.
  static List<String>? params(String name) =>
      name == screenView ? _screenParams : app[name];
}

/// Os eventos do app, um por linha da tabela da E1.03. Os valores de texto
/// já vêm como código (`vitoria`, `ganhar`...); os `bool` saem `sim|nao`.
abstract final class AnalyticsEvents {
  static AnalyticsEvent cursoCartaoHome({
    required String curso,
    required String estado,
    required String destino,
  }) => _e('curso_cartao_home', {
    'curso': curso,
    'estado': estado,
    'destino': destino,
  });

  static AnalyticsEvent cursoGuiaAba({
    required String curso,
    required String aba,
    required String origem,
  }) => _e('curso_guia_aba', {'curso': curso, 'aba': aba, 'origem': origem});

  static AnalyticsEvent treinoMetaInicio({
    required String curso,
    required String tipo,
    required String aulaId,
    required int estrela,
    required int diaCiclo,
    required String origem,
    required bool mock,
  }) => _e('treino_meta_inicio', {
    'curso': curso,
    'tipo': tipo,
    'aula_id': aulaId,
    'estrela': estrela,
    'dia_ciclo': diaCiclo,
    'origem': origem,
    'mock': _yn(mock),
  });

  static AnalyticsEvent treinoMetaFim({
    required String curso,
    required String tipo,
    required String aulaId,
    required int estrela,
    required int diaCiclo,
    required String origem,
    required bool mock,
    required bool acertou,
    required int dicas,
    required int tempoS,
    required int metasRestantes,
    int? pontos,
    bool falaErro = false,
  }) => _e('treino_meta_fim', {
    'curso': curso,
    'tipo': tipo,
    'aula_id': aulaId,
    'estrela': estrela,
    'dia_ciclo': diaCiclo,
    'origem': origem,
    'mock': _yn(mock),
    'acertou': _yn(acertou),
    'dicas': dicas,
    'tempo_s': tempoS,
    'metas_restantes': metasRestantes,
    'pontos': pontos,
    'fala_erro': _yn(falaErro),
  });

  static AnalyticsEvent treinoTrechoInicio({
    required String curso,
    required String aulaId,
    required String trecho,
    required int trechosTotal,
    required bool revisao,
    required String origem,
    required bool mock,
  }) => _e('treino_trecho_inicio', {
    'curso': curso,
    'aula_id': aulaId,
    'trecho': trecho,
    'trechos_total': trechosTotal,
    'revisao': _yn(revisao),
    'origem': origem,
    'mock': _yn(mock),
  });

  static AnalyticsEvent treinoTrechoFim({
    required String curso,
    required String aulaId,
    required String trecho,
    required int erros,
    required int toquesVoltar,
    required int toquesAvancar,
    required int toquesNotacao,
    required int tempoS,
    required bool mock,
  }) => _e('treino_trecho_fim', {
    'curso': curso,
    'aula_id': aulaId,
    'trecho': trecho,
    'erros': erros,
    'toques_voltar': toquesVoltar,
    'toques_avancar': toquesAvancar,
    'toques_notacao': toquesNotacao,
    'tempo_s': tempoS,
    'mock': _yn(mock),
  });

  static AnalyticsEvent treinoCicloFim({
    required String curso,
    required String aulaId,
    required String fase,
    required int nota,
    required String resultado,
    required bool exerciciosMock,
  }) => _e('treino_ciclo_fim', {
    'curso': curso,
    'aula_id': aulaId,
    'fase': fase,
    'nota': nota,
    'resultado': resultado,
    'exercicios_mock': _yn(exerciciosMock),
  });

  static AnalyticsEvent treinoCicloAcao({
    required String curso,
    required String aulaId,
    required String acao,
  }) => _e('treino_ciclo_acao', {
    'curso': curso,
    'aula_id': aulaId,
    'acao': acao,
  });

  static AnalyticsEvent treinoAulaExtra({
    required String curso,
    required String aulaId,
    required bool diaFolga,
  }) => _e('treino_aula_extra', {
    'curso': curso,
    'aula_id': aulaId,
    'dia_folga': _yn(diaFolga),
  });

  static AnalyticsEvent treinoMetaDobrada({
    required String curso,
    required int metasNovas,
  }) => _e('treino_meta_dobrada', {'curso': curso, 'metas_novas': metasNovas});

  static AnalyticsEvent treinoDiaCompleto({
    required String curso,
    required int metas,
    required int aulasExtra,
    required bool dobrou,
  }) => _e('treino_dia_completo', {
    'curso': curso,
    'metas': metas,
    'aulas_extra': aulasExtra,
    'dobrou': _yn(dobrou),
  });

  static AnalyticsEvent treinoPlanoAlterado({
    required String curso,
    required int minutos,
    required int dias,
    required String diasMascara,
    required bool lembrete,
    required int hora,
    required bool primeiraVez,
  }) => _e('treino_plano_alterado', {
    'curso': curso,
    'minutos': minutos,
    'dias': dias,
    'dias_mascara': diasMascara,
    'lembrete': _yn(lembrete),
    'hora': hora,
    'primeira_vez': _yn(primeiraVez),
  });

  static AnalyticsEvent treinoLembreteAgendado({
    required String curso,
    required int hora,
    required int metas,
    required bool aulaPendente,
  }) => _e('treino_lembrete_agendado', {
    'curso': curso,
    'hora': hora,
    'metas': metas,
    'aula_pendente': _yn(aulaPendente),
  });

  static AnalyticsEvent treinoLembreteMostrado({
    required String curso,
    required int atrasoMin,
  }) =>
      _e('treino_lembrete_mostrado', {'curso': curso, 'atraso_min': atrasoMin});

  static AnalyticsEvent _e(String name, [Map<String, Object?> p = const {}]) =>
      AnalyticsEvent._(name, p);

  static String? _yn(bool? value) =>
      value == null ? null : AnalyticsRules.yesNo(value);

  static int? _s(Duration? time) =>
      time == null ? null : AnalyticsRules.seconds(time);

  static String? _list(Iterable<String>? ids) =>
      ids == null || ids.isEmpty ? null : ids.join(',');

  // Entrada, perfil e conta (E1.11, E1.13).

  /// `entrada`: `loja|link`.
  static AnalyticsEvent tutorialBegin({required String entrada}) =>
      _e('tutorial_begin', {'entrada': entrada});

  static AnalyticsEvent tutorialComplete({
    required bool pulado,
    required int passosVistos,
  }) => _e('tutorial_complete', {
    'pulado': _yn(pulado),
    'passos_vistos': passosVistos,
  });

  /// `objetivo`: `aprender_jogar|aprender_finais|treinar_finais`.
  static AnalyticsEvent objetivoDefinido({
    required String objetivo,
    required bool trocado,
  }) =>
      _e('objetivo_definido', {'objetivo': objetivo, 'trocado': _yn(trocado)});

  /// `via`: `teste|lichess|chesscom|manual|zero`.
  static AnalyticsEvent nivelDefinido({
    required String via,
    required int? rating,
    bool provisorio = false,
  }) => _e('nivel_definido', {
    'via': via,
    'faixa': AnalyticsRules.ratingBand(rating),
    'provisorio': _yn(provisorio),
  });

  /// `resultado`: `concluido|pulado|usou_1500`.
  static AnalyticsEvent testeNivelFim({
    required String resultado,
    int? rating,
    Duration? tempo,
  }) => _e('teste_nivel_fim', {
    'resultado': resultado,
    'faixa': AnalyticsRules.ratingBand(rating),
    'tempo_s': _s(tempo),
  });

  /// `resposta`: `aceitou|agora_nao`; `momento`: `pos_vitoria` (depois da
  /// 1ª vitória), `pos_lichess` ou `pos_desafio_link` (antes da aula do link
  /// de campanha, T84).
  static AnalyticsEvent contaConvite({
    required String resposta,
    required String momento,
  }) => _e('conta_convite', {'resposta': resposta, 'momento': momento});

  /// `method`: `google|email`.
  static AnalyticsEvent signUp({required String method}) =>
      _e('sign_up', {'method': method});

  static AnalyticsEvent login({required String method}) =>
      _e('login', {'method': method});

  /// `acao`: `conectado|atualizado|desconectado`.
  static AnalyticsEvent contaLichess({required String acao, int? rating}) => _e(
    'conta_lichess',
    {'acao': acao, 'faixa': AnalyticsRules.ratingBand(rating)},
  );

  /// O Lichess conectou: `origem` `nivel|perfil` (de onde "Seu nível" foi
  /// aberto); `tem_conta` `sim|nao` (já havia conta no Lucena).
  static AnalyticsEvent lichessConectado({
    required String origem,
    required bool temConta,
  }) => _e('lichess_conectado', {
    'origem': origem,
    'tem_conta': AnalyticsRules.yesNo(temConta),
  });

  static AnalyticsEvent contaProgressoRecuperado({required int itens}) =>
      _e('conta_progresso_recuperado', {'itens': itens});

  static AnalyticsEvent contaApagada() => _e('conta_apagada');

  // Link, post e compartilhar (E1.14, E1.15).

  /// `ganhar|empatar`.
  static String goal(PositionGoal goal) => switch (goal) {
    PositionGoal.win => 'ganhar',
    PositionGoal.draw => 'empatar',
  };

  /// `maia|stockfish|dois_jogadores`.
  static String opponent(OpponentKind kind) => switch (kind) {
    OpponentKind.maia => 'maia',
    OpponentKind.stockfish => 'stockfish',
    OpponentKind.twoPlayers => 'dois_jogadores',
  };

  /// O `link_aberto` de [link]. [installedNow]: o app abriu pela 1ª vez por
  /// ele.
  static AnalyticsEvent linkOpened(
    ChallengeLink link, {
    required bool installedNow,
  }) => linkAberto(
    instalacao: installedNow ? 'recem_instalado' : 'ja_instalado',
    codigo: link.code,
    origemLink: AnalyticsRules.linkOrigin(link.utm['utm_source']),
    geracao: link.generation,
    primeiraAbertura: installedNow,
    posicaoId: AnalyticsRules.positionId(link.positionId, link.fen),
    meta: goal(link.goal),
    adversario: opponent(link.opponent),
    nivel: link.level,
    relogio: link.clock?.code,
    asCegas: link.blind,
    travado: link.locked,
    utmFonte: AnalyticsRules.campaignValue(link.utm, 'utm_source'),
    utmMeio: AnalyticsRules.campaignValue(link.utm, 'utm_medium'),
    utmCampanha: AnalyticsRules.campaignValue(link.utm, 'utm_campaign'),
    utmPost: AnalyticsRules.campaignValue(link.utm, 'utm_content'),
  );

  /// O `link_criado` de [link], já marcado com a geração e a tela.
  static AnalyticsEvent linkCreated(
    ChallengeLink link, {
    required String tela,
    String? parent,
  }) => linkCriado(
    codigo: link.code,
    tela: tela,
    geracao: link.generation,
    codigoPai: parent,
    posicaoId: AnalyticsRules.positionId(link.positionId, link.fen),
    adversario: opponent(link.opponent),
    nivel: link.level,
    relogio: link.clock?.code,
    asCegas: link.blind,
    travado: link.locked,
  );

  static AnalyticsEvent linkAberto({
    required String instalacao,
    required String codigo,
    required String origemLink,
    required int geracao,
    required bool primeiraAbertura,
    required String posicaoId,
    required String meta,
    required String adversario,
    int? nivel,
    String? relogio,
    required bool asCegas,
    required bool travado,
    String? utmFonte,
    String? utmMeio,
    String? utmCampanha,
    String? utmPost,
  }) => _e('link_aberto', {
    'instalacao': instalacao,
    'codigo': codigo,
    'origem_link': origemLink,
    'geracao': geracao,
    'primeira_abertura': _yn(primeiraAbertura),
    'posicao_id': posicaoId,
    'meta': meta,
    'adversario': adversario,
    'nivel': nivel,
    'relogio': relogio,
    'as_cegas': _yn(asCegas),
    'travado': _yn(travado),
    'utm_fonte': utmFonte,
    'utm_meio': utmMeio,
    'utm_campanha': utmCampanha,
    'utm_post': utmPost,
  });

  /// `tela`: `criar_desafio|fim_partida|final_dia|final_destaque|resultado_link`.
  static AnalyticsEvent linkCriado({
    required String codigo,
    required String tela,
    required int geracao,
    String? codigoPai,
    required String posicaoId,
    required String adversario,
    int? nivel,
    String? relogio,
    required bool asCegas,
    required bool travado,
  }) => _e('link_criado', {
    'codigo': codigo,
    'tela': tela,
    'geracao': geracao,
    'codigo_pai': codigoPai ?? AnalyticsRules.none,
    'posicao_id': posicaoId,
    'adversario': adversario,
    'nivel': nivel,
    'relogio': relogio,
    'as_cegas': _yn(asCegas),
    'travado': _yn(travado),
  });

  /// `content_type`: `desafio|resultado_link|final_dia|final_destaque|resultado`;
  /// `resultado`: `concluido|cancelado|indisponivel`.
  static AnalyticsEvent share({
    required String contentType,
    required String itemId,
    required String resultado,
    String? codigo,
    int? geracao,
  }) => _e('share', {
    'content_type': contentType,
    'item_id': itemId,
    'method': 'sistema',
    'resultado': resultado,
    'codigo': codigo,
    'geracao': geracao,
  });

  static AnalyticsEvent linkCopiado({
    required String tela,
    required String codigo,
    required int geracao,
  }) =>
      _e('link_copiado', {'tela': tela, 'codigo': codigo, 'geracao': geracao});

  /// `acao`: `jogar_de_novo|compartilhar|conhecer_app`.
  static AnalyticsEvent linkFimAcao({
    required String acao,
    required String resultado,
    required String codigo,
    required String origemLink,
  }) => _e('link_fim_acao', {
    'acao': acao,
    'resultado': resultado,
    'codigo': codigo,
    'origem_link': origemLink,
  });

  // Funil do link de campanha (T84).

  static AnalyticsEvent _campaign(
    String name,
    Campaign campaign, [
    Map<String, Object?> extra = const {},
  ]) => _e(name, {
    'tipo': campaign.kind,
    'utm_fonte': AnalyticsRules.campaignValue(campaign.utm, 'utm_source'),
    'utm_campanha': AnalyticsRules.campaignValue(campaign.utm, 'utm_campaign'),
    'utm_post': AnalyticsRules.campaignValue(campaign.utm, 'utm_content'),
    'codigo': campaign.code,
    'aula_id': campaign.lesson?.id,
    'tipo_aula': campaign.lesson?.analyticsKind,
    ...extra,
  });

  /// O link do post abriu o app. `instalacao`: `recem_instalado|ja_instalado`.
  static AnalyticsEvent campanhaLinkAberto(
    Campaign campaign, {
    required bool installedNow,
  }) => _campaign('campanha_link_aberto', campaign, {
    'instalacao': installedNow ? 'recem_instalado' : 'ja_instalado',
  });

  /// O app instalado pela Play trouxe o link no Install Referrer.
  static AnalyticsEvent campanhaInstalacao(Campaign campaign) =>
      _campaign('campanha_instalacao', campaign);

  static AnalyticsEvent campanhaDesafioInicio(Campaign campaign) =>
      _campaign('campanha_desafio_inicio', campaign);

  /// `resultado`: o do `partida_fim`; `conseguiu`: cumpriu o objetivo.
  static AnalyticsEvent campanhaDesafioFim(
    Campaign campaign, {
    required String resultado,
    required bool conseguiu,
  }) => _campaign('campanha_desafio_fim', campaign, {
    'resultado': resultado,
    'conseguiu': _yn(conseguiu),
  });

  /// `destaque`: `principal|secundaria`.
  static AnalyticsEvent campanhaOfertaVista(
    Campaign campaign, {
    required String destaque,
  }) => _campaign('campanha_oferta_vista', campaign, {'destaque': destaque});

  static AnalyticsEvent campanhaOfertaTocada(
    Campaign campaign, {
    required String destaque,
  }) => _campaign('campanha_oferta_tocada', campaign, {'destaque': destaque});

  /// `resposta`: `aceitou|agora_nao|ja_tem_conta`.
  static AnalyticsEvent campanhaCadastro(
    Campaign campaign, {
    required String resposta,
  }) => _campaign('campanha_cadastro', campaign, {'resposta': resposta});

  /// `disponivel`: a aula existe e está liberada.
  static AnalyticsEvent campanhaAulaAberta(
    Campaign campaign, {
    required bool disponivel,
  }) => _campaign('campanha_aula_aberta', campaign, {
    'disponivel': _yn(disponivel),
  });

  static AnalyticsEvent campanhaAulaConcluida(Campaign campaign) =>
      _campaign('campanha_aula_concluida', campaign);

  // Partidas e modos.

  /// `origem`: `link|nova_partida|catalogo|final_destaque|final_dia|aula|jornada`.
  static AnalyticsEvent partidaConfigVista({
    required String origem,
    String? posicaoId,
  }) => _e('partida_config_vista', {'origem': origem, 'posicao_id': posicaoId});

  /// `modo`: `livre|jornada|maratona|speedrun|cegas|desafio_estrela|catalogo|
  /// final_destaque|final_dia|link`.
  static AnalyticsEvent partidaIniciada({
    required String modo,
    required String posicaoId,
    required String meta,
    required String lado,
    required String adversario,
    int? nivel,
    String? relogio,
    required bool asCegas,
    bool travado = false,
    String? codigo,
  }) => _e('partida_iniciada', {
    'modo': modo,
    'posicao_id': posicaoId,
    'meta': meta,
    'lado': lado,
    'adversario': adversario,
    'nivel': nivel,
    'relogio': relogio,
    'as_cegas': _yn(asCegas),
    'travado': _yn(travado),
    'codigo': codigo,
  });

  static AnalyticsEvent partidaPrimeiroLance({
    required String modo,
    required String posicaoId,
    required Duration tempo,
  }) => _e('partida_primeiro_lance', {
    'modo': modo,
    'posicao_id': posicaoId,
    'tempo_s': _s(tempo),
  });

  /// `resultado`: `vitoria|empate|derrota|abandono|tempo`; `motivo`:
  /// `mate|afogamento|material|regra_50|repeticao|acordo|tempo|saiu`.
  static AnalyticsEvent partidaFim({
    required String modo,
    required String posicaoId,
    required String meta,
    required String adversario,
    int? nivel,
    required String resultado,
    required String motivo,
    required int lances,
    required Duration tempo,
    int? estrelas,
    String? codigo,
  }) => _e('partida_fim', {
    'modo': modo,
    'posicao_id': posicaoId,
    'meta': meta,
    'adversario': adversario,
    'nivel': nivel,
    'resultado': resultado,
    'motivo': motivo,
    'lances': lances,
    'tempo_s': _s(tempo),
    'estrelas': estrelas,
    'codigo': codigo,
  });

  /// `origem`: `fim_partida|historico|final_destaque`.
  static AnalyticsEvent analiseAberta({
    required String origem,
    String? posicaoId,
  }) => _e('analise_aberta', {'origem': origem, 'posicao_id': posicaoId});

  // Aulas e exercícios (E1.05).

  /// `tipo_aula`: `finais|escola|pilares`; `origem`:
  /// `trilha|home|continuar|catalogo|link|aviso|treino_home|treino_guia|treino_metas`.
  static AnalyticsEvent aulaAberta({
    required String aulaId,
    required String tipoAula,
    required String origem,
    required bool retomada,
    required bool primeiraVez,
  }) => _e('aula_aberta', {
    'aula_id': aulaId,
    'tipo_aula': tipoAula,
    'origem': origem,
    'retomada': _yn(retomada),
    'primeira_vez': _yn(primeiraVez),
  });

  static AnalyticsEvent aulaCapituloInicio({
    required String aulaId,
    required String capituloId,
    required int capitulo,
    required int capitulosTotal,
    required String tipoAula,
  }) => _e('aula_capitulo_inicio', {
    'aula_id': aulaId,
    'capitulo_id': capituloId,
    'capitulo': capitulo,
    'capitulos_total': capitulosTotal,
    'tipo_aula': tipoAula,
  });

  static AnalyticsEvent aulaCapituloFim({
    required String aulaId,
    required String capituloId,
    required int capitulo,
    required Duration tempo,
    required int exercicios,
    required int erros,
    required int dicas,
  }) => _e('aula_capitulo_fim', {
    'aula_id': aulaId,
    'capitulo_id': capituloId,
    'capitulo': capitulo,
    'tempo_s': _s(tempo),
    'exercicios': exercicios,
    'erros': erros,
    'dicas': dicas,
  });

  /// `tipo_passo`: `mover|tocar|estrelas`.
  static AnalyticsEvent exercicioResultado({
    required String aulaId,
    required String capituloId,
    required String exercicioId,
    required String tipoPasso,
    required bool acertou,
    required int tentativas,
    required int dicas,
    required Duration tempo,
  }) => _e('exercicio_resultado', {
    'aula_id': aulaId,
    'capitulo_id': capituloId,
    'exercicio_id': exercicioId,
    'tipo_passo': tipoPasso,
    'acertou': _yn(acertou),
    'tentativas': tentativas,
    'dicas': dicas,
    'tempo_s': _s(tempo),
  });

  static AnalyticsEvent aulaTesteInicio({
    required String aulaId,
    required int exercicios,
  }) => _e('aula_teste_inicio', {'aula_id': aulaId, 'exercicios': exercicios});

  static AnalyticsEvent aulaTesteFim({
    required String aulaId,
    required bool aprovado,
    required int acertosPrimeira,
    required int exercicios,
    int? tentativas,
    Duration? tempo,
  }) => _e('aula_teste_fim', {
    'aula_id': aulaId,
    'aprovado': _yn(aprovado),
    'acertos_1a_tentativa': acertosPrimeira,
    'exercicios': exercicios,
    'tentativas': tentativas,
    'tempo_s': _s(tempo),
  });

  static AnalyticsEvent aulaConcluida({
    required String aulaId,
    required String tipoAula,
    Duration? tempo,
    int? erros,
    int? dicas,
    int? estrelas,
    int? sessoes,
    String? origem,
  }) => _e('aula_concluida', {
    'aula_id': aulaId,
    'tipo_aula': tipoAula,
    'tempo_s': _s(tempo),
    'erros': erros,
    'dicas': dicas,
    'estrelas': estrelas,
    'sessoes': sessoes,
    'origem': origem,
  });

  /// "As aulas ainda não estão disponíveis" (o conteúdo não baixou).
  /// `origem`: `trilha_finais|escola|aula`.
  static AnalyticsEvent aulaIndisponivel({required String origem}) =>
      _e('aula_indisponivel', {'origem': origem});

  static AnalyticsEvent aulaSaida({
    required String aulaId,
    String? capituloId,
    String? exercicioId,
    required Duration tempo,
    int? segAposAnuncio,
  }) => _e('aula_saida', {
    'aula_id': aulaId,
    'capitulo_id': capituloId,
    'exercicio_id': exercicioId,
    'tempo_s': _s(tempo),
    'seg_apos_anuncio': segAposAnuncio,
  });

  // Catálogo de finais (E1.06).

  /// `origem`: `catalogo|busca|aula|home`.
  static AnalyticsEvent finalAberto({
    required String finalId,
    required String grupo,
    required String origem,
    required bool temAula,
  }) => _e('final_aberto', {
    'final_id': finalId,
    'grupo': grupo,
    'origem': origem,
    'tem_aula': _yn(temAula),
  });

  /// Só o tamanho do termo, nunca o termo.
  static AnalyticsEvent finalBusca({
    required int tamanhoTermo,
    required int resultados,
  }) => _e('final_busca', {
    'tamanho_termo': tamanhoTermo,
    'resultados': resultados,
  });

  /// `tipo`: `grupo|meta|aula`.
  static AnalyticsEvent finalFiltro({
    required String tipo,
    required String valor,
    required int resultados,
  }) => _e('final_filtro', {
    'tipo': tipo,
    'valor': valor,
    'resultados': resultados,
  });

  // Finais em destaque e torneios (E1.17, E1.24).

  /// `entrada`: `home|lista|torneio|aviso`.
  static AnalyticsEvent finalDestaqueAberto({
    required String finalId,
    String? torneioId,
    required String entrada,
  }) => _e('final_destaque_aberto', {
    'final_id': finalId,
    'torneio_id': torneioId,
    'entrada': entrada,
  });

  /// `tipo`: `pais|origem`.
  static AnalyticsEvent finalDestaqueFiltro({
    required String tipo,
    required String valor,
    required int resultados,
  }) => _e('final_destaque_filtro', {
    'tipo': tipo,
    'valor': valor,
    'resultados': resultados,
  });

  static AnalyticsEvent finalDestaqueTorneio({
    required String torneioId,
    required bool emAndamento,
    required String entrada,
  }) => _e('final_destaque_torneio', {
    'torneio_id': torneioId,
    'em_andamento': _yn(emAndamento),
    'entrada': entrada,
  });

  static AnalyticsEvent finalDestaqueAviso({
    required String torneioId,
    required bool ligado,
  }) => _e('final_destaque_aviso', {
    'torneio_id': torneioId,
    'ligado': _yn(ligado),
  });

  static AnalyticsEvent finalDestaqueAcheLance({
    required String finalId,
    required bool acertou,
    required int tentativas,
    required bool dica,
    required bool verResposta,
  }) => _e('final_destaque_ache_lance', {
    'final_id': finalId,
    'acertou': _yn(acertou),
    'tentativas': tentativas,
    'dica': _yn(dica),
    'ver_resposta': _yn(verResposta),
  });

  /// `secao`: `torneio|jogadores|aconteceu|partida`.
  static AnalyticsEvent finalDestaqueLivrinho({
    required String finalId,
    required String secao,
  }) => _e('final_destaque_livrinho', {'final_id': finalId, 'secao': secao});

  static AnalyticsEvent finalDestaqueConcluido({
    required String finalId,
    String? torneioId,
    required bool acertou,
    required int lances,
  }) => _e('final_destaque_concluido', {
    'final_id': finalId,
    'torneio_id': torneioId,
    'acertou': _yn(acertou),
    'lances': lances,
  });

  /// `destino`: `fide|chess_results|lichess|play|privacidade`.
  static AnalyticsEvent saidaExterna({
    required String destino,
    String? finalId,
  }) => _e('saida_externa', {'destino': destino, 'final_id': finalId});

  // Retenção: final do dia, avisos e região (E1.21, E1.22).

  /// `entrada`: `home|aviso|lembrete|link`.
  static AnalyticsEvent finalDiaAberto({
    required String entrada,
    required int sequencia,
    required bool jaJogouHoje,
  }) => _e('final_dia_aberto', {
    'entrada': entrada,
    'sequencia': sequencia,
    'ja_jogou_hoje': _yn(jaJogouHoje),
  });

  /// `data`: `AAAA-MM-DD` do aparelho.
  static AnalyticsEvent finalDiaConcluido({
    required String finalId,
    required String data,
    required bool acertou,
    required int lances,
    required int verdes,
    required int amarelos,
    required int vermelhos,
    required int sequencia,
  }) => _e('final_dia_concluido', {
    'final_id': finalId,
    'data': data,
    'acertou': _yn(acertou),
    'lances': lances,
    'verdes': verdes,
    'amarelos': amarelos,
    'vermelhos': vermelhos,
    'sequencia': sequencia,
  });

  static AnalyticsEvent sequenciaVista({
    required int sequencia,
    required int recorde,
  }) => _e('sequencia_vista', {'sequencia': sequencia, 'recorde': recorde});

  /// `acao`: `jogou_hoje|agora_nao`.
  static AnalyticsEvent sequenciaPerdida({
    required int tamanho,
    required int recorde,
    required String acao,
  }) => _e('sequencia_perdida', {
    'tamanho': tamanho,
    'recorde': recorde,
    'acao': acao,
  });

  /// `resposta`: `permitiu|agora_nao|negou_sistema`; `gatilho`:
  /// `final_dia|final_destaque|treino`.
  static AnalyticsEvent avisoPedido({
    required String resposta,
    required String gatilho,
  }) => _e('aviso_pedido', {'resposta': resposta, 'gatilho': gatilho});

  /// `tipo`: `torneios|dia|novidades|aulas|treino`.
  static AnalyticsEvent avisoChave({
    required String tipo,
    required bool ligado,
  }) => _e('aviso_chave', {'tipo': tipo, 'ligado': _yn(ligado)});

  /// `canal`: `push|local`.
  static AnalyticsEvent avisoAberto({
    required String canal,
    required String tipo,
  }) => _e('aviso_aberto', {'canal': canal, 'tipo': tipo});

  /// Tocou num push do painel (E1.19 3.8): o "% tocaram" de cada envio e
  /// país. `push_id`: o envio; `pais`: o país da mensagem (sem: Todos).
  static AnalyticsEvent pushAberto({required String pushId, String? pais}) =>
      _e('push_aberto', {'push_id': pushId, 'pais': pais});

  /// `acao`: `confirmou|trocou|pulou`.
  static AnalyticsEvent perfilRegiaoDefinida({
    required String acao,
    required bool temEstado,
  }) => _e('perfil_regiao_definida', {
    'acao': acao,
    'tem_estado': _yn(temEstado),
  });

  // Questionários, feedback e avaliação (E1.05, E1.26).

  /// `tipo`: `finais|escola|pagaria`; `origem`:
  /// `trilha|aula_concluida|cartao_aulas`.
  static AnalyticsEvent questionarioAberto({
    required String tipo,
    required String origem,
  }) => _e('questionario_aberto', {'tipo': tipo, 'origem': origem});

  static AnalyticsEvent questionarioPasso({
    required String tipo,
    required int passo,
    required int passosTotal,
  }) => _e('questionario_passo', {
    'tipo': tipo,
    'passo': passo,
    'passos_total': passosTotal,
  });

  /// Só categorias e contagens: o texto livre nunca sai.
  static AnalyticsEvent questionarioEnviado({
    required String tipo,
    String? aulaId,
    int? nota,
    String? interesse,
    Iterable<String>? melhorar,
    Iterable<String>? topicos,
    Iterable<String>? dificuldades,
    String? cursoFaixa,
    String? mensalFaixa,
    required bool temTexto,
    bool? reverAula,
  }) => _e('questionario_enviado', {
    'tipo': tipo,
    'aula_id': aulaId,
    'nota': nota,
    'interesse': interesse,
    'melhorar': _list(melhorar),
    'topicos': _list(topicos),
    'dificuldades': _list(dificuldades),
    'curso_faixa': cursoFaixa,
    'mensal_faixa': mensalFaixa,
    'tem_texto': _yn(temTexto),
    'rever_aula': _yn(reverAula),
  });

  /// `como`: `agora_nao|fechou`.
  static AnalyticsEvent questionarioDispensado({
    required String tipo,
    required int passo,
    required String como,
  }) => _e('questionario_dispensado', {
    'tipo': tipo,
    'passo': passo,
    'como': como,
  });

  /// Nunca o texto: o tipo e a faixa do tamanho.
  static AnalyticsEvent feedbackEnviado({
    required String tipo,
    required int tamanho,
  }) => _e('feedback_enviado', {
    'tipo': tipo,
    'tamanho_faixa': AnalyticsRules.lengthBand(tamanho),
  });

  /// `gatilho`: `aula|final`.
  static AnalyticsEvent avaliacaoPedida({
    required int numero,
    required String gatilho,
  }) => _e('avaliacao_pedida', {'numero': numero, 'gatilho': gatilho});

  static AnalyticsEvent avaliacaoPerfilAberto() =>
      _e('avaliacao_perfil_aberto');

  // Anúncios e compra (E1.25).

  /// `resultado`: `obtido|nao_exigido|negado|erro`; `origem`:
  /// `primeira_abertura|privacidade`.
  static AnalyticsEvent anuncioConsentimento({
    required String resultado,
    required String origem,
  }) => _e('anuncio_consentimento', {'resultado': resultado, 'origem': origem});

  /// `resultado`: `ok|sem_anuncio|sem_consentimento|carencia|intervalo|
  /// sem_internet|comprado|erro`.
  static AnalyticsEvent anuncioPedido({
    required String resultado,
    required String aulaId,
    required int licoesAbertas,
  }) => _e('anuncio_pedido', {
    'resultado': resultado,
    'aula_id': aulaId,
    'licoes_abertas': licoesAbertas,
  });

  static AnalyticsEvent anuncioVisto({
    required String aulaId,
    required bool ateOFim,
    required Duration tempo,
    required int licoesAbertas,
  }) => _e('anuncio_visto', {
    'aula_id': aulaId,
    'ate_o_fim': _yn(ateOFim),
    'tempo_s': _s(tempo),
    'licoes_abertas': licoesAbertas,
  });

  /// `etapa`: `aberto|comprado|pendente|cancelado|restaurado`; `origem`:
  /// `perfil|anuncio|privacidade`.
  static AnalyticsEvent anuncioRemocao({
    required String etapa,
    required String origem,
  }) => _e('anuncio_remocao', {'etapa': etapa, 'origem': origem});

  static AnalyticsEvent purchase({required double value}) => _e('purchase', {
    'value': value,
    'currency': 'BRL',
    'item_id': 'remover_anuncios',
  });

  // Corrida de problemas (E1.31).

  /// `acao`: `aquecer|jogar_direto|pular|nao_perguntar`.
  static AnalyticsEvent corridaAquecimento({required String acao}) =>
      _e('corrida_aquecimento', {'acao': acao});

  /// `tema`: `rook|pawns|queen|minor|todos`.
  static AnalyticsEvent corridaIniciada({
    required String tema,
    required int recorde,
  }) => _e('corrida_iniciada', {'tema': tema, 'recorde': recorde});

  static AnalyticsEvent corridaProblema({
    required String problemaId,
    required String tema,
    required int nivel,
    required bool acertou,
    required Duration tempo,
    required int indice,
  }) => _e('corrida_problema', {
    'problema_id': problemaId,
    'tema': tema,
    'nivel': nivel,
    'acertou': _yn(acertou),
    'tempo_s': _s(tempo),
    'indice': indice,
  });

  /// `motivo`: `erros|tempo|saiu`.
  static AnalyticsEvent corridaFim({
    required String motivo,
    required int acertos,
    required int erros,
    required Duration tempo,
    required int nivelMax,
    required bool novoRecorde,
  }) => _e('corrida_fim', {
    'motivo': motivo,
    'acertos': acertos,
    'erros': erros,
    'tempo_s': _s(tempo),
    'nivel_max': nivelMax,
    'novo_recorde': _yn(novoRecorde),
  });

  // Versão do app (E1.32).

  /// `tipo`: `obrigatoria|recomendada`.
  static AnalyticsEvent atualizacaoVista({
    required String tipo,
    required int buildAtual,
    required int buildPedido,
  }) => _e('atualizacao_vista', {
    'tipo': tipo,
    'build_atual': buildAtual,
    'build_pedido': buildPedido,
  });

  /// `acao`: `atualizar|agora_nao`; `via`: `play_no_app|loja`.
  static AnalyticsEvent atualizacaoAcao({
    required String tipo,
    required String acao,
    required String via,
  }) => _e('atualizacao_acao', {'tipo': tipo, 'acao': acao, 'via': via});

  // Privacidade (E1.03).

  static AnalyticsEvent privacidadeAnalytics({required bool ligado}) =>
      _e('privacidade_analytics', {'ligado': _yn(ligado)});

  /// O `screen_view` manual: só o nome da rota (`/featured/:id`), nunca o
  /// caminho com id.
  static AnalyticsEvent screenView(String route) => _e(
    AnalyticsCatalog.screenView,
    {'screen_name': route, 'screen_class': route},
  );
}
