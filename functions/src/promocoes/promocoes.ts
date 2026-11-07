// Promoções do Pilares (E1.19 R5, contrato de promoções §3 e §6 R21–R25): criar,
// editar, encerrar e publicar de novo (painel); validar o cupom e reservar a
// vaga (app). A Play entra pela interface [PlayOfertas] (fake nos testes).
import { FieldValue, Firestore, Timestamp, type DocumentData, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { iso } from '../comum/datas';
import {
  ANTECEDENCIA_TODOS,
  PRODUTO,
  cruzam,
  estadoDe,
  gerarCodigo,
  idDaOferta,
  lerLimite,
  lerPedidoPromocao,
  linkDoCupom,
  normalizarCodigo,
  vence,
  type Desconto,
  type Origem,
  type PromocaoGravada,
} from './regras';

/** Por que a Play recusou (mapeado para o texto da `PromoPlayRecusou`). */
export type MotivoPlay = 'precoMinimo' | 'datas' | 'permissao' | 'naoConfigurada' | 'outro';

export class ErroPlay extends Error {
  constructor(readonly motivo: MotivoPlay, mensagem?: string) {
    super(mensagem ?? motivo);
  }
}

export interface OfertaPlay {
  produto: string;
  offerId: string;
  /** `lucena-todos` ou `lucena-link`. */
  tag: string;
  desconto: Desconto;
  inicio: Date | null;
  fim: Date | null;
  /** Valor em reais vale só no Brasil (regra 2). */
  soBrasil: boolean;
  /** Uma compra com desconto por conta (regra 4). */
  limitePorConta: 1;
}

/** O que as Functions pedem à Play Developer API (ofertas de produto único). */
export interface PlayOfertas {
  /** Preço base do produto no Brasil, em centavos. */
  precoCentavos(produto: string): Promise<number>;
  /** Cria e ativa a oferta. */
  criarOferta(oferta: OfertaPlay): Promise<void>;
  ofertaExiste(produto: string, offerId: string): Promise<boolean>;
  desativarOferta(produto: string, offerId: string): Promise<void>;
}

export interface DepsPromocoes {
  db: Firestore;
  play: PlayOfertas;
  agora: Date;
  sorteio?: () => number;
}

/** Reserva de vaga de um link com limite (R24). */
export const RESERVA_MS = 30 * 60_000;

const COLECAO = 'promocoes';

function falha(codigo: string, msg: string, extra: Record<string, unknown> = {}): never {
  throw new HttpsError('failed-precondition', msg, { codigo, ...extra });
}

function data(v: unknown): Date | null {
  const s = iso(v);
  return s ? new Date(s) : null;
}

function gravada(d: DocumentData): PromocaoGravada & {
  tipo: 'todos' | 'link';
  nome: string;
  desconto: Desconto;
  offerId: string;
} {
  return {
    tipo: d.tipo,
    nome: d.nome,
    desconto: d.desconto,
    offerId: d.offerId,
    situacao: d.situacao,
    inicio: data(d.inicio) ?? new Date(0),
    fim: data(d.fim),
    limite: d.limite ?? null,
    usos: d.usos ?? 0,
    encerradaPor: d.encerradaPor ?? null,
    motivoPlay: d.motivoPlay ?? null,
  };
}

function idValido(v: unknown): string {
  if (typeof v !== 'string' || v.length === 0 || v.length > 128 || v.includes('/')) {
    throw new HttpsError('invalid-argument', 'Informe a promoção.');
  }
  return v;
}

async function precoAtual(play: PlayOfertas): Promise<number> {
  try {
    return await play.precoCentavos(PRODUTO);
  } catch (e) {
    if (e instanceof ErroPlay) falha('play', 'Não deu para ler o preço no Google Play.', { motivo: e.motivo });
    throw e;
  }
}

/** As Para todos publicadas que ainda não terminaram. */
async function todosVigentes(db: Firestore, agora: Date) {
  const s = await db.collection(COLECAO).where('tipo', '==', 'todos').where('situacao', '==', 'publicada').get();
  return s.docs
    .map((doc) => ({ id: doc.id, ...gravada(doc.data()) }))
    .filter((p) => estadoDe(p, agora).estado !== 'encerrada');
}

/** Regra 5: duas Para todos no mesmo período não podem. */
function conferirConflito(pedido: { inicio: Date; fim: Date | null }, vigentes: Awaited<ReturnType<typeof todosVigentes>>): void {
  const outra = vigentes.find((p) => cruzam(p, pedido));
  if (outra) {
    falha('conflito', `Já existe uma promoção para todos neste período: ${outra.nome}.`, {
      promocaoId: outra.id,
      nome: outra.nome,
    });
  }
}

async function offerIdLivre(db: Firestore, base: string): Promise<string> {
  for (let n = 1; n < 50; n++) {
    const id = n === 1 ? base : `${base}-${n}`;
    const s = await db.collection(COLECAO).where('offerId', '==', id).limit(1).get();
    if (s.empty) return id;
  }
  throw new HttpsError('resource-exhausted', 'Nome já usado em muitas promoções.');
}

function ofertaDe(p: { tipo: 'todos' | 'link'; offerId: string; desconto: Desconto; inicio: Date; fim: Date | null }): OfertaPlay {
  const todos = p.tipo === 'todos';
  return {
    produto: PRODUTO,
    offerId: p.offerId,
    tag: todos ? 'lucena-todos' : 'lucena-link',
    desconto: p.desconto,
    // Link: a oferta é por nível e sem datas; a validade de cada link fica no Firestore.
    inicio: todos ? p.inicio : null,
    fim: todos ? p.fim : null,
    soBrasil: p.desconto.tipo === 'brl',
    limitePorConta: 1,
  };
}

/** Publica na Play; devolve o motivo se ela recusou (outro erro sobe). */
async function publicar(play: PlayOfertas, p: Parameters<typeof ofertaDe>[0]): Promise<MotivoPlay | null> {
  try {
    if (p.tipo === 'link' && (await play.ofertaExiste(PRODUTO, p.offerId))) return null;
    await play.criarOferta(ofertaDe(p));
    return null;
  } catch (e) {
    if (e instanceof ErroPlay) return e.motivo;
    throw e;
  }
}

async function codigoLivre(d: DepsPromocoes, pedido: string | null): Promise<string> {
  if (pedido) {
    if ((await d.db.doc(`cupons/${pedido}`).get()).exists) {
      throw new HttpsError('already-exists', 'Este código já está em uso.', { codigo: 'codigoEmUso' });
    }
    return pedido;
  }
  for (let i = 0; i < 20; i++) {
    const c = gerarCodigo(d.sorteio);
    if (!(await d.db.doc(`cupons/${c}`).get()).exists) return c;
  }
  throw new HttpsError('resource-exhausted', 'Não deu para gerar um código livre.');
}

export interface ResultadoCriar {
  id: string;
  estado: 'agendada' | 'ativa' | 'naoPublicada';
  motivo?: MotivoPlay;
  codigo?: string;
  link?: string;
  /** Regra 5: link menor que uma Para todos no mesmo período (o aluno fica com a maior). */
  aviso?: { codigo: 'menorQueTodos'; nome: string };
}

/** R21/R22 · Criar Para todos ou link. */
export async function criarPromocaoCore(d: DepsPromocoes, adminUid: string, dados: unknown): Promise<ResultadoCriar> {
  const preco = await precoAtual(d.play);
  const pedido = lerPedidoPromocao(dados, preco, d.agora);
  const vigentes = await todosVigentes(d.db, d.agora);
  let aviso: ResultadoCriar['aviso'];
  if (pedido.tipo === 'todos') {
    conferirConflito(pedido, vigentes);
  } else {
    const maior = vigentes.find(
      (p) => cruzam(p, pedido) && vence({ ...p, todos: true }, { ...pedido, todos: false }, preco).todos,
    );
    if (maior) aviso = { codigo: 'menorQueTodos', nome: maior.nome };
  }

  const codigo = pedido.tipo === 'link' ? await codigoLivre(d, pedido.codigo) : null;
  const offerId = pedido.tipo === 'todos' ? await offerIdLivre(d.db, idDaOferta(pedido)) : idDaOferta(pedido);
  const motivo = await publicar(d.play, { ...pedido, offerId });

  const ref = d.db.collection(COLECAO).doc();
  const doc = {
    tipo: pedido.tipo,
    nome: pedido.nome,
    produto: PRODUTO,
    desconto: pedido.desconto,
    precoCentavos: preco,
    inicio: Timestamp.fromDate(pedido.inicio),
    fim: pedido.fim ? Timestamp.fromDate(pedido.fim) : null,
    origem: pedido.origem,
    parceiro: pedido.parceiro,
    codigo,
    link: codigo ? linkDoCupom(codigo, pedido.origem as Origem) : null,
    limite: pedido.limite,
    usos: 0,
    offerId,
    situacao: motivo ? 'naoPublicada' : 'publicada',
    motivoPlay: motivo,
    encerradaPor: null,
    funil: { cliques: 0, aberturas: 0, viramPreco: 0, compras: 0, receitaCentavos: 0 },
    criadaPor: adminUid,
    criadaEm: Timestamp.fromDate(d.agora),
  };
  await d.db.runTransaction(async (tx) => {
    // O código é único: `create` falha se outro admin pegou o mesmo no meio do caminho.
    if (codigo) tx.create(d.db.doc(`cupons/${codigo}`), { promocaoId: ref.id });
    tx.create(ref, doc);
  }).catch((e) => {
    if ((e as { code?: number }).code === 6) {
      throw new HttpsError('already-exists', 'Este código já está em uso.', { codigo: 'codigoEmUso' });
    }
    throw e;
  });

  const estado = estadoDe(gravada(doc), d.agora).estado as ResultadoCriar['estado'];
  return {
    id: ref.id,
    estado,
    ...(motivo ? { motivo } : {}),
    ...(codigo ? { codigo, link: doc.link as string } : {}),
    ...(aviso ? { aviso } : {}),
  };
}

/** `PromoPlayRecusou` › Tentar novamente: publica de novo uma Não publicada. */
export async function republicarPromocaoCore(d: DepsPromocoes, _adminUid: string, dados: unknown) {
  const id = idValido((dados as Record<string, unknown> | null)?.id);
  const ref = d.db.doc(`${COLECAO}/${id}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Promoção não encontrada.');
  const p = gravada(snap.data()!);
  if (p.situacao !== 'naoPublicada') falha('jaPublicada', 'A promoção já está no Google Play.');
  if (p.tipo === 'todos') {
    if (p.inicio.getTime() < d.agora.getTime() + ANTECEDENCIA_TODOS) {
      throw new HttpsError('invalid-argument', 'A promoção começa daqui a 1 hora ou mais.', { codigo: 'inicioCedo' });
    }
    conferirConflito(p, (await todosVigentes(d.db, d.agora)).filter((o) => o.id !== id));
  }
  const motivo = await publicar(d.play, p);
  await ref.update(motivo ? { motivoPlay: motivo } : { situacao: 'publicada', motivoPlay: null });
  const estado = estadoDe({ ...p, situacao: motivo ? 'naoPublicada' : 'publicada', motivoPlay: motivo }, d.agora);
  return { id, estado: estado.estado, ...(motivo ? { motivo } : {}) };
}

/** Regra 7 · Só nome e limite de usos mudam depois de criada (`{id, nome?, limite?}`). */
export async function editarPromocaoCore(d: DepsPromocoes, adminUid: string, dados: unknown) {
  const dd = (dados ?? {}) as Record<string, unknown>;
  const id = idValido(dd.id);
  const permitidos = ['id', 'nome', 'limite'];
  const extra = Object.keys(dd).find((k) => !permitidos.includes(k));
  if (extra) {
    throw new HttpsError('invalid-argument', 'Depois de criada, só nome e limite de usos mudam.', {
      codigo: 'naoEditavel',
      campo: extra,
    });
  }
  const ref = d.db.doc(`${COLECAO}/${id}`);
  await d.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Promoção não encontrada.');
    const p = gravada(snap.data()!);
    if (estadoDe(p, d.agora).estado === 'encerrada') falha('jaEncerrada', 'A promoção já foi encerrada.');
    const mudar: Record<string, unknown> = { editadaPor: adminUid, editadaEm: Timestamp.fromDate(d.agora) };
    if ('nome' in dd) {
      if (typeof dd.nome !== 'string' || dd.nome.trim().length === 0 || dd.nome.trim().length > 60) {
        throw new HttpsError('invalid-argument', 'Dê um nome de até 60 caracteres.', { codigo: 'nomeInvalido' });
      }
      mudar.nome = dd.nome.trim();
    }
    if ('limite' in dd) {
      if (p.tipo !== 'link') throw new HttpsError('invalid-argument', 'Limite de usos só vale para link.');
      mudar.limite = lerLimite(dd.limite, p.usos);
    }
    tx.update(ref, mudar);
  });
  return { id };
}

/** Outro link publicado e não encerrado usa a mesma oferta da Play? */
async function ofertaEmUso(d: DepsPromocoes, offerId: string, exceto: string): Promise<boolean> {
  const s = await d.db
    .collection(COLECAO)
    .where('offerId', '==', offerId)
    .where('situacao', '==', 'publicada')
    .get();
  return s.docs.some((doc) => doc.id !== exceto && estadoDe(gravada(doc.data()), d.agora).estado !== 'encerrada');
}

/** R25 · Encerrar à mão (`{id}`). Quem já comprou não muda; sem desfazer (regra 8). */
export async function encerrarPromocaoCore(d: DepsPromocoes, adminUid: string, dados: unknown) {
  const id = idValido((dados as Record<string, unknown> | null)?.id);
  const ref = d.db.doc(`${COLECAO}/${id}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Promoção não encontrada.');
  const p = gravada(snap.data()!);
  if (estadoDe(p, d.agora).estado === 'encerrada') falha('jaEncerrada', 'A promoção já foi encerrada.');

  // Para todos: a oferta sai da Play antes; se a Play falhar, nada muda aqui.
  if (p.tipo === 'todos' && p.situacao === 'publicada') {
    try {
      await d.play.desativarOferta(PRODUTO, p.offerId);
    } catch (e) {
      if (e instanceof ErroPlay) falha('play', 'O Google Play não encerrou a promoção.', { motivo: e.motivo });
      throw e;
    }
  }
  await ref.update({
    situacao: 'encerrada',
    encerradaPor: 'mao',
    encerradaEm: Timestamp.fromDate(d.agora),
    encerradaPorUid: adminUid,
  });
  // Link: a oferta por nível só sai da Play quando nenhum link ativo a usa.
  let ofertaDesativada = p.tipo === 'todos' && p.situacao === 'publicada';
  if (p.tipo === 'link' && p.situacao === 'publicada' && !(await ofertaEmUso(d, p.offerId, id))) {
    try {
      await d.play.desativarOferta(PRODUTO, p.offerId);
      ofertaDesativada = true;
    } catch (e) {
      // O link já não vale (validarCupom recusa); a oferta parada na Play não chega a ninguém.
      if (!(e instanceof ErroPlay)) throw e;
    }
  }
  return { id, ofertaDesativada };
}

export type MotivoCupom = 'naoExiste' | 'foraDaData' | 'encerrado' | 'esgotado';

interface CupomLido {
  id: string;
  p: ReturnType<typeof gravada> & { codigo: string };
}

async function lerCupom(d: DepsPromocoes, tx: Transaction | null, codigo: unknown): Promise<CupomLido | MotivoCupom> {
  let c: string;
  try {
    c = normalizarCodigo(codigo);
  } catch {
    return 'naoExiste';
  }
  const ler = <T>(r: FirebaseFirestore.DocumentReference<T>) => (tx ? tx.get(r) : r.get());
  const cupom = await ler(d.db.doc(`cupons/${c}`));
  const promocaoId = cupom.data()?.promocaoId;
  if (typeof promocaoId !== 'string') return 'naoExiste';
  const snap = await ler(d.db.doc(`${COLECAO}/${promocaoId}`));
  if (!snap.exists) return 'naoExiste';
  const p = { ...gravada(snap.data()!), codigo: c };
  if (p.tipo !== 'link') return 'naoExiste';
  const e = estadoDe(p, d.agora);
  if (e.estado === 'naoPublicada') return 'naoExiste';
  if (e.estado === 'agendada') return 'foraDaData';
  if (e.estado === 'encerrada') return e.por === 'data' ? 'foraDaData' : e.por === 'limite' ? 'esgotado' : 'encerrado';
  return { id: promocaoId, p };
}

/** Reservas que ainda valem, de outras contas. */
async function reservasDeOutros(d: DepsPromocoes, tx: Transaction | null, id: string, uid: string): Promise<number> {
  const q = d.db.collection(`${COLECAO}/${id}/reservas`).where('expiraEm', '>', Timestamp.fromDate(d.agora));
  const s = tx ? await tx.get(q) : await q.get();
  return s.docs.filter((doc) => doc.id !== uid).length;
}

function semVaga(p: CupomLido['p'], outros: number): boolean {
  return p.limite !== null && p.usos + outros >= p.limite;
}

function exigeConta(uid: string | null | undefined): string {
  if (!uid) throw new HttpsError('unauthenticated', 'Entre com a sua conta.');
  return uid;
}

/** R23 · O app confere o código guardado (`{codigo}`); sem conta, o código espera o login. */
export async function validarCupomCore(d: DepsPromocoes, uid: string | null | undefined, dados: unknown) {
  const conta = exigeConta(uid);
  const lido = await lerCupom(d, null, (dados as Record<string, unknown> | null)?.codigo);
  if (typeof lido === 'string') return { valido: false as const, motivo: lido };
  if (semVaga(lido.p, await reservasDeOutros(d, null, lido.id, conta))) {
    return { valido: false as const, motivo: 'esgotado' as MotivoCupom };
  }
  return {
    valido: true as const,
    promocaoId: lido.id,
    codigo: lido.p.codigo,
    offerId: lido.p.offerId,
    desconto: lido.p.desconto,
    fim: lido.p.fim?.toISOString() ?? null,
  };
}

/** R24 · Antes do `launchBillingFlow`: segura a vaga do link por 30 minutos (`{codigo}`). */
export async function reservarVagaCore(d: DepsPromocoes, uid: string | null | undefined, dados: unknown) {
  const conta = exigeConta(uid);
  return d.db.runTransaction(async (tx) => {
    const lido = await lerCupom(d, tx, (dados as Record<string, unknown> | null)?.codigo);
    if (typeof lido === 'string') falha(lido, 'O desconto deste link não vale mais.');
    if (semVaga(lido.p, await reservasDeOutros(d, tx, lido.id, conta))) {
      falha('esgotado', 'O desconto deste link não vale mais.');
    }
    const expiraEm = new Date(d.agora.getTime() + RESERVA_MS);
    tx.set(d.db.doc(`${COLECAO}/${lido.id}/reservas/${conta}`), {
      expiraEm: Timestamp.fromDate(expiraEm),
      em: FieldValue.serverTimestamp(),
    });
    return { promocaoId: lido.id, offerId: lido.p.offerId, expiraEm: expiraEm.toISOString() };
  });
}
