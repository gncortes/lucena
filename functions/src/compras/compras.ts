// H-R5-3A · conferirCompra (R24, roteiro R11): o app manda o token da compra →
// a Play confirma (`productsv2`) → `acessos/{uid}` ganha o curso com origem
// compra e o `offerId` → a promoção soma a compra → `acknowledge`. Idempotente
// pelo `orderId` (`compras/{orderId}`): o app pode repetir até dar certo.
import { FieldValue, Firestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { centavosDeDesconto, PRODUTO, type Desconto } from '../promocoes/regras';
import type { PlayOfertas } from '../promocoes/promocoes';
import { ErroPlayCompra, type CompraPlay, type PlayCompras } from './play';

export interface DepsCompras {
  db: Firestore;
  play: PlayCompras;
  /** Preço cheio do produto (para a receita da promoção). */
  ofertas: Pick<PlayOfertas, 'precoCentavos'>;
  agora: Date;
}

/** Produto da Play → curso em `acessos/{uid}.cursos`. */
export const CURSO_DO_PRODUTO: Readonly<Record<string, string>> = { [PRODUTO]: 'pilares' };

export type ResultadoConferir =
  | { situacao: 'liberado'; curso: string; orderId: string; offerId: string | null; jaConferida: boolean }
  | { situacao: 'pendente'; orderId: string };

function falha(codigo: string, msg: string, tipo: 'failed-precondition' | 'invalid-argument' | 'permission-denied' = 'failed-precondition'): never {
  throw new HttpsError(tipo, msg, { codigo });
}

function lerToken(dados: unknown): string {
  const t = (dados as Record<string, unknown> | null)?.token;
  if (typeof t !== 'string' || t.length === 0 || t.length > 4096) falha('tokenInvalido', 'Token da compra inválido.', 'invalid-argument');
  return t;
}

async function consultar(play: PlayCompras, token: string): Promise<CompraPlay> {
  try {
    return await play.consultar(token);
  } catch (e) {
    if (e instanceof ErroPlayCompra) {
      if (e.motivo === 'tokenInvalido') falha('tokenInvalido', 'A Play não reconheceu esta compra.', 'invalid-argument');
      if (e.motivo === 'naoConfigurada') falha('playNaoConfigurada', 'A conferência da compra ainda não está ligada.');
    }
    throw new HttpsError('unavailable', 'Não foi possível falar com a Play agora.', { codigo: 'playFora' });
  }
}

/** País do perfil (ProgressSummary.profile.country), como no presente. */
async function paisDoPerfil(db: Firestore, uid: string): Promise<string | null> {
  const p = (await db.doc(`users/${uid}/progress/summary`).get()).get('profile.country');
  return typeof p === 'string' && p.length > 0 ? p.toUpperCase() : null;
}

/**
 * Promoção da compra pelo `offerId`. Vários links podem dividir a oferta da Play
 * (mesmo desconto): vale o da reserva desta conta; sem reserva, a Para todos.
 */
async function promocaoDaOferta(db: Firestore, offerId: string, uid: string) {
  const s = await db.collection('promocoes').where('offerId', '==', offerId).get();
  if (s.empty) return null;
  for (const doc of s.docs) {
    if ((await doc.ref.collection('reservas').doc(uid).get()).exists) return doc;
  }
  return s.docs.find((d) => d.get('tipo') === 'todos') ?? s.docs[0];
}

export async function conferirCompraCore(d: DepsCompras, uid: string | null | undefined, dados: unknown): Promise<ResultadoConferir> {
  if (!uid) throw new HttpsError('unauthenticated', 'Entre com a sua conta.');
  const token = lerToken(dados);
  const compra = await consultar(d.play, token);
  if (compra.conta && compra.conta !== uid) falha('outraConta', 'Esta compra é de outra conta.', 'permission-denied');
  const linha = compra.linhas.find((l) => CURSO_DO_PRODUTO[l.productId]);
  if (!linha) falha('produtoDesconhecido', 'Produto da compra desconhecido.');
  if (compra.estado === 'CANCELLED') falha('cancelada', 'Esta compra foi cancelada.');
  if (compra.estado === 'PENDING') return { situacao: 'pendente', orderId: compra.orderId };

  const curso = CURSO_DO_PRODUTO[linha.productId];
  const compraRef = d.db.doc(`compras/${compra.orderId}`);
  const acessosRef = d.db.doc(`acessos/${uid}`);
  const pais = await paisDoPerfil(d.db, uid);
  const promo = linha.offerId ? await promocaoDaOferta(d.db, linha.offerId, uid) : null;
  const preco = promo ? await d.ofertas.precoCentavos(linha.productId) : null;
  const quando = Timestamp.fromDate(d.agora);

  const jaConferida = await d.db.runTransaction(async (tx) => {
    const feita = await tx.get(compraRef);
    if (feita.exists) {
      if (feita.get('uid') !== uid) falha('outraConta', 'Esta compra é de outra conta.', 'permission-denied');
      return true;
    }
    const acessos = await tx.get(acessosRef);
    const anterior = acessos.get(`cursos.${curso}`) as DocumentData | undefined;
    const acesso: DocumentData = {
      origem: 'compra',
      plano: 'vitalicio',
      compradoEm: quando,
      orderId: compra.orderId,
      offerId: linha.offerId,
      pais,
      regiaoCompra: compra.regiao,
    };
    if (compra.teste) acesso.teste = true;
    tx.set(acessosRef, { cursos: { [curso]: acesso } }, { mergeFields: [`cursos.${curso}`] });
    tx.set(acessosRef.collection('registro').doc(), {
      acao: 'compra',
      curso,
      origem: 'compra',
      plano: 'vitalicio',
      orderId: compra.orderId,
      offerId: linha.offerId,
      anterior: anterior ?? null,
      em: quando,
    });
    const gravada: DocumentData = {
      uid,
      curso,
      produto: linha.productId,
      offerId: linha.offerId,
      offerTags: linha.offerTags,
      promocaoId: promo?.id ?? null,
      regiao: compra.regiao,
      teste: compra.teste,
      reconhecida: compra.reconhecida,
      em: quando,
    };
    if (promo && preco !== null) {
      const desconto = promo.get('desconto') as Desconto;
      const receita = Math.max(0, preco - centavosDeDesconto(desconto, preco));
      gravada.receitaCentavos = receita;
      tx.update(promo.ref, {
        usos: FieldValue.increment(1),
        'funil.compras': FieldValue.increment(1),
        'funil.receitaCentavos': FieldValue.increment(receita),
      });
      tx.delete(promo.ref.collection('reservas').doc(uid));
    }
    tx.set(compraRef, gravada);
    return false;
  });

  // Reconhece por último: se falhar, o acesso já está gravado e a próxima chamada tenta de novo.
  if (!compra.reconhecida) {
    try {
      await d.play.reconhecer(linha.productId, token);
      await compraRef.update({ reconhecida: true, reconhecidaEm: Timestamp.fromDate(d.agora) });
    } catch {
      await compraRef.update({ reconhecida: false });
    }
  }
  return { situacao: 'liberado', curso, orderId: compra.orderId, offerId: linha.offerId, jaConferida };
}
