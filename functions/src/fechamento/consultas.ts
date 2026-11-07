// As consultas ao export do Analytics no BigQuery (uma tabela `events_aaaammdd` por dia).
// Uma linha por combinação de evento e dimensões, com eventos e pessoas
// distintas. As dimensões só vêm preenchidas nos eventos que as usam, para que
// `pessoas` de um evento sem elas seja a contagem certa por país.

/** Uma linha do resultado de [sqlDoDia]. */
export interface LinhaEvento {
  evento: string;
  pais: string;
  curso: string | null;
  aula: string | null;
  capitulo: string | null;
  exercicio: string | null;
  acertou: string | null;
  fonte: string | null;
  eventos: number;
  pessoas: number;
}

/** Pseudo-eventos que a própria consulta cria (pessoas ativas no dia). */
export const ATIVOS_APP = '_ativos_app';
export const ATIVOS_CURSO = '_ativos_curso';

/** Eventos do app que entram no resumo (o resto da tabela é ignorado). */
export const EVENTOS = [
  'treino_objetivo_definido',
  'treino_meta_inicio',
  'treino_meta_fim',
  'treino_ciclo_fim',
  'aula_aberta',
  'aula_capitulo_inicio',
  'aula_capitulo_fim',
  'exercicio_resultado',
  'aula_concluida',
  'aula_saida',
  'pilares_oferta_vista',
  'demo_inicio',
  'campanha_link_aberto',
  'campanha_instalacao',
] as const;

const AULA = ['aula_aberta', 'aula_capitulo_inicio', 'aula_capitulo_fim', 'exercicio_resultado', 'aula_concluida', 'aula_saida'];
const CAPITULO = ['aula_capitulo_inicio', 'aula_capitulo_fim', 'exercicio_resultado', 'aula_saida'];
const EXERCICIO = ['exercicio_resultado', 'aula_saida'];
const ACERTOU = ['treino_meta_fim', 'exercicio_resultado'];
const FONTE = ['campanha_link_aberto', 'campanha_instalacao'];

const TABELA = /^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+){1,2}$/;
const DATASET = /^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)?$/;

/** `projeto.dataset.tabela` ou `dataset.tabela`, sem nada que injete SQL. */
export function tabelaSegura(nome: string): string {
  if (!TABELA.test(nome)) throw new Error(`Tabela inválida: ${nome}`);
  return `\`${nome}\``;
}

function param(chave: string): string {
  return `(SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING), CAST(value.double_value AS STRING))
      FROM UNNEST(event_params) WHERE key = '${chave}')`;
}

function propriedade(chave: string): string {
  return `(SELECT value.string_value FROM UNNEST(user_properties) WHERE key = '${chave}')`;
}

function so(eventos: string[], expr: string): string {
  return `IF(event_name IN (${eventos.map((e) => `'${e}'`).join(', ')}), ${expr}, NULL)`;
}

/**
 * Contagens do dia numa tabela (`events_aaaammdd` ou `events_intraday_aaaammdd`).
 * `pais` vem da propriedade do usuário (sem ela, `ZZ`).
 */
export function sqlDoDia(tabela: string): string {
  const t = tabelaSegura(tabela);
  return `WITH base AS (
  SELECT event_name, user_pseudo_id,
    UPPER(IFNULL(${propriedade('pais')}, 'ZZ')) AS pais,
    ${param('curso')} AS curso,
    ${param('aula_id')} AS aula,
    ${param('capitulo_id')} AS capitulo,
    ${param('exercicio_id')} AS exercicio,
    ${param('acertou')} AS acertou,
    ${propriedade('origem_fonte')} AS fonte
  FROM ${t}
),
linhas AS (
  SELECT event_name AS evento, user_pseudo_id, pais,
    ${so(['treino_objetivo_definido', 'treino_meta_inicio', 'treino_meta_fim', 'treino_ciclo_fim'], 'curso')} AS curso,
    ${so(AULA, 'aula')} AS aula,
    ${so(CAPITULO, 'capitulo')} AS capitulo,
    ${so(EXERCICIO, 'exercicio')} AS exercicio,
    ${so(ACERTOU, 'acertou')} AS acertou,
    ${so(FONTE, "IFNULL(fonte, 'direto')")} AS fonte
  FROM base WHERE event_name IN UNNEST(@eventos)
  UNION ALL
  SELECT '${ATIVOS_APP}', user_pseudo_id, pais, NULL, NULL, NULL, NULL, NULL, NULL
  FROM base WHERE event_name = 'user_engagement'
  UNION ALL
  SELECT '${ATIVOS_CURSO}', user_pseudo_id, pais, curso, NULL, NULL, NULL, NULL, NULL
  FROM base WHERE STARTS_WITH(event_name, 'treino_') AND curso IS NOT NULL
)
SELECT evento, pais, curso, aula, capitulo, exercicio, acertou, fonte,
  COUNT(*) AS eventos, COUNT(DISTINCT user_pseudo_id) AS pessoas
FROM linhas
GROUP BY evento, pais, curso, aula, capitulo, exercicio, acertou, fonte`;
}

/**
 * Pessoas distintas ativas (`user_engagement`) nas janelas que terminam em [fim]
 * (`aaaammdd`): `{ativos7: 7, ativos3m: 90, …}` → uma coluna por janela.
 * `_TABLE_SUFFIX` entre datas deixa de fora as tabelas `intraday_`.
 */
export function sqlAtivos(dataset: string, janelas: Record<string, number>): string {
  if (!DATASET.test(dataset)) throw new Error(`Dataset inválido: ${dataset}`);
  const t = `\`${dataset}.events_*\``;
  const colunas = Object.keys(janelas)
    .map((nome) => {
      if (!/^ativos\w+$/.test(nome)) throw new Error(`Janela inválida: ${nome}`);
      return `COUNT(DISTINCT IF(_TABLE_SUFFIX >= @${nome}, user_pseudo_id, NULL)) AS ${nome}`;
    })
    .join(',\n  ');
  return `SELECT
  ${colunas}
FROM ${t}
WHERE _TABLE_SUFFIX BETWEEN @inicio AND @fim AND event_name = 'user_engagement'`;
}
