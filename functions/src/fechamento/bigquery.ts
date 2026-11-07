// O export do Analytics no BigQuery (dataset `analytics_<propriedade>` do mesmo projeto).
import { v1alpha } from '@google-analytics/data';
import { BigQuery } from '@google-cloud/bigquery';
import {
  etapaDaPermissao,
  etapasDasTelas,
  etapasDoFunil,
  FUNIS,
  pedidoDoFunil,
  sqlPermissao,
  sqlTelas,
  type FonteAtencao,
  type RespostaFunil,
} from './atencao';
import { EVENTOS, sqlAtivos, sqlDoDia, type LinhaEvento } from './consultas';
import { somarDias, sufixo } from './datas';
import type { Analytics } from './fechar';
import type { FonteAtivos } from './periodo';

function texto(v: unknown): string | null {
  return v === null || v === undefined ? null : String(v);
}

function paraLinha(r: Record<string, unknown>): LinhaEvento {
  return {
    evento: String(r.evento),
    pais: String(r.pais ?? 'ZZ'),
    curso: texto(r.curso),
    aula: texto(r.aula),
    capitulo: texto(r.capitulo),
    exercicio: texto(r.exercicio),
    acertou: texto(r.acertou),
    fonte: texto(r.fonte),
    eventos: Number(r.eventos ?? 0),
    pessoas: Number(r.pessoas ?? 0),
  };
}

export function analyticsDoBigQuery(dataset: string, bq = new BigQuery()): Analytics {
  const tabelaExiste = async (tabela: string) => {
    const [existe] = await bq.dataset(dataset).table(tabela).exists();
    return existe;
  };
  const linhas = async (tabela: string) => {
    const [rows] = await bq.query({
      query: sqlDoDia(`${dataset}.${tabela}`),
      params: { eventos: [...EVENTOS] },
    });
    return (rows as Record<string, unknown>[]).map(paraLinha);
  };
  return {
    exportPronto: (dia) => tabelaExiste(`events_${sufixo(dia)}`),
    linhasDoDia: (dia) => linhas(`events_${sufixo(dia)}`),
    async linhasDeHoje(dia) {
      const tabela = `events_intraday_${sufixo(dia)}`;
      return (await tabelaExiste(tabela)) ? linhas(tabela) : null;
    },
    async ativos(dia, janelas) {
      const maior = Math.max(...Object.values(janelas));
      const params: Record<string, string> = {
        inicio: sufixo(somarDias(dia, 1 - maior)),
        fim: sufixo(dia),
      };
      for (const [nome, dias] of Object.entries(janelas)) params[nome] = sufixo(somarDias(dia, 1 - dias));
      const [rows] = await bq.query({ query: sqlAtivos(dataset, janelas), params });
      const r = (rows as Record<string, unknown>[])[0] ?? {};
      return Object.fromEntries(Object.keys(janelas).map((k) => [k, Number(r[k] ?? 0)]));
    },
  };
}

/** H-R5-36 · Pessoas distintas ativas no período, numa consulta (a mesma SQL das janelas, com uma janela só). */
export function ativosDoBigQuery(dataset: string, bq: Pick<BigQuery, 'query'> = new BigQuery()): FonteAtivos {
  return {
    async ativosEntre(inicio, fim) {
      const params = { inicio: sufixo(inicio), fim: sufixo(fim), ativosPeriodo: sufixo(inicio) };
      const [rows] = await bq.query({ query: sqlAtivos(dataset, { ativosPeriodo: 0 }), params });
      return Number((rows as Record<string, unknown>[])[0]?.ativosPeriodo ?? 0);
    },
  };
}

/** O pedaço da Data API (v1alpha) que os pontos de atenção usam; nos testes, uma resposta gravada. */
export interface ClienteFunil {
  runFunnelReport(pedido: ReturnType<typeof pedidoDoFunil>): Promise<[RespostaFunil, ...unknown[]]>;
}

/** Funis pela GA4 Data API; permissão e telas pelo export no BigQuery. Datas em aaaa-mm-dd. */
export function atencaoDoAnalytics(
  dataset: string,
  propriedade: string,
  bq: Pick<BigQuery, 'query'> = new BigQuery(),
  ga: ClienteFunil = new v1alpha.AlphaAnalyticsDataClient() as unknown as ClienteFunil,
): FonteAtencao {
  return {
    async etapas(inicio, fim) {
      const params = { inicio: sufixo(inicio), fim: sufixo(fim) };
      const [funis, [telas], [permissao]] = await Promise.all([
        Promise.all(
          FUNIS.map(async (f) => etapasDoFunil(f, (await ga.runFunnelReport(pedidoDoFunil(propriedade, f, inicio, fim)))[0])),
        ),
        bq.query({ query: sqlTelas(dataset), params }),
        bq.query({ query: sqlPermissao(dataset), params }),
      ]);
      return [
        ...funis.flat(),
        etapaDaPermissao((permissao as Record<string, unknown>[])[0]),
        ...etapasDasTelas(telas as Record<string, unknown>[]),
      ];
    },
  };
}
