// H-R5-37 · Decidir um item da Caixa e conferir as fontes (R5 §4 e §11 R9/R13).
// Tudo numa transação: o item precisa estar aguardando; quem chega depois de outro admin recebe `jaDecidido`.
// A reprovação também vai a `decisoes/{id}`, que o fechamento põe no relatório do agente ("decisões recentes").
import { Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { diaLocal, somarDias } from '../fechamento/datas';

/** Estados em que o item espera o Gabriel na Caixa (contrato do embasamento §4). */
export const PENDENTES = ['sugerido', 'aguardandoVideo'] as const;

/** Motivos da folha de reprovar (R5 §4); `outro` exige a frase. */
export const MOTIVOS = [
  'fatoErrado',
  'lanceErrado',
  'textoForaDoPadrao',
  'temaRepetido',
  'naoServePublico',
  'outro',
] as const;
export type Motivo = (typeof MOTIVOS)[number];

export interface DepsEntregas {
  db: Firestore;
  agora: Date;
}

/** Por que o Aprovar segue travado (o painel mostra o motivo). */
export type Trava = 'semVideo' | 'fonteNaoConferida' | 'fatoDeHoje';

function invalido(msg: string): never {
  throw new HttpsError('invalid-argument', msg);
}

function idValido(v: unknown): string {
  if (typeof v !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(v)) invalido('Informe o id do item.');
  return v;
}

function texto(v: unknown, max: number, campo: string): string | null {
  if (v === undefined || v === null || v === '') return null;
  if (typeof v !== 'string' || v.trim().length === 0 || v.length > max) invalido(`${campo}: texto até ${max} caracteres.`);
  return v.trim();
}

function semItem(): never {
  throw new HttpsError('not-found', 'Item não encontrado.', { codigo: 'itemNaoExiste' });
}

function jaDecidido(): never {
  throw new HttpsError('failed-precondition', 'Este post já foi decidido.', { codigo: 'jaDecidido' });
}

const pendente = (e: DocumentData) => (PENDENTES as readonly string[]).includes(e.estado);

/** Vídeo: formato `video` (o roteiro de cenas) precisa de uma mídia de vídeo antes de aprovar. */
function precisaVideo(e: DocumentData): boolean {
  return e.formato === 'video';
}

function temVideo(e: DocumentData): boolean {
  return Array.isArray(e.midias) && e.midias.some((m: DocumentData) => m?.tipo === 'video' && m?.url);
}

/** O que impede aprovar, na ordem em que o painel mostra (vazio = pode). */
export function travasDeAprovar(e: DocumentData, ontem: string): Trava[] {
  const travas: Trava[] = [];
  if (precisaVideo(e) && !temVideo(e)) travas.push('semVideo');
  const fontes: DocumentData[] = Array.isArray(e.fontes) ? e.fontes : [];
  if (fontes.some((f) => !f?.conferidaEm)) travas.push('fonteNaoConferida');
  const datas = [e.dataFato, ...fontes.map((f) => f?.data)].filter((d): d is string => typeof d === 'string');
  if (datas.some((d) => d.slice(0, 10) > ontem)) travas.push('fatoDeHoje');
  return travas;
}

export interface Decidido {
  id: string;
  estado: 'aprovado' | 'reprovado';
}

/**
 * `{id, decisao: 'aprovar'|'reprovar', motivo?, frase?, agendadoPara?}`. Reprovar exige motivo (e frase em `outro`);
 * aprovar recusa com `travado` + `travas` (sem vídeo, fonte não conferida, fato de hoje).
 */
export async function decidirEntregaCore(d: DepsEntregas, admin: string, dados: unknown): Promise<Decidido> {
  const p = (dados ?? {}) as Record<string, unknown>;
  const id = idValido(p.id);
  const decisao = p.decisao;
  if (decisao !== 'aprovar' && decisao !== 'reprovar') invalido('Decisão: aprovar ou reprovar.');

  let motivo: Motivo | null = null;
  let frase: string | null = null;
  let agendadoPara: Timestamp | null = null;
  if (decisao === 'reprovar') {
    if (!(MOTIVOS as readonly unknown[]).includes(p.motivo)) invalido('Escolha o motivo da reprovação.');
    motivo = p.motivo as Motivo;
    frase = texto(p.frase, 300, 'Frase');
    if (motivo === 'outro' && !frase) invalido('Em "Outro", escreva o motivo.');
  } else if (p.agendadoPara !== undefined && p.agendadoPara !== null) {
    const ms = typeof p.agendadoPara === 'string' ? Date.parse(p.agendadoPara) : NaN;
    if (Number.isNaN(ms) || ms <= d.agora.getTime()) invalido('Agende para um horário futuro (ISO 8601).');
    agendadoPara = Timestamp.fromMillis(ms);
  }

  const ref = d.db.doc(`entregas/${id}`);
  const ontem = somarDias(diaLocal(d.agora), -1);
  const em = Timestamp.fromDate(d.agora);
  return d.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) semItem();
    const e = snap.data()!;
    if (!pendente(e)) jaDecidido();

    if (decisao === 'aprovar') {
      const travas = travasDeAprovar(e, ontem);
      if (travas.length > 0) {
        throw new HttpsError('failed-precondition', 'O post ainda não pode ser aprovado.', { codigo: 'travado', travas });
      }
      tx.update(ref, {
        estado: 'aprovado',
        decisao: { acao: 'aprovar', por: admin, em, agendadoPara },
        atualizadoEm: em,
      });
      return { id, estado: 'aprovado' as const };
    }

    tx.update(ref, {
      estado: 'reprovado',
      decisao: { acao: 'reprovar', motivo, frase, por: admin, em },
      atualizadoEm: em,
    });
    tx.create(d.db.collection('decisoes').doc(), {
      entregaId: id,
      acao: 'reprovar',
      motivo,
      frase,
      titulo: typeof e.titulo === 'string' ? e.titulo : null,
      formato: typeof e.formato === 'string' ? e.formato : null,
      pais: typeof e.pais === 'string' ? e.pais : null,
      por: admin,
      em,
      dia: diaLocal(d.agora),
    });
    return { id, estado: 'reprovado' as const };
  });
}

/** `{id, indice}`: marca `fontes[indice]` como conferida pelo admin (idempotente: a 1ª conferência fica). */
export async function marcarFonteConferidaCore(
  d: DepsEntregas,
  admin: string,
  dados: unknown,
): Promise<{ id: string; indice: number; pendentes: number }> {
  const p = (dados ?? {}) as Record<string, unknown>;
  const id = idValido(p.id);
  const indice = p.indice;
  if (typeof indice !== 'number' || !Number.isInteger(indice) || indice < 0) invalido('Índice da fonte inválido.');

  const ref = d.db.doc(`entregas/${id}`);
  return d.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) semItem();
    const e = snap.data()!;
    if (!pendente(e)) jaDecidido();
    const fontes: DocumentData[] = Array.isArray(e.fontes) ? [...e.fontes] : [];
    if (indice >= fontes.length) {
      throw new HttpsError('not-found', 'Fonte não encontrada.', { codigo: 'fonteNaoExiste' });
    }
    if (!fontes[indice].conferidaEm) {
      fontes[indice] = { ...fontes[indice], conferidaPor: admin, conferidaEm: Timestamp.fromDate(d.agora) };
      tx.update(ref, { fontes, atualizadoEm: Timestamp.fromDate(d.agora) });
    }
    return { id, indice, pendentes: fontes.filter((f) => !f.conferidaEm).length };
  });
}

/** `relatorios/{dia}.decisoesRecentes`: as reprovações dos 7 dias que terminam no dia fechado (até 30). */
export const DECISOES_NO_RELATORIO = 30;

export async function decisoesRecentes(db: Firestore, dia: string): Promise<DocumentData[]> {
  const s = await db
    .collection('decisoes')
    .where('dia', '>=', somarDias(dia, -6))
    .where('dia', '<=', dia)
    .orderBy('dia', 'desc')
    .limit(DECISOES_NO_RELATORIO)
    .get();
  return s.docs.map((doc) => {
    const x = doc.data();
    return {
      dia: x.dia,
      entregaId: x.entregaId,
      acao: x.acao,
      motivo: x.motivo ?? null,
      frase: x.frase ?? null,
      titulo: x.titulo ?? null,
      formato: x.formato ?? null,
      pais: x.pais ?? null,
    };
  });
}
