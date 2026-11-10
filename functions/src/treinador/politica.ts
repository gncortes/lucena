// T87 · Configuração do painel, direito `treinador`, cotas e orçamento: quem entra na fila e com quantos nós.
import { type DocumentData, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { CONFIG_PADRAO, type ConfigAnalise } from './analise';

/** `treinador_config/geral` com os padrões para campo ausente (o painel pode gravar só parte). */
export interface ConfigTreinador {
  ativo: boolean;
  exerciciosPorPartida: number;
  orcamentoMensalUsd: number;
  /** Grátis entra na fila (enquanto houver orçamento). */
  filaGratis: boolean;
  gratisPorSemana: number;
  tetoMensalAssinante: number;
  nosUsuario: number;
  nosDemais: number;
  /** Nós do grátis (todas as posições). */
  nosGratis: number;
  pushLigado: boolean;
  tipos: ConfigAnalise['tipos'];
}

export const CONFIG_TREINADOR_PADRAO: ConfigTreinador = {
  ativo: true,
  exerciciosPorPartida: 4,
  orcamentoMensalUsd: 20,
  filaGratis: true,
  gratisPorSemana: 2,
  tetoMensalAssinante: 150,
  nosUsuario: 1_000_000,
  nosDemais: 300_000,
  nosGratis: 300_000,
  pushLigado: true,
  tipos: CONFIG_PADRAO.tipos,
};

function num(v: unknown, padrao: number, min: number, max: number): number {
  return typeof v === 'number' && Number.isFinite(v) ? Math.max(min, Math.min(max, Math.round(v))) : padrao;
}

function bool(v: unknown, padrao: boolean): boolean {
  return typeof v === 'boolean' ? v : padrao;
}

export function lerConfig(d: DocumentData | undefined): ConfigTreinador {
  const p = CONFIG_TREINADOR_PADRAO;
  const c = d ?? {};
  const t = (c.tipos ?? {}) as Record<string, unknown>;
  return {
    ativo: bool(c.ativo, p.ativo),
    exerciciosPorPartida: num(c.exerciciosPorPartida, p.exerciciosPorPartida, 1, 6),
    orcamentoMensalUsd:
      typeof c.orcamentoMensalUsd === 'number' && c.orcamentoMensalUsd >= 0 ? c.orcamentoMensalUsd : p.orcamentoMensalUsd,
    filaGratis: bool(c.filaGratis, p.filaGratis),
    gratisPorSemana: num(c.gratisPorSemana, p.gratisPorSemana, 0, 50),
    tetoMensalAssinante: num(c.tetoMensalAssinante, p.tetoMensalAssinante, 1, 10_000),
    nosUsuario: num(c.nosUsuario, p.nosUsuario, 50_000, 5_000_000),
    nosDemais: num(c.nosDemais, p.nosDemais, 20_000, 5_000_000),
    nosGratis: num(c.nosGratis, p.nosGratis, 20_000, 5_000_000),
    pushLigado: bool(c.pushLigado, p.pushLigado),
    tipos: {
      seu_melhor: bool(t.seu_melhor, p.tipos.seu_melhor),
      adversario: bool(t.adversario, p.tipos.adversario),
      decisivo: bool(t.decisivo, p.tipos.decisivo),
    },
  };
}

export async function config(db: Firestore): Promise<ConfigTreinador> {
  return lerConfig((await db.doc('treinador_config/geral').get()).data());
}

/** Direito vigente: sem `revogadoEm` e com `ate` futuro (ou sem `ate`). */
export function direitoVigente(c: DocumentData | undefined, agora: Date): boolean {
  if (!c || c.revogadoEm) return false;
  const ate = c.ate;
  if (ate === undefined || ate === null) return true;
  const ms = ate instanceof Timestamp ? ate.toMillis() : ate instanceof Date ? ate.getTime() : Date.parse(String(ate));
  return Number.isFinite(ms) && ms > agora.getTime();
}

export async function ehAssinante(db: Firestore, uid: string, agora: Date): Promise<boolean> {
  const a = await db.doc(`acessos/${uid}`).get();
  return direitoVigente(a.get('cursos.treinador'), agora);
}

// ---------------------------------------------------------------- datas (America/Sao_Paulo)

/** "AAAA-MM-DD" no fuso de Brasília (UTC−3, sem horário de verão desde 2019). */
export function diaBR(d: Date): string {
  return new Date(d.getTime() - 3 * 3600_000).toISOString().slice(0, 10);
}

export function mesBR(d: Date): string {
  return diaBR(d).slice(0, 7);
}

/** Segunda-feira da semana ("AAAA-MM-DD"), no fuso de Brasília. */
export function semanaBR(d: Date): string {
  const br = new Date(d.getTime() - 3 * 3600_000);
  const dow = (br.getUTCDay() + 6) % 7;
  return new Date(br.getTime() - dow * 86_400_000).toISOString().slice(0, 10);
}

/** Dias no mês de "AAAA-MM". */
export function diasNoMes(mes: string): number {
  const [a, m] = mes.split('-').map(Number);
  return new Date(Date.UTC(a, m, 0)).getUTCDate();
}

// ---------------------------------------------------------------- decisão

export type Plano = 'assinante' | 'gratis';

export type Decisao =
  | { entra: true; plano: Plano; espera: 'orcamento' | null }
  | { entra: false; plano: Plano; motivo: 'inativo' | 'cota' | 'teto' };

/**
 * Cota do usuário em `treinador_contas/{uid}`: `semana {id, n}` (grátis) e `mes {id, n}` (assinante).
 * Orçamento a 100%: grátis espera na fila (`espera: 'orcamento'`), assinante segue.
 */
export function decidir(
  cfg: ConfigTreinador,
  plano: Plano,
  conta: DocumentData | undefined,
  gastoMesUsd: number,
  agora: Date,
): Decisao {
  if (!cfg.ativo) return { entra: false, plano, motivo: 'inativo' };
  if (plano === 'assinante') {
    const n = conta?.mes?.id === mesBR(agora) ? Number(conta.mes.n) || 0 : 0;
    if (n >= cfg.tetoMensalAssinante) return { entra: false, plano, motivo: 'teto' };
    return { entra: true, plano, espera: null };
  }
  if (!cfg.filaGratis) return { entra: false, plano, motivo: 'inativo' };
  const n = conta?.semana?.id === semanaBR(agora) ? Number(conta.semana.n) || 0 : 0;
  if (n >= cfg.gratisPorSemana) return { entra: false, plano, motivo: 'cota' };
  const estourado = cfg.orcamentoMensalUsd > 0 && gastoMesUsd >= cfg.orcamentoMensalUsd;
  return { entra: true, plano, espera: estourado ? 'orcamento' : null };
}

/** Campos que somam 1 na cota da conta (merge em `treinador_contas/{uid}`). */
export function somarCota(conta: DocumentData | undefined, plano: Plano, agora: Date): DocumentData {
  if (plano === 'assinante') {
    const id = mesBR(agora);
    const n = conta?.mes?.id === id ? Number(conta.mes.n) || 0 : 0;
    return { mes: { id, n: n + 1 } };
  }
  const id = semanaBR(agora);
  const n = conta?.semana?.id === id ? Number(conta.semana.n) || 0 : 0;
  return { semana: { id, n: n + 1 } };
}

/** Configuração da análise pelo plano: grátis usa `nosGratis` em todas as posições. */
export function configDaAnalise(cfg: ConfigTreinador, plano: Plano): ConfigAnalise {
  const nos = plano === 'assinante' ? { nosUsuario: cfg.nosUsuario, nosDemais: cfg.nosDemais } : { nosUsuario: cfg.nosGratis, nosDemais: cfg.nosGratis };
  return { ...nos, exercicios: cfg.exerciciosPorPartida, tipos: cfg.tipos };
}

/**
 * Preço do Cloud Run/Functions 2ª geração no tier 2 (southamerica-east1): vCPU-s e GiB-s, sem a cota grátis.
 * A análise roda com 1 vCPU e 2 GiB.
 */
export const PRECO = { vcpuSeg: 0.0000336, gibSeg: 0.0000035, vcpu: 1, gib: 2 };

export function custoUsd(segundos: number): number {
  return segundos * (PRECO.vcpu * PRECO.vcpuSeg + PRECO.gib * PRECO.gibSeg);
}
