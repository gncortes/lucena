// Do export do Analytics e das compras ao documento do dia, do mês e ao
// relatório do agente (R5 §2). Só contagens: nenhum dado pessoal.
import { ATIVOS_APP, ATIVOS_CURSO, type LinhaEvento } from './consultas';

export type Arvore = { [chave: string]: number | Arvore };

/** Uma liberação de curso do dia, lida de `acessos` (não do Analytics). */
export interface Compra {
  curso: string;
  origem: string;
  plano: string;
  pais: string;
  receitaCentavos: number;
}

export interface Contadores {
  cursos: Arvore;
  aulas: Arvore;
  redes: Arvore;
  paises: Arvore;
}

export type EstadoAnalytics = 'ok' | 'incompleto';

export const VERSAO_ESQUEMA = 1;

/** Limite do relatório que o agente PO lê. */
export const LIMITE_RELATORIO = 50 * 1024;

/** Ids de aula e exercício viram chave de mapa: sem ponto, barra nem vazio. */
function chave(valor: string | null | undefined, padrao: string): string {
  const v = (valor ?? '').trim().replace(/[./\s]+/g, '_');
  return v.length > 0 ? v : padrao;
}

function somar(arvore: Arvore, caminho: string[], n: number): void {
  let no = arvore;
  for (const parte of caminho.slice(0, -1)) {
    const filho = no[parte];
    if (typeof filho !== 'object') no[parte] = {};
    no = no[parte] as Arvore;
  }
  const folha = caminho[caminho.length - 1];
  const atual = no[folha];
  no[folha] = (typeof atual === 'number' ? atual : 0) + n;
}

/** As contagens do dia (ou de hoje até agora) por curso, aula, rede e país. */
export function contar(linhas: readonly LinhaEvento[], compras: readonly Compra[]): Contadores {
  const c: Contadores = { cursos: {}, aulas: {}, redes: {}, paises: {} };
  for (const l of linhas) {
    const pais = chave(l.pais, 'ZZ').toUpperCase();
    const curso = chave(l.curso, '');
    const aula = chave(l.aula, 'semAula');
    switch (l.evento) {
      case 'treino_objetivo_definido':
        if (!curso) break;
        somar(c.cursos, [curso, 'inscritos'], l.pessoas);
        somar(c.cursos, [curso, 'paises', pais, 'inscritos'], l.pessoas);
        break;
      case 'treino_meta_inicio':
        if (curso) somar(c.cursos, [curso, 'metas', 'marcadas'], l.eventos);
        break;
      case 'treino_meta_fim':
        if (curso && l.acertou === 'sim') somar(c.cursos, [curso, 'metas', 'cumpridas'], l.eventos);
        break;
      case 'treino_ciclo_fim':
        if (curso) somar(c.cursos, [curso, 'ciclos'], l.eventos);
        break;
      case ATIVOS_CURSO:
        if (curso) somar(c.cursos, [curso, 'ativos'], l.pessoas);
        break;
      case 'pilares_oferta_vista':
        somar(c.cursos, ['pilares', 'pagina'], l.pessoas);
        somar(c.cursos, ['pilares', 'paises', pais, 'pagina'], l.pessoas);
        break;
      case 'demo_inicio':
        somar(c.cursos, ['pilares', 'demo'], l.pessoas);
        somar(c.cursos, ['pilares', 'paises', pais, 'demo'], l.pessoas);
        break;
      case 'aula_aberta':
        somar(c.aulas, [aula, 'abriram'], l.pessoas);
        break;
      case 'aula_concluida':
        somar(c.aulas, [aula, 'concluiram'], l.pessoas);
        break;
      case 'aula_capitulo_inicio':
        somar(c.aulas, [aula, 'capitulos', chave(l.capitulo, 'semCapitulo'), 'iniciaram'], l.pessoas);
        break;
      case 'aula_capitulo_fim':
        somar(c.aulas, [aula, 'capitulos', chave(l.capitulo, 'semCapitulo'), 'concluiram'], l.pessoas);
        break;
      case 'exercicio_resultado':
        if (l.acertou === 'nao') somar(c.aulas, [aula, 'erros', chave(l.exercicio, 'semExercicio')], l.eventos);
        break;
      case 'aula_saida':
        somar(c.aulas, [aula, 'saida', chave(l.exercicio ?? l.capitulo, 'inicio')], l.eventos);
        break;
      case 'campanha_link_aberto':
        somar(c.redes, [chave(l.fonte, 'direto'), pais, 'abriram'], l.pessoas);
        break;
      case 'campanha_instalacao':
        somar(c.redes, [chave(l.fonte, 'direto'), pais, 'instalaram'], l.pessoas);
        break;
      case ATIVOS_APP:
        somar(c.paises, [pais, 'ativos'], l.pessoas);
        break;
    }
  }
  for (const k of compras) {
    const curso = chave(k.curso, 'semCurso');
    const pais = chave(k.pais, 'ZZ').toUpperCase();
    const tipo = k.origem === 'presente' ? 'presente' : chave(k.plano, 'vitalicio');
    somar(c.cursos, [curso, 'compras', tipo], 1);
    somar(c.cursos, [curso, 'receitaCentavos'], k.receitaCentavos);
    somar(c.cursos, [curso, 'paises', pais, 'compras'], 1);
    somar(c.cursos, [curso, 'paises', pais, 'receitaCentavos'], k.receitaCentavos);
  }
  return c;
}

/** Cópia sem os nós que não se somam entre dias (pessoas distintas) ou que só servem ao dia. */
function filtrar(arvore: Arvore, fora: (chave: string) => boolean): Arvore {
  const saida: Arvore = {};
  for (const [k, v] of Object.entries(arvore)) {
    if (fora(k)) continue;
    saida[k] = typeof v === 'number' ? v : filtrar(v, fora);
  }
  return saida;
}

function somarArvores(a: Arvore, b: Arvore): Arvore {
  const saida: Arvore = filtrar(a, () => false);
  for (const [k, v] of Object.entries(b)) {
    const atual = saida[k];
    if (typeof v === 'number') {
      saida[k] = (typeof atual === 'number' ? atual : 0) + v;
    } else {
      saida[k] = somarArvores(typeof atual === 'object' ? atual : {}, v);
    }
  }
  return saida;
}

const naoSoma = (k: string) => k.startsWith('ativos');
const soDoDia = (k: string) => naoSoma(k) || k === 'erros' || k === 'saida' || k === 'capitulos';

function somaveis(c: Contadores, fora: (k: string) => boolean): Arvore {
  return filtrar({ cursos: c.cursos, aulas: c.aulas, redes: c.redes, paises: c.paises }, fora);
}

export interface ResumoDia extends Contadores {
  dia: string;
  fechadoEm: Date;
  versaoEsquema: number;
  fontes: { analytics: EstadoAnalytics; play: 'ok' };
  ativos: Record<string, number>;
  pontosAtencao: unknown[];
  acum: Arvore;
}

/**
 * O documento `resumosDia/{dia}`. `acum` = o do último dia fechado + o deste
 * (sem ativos, erros, saídas e capítulos, que valem só para o dia).
 */
export function montarResumoDia(args: {
  dia: string;
  contadores: Contadores;
  ativos: Record<string, number>;
  acumAnterior: Arvore | null;
  analytics: EstadoAnalytics;
  fechadoEm: Date;
}): ResumoDia {
  return {
    dia: args.dia,
    fechadoEm: args.fechadoEm,
    versaoEsquema: VERSAO_ESQUEMA,
    fontes: { analytics: args.analytics, play: 'ok' },
    ...args.contadores,
    ativos: args.ativos,
    pontosAtencao: [],
    acum: somarArvores(args.acumAnterior ?? {}, somaveis(args.contadores, soDoDia)),
  };
}

export interface ResumoMes {
  mes: string;
  dias: string[];
  atualizadoEm: Date;
  versaoEsquema: number;
  fontes: { analytics: EstadoAnalytics; play: 'ok' };
  cursos: Arvore;
  aulas: Arvore;
  redes: Arvore;
  paises: Arvore;
  ativos: Record<string, number>;
  acum: Arvore;
}

/**
 * Soma o dia em `resumosMes/{aaaa-mm}`. Dia já somado não soma de novo.
 * Mensal: mesmo formato, sem capítulos, erros nem saídas.
 */
export function somarNoMes(mes: ResumoMes | null, dia: ResumoDia, ativosDoMes: Record<string, number>): ResumoMes {
  const base: ResumoMes = mes ?? {
    mes: dia.dia.slice(0, 7),
    dias: [],
    atualizadoEm: dia.fechadoEm,
    versaoEsquema: VERSAO_ESQUEMA,
    fontes: { analytics: 'ok', play: 'ok' },
    cursos: {},
    aulas: {},
    redes: {},
    paises: {},
    ativos: {},
    acum: {},
  };
  if (base.dias.includes(dia.dia)) return base;
  const doDia = somaveis(dia, soDoDia);
  return {
    ...base,
    dias: [...base.dias, dia.dia].sort(),
    atualizadoEm: dia.fechadoEm,
    fontes: {
      analytics: base.fontes.analytics === 'incompleto' || dia.fontes.analytics === 'incompleto' ? 'incompleto' : 'ok',
      play: 'ok',
    },
    cursos: somarArvores(base.cursos, doDia.cursos as Arvore),
    aulas: somarArvores(base.aulas, doDia.aulas as Arvore),
    redes: somarArvores(base.redes, doDia.redes as Arvore),
    paises: somarArvores(base.paises, doDia.paises as Arvore),
    ativos: { ...base.ativos, ...ativosDoMes },
    acum: dia.acum,
  };
}

/** Os N maiores de um mapa de contagens (o resto some do relatório). */
function maiores(arvore: Arvore, n: number): Arvore {
  return Object.fromEntries(
    Object.entries(arvore)
      .filter((e): e is [string, number] => typeof e[1] === 'number')
      .sort((a, b) => b[1] - a[1])
      .slice(0, n),
  );
}

function tamanho(valor: unknown): number {
  return Buffer.byteLength(JSON.stringify(valor), 'utf8');
}

/**
 * `relatorios/{dia}`: o resumo sem campos de controle, ≤ 50 KB. Se passar,
 * erros e saídas ficam só nos 5 maiores por aula; se ainda passar, saem os capítulos.
 */
export function montarRelatorio(r: ResumoDia): { relatorio: Record<string, unknown>; cortado: boolean } {
  const { fechadoEm: _f, versaoEsquema: _v, acum: _a, ...resto } = r;
  let relatorio: Record<string, unknown> = { ...resto };
  if (tamanho(relatorio) <= LIMITE_RELATORIO) return { relatorio, cortado: false };

  const cortar = (fora: (k: string) => boolean, topo: number) => {
    const aulas: Arvore = {};
    for (const [id, a] of Object.entries(r.aulas)) {
      if (typeof a === 'number') continue;
      const nova: Arvore = {};
      for (const [k, v] of Object.entries(a)) {
        if (fora(k)) continue;
        nova[k] = typeof v === 'object' && (k === 'erros' || k === 'saida') ? maiores(v, topo) : v;
      }
      aulas[id] = nova;
    }
    return { ...resto, aulas };
  };
  relatorio = cortar(() => false, 5);
  if (tamanho(relatorio) > LIMITE_RELATORIO) relatorio = cortar((k) => k === 'capitulos', 3);
  return { relatorio, cortado: true };
}
