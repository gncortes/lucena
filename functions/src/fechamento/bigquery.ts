// O export do Analytics no BigQuery (dataset `analytics_<propriedade>` do mesmo projeto).
import { BigQuery } from '@google-cloud/bigquery';
import { EVENTOS, sqlAtivos, sqlDoDia, type LinhaEvento } from './consultas';
import { somarDias, sufixo } from './datas';
import type { Analytics } from './fechar';

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
