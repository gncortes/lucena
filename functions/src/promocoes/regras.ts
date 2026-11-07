// Promoções do Pilares (E1.19 R5, contrato de promoções §3): as regras que não
// dependem do Firestore nem da Play. Só o vitalício tem promoção e o cupom só
// chega pelo link (decisão 6 do Gabriel).
import { HttpsError } from 'firebase-functions/https';

/** O único produto com promoção (Play: compra única). */
export const PRODUTO = 'pilares_vitalicio';

export const ORIGENS = ['instagram', 'youtube', 'facebook', 'x', 'parceiro', 'outro'] as const;
export type Origem = (typeof ORIGENS)[number];

export type Tipo = 'todos' | 'link';

/** Desconto em % (5 a 90) ou em centavos de real (só Brasil). */
export type Desconto = { tipo: 'pct'; valor: number } | { tipo: 'brl'; centavos: number };

export interface PedidoPromocao {
  tipo: Tipo;
  nome: string;
  desconto: Desconto;
  inicio: Date;
  fim: Date | null;
  origem: Origem | null;
  parceiro: string | null;
  codigo: string | null;
  limite: number | null;
}

const HORA = 3600_000;
const DIA = 24 * HORA;
/** Regra 3: a Play leva tempo para entregar a oferta nova ao app. */
export const ANTECEDENCIA_TODOS = HORA;
export const DURACAO_MAXIMA_TODOS = 31 * DIA;

function invalido(msg: string, codigo?: string): never {
  throw new HttpsError('invalid-argument', msg, codigo ? { codigo } : undefined);
}

function data(v: unknown, campo: string): Date {
  const d = new Date(String(v));
  if (v === undefined || v === null || v === '' || Number.isNaN(d.getTime())) invalido(`${campo}: data ISO.`);
  return d;
}

/** Regra 2: % inteiro de 5 a 90, ou valor em reais menor que o preço. */
export function lerDesconto(v: unknown, precoCentavos: number): Desconto {
  const d = (v ?? {}) as Record<string, unknown>;
  if (d.tipo === 'pct') {
    const valor = d.valor;
    if (typeof valor !== 'number' || !Number.isInteger(valor) || valor < 5 || valor > 90) {
      invalido('O desconto vai de 5% a 90%.', 'descontoForaDaFaixa');
    }
    return { tipo: 'pct', valor };
  }
  if (d.tipo === 'brl') {
    const centavos = d.centavos;
    if (typeof centavos !== 'number' || !Number.isInteger(centavos) || centavos <= 0 || centavos >= precoCentavos) {
      invalido('O desconto em reais tem de ser menor que o preço.', 'descontoForaDaFaixa');
    }
    return { tipo: 'brl', centavos };
  }
  return invalido('desconto: {tipo: pct, valor} ou {tipo: brl, centavos}.');
}

/** Regra 6: 4 a 20 maiúsculas e números (o que vier minúsculo sobe). */
export function normalizarCodigo(v: unknown): string {
  if (typeof v !== 'string') invalido('Código: 4 a 20 letras e números.', 'codigoInvalido');
  const c = v.trim().toUpperCase();
  if (!/^[A-Z0-9]{4,20}$/.test(c)) invalido('Código: 4 a 20 letras e números.', 'codigoInvalido');
  return c;
}

/** Regra 6: sem 0/O/1/I, que se confundem ao digitar ou ler. */
export const ALFABETO_CODIGO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** Código gerado: 6 caracteres do [ALFABETO_CODIGO]; [sorteio] devolve um número em [0, 1). */
export function gerarCodigo(sorteio: () => number = Math.random): string {
  let c = '';
  for (let i = 0; i < 6; i++) c += ALFABETO_CODIGO[Math.floor(sorteio() * ALFABETO_CODIGO.length)];
  return c;
}

/** Regra 6: o link que o painel copia. */
export function linkDoCupom(codigo: string, origem: Origem): string {
  return `https://playlucena.com/oferta/${codigo}?utm_source=${origem}&utm_campaign=${codigo.toLowerCase()}`;
}

/** Regras 1 a 4 e 6 (formato): lê o pedido do painel; datas em UTC (o painel converte de Brasília). */
export function lerPedidoPromocao(dados: unknown, precoCentavos: number, agora: Date): PedidoPromocao {
  const d = (dados ?? {}) as Record<string, unknown>;
  if (d.tipo !== 'todos' && d.tipo !== 'link') invalido('tipo: todos ou link.');
  const tipo = d.tipo as Tipo;
  if (typeof d.nome !== 'string' || d.nome.trim().length === 0 || d.nome.trim().length > 60) {
    invalido('Dê um nome de até 60 caracteres.', 'nomeInvalido');
  }
  const nome = d.nome.trim();
  const desconto = lerDesconto(d.desconto, precoCentavos);

  if (tipo === 'todos') {
    const inicio = data(d.inicio, 'inicio');
    const fim = data(d.fim, 'fim');
    if (inicio.getTime() < agora.getTime() + ANTECEDENCIA_TODOS) {
      invalido('A promoção começa daqui a 1 hora ou mais.', 'inicioCedo');
    }
    if (fim <= inicio) invalido('O fim vem depois do começo.', 'fimAntesDoInicio');
    if (fim.getTime() - inicio.getTime() > DURACAO_MAXIMA_TODOS) {
      invalido('A promoção dura no máximo 31 dias.', 'duracaoLonga');
    }
    if (d.limite !== undefined && d.limite !== null) invalido('Limite de usos só vale para link.');
    if (d.codigo !== undefined && d.codigo !== null) invalido('Código só vale para link.');
    return { tipo, nome, desconto, inicio, fim, origem: null, parceiro: null, codigo: null, limite: null };
  }

  const inicio = d.inicio === undefined || d.inicio === null ? agora : data(d.inicio, 'inicio');
  const fim = d.fim === undefined || d.fim === null ? null : data(d.fim, 'fim');
  if (fim && fim <= inicio) invalido('O fim vem depois do começo.', 'fimAntesDoInicio');
  if (fim && fim <= agora) invalido('O fim já passou.', 'fimAntesDoInicio');
  if (!ORIGENS.includes(d.origem as Origem)) invalido(`origem: ${ORIGENS.join(', ')}.`);
  const origem = d.origem as Origem;
  let parceiro: string | null = null;
  if (origem === 'parceiro') {
    if (typeof d.parceiro !== 'string' || d.parceiro.trim().length === 0 || d.parceiro.trim().length > 60) {
      invalido('Informe o nome do parceiro.', 'parceiroFaltando');
    }
    parceiro = d.parceiro.trim();
  }
  const codigo = d.codigo === undefined || d.codigo === null || d.codigo === '' ? null : normalizarCodigo(d.codigo);
  const limite = lerLimite(d.limite, 0);
  return { tipo, nome, desconto, inicio, fim, origem, parceiro, codigo, limite };
}

/** Regras 4 e 7: inteiro ≥ 1 e nunca abaixo dos usos já feitos; null = sem limite. */
export function lerLimite(v: unknown, usos: number): number | null {
  if (v === undefined || v === null) return null;
  if (typeof v !== 'number' || !Number.isInteger(v) || v < 1 || v > 1_000_000) {
    invalido('Limite de usos: número inteiro a partir de 1.', 'limiteInvalido');
  }
  if (v < usos) invalido(`O limite não pode ficar abaixo dos ${usos} usos feitos.`, 'limiteAbaixoDosUsos');
  return v;
}

/** Valor do desconto em centavos sobre o preço (para comparar % com R$, regra 5). */
export function centavosDeDesconto(d: Desconto, precoCentavos: number): number {
  return d.tipo === 'pct' ? Math.round((precoCentavos * d.valor) / 100) : d.centavos;
}

/** Os dois períodos se cruzam (fim null = sem fim). */
export function cruzam(a: { inicio: Date; fim: Date | null }, b: { inicio: Date; fim: Date | null }): boolean {
  const fimA = a.fim?.getTime() ?? Infinity;
  const fimB = b.fim?.getTime() ?? Infinity;
  return a.inicio.getTime() < fimB && b.inicio.getTime() < fimA;
}

/** Regra 5: entre duas que valem ao mesmo tempo, vence o maior desconto; empate, a que termina primeiro. */
export function vence<T extends { desconto: Desconto; fim: Date | null }>(a: T, b: T, precoCentavos: number): T {
  const da = centavosDeDesconto(a.desconto, precoCentavos);
  const db = centavosDeDesconto(b.desconto, precoCentavos);
  if (da !== db) return da > db ? a : b;
  return (a.fim?.getTime() ?? Infinity) <= (b.fim?.getTime() ?? Infinity) ? a : b;
}

/** Id da oferta na Play: Para todos = slug + ano (`black-friday-2026`); link = por nível (`link-20`, `link-brl-1000`). */
export function idDaOferta(p: Pick<PedidoPromocao, 'tipo' | 'nome' | 'desconto' | 'inicio'>): string {
  if (p.tipo === 'link') {
    return p.desconto.tipo === 'pct' ? `link-${p.desconto.valor}` : `link-brl-${p.desconto.centavos}`;
  }
  const slug = p.nome
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 50)
    .replace(/-+$/g, '');
  const ano = String(p.inicio.getUTCFullYear());
  const base = slug.length === 0 ? 'promocao' : slug;
  return base.endsWith(ano) ? base : `${base}-${ano}`;
}

/** Situação gravada; o estado da tela sai dela e das datas ([estadoDe]). */
export type Situacao = 'publicada' | 'naoPublicada' | 'encerrada';
export type EncerradaPor = 'data' | 'limite' | 'mao';
export type Estado =
  | { estado: 'agendada' }
  | { estado: 'ativa' }
  | { estado: 'encerrada'; por: EncerradaPor }
  | { estado: 'naoPublicada'; motivo: string };

export interface PromocaoGravada {
  situacao: Situacao;
  inicio: Date;
  fim: Date | null;
  limite: number | null;
  usos: number;
  encerradaPor?: EncerradaPor | null;
  motivoPlay?: string | null;
}

/** Regra 9: Agendada · Ativa · Encerrada (por data, por limite ou à mão) · Não publicada. */
export function estadoDe(p: PromocaoGravada, agora: Date): Estado {
  if (p.situacao === 'naoPublicada') return { estado: 'naoPublicada', motivo: p.motivoPlay ?? 'outro' };
  if (p.situacao === 'encerrada') return { estado: 'encerrada', por: p.encerradaPor ?? 'mao' };
  if (p.fim && p.fim <= agora) return { estado: 'encerrada', por: 'data' };
  if (p.limite !== null && p.usos >= p.limite) return { estado: 'encerrada', por: 'limite' };
  if (p.inicio > agora) return { estado: 'agendada' };
  return { estado: 'ativa' };
}
