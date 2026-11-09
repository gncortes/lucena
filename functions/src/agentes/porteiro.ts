// AG-5b.1 · Regras puras do porteiro (E1.21 §6.1 e §6.2): esquema único do lote (ajv), allowlist de URL,
// texto puro e o mapeamento referencias → fontes. Sem Firestore: a gravação fica em importar.ts.
import { createHash } from 'node:crypto';
import Ajv2020 from 'ajv/dist/2020';
import esquema from './entregas-v1.schema.json';
import dominios from './dominios.json';

/** Por que um lote ou item foi para a quarentena (o painel mostra o motivo). */
export const MOTIVOS_QUARENTENA = [
  'corpoGrande',
  'jsonInvalido',
  'esquema',
  'urlForaDaLista',
  'html',
  'comando',
  'caractereInvisivel',
  'idRepetido',
  'limiteDaNoite',
  'limiteLotesAgente',
  'hashDiferente',
] as const;
export type MotivoQuarentena = (typeof MOTIVOS_QUARENTENA)[number];

/** Corpo máximo do lote (§6.1). */
export const CORPO_MAXIMO = 256 * 1024;
/** Entregas aceitas por noite, somando todos os agentes (§6.1). */
export const ENTREGAS_POR_NOITE = 20;
/** Lotes por agente por noite (§6.1). */
export const LOTES_POR_AGENTE = 2;

export interface Referencia {
  tipo: string;
  titulo: string;
  url: string;
  origem: string;
  trecho?: string;
  publico?: boolean;
  data?: string;
}

export interface ItemLote {
  idLocal: string;
  referencias: Referencia[];
  [campo: string]: unknown;
}

export interface Lote {
  versao: 1;
  agente: string;
  resumo: string;
  geradoEm?: string;
  entregas: ItemLote[];
}

/** Um problema achado num texto: o motivo e onde (caminho no JSON). */
export interface Achado {
  motivo: MotivoQuarentena;
  onde: string;
}

const ajv = new Ajv2020({ allErrors: true, strict: false });
const validarLote = ajv.compile<Lote>(esquema);

const HOSTS = new Set<string>(dominios.hosts);
const TEXTO_LIVRE = new Set<string>(dominios.textoLivre);

export function sha256(texto: string): string {
  return createHash('sha256').update(texto, 'utf8').digest('hex');
}

/** A noite começa ao meio-dia de Brasília: o lote das 02:41 de 09/11 conta para a noite de 08/11. */
export function noiteDe(agora: Date, diaLocal: (d: Date) => string): string {
  return diaLocal(new Date(agora.getTime() - 12 * 3_600_000));
}

/** Confere o lote contra entregas-v1 (cópia de lucena-utils/agentes/esquema). Devolve até 20 erros legíveis. */
export function conferirEsquema(lote: unknown): { ok: true; lote: Lote } | { ok: false; erros: string[] } {
  if (validarLote(lote)) return { ok: true, lote };
  const erros = (validarLote.errors ?? []).slice(0, 20).map((e) => `${e.instancePath || '/'} ${e.message ?? ''}`.trim());
  return { ok: false, erros };
}

// Controle (menos \t \n \r), zero-width, marcas de direção e BOM.
const INVISIVEL = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F​-‏‪-‮⁠-⁤﻿]/;
// Tag (<script, </b, <!--, <?xml), entidade HTML e esquemas que executam.
const HTML = /<\s*\/?\s*[A-Za-z!?]|&(#\d+|#x[0-9a-f]+|[a-z]{2,8});|\b(javascript|vbscript|data)\s*:/i;
// Comando de shell e instrução para o modelo (mesma família do ORDEM do validar.py).
const COMANDO: RegExp[] = [
  /`/,
  /\$\(|\$\{/,
  /&&|\|\|/,
  /\|\s*(sh|bash|zsh|python3?|node)\b/,
  /\brm\s+-[a-z]*[rf]/i,
  /\b(curl|wget|sudo|chmod|eval|exec)\s/i,
  /\bignor(e|ar|em)\b.{0,30}\b(regras?|instru\w*|rules?|instructions?)\b/i,
  /instru[cç][oõ]es anteriores|previous instructions|system prompt|prompt do sistema/i,
];
// URL com esquema ou www., e domínio solto com TLD comum em minúsculas (ex.: "golpe.com/x").
const URL_NO_TEXTO =
  /\b(?:https?:\/\/|www\.)[^\s<>"')\]]+|\b(?:[a-z0-9-]+\.)+(?:com|org|net|app|io|br|ly|gg|tv|ovh|info|xyz|ru|de|site|link|top|click)\b(?:\/[^\s<>"')\]]*)?/gi;

/** Host da URL se ela é https, sem usuário/senha/porta; senão null. */
function hostHttps(url: string): string | null {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return null;
  }
  if (u.protocol !== 'https:' || u.username || u.password || u.port) return null;
  return u.hostname;
}

/** URL de referência: só https com host exatamente na allowlist. */
export function urlPermitida(url: string): boolean {
  const host = hostHttps(url);
  return host !== null && HOSTS.has(host);
}

/** Host citado no título de uma referência ("chessgames.com: …"): o da allowlist, com ou sem www. */
function hostDeReferencia(host: string): boolean {
  return HOSTS.has(host) || HOSTS.has(`www.${host}`) || TEXTO_LIVRE.has(host);
}

/**
 * Problemas de um texto livre (legenda, título, porquê…): só texto puro e só link para lucena.app. Nos campos de uma
 * referência (`naReferencia`), o nome do site da allowlist também vale.
 */
export function conferirTexto(texto: string, onde: string, naReferencia = false): Achado[] {
  const achados: Achado[] = [];
  if (INVISIVEL.test(texto)) achados.push({ motivo: 'caractereInvisivel', onde });
  // `lucena.app/p/<id>` é o marcador do link do app que o esquema manda escrever (o id ainda não existe na noite).
  if (HTML.test(texto.replaceAll('lucena.app/p/<id>', ''))) achados.push({ motivo: 'html', onde });
  if (COMANDO.some((r) => r.test(texto))) achados.push({ motivo: 'comando', onde });
  for (const m of texto.replaceAll('lucena.app/p/<id>', 'lucena.app/p/').match(URL_NO_TEXTO) ?? []) {
    const comEsquema = /^https?:\/\//i.test(m) ? m : `https://${m}`;
    let host: string | null = null;
    try {
      host = new URL(comEsquema).hostname;
    } catch {
      host = null;
    }
    const httpPuro = /^http:\/\//i.test(m);
    const permitido = host !== null && (naReferencia ? hostDeReferencia(host) : TEXTO_LIVRE.has(host));
    if (httpPuro || !permitido) {
      achados.push({ motivo: 'urlForaDaLista', onde });
      break;
    }
  }
  return achados;
}

/** Percorre todas as strings do item (valores e chaves); a URL de referências tem regra própria. */
export function conferirItem(item: ItemLote): Achado[] {
  const achados: Achado[] = [];
  const visitar = (v: unknown, onde: string): void => {
    if (typeof v === 'string') {
      if (/^\/referencias\/\d+\/url$/.test(onde)) {
        if (!urlPermitida(v)) achados.push({ motivo: 'urlForaDaLista', onde });
        if (INVISIVEL.test(v)) achados.push({ motivo: 'caractereInvisivel', onde });
      } else {
        achados.push(...conferirTexto(v, onde, /^\/referencias\/\d+\//.test(onde)));
      }
    } else if (Array.isArray(v)) {
      v.forEach((x, i) => visitar(x, `${onde}/${i}`));
    } else if (v !== null && typeof v === 'object') {
      for (const [k, x] of Object.entries(v)) {
        achados.push(...conferirTexto(k, `${onde}/${k}`).filter((a) => a.motivo !== 'urlForaDaLista'));
        visitar(x, `${onde}/${k}`);
      }
    }
  };
  visitar(item, '');
  return achados;
}

/** fontes[] da entrega (o formato que decidirEntrega e marcarFonteConferida já leem), uma por referência. */
export function fontesDe(referencias: Referencia[]): Record<string, unknown>[] {
  return referencias.map((r) => ({
    afirmacao: r.titulo,
    url: r.url,
    tipo: r.tipo,
    origem: r.origem,
    ...(r.data ? { data: r.data } : {}),
  }));
}

/** Id da entrega no Firestore: o porteiro carimba (o agente só dá o idLocal). */
export function idDaEntrega(loteId: string, idLocal: string): string {
  return `${loteId}-${idLocal}`.slice(0, 128);
}

/** loteId vem do caminho do arquivo no repositório dos agentes (ex.: 2026-11-09-roteirista-posicao-0241). */
export function loteIdValido(v: unknown): v is string {
  return typeof v === 'string' && /^[A-Za-z0-9_-]{3,100}$/.test(v);
}
