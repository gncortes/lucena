// AG-5b.1 · importarLote: o porteiro grava o lote de um agente (E1.21 §6.1). Sem motor e sem WIF ainda (AG-5b.2/5b.3).
// Tudo numa transação: idempotente por lotes/{loteId} + sha256; o aceito vira entregas/{id} 'sugerido'; o recusado vai a
// quarentena/{id} com o motivo. Contadores da noite em agentesNoite/{noite} (≤ 20 entregas, ≤ 2 lotes por agente).
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/https';
import { diaLocal } from '../fechamento/datas';
import {
  CORPO_MAXIMO,
  ENTREGAS_POR_NOITE,
  LOTES_POR_AGENTE,
  conferirEsquema,
  conferirItem,
  conferirTexto,
  fontesDe,
  idDaEntrega,
  loteIdValido,
  noiteDe,
  sha256,
  type ItemLote,
  type MotivoQuarentena,
} from './porteiro';

export interface DepsImportar {
  db: Firestore;
  agora: Date;
}

export interface Recusa {
  idLocal: string | null;
  motivo: MotivoQuarentena;
  detalhes: string[];
}

export interface ResultadoLote {
  loteId: string;
  estado: 'importado' | 'parcial' | 'recusado';
  aceitas: string[];
  recusadas: Recusa[];
  repetido: boolean;
}

/** Quanto do item recusado fica guardado (como texto, nunca como estrutura) para o Gabriel ver na quarentena. */
const ITEM_NA_QUARENTENA = 20_000;

function invalido(msg: string): never {
  throw new HttpsError('invalid-argument', msg);
}

/** Recusa do lote inteiro (antes de olhar os itens). */
function recusaDoLote(motivo: MotivoQuarentena, detalhes: string[]): Recusa {
  return { idLocal: null, motivo, detalhes: detalhes.slice(0, 20) };
}

/** Lê e confere o corpo fora da transação (nada de Firestore aqui). */
function analisar(conteudo: string): {
  agente: string | null;
  itens: ItemLote[];
  recusaLote: Recusa | null;
} {
  if (Buffer.byteLength(conteudo, 'utf8') > CORPO_MAXIMO) {
    return { agente: null, itens: [], recusaLote: recusaDoLote('corpoGrande', [`> ${CORPO_MAXIMO} bytes`]) };
  }
  let bruto: unknown;
  try {
    bruto = JSON.parse(conteudo);
  } catch {
    return { agente: null, itens: [], recusaLote: recusaDoLote('jsonInvalido', ['JSON ilegível']) };
  }
  const r = conferirEsquema(bruto);
  if (!r.ok) {
    const agente = typeof (bruto as { agente?: unknown })?.agente === 'string' ? (bruto as { agente: string }).agente : null;
    return { agente: agente && /^[a-z-]{1,40}$/.test(agente) ? agente : null, itens: [], recusaLote: recusaDoLote('esquema', r.erros) };
  }
  const achadosResumo = conferirTexto(r.lote.resumo, '/resumo');
  if (achadosResumo.length > 0) {
    return {
      agente: r.lote.agente,
      itens: [],
      recusaLote: recusaDoLote(achadosResumo[0].motivo, achadosResumo.map((a) => `${a.motivo} em ${a.onde}`)),
    };
  }
  return { agente: r.lote.agente, itens: r.lote.entregas, recusaLote: null };
}

/**
 * `{loteId, conteudo}`: `conteudo` é o texto do arquivo saida/<data>/<agente>-<hhmm>.json como está no git (o sha256 é
 * dele). Mesmo loteId e mesmo hash = devolve o resultado gravado; hash diferente = `already-exists` (409) + quarentena.
 */
export async function importarLoteCore(d: DepsImportar, dados: unknown): Promise<ResultadoLote> {
  const p = (dados ?? {}) as Record<string, unknown>;
  if (!loteIdValido(p.loteId)) invalido('loteId: letras, números, - e _ (3 a 100).');
  if (typeof p.conteudo !== 'string' || p.conteudo.length === 0) invalido('conteudo: o texto JSON do lote.');
  const loteId = p.loteId;
  const conteudo = p.conteudo;
  const hash = sha256(conteudo);
  const noite = noiteDe(d.agora, diaLocal);
  const em = Timestamp.fromDate(d.agora);
  const analise = analisar(conteudo);

  const loteRef = d.db.doc(`lotes/${loteId}`);
  const noiteRef = d.db.doc(`agentesNoite/${noite}`);

  const resultado = await d.db.runTransaction(async (tx) => {
    const [loteSnap, noiteSnap] = await Promise.all([tx.get(loteRef), tx.get(noiteRef)]);
    if (loteSnap.exists) {
      const antes = loteSnap.data()!;
      if (antes.sha256 !== hash) return { conflito: true as const, sha256Antes: String(antes.sha256) };
      return {
        conflito: false as const,
        r: {
          loteId,
          estado: antes.estado,
          aceitas: antes.aceitas ?? [],
          recusadas: antes.recusadas ?? [],
          repetido: true,
        } as ResultadoLote,
      };
    }

    const contagem = noiteSnap.exists ? noiteSnap.data()! : {};
    const entregasNaNoite: number = typeof contagem.entregas === 'number' ? contagem.entregas : 0;
    const lotesDoAgente: number =
      analise.agente && typeof contagem.lotes?.[analise.agente] === 'number' ? contagem.lotes[analise.agente] : 0;

    const recusadas: Recusa[] = [];
    const itemDaRecusa: (ItemLote | null)[] = [];
    const aceitos: ItemLote[] = [];

    if (analise.recusaLote) {
      recusadas.push(analise.recusaLote);
      itemDaRecusa.push(null);
    } else if (lotesDoAgente >= LOTES_POR_AGENTE) {
      recusadas.push(recusaDoLote('limiteLotesAgente', [`${analise.agente}: ${LOTES_POR_AGENTE} lotes na noite ${noite}`]));
      itemDaRecusa.push(null);
    } else {
      const vistos = new Set<string>();
      let vagas = Math.max(0, ENTREGAS_POR_NOITE - entregasNaNoite);
      analise.itens.forEach((item) => {
        const achados = conferirItem(item);
        let recusa: Recusa | null = null;
        if (vistos.has(item.idLocal)) {
          recusa = { idLocal: item.idLocal, motivo: 'idRepetido', detalhes: [`idLocal ${item.idLocal} repetido no lote`] };
        } else if (achados.length > 0) {
          const motivos = [...new Set(achados.map((a) => a.motivo))];
          recusa = {
            idLocal: item.idLocal,
            motivo: motivos[0],
            detalhes: achados.slice(0, 20).map((a) => `${a.motivo} em ${a.onde}`),
          };
        } else if (vagas === 0) {
          recusa = {
            idLocal: item.idLocal,
            motivo: 'limiteDaNoite',
            detalhes: [`${ENTREGAS_POR_NOITE} entregas na noite ${noite}`],
          };
        }
        vistos.add(item.idLocal);
        if (recusa) {
          recusadas.push(recusa);
          itemDaRecusa.push(item);
        } else {
          vagas -= 1;
          aceitos.push(item);
        }
      });
    }

    const aceitas = aceitos.map((item) => idDaEntrega(loteId, item.idLocal));
    aceitos.forEach((item, i) => {
      const { estado: _estado, ...campos } = item;
      tx.create(d.db.doc(`entregas/${aceitas[i]}`), {
        ...campos,
        estado: 'sugerido',
        agente: analise.agente,
        loteId,
        fontes: fontesDe(item.referencias),
        conferidoNoMotor: false,
        hashConteudo: sha256(JSON.stringify(item)),
        noite,
        criadaEm: em,
        atualizadoEm: em,
      });
    });

    recusadas.forEach((r, n) => {
      const original = itemDaRecusa[n];
      const item = original ? JSON.stringify(original).slice(0, ITEM_NA_QUARENTENA) : null;
      tx.create(d.db.doc(`quarentena/${loteId}-${n + 1}`), {
        loteId,
        agente: analise.agente,
        idLocal: r.idLocal,
        motivo: r.motivo,
        detalhes: r.detalhes,
        item,
        sha256: hash,
        noite,
        criadaEm: em,
      });
    });

    const estado: ResultadoLote['estado'] =
      aceitas.length === 0 ? 'recusado' : recusadas.length === 0 ? 'importado' : 'parcial';
    tx.create(loteRef, {
      agente: analise.agente,
      sha256: hash,
      tamanho: Buffer.byteLength(conteudo, 'utf8'),
      estado,
      aceitas,
      recusadas,
      noite,
      recebidoEm: em,
    });
    if (analise.agente && !analise.recusaLote && lotesDoAgente < LOTES_POR_AGENTE) {
      tx.set(
        noiteRef,
        {
          entregas: FieldValue.increment(aceitas.length),
          lotes: { [analise.agente]: FieldValue.increment(1) },
          atualizadoEm: em,
        },
        { merge: true },
      );
    }
    return { conflito: false as const, r: { loteId, estado, aceitas, recusadas, repetido: false } };
  });

  if (resultado.conflito) {
    // Mesmo loteId com outro conteúdo: alerta na quarentena (id pelo hash novo, então repetir não duplica) e 409.
    await d.db.doc(`quarentena/${loteId}-hash-${hash.slice(0, 12)}`).set({
      loteId,
      agente: analise.agente,
      idLocal: null,
      motivo: 'hashDiferente',
      detalhes: [`sha256 gravado ${resultado.sha256Antes.slice(0, 12)}, recebido ${hash.slice(0, 12)}`],
      item: null,
      sha256: hash,
      noite,
      criadaEm: em,
    });
    throw new HttpsError('already-exists', 'Lote já importado com outro conteúdo.', { codigo: 'hashDiferente' });
  }
  return resultado.r;
}
