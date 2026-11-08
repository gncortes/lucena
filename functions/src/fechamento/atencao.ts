// H-R5-35 · Pontos de atenção (R5 §8, roteiro R20): onde mais gente abandona nos 7 dias que terminam no dia fechado,
// comparado aos 7 anteriores. Os funis vêm da GA4 Data API (runFunnelReport, só na v1alpha); a permissão de
// notificação e as telas com mais saída vêm do export no BigQuery (a Data API não tem saída de tela em app).
import { somarDias } from './datas';

/** Um passo de um fluxo: quantas pessoas chegaram nele e quantas seguiram. */
export interface Etapa {
  fluxo: string;
  passo: string;
  chegaram: number;
  seguiram: number;
}

export interface Ponto extends Etapa {
  /** Fração que saiu (0,61 = 61%), 3 casas. */
  saida: number;
  /** Diferença em pontos percentuais para os 7 dias anteriores; null se lá o passo tinha < 30 pessoas. */
  variacaoPp: number | null;
}

/** Os pontos de atenção gravados no resumo do dia. */
export interface PontosAtencao {
  inicio: string;
  fim: string;
  itens: Ponto[];
}

/** Lê as etapas de um intervalo de dias (aaaa-mm-dd, inclusive). */
export interface FonteAtencao {
  etapas(inicio: string, fim: string): Promise<Etapa[]>;
}

export const MINIMO_PESSOAS = 30;
export const MAXIMO_ITENS = 5;
export const JANELA_DIAS = 7;

/** Passo do funil: um evento (ou qualquer um da lista). */
export interface PassoFunil {
  nome: string;
  eventos: string[];
}

export interface Funil {
  fluxo: string;
  passos: PassoFunil[];
}

/** Os fluxos do R5 §8 (a permissão de notificação sai do BigQuery, pela propriedade `aviso_permitido`). */
export const FUNIS: Funil[] = [
  {
    fluxo: 'Entrada no app',
    passos: [
      { nome: 'Primeira abertura', eventos: ['first_open'] },
      { nome: 'Boas-vindas', eventos: ['tutorial_begin'] },
      { nome: 'Fim das boas-vindas', eventos: ['tutorial_complete'] },
      { nome: 'Nível definido', eventos: ['nivel_definido'] },
    ],
  },
  {
    fluxo: 'Primeira lição',
    passos: [
      { nome: 'Lição aberta', eventos: ['aula_aberta'] },
      { nome: 'Capítulo iniciado', eventos: ['aula_capitulo_inicio'] },
      { nome: 'Exercício 1', eventos: ['exercicio_resultado'] },
      { nome: 'Capítulo concluído', eventos: ['aula_capitulo_fim'] },
    ],
  },
  {
    fluxo: 'Demo → compra',
    passos: [
      { nome: 'Oferta vista', eventos: ['pilares_oferta_vista'] },
      { nome: 'Demonstração', eventos: ['demo_inicio'] },
      { nome: 'Fim da demonstração', eventos: ['demo_fim'] },
      { nome: 'Compra', eventos: ['purchase'] },
    ],
  },
  {
    fluxo: 'Criação de conta',
    passos: [
      { nome: 'Convite para a conta', eventos: ['conta_convite'] },
      { nome: 'Conta criada', eventos: ['sign_up', 'login'] },
    ],
  },
];

export const FLUXO_PERMISSAO = 'Permissão de notificação';
export const PASSO_PERMISSAO = 'Pedido de permissão';
export const FLUXO_TELA = 'Tela';

/** Telas onde sair é o fim natural da visita (não são ponto de atenção). */
export const TELAS_FORA = ['/'];

const taxa = (e: Etapa) => (e.chegaram - e.seguiram) / e.chegaram;
const arred = (n: number, casas: number) => Math.round(n * 10 ** casas) / 10 ** casas;
const chave = (e: Etapa) => `${e.fluxo}\u0000${e.passo}`;

/**
 * Até 5 pontos, pela maior piora: passos com < 30 pessoas ficam fora; sem comparação, a taxa de saída desempata.
 * De cada fluxo entra só o passo com mais saída (as telas contam uma a uma).
 */
export function pontosDeAtencao(atual: Etapa[], anterior: Etapa[]): Ponto[] {
  const antes = new Map(anterior.filter((e) => e.chegaram >= MINIMO_PESSOAS).map((e) => [chave(e), taxa(e)]));
  const melhorDoFluxo = new Map<string, Ponto>();
  for (const e of atual) {
    if (e.chegaram < MINIMO_PESSOAS || e.seguiram > e.chegaram) continue;
    if (e.fluxo === FLUXO_TELA && TELAS_FORA.includes(e.passo)) continue;
    const saida = taxa(e);
    const anteriorTaxa = antes.get(chave(e));
    const p: Ponto = {
      ...e,
      saida: arred(saida, 3),
      variacaoPp: anteriorTaxa === undefined ? null : arred((saida - anteriorTaxa) * 100, 1),
    };
    const grupo = e.fluxo === FLUXO_TELA ? chave(e) : e.fluxo;
    const atualDoGrupo = melhorDoFluxo.get(grupo);
    if (!atualDoGrupo || p.saida > atualDoGrupo.saida) melhorDoFluxo.set(grupo, p);
  }
  return [...melhorDoFluxo.values()]
    .sort((a, b) => (b.variacaoPp ?? -Infinity) - (a.variacaoPp ?? -Infinity) || b.saida - a.saida)
    .slice(0, MAXIMO_ITENS);
}

/** Lê as duas janelas e monta os pontos; o erro sobe para quem chama decidir o estado. */
export async function lerPontosAtencao(fonte: FonteAtencao, dia: string): Promise<PontosAtencao> {
  const inicio = somarDias(dia, 1 - JANELA_DIAS);
  const [atual, anterior] = await Promise.all([
    fonte.etapas(inicio, dia),
    fonte.etapas(somarDias(inicio, -JANELA_DIAS), somarDias(inicio, -1)),
  ]);
  return { inicio, fim: dia, itens: pontosDeAtencao(atual, anterior) };
}

// ---- Resposta do runFunnelReport ----

type Valor = { value?: string | null } | null;
type Linha = { dimensionValues?: Valor[] | null; metricValues?: Valor[] | null } | null;
export interface RespostaFunil {
  funnelTable?: {
    dimensionHeaders?: ({ name?: string | null } | null)[] | null;
    metricHeaders?: ({ name?: string | null } | null)[] | null;
    rows?: Linha[] | null;
  } | null;
}

/** O pedido do funil (sem breakdown): um passo por evento, com OR quando há mais de um. */
export function pedidoDoFunil(propriedade: string, funil: Funil, inicio: string, fim: string) {
  return {
    property: `properties/${propriedade}`,
    dateRanges: [{ startDate: inicio, endDate: fim }],
    funnel: {
      steps: funil.passos.map((p) => ({
        name: p.nome,
        filterExpression:
          p.eventos.length === 1
            ? { funnelEventFilter: { eventName: p.eventos[0] } }
            : { orGroup: { expressions: p.eventos.map((eventName) => ({ funnelEventFilter: { eventName } })) } },
      })),
    },
  };
}

/** Do funnelTable às etapas: quem chegou no passo n e quem chegou no n+1. O último passo não tem saída. */
export function etapasDoFunil(funil: Funil, resposta: RespostaFunil): Etapa[] {
  const tabela = resposta.funnelTable;
  if (!tabela) throw new Error('runFunnelReport sem funnelTable');
  const iPasso = (tabela.dimensionHeaders ?? []).findIndex((h) => h?.name === 'funnelStepName');
  const iPessoas = (tabela.metricHeaders ?? []).findIndex((h) => h?.name === 'activeUsers');
  if (iPasso < 0 || iPessoas < 0) throw new Error('runFunnelReport sem funnelStepName ou activeUsers');
  const pessoas = new Map<string, number>();
  for (const r of tabela.rows ?? []) {
    const nome = r?.dimensionValues?.[iPasso]?.value ?? '';
    // "1. Primeira abertura" → "Primeira abertura"
    pessoas.set(nome.replace(/^\d+\.\s*/, ''), Number(r?.metricValues?.[iPessoas]?.value ?? 0));
  }
  const etapas: Etapa[] = [];
  for (let i = 0; i < funil.passos.length - 1; i++) {
    etapas.push({
      fluxo: funil.fluxo,
      passo: funil.passos[i].nome,
      chegaram: pessoas.get(funil.passos[i].nome) ?? 0,
      seguiram: pessoas.get(funil.passos[i + 1].nome) ?? 0,
    });
  }
  return etapas;
}

// ---- SQL do BigQuery (telas e permissão) ----

const DATASET = /^[A-Za-z0-9_]+$/;

/** Por tela: quem a viu e quem terminou uma sessão nela, nos dias `@inicio`..`@fim` (aaaammdd). */
export function sqlTelas(dataset: string): string {
  if (!DATASET.test(dataset)) throw new Error(`dataset inválido: ${dataset}`);
  return `
WITH v AS (
  SELECT user_pseudo_id AS u,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS s,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'firebase_screen') AS tela,
    event_timestamp AS t
  FROM \`${dataset}.events_*\`
  WHERE _TABLE_SUFFIX BETWEEN @inicio AND @fim AND event_name = 'screen_view'
),
ultimas AS (
  SELECT u, ARRAY_AGG(tela ORDER BY t DESC LIMIT 1)[OFFSET(0)] AS tela
  FROM v WHERE tela IS NOT NULL GROUP BY u, s
),
viram AS (SELECT tela, COUNT(DISTINCT u) AS chegaram FROM v WHERE tela IS NOT NULL GROUP BY tela),
sairam AS (SELECT tela, COUNT(DISTINCT u) AS sairam FROM ultimas GROUP BY tela)
SELECT viram.tela, viram.chegaram, IFNULL(sairam.sairam, 0) AS sairam
FROM viram LEFT JOIN sairam USING (tela)
ORDER BY viram.chegaram DESC
LIMIT 200`;
}

/** A última resposta de cada pessoa à permissão de notificação (`aviso_permitido`: sim|nao; `nunca` não conta). */
export function sqlPermissao(dataset: string): string {
  if (!DATASET.test(dataset)) throw new Error(`dataset inválido: ${dataset}`);
  return `
SELECT COUNTIF(v IN ('sim', 'nao')) AS chegaram, COUNTIF(v = 'sim') AS seguiram
FROM (
  SELECT user_pseudo_id, ARRAY_AGG(up.value.string_value ORDER BY event_timestamp DESC LIMIT 1)[OFFSET(0)] AS v
  FROM \`${dataset}.events_*\`, UNNEST(user_properties) AS up
  WHERE _TABLE_SUFFIX BETWEEN @inicio AND @fim AND up.key = 'aviso_permitido'
  GROUP BY user_pseudo_id
)`;
}

export function etapasDasTelas(rows: Record<string, unknown>[]): Etapa[] {
  return rows.map((r) => {
    const chegaram = Number(r.chegaram ?? 0);
    return { fluxo: FLUXO_TELA, passo: String(r.tela), chegaram, seguiram: chegaram - Number(r.sairam ?? 0) };
  });
}

export function etapaDaPermissao(row: Record<string, unknown> | undefined): Etapa {
  return {
    fluxo: FLUXO_PERMISSAO,
    passo: PASSO_PERMISSAO,
    chegaram: Number(row?.chegaram ?? 0),
    seguiram: Number(row?.seguiram ?? 0),
  };
}
