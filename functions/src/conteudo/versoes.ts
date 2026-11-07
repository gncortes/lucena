// H-R5-38 · Versões do conteúdo e pedidos de correção (R4 Versões, resposta 5; R5 §3 e §11 R16; fluxos/conteudo.md).
//
// O lançamento (`release`) é imutável: o PC (stage_release, Admin SDK) sobe `content/releases/{release}/` no Storage
// (manifest.json + arquivos + falas.json) e cria `revisoes/{id}` com o índice pronto. O painel só move o ponteiro:
//   rascunho → emRevisao → (publicarVersao teste) noTeste → (conferirVersao) conferida → (publicarVersao alunos) noAr.
// `conteudo/teste` é o índice que o app de teste lê; `conteudo/alunos`, o dos alunos (formato de lesson_package_index.dart).
// Reverter aponta `conteudo/alunos` de volta para um lançamento que já esteve no ar.
import { Timestamp, FieldValue, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';

/** Lê um arquivo do bucket do conteúdo (null = não existe). */
export interface LeitorConteudo {
  ler(caminho: string): Promise<Buffer | null>;
}

export interface DepsVersoes {
  db: Firestore;
  conteudo: LeitorConteudo;
  agora: Date;
}

export type Destino = 'teste' | 'alunos';
export const INDICES: Readonly<Record<Destino, string>> = { teste: 'conteudo/teste', alunos: 'conteudo/alunos' };

/** Estados de `revisoes/{id}`; `anterior` = esteve no ar e foi substituída (pode voltar); `revertida` = saiu por reversão. */
export type EstadoRevisao = 'rascunho' | 'emRevisao' | 'noTeste' | 'conferida' | 'noAr' | 'anterior' | 'revertida' | 'descartada';

export const PROBLEMAS = ['confusa', 'rapidaDemais', 'erroDeXadrez', 'outro'] as const;
export type Problema = (typeof PROBLEMAS)[number];

const RELEASE = /^[A-Za-z0-9_-]+$/;
const HASH = /^[0-9a-f]{64}$/;
const MAX_MANIFESTO = 1024 * 1024;
const MAX_FALAS = 4 * 1024 * 1024;

function invalido(msg: string): never {
  throw new HttpsError('invalid-argument', msg);
}

function precondicao(msg: string, detalhes: Record<string, unknown>): never {
  throw new HttpsError('failed-precondition', msg, detalhes);
}

function idValido(v: unknown, campo = 'id da versão'): string {
  if (typeof v !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(v)) invalido(`Informe o ${campo}.`);
  return v;
}

function semRevisao(): never {
  throw new HttpsError('not-found', 'Versão não encontrada.', { codigo: 'versaoNaoExiste' });
}

/** O índice gravado pelo PC na revisão precisa abrir no app (mesmas regras de LessonPackageIndex.fromJson). */
export function indiceValido(indice: unknown, release: unknown): indice is DocumentData {
  if (typeof release !== 'string' || !RELEASE.test(release)) return false;
  const i = indice as DocumentData | null;
  if (!i || i.format !== 1 || i.status !== 'published' || i.release !== release) return false;
  const pacotes = i.packages;
  if (!pacotes || typeof pacotes !== 'object' || Array.isArray(pacotes) || Object.keys(pacotes).length === 0) return false;
  return Object.values(pacotes as Record<string, DocumentData>).every(
    (p) =>
      Number.isInteger(p?.bytes) &&
      p.bytes >= 0 &&
      typeof p.sha256 === 'string' &&
      HASH.test(p.sha256) &&
      p.files &&
      typeof p.files === 'object' &&
      Object.keys(p.files).length > 0,
  );
}

async function json(leitor: LeitorConteudo, caminho: string, max: number): Promise<DocumentData | null> {
  const bytes = await leitor.ler(caminho);
  if (!bytes || bytes.length > max) return null;
  try {
    return JSON.parse(bytes.toString('utf8'));
  } catch {
    return null;
  }
}

/** O lançamento existe no Storage com o manifesto do formato 1 (o app recusa outro). */
async function exigeLancamento(leitor: LeitorConteudo, release: string): Promise<void> {
  const m = await json(leitor, `content/releases/${release}/manifest.json`, MAX_MANIFESTO);
  if (!m || m.format !== 1 || m.release !== release || m.status !== 'published' || !m.files) {
    precondicao('O pacote desta versão não está no servidor.', { codigo: 'pacoteAusente' });
  }
}

/** `falas.json` do lançamento: `{format: 1, falas: {chave: sha256 do texto}}` (gerado no PC junto do pacote). */
async function falasDe(leitor: LeitorConteudo, release: string): Promise<Record<string, string>> {
  const f = await json(leitor, `content/releases/${release}/falas.json`, MAX_FALAS);
  if (!f || f.format !== 1 || !f.falas || typeof f.falas !== 'object') {
    precondicao('O pacote desta versão não está no servidor.', { codigo: 'pacoteAusente' });
  }
  return f.falas as Record<string, string>;
}

function registro(acao: string, por: string, em: Timestamp) {
  return FieldValue.arrayUnion({ acao, por, em });
}

/** O que vai ao documento do índice: o formato do app + o que o app mostra no aviso "Atualizada". */
function documentoIndice(id: string, r: DocumentData, por: string, em: Timestamp): DocumentData {
  return {
    ...(r.indice as DocumentData),
    revisao: id,
    curso: r.curso ?? null,
    numero: r.numero ?? null,
    resumo: r.resumo ?? null,
    publicadoPor: por,
    publicadoEm: em,
  };
}

export interface Publicado {
  id: string;
  estado: EstadoRevisao;
  release: string;
}

/**
 * `{id, destino: 'teste'|'alunos'}`. Teste: de `emRevisao` (ou de novo, de `noTeste`). Alunos: só depois de conferida
 * no app de teste (`naoConferida`). O pacote precisa estar no Storage (`pacoteAusente`) e o índice da revisão, válido.
 */
export async function publicarVersaoCore(d: DepsVersoes, admin: string, dados: unknown): Promise<Publicado> {
  const p = (dados ?? {}) as Record<string, unknown>;
  const id = idValido(p.id);
  const destino = p.destino;
  if (destino !== 'teste' && destino !== 'alunos') invalido('Destino: teste ou alunos.');

  const ref = d.db.doc(`revisoes/${id}`);
  const antes = await ref.get();
  if (!antes.exists) semRevisao();
  const release = antes.data()!.release;
  if (!indiceValido(antes.data()!.indice, release)) {
    precondicao('O índice desta versão está incompleto.', { codigo: 'indiceInvalido' });
  }
  await exigeLancamento(d.conteudo, release);

  const em = Timestamp.fromDate(d.agora);
  const indiceRef = d.db.doc(INDICES[destino]);
  return d.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const atual = await tx.get(indiceRef);
    const r = snap.data()!;
    if (r.release !== release) precondicao('A versão mudou. Abra de novo.', { codigo: 'versaoMudou' });

    if (destino === 'teste') {
      if (r.estado !== 'emRevisao' && r.estado !== 'noTeste') {
        precondicao('Só uma versão em revisão vai ao app de teste.', { codigo: 'estadoInvalido', estado: r.estado });
      }
      const outra = atual.exists ? atual.data()!.revisao : null;
      if (typeof outra === 'string' && outra !== id) {
        // A versão que estava no teste e ainda não foi aos alunos volta a "em revisão" (sai do celular do Gabriel).
        const o = await tx.get(d.db.doc(`revisoes/${outra}`));
        if (o.exists && (o.data()!.estado === 'noTeste' || o.data()!.estado === 'conferida')) {
          tx.update(o.ref, { estado: 'emRevisao' });
        }
      }
      tx.set(indiceRef, documentoIndice(id, r, admin, em));
      tx.update(ref, { estado: 'noTeste', noTesteEm: em, noTestePor: admin, historico: registro('teste', admin, em) });
      return { id, estado: 'noTeste' as const, release };
    }

    if (r.estado !== 'conferida') {
      precondicao('Confira a versão no app de teste antes de publicar.', { codigo: 'naoConferida', estado: r.estado });
    }
    const anterior = atual.exists ? atual.data()!.revisao : null;
    if (typeof anterior === 'string' && anterior !== id) {
      tx.update(d.db.doc(`revisoes/${anterior}`), { estado: 'anterior', saiuEm: em });
    }
    tx.set(indiceRef, documentoIndice(id, r, admin, em));
    tx.update(ref, { estado: 'noAr', publicadaEm: em, publicadaPor: admin, historico: registro('alunos', admin, em) });
    return { id, estado: 'noAr' as const, release };
  });
}

/** `{id}`: o Gabriel conferiu no celular a versão que está no app de teste ("Marcar como conferida"). */
export async function conferirVersaoCore(d: DepsVersoes, admin: string, dados: unknown): Promise<Publicado> {
  const id = idValido(((dados ?? {}) as Record<string, unknown>).id);
  const ref = d.db.doc(`revisoes/${id}`);
  const em = Timestamp.fromDate(d.agora);
  return d.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const teste = await tx.get(d.db.doc(INDICES.teste));
    if (!snap.exists) semRevisao();
    const r = snap.data()!;
    if (r.estado !== 'noTeste' || teste.data()?.revisao !== id) {
      precondicao('Esta versão não está no app de teste.', { codigo: 'naoEstaNoTeste', estado: r.estado });
    }
    tx.update(ref, { estado: 'conferida', conferidaEm: em, conferidaPor: admin, historico: registro('conferida', admin, em) });
    return { id, estado: 'conferida' as const, release: r.release };
  });
}

/** `{id}`: volta o app dos alunos para um lançamento que já esteve no ar (imutável; só troca o ponteiro). */
export async function reverterVersaoCore(d: DepsVersoes, admin: string, dados: unknown): Promise<Publicado> {
  const id = idValido(((dados ?? {}) as Record<string, unknown>).id);
  const ref = d.db.doc(`revisoes/${id}`);
  const antes = await ref.get();
  if (!antes.exists) semRevisao();
  const release = antes.data()!.release;
  if (!indiceValido(antes.data()!.indice, release)) {
    precondicao('O índice desta versão está incompleto.', { codigo: 'indiceInvalido' });
  }
  await exigeLancamento(d.conteudo, release);

  const em = Timestamp.fromDate(d.agora);
  const indiceRef = d.db.doc(INDICES.alunos);
  return d.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const atual = await tx.get(indiceRef);
    const r = snap.data()!;
    const noAr = atual.exists ? atual.data()!.revisao : null;
    if (noAr === id) precondicao('Esta versão já está no app dos alunos.', { codigo: 'jaNoAr' });
    if (r.estado !== 'anterior' && r.estado !== 'revertida') {
      precondicao('Só se volta para uma versão que já esteve no app dos alunos.', { codigo: 'nuncaPublicada', estado: r.estado });
    }
    if (typeof noAr === 'string') {
      tx.update(d.db.doc(`revisoes/${noAr}`), { estado: 'revertida', saiuEm: em, historico: registro('revertida', admin, em) });
    }
    tx.set(indiceRef, { ...documentoIndice(id, r, admin, em), revertidoDe: noAr ?? null });
    tx.update(ref, { estado: 'noAr', publicadaEm: em, publicadaPor: admin, historico: registro('reverter', admin, em) });
    return { id, estado: 'noAr' as const, release };
  });
}

const PUBLICADAS = ['noAr', 'anterior', 'revertida'];

/**
 * `{chave, revisao, problema, texto?, numero?}` (R16). A chave (ex. `pilares/c4/atracao/fala2`) precisa existir na versão
 * base; se a versão no ar é outra e a fala mudou nela, recusa com `falaMudou` ("Esta fala mudou na v3. Confira antes de pedir.").
 */
export async function pedirCorrecaoCore(
  d: DepsVersoes,
  admin: string,
  dados: unknown,
): Promise<{ id: string; estado: 'enviado' }> {
  const p = (dados ?? {}) as Record<string, unknown>;
  const chave = p.chave;
  if (typeof chave !== 'string' || !/^[a-z0-9_-]+(\/[A-Za-z0-9_-]+){1,8}$/.test(chave)) invalido('Informe a chave da fala.');
  const base = idValido(p.revisao, 'id da versão base');
  if (!(PROBLEMAS as readonly unknown[]).includes(p.problema)) invalido('Escolha qual é o problema.');
  const problema = p.problema as Problema;
  const texto = opcional(p.texto, 500, 'Texto');
  if (problema === 'outro' && !texto) invalido('Em "Outro", descreva o problema.');
  const numero = opcional(p.numero, 120, 'Número');

  const [revBase, indice] = await Promise.all([d.db.doc(`revisoes/${base}`).get(), d.db.doc(INDICES.alunos).get()]);
  if (!revBase.exists || !PUBLICADAS.includes(revBase.data()!.estado)) semRevisao();
  const rb = revBase.data()!;
  const falasBase = await falasDe(d.conteudo, rb.release);
  if (!Object.prototype.hasOwnProperty.call(falasBase, chave)) {
    throw new HttpsError('not-found', 'Fala não encontrada nesta versão.', { codigo: 'falaNaoExiste' });
  }

  const noAr = indice.exists ? indice.data()!.revisao : null;
  if (typeof noAr === 'string' && noAr !== base) {
    const revAtual = await d.db.doc(`revisoes/${noAr}`).get();
    const atual = revAtual.data();
    if (atual && atual.release !== rb.release) {
      const falasAtual = await falasDe(d.conteudo, atual.release);
      if (falasAtual[chave] !== falasBase[chave]) {
        const n = atual.numero ?? '';
        precondicao(`Esta fala mudou na v${n}. Confira antes de pedir.`, { codigo: 'falaMudou', numero: atual.numero ?? null, revisao: noAr });
      }
    }
  }

  const em = Timestamp.fromDate(d.agora);
  const ref = d.db.collection('pedidosCorrecao').doc();
  await ref.create({
    chave,
    curso: rb.curso ?? null,
    revisaoBase: base,
    numeroBase: rb.numero ?? null,
    release: rb.release,
    hashFala: falasBase[chave],
    problema,
    texto,
    numero,
    estado: 'enviado',
    por: admin,
    em,
    historico: [{ estado: 'enviado', por: admin, em }],
  });
  return { id: ref.id, estado: 'enviado' };
}

function opcional(v: unknown, max: number, campo: string): string | null {
  if (v === undefined || v === null || v === '') return null;
  if (typeof v !== 'string' || v.length > max) invalido(`${campo}: texto até ${max} caracteres.`);
  return v.trim() || null;
}
