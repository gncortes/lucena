// T87 · Falas por modelo (PT-BR, Viktor formal) dos exercícios, comentários dos lances e resumo.
// Régua: docs/ia/texto-de-tela.md e .claude/skills/aula-final/regras.md (notação R D T B C; o "erro" nunca dá a
// solução; sem "mate em N"; avaliação sempre com motivo concreto). Cada fato vem do motor (linha e tema).
import type { Achado, Tema } from './xadrez';
import type { ClasseLance, Cor, Falas, Fases, TipoExercicio } from './tipos';

/** Frase do tema para o acerto e a solução (vazia sem tema). */
function fraseDoTema(a: Achado, lado: string): string {
  switch (a.tema) {
    case 'mate':
      return `O rei ${lado === 'brancas' ? 'preto' : 'branco'} não escapa do mate.`;
    case 'garfo':
      return a.peca && a.alvos && a.alvos.length >= 2
        ? `É um garfo: ${a.peca} ataca ${a.alvos[0]} e ${a.alvos[1]} de uma vez.`
        : 'É um garfo: a peça ataca dois alvos de uma vez.';
    case 'peca_solta':
      return a.peca ? `${maiuscula(a.peca)} estava sem defensor.` : 'A peça capturada estava sem defensor.';
    case 'xeque_duplo':
      return 'Com o xeque duplo, o rei é obrigado a se mover.';
    case 'xeque_descoberto':
      return 'O xeque vem da peça de trás, e a peça que saiu fica livre para atacar.';
    case 'promocao':
      return 'O peão abre caminho até a promoção.';
    default:
      return '';
  }
}

/** Pergunta do "erro": aponta o tipo de recurso, nunca a peça, a casa ou o lance. */
function dicaDoTema(t: Tema | null): string {
  switch (t) {
    case 'mate':
      return 'Procure os xeques: o rei adversário tem poucas casas.';
    case 'garfo':
      return 'Procure um lance que ataque duas peças de uma vez.';
    case 'peca_solta':
      return 'Confira se alguma peça do adversário ficou sem defensor.';
    case 'xeque_duplo':
    case 'xeque_descoberto':
      return 'Procure um xeque que também libere outra peça.';
    case 'promocao':
      return 'Olhe para os peões mais avançados.';
    case 'final_peoes':
    case 'final_torres':
    case 'final_pecas_menores':
    case 'final_dama':
    case 'final':
      return 'Compare os lances do rei e dos peões passados.';
    default:
      return 'Compare os lances que forçam a resposta: xeques, capturas e ameaças.';
  }
}

function maiuscula(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export interface DadosFala {
  tipo: TipoExercicio;
  /** "14.Cf3" (solução numerada). */
  solucao: string;
  /** "14.Bd3" (o que foi jogado na partida, numerado). */
  jogado: string;
  /** Continuação do motor depois da solução ("14...Dxd4 15.Txd4"), pode ser vazia. */
  continuacao: string;
  /** Lado que joga o exercício. */
  lado: Cor;
  achado: Achado;
}

export function falasDoExercicio(d: DadosFala): Falas {
  const tema = fraseDoTema(d.achado, d.lado);
  const cont = d.continuacao ? ` A continuação é ${d.continuacao}.` : '';
  let enunciado: string;
  switch (d.tipo) {
    case 'adversario':
      enunciado = `Agora você joga com as ${d.lado}, no lugar do seu adversário. Ele jogou ${d.jogado}; encontre o lance mais forte.`;
      break;
    case 'decisivo':
      enunciado = `Este foi o momento que decidiu a partida. Você jogou ${d.jogado}; encontre o lance certo.`;
      break;
    default:
      enunciado = `Na partida, você jogou ${d.jogado}. Encontre um lance melhor.`;
  }
  return {
    enunciado,
    acerto: `${d.solucao}! ${tema}`.trim(),
    erro: `Não é esse o lance. ${dicaDoTema(d.achado.tema)}`,
    solucao: `A solução é ${d.solucao}. ${tema}${cont}`.replace(/\s+/g, ' ').trim(),
  };
}

/** Frase curta da resposta que pune, pelo tema do lance do adversário. */
function punicao(a: Achado): string {
  switch (a.tema) {
    case 'mate':
      return 'leva ao mate';
    case 'garfo':
      return 'faz um garfo';
    case 'peca_solta':
      return a.peca ? `captura ${a.peca}, que ficou sem defensor` : 'captura uma peça sem defensor';
    case 'xeque_duplo':
      return 'dá xeque duplo';
    case 'xeque_descoberto':
      return 'dá xeque descoberto';
    case 'promocao':
      return 'abre caminho para a promoção';
    default:
      return '';
  }
}

/** Comentário do lance (só imprecisão, erro e grave). */
export function comentarioDoLance(
  classe: ClasseLance,
  melhor: string | null,
  resposta: { lance: string; achado: Achado } | null,
): string | null {
  if (classe === 'ok' || !melhor) return null;
  const p = resposta ? punicao(resposta.achado) : '';
  const depois = p && resposta ? ` Agora ${resposta.lance} ${p}.` : '';
  const rotulo = classe === 'grave' ? 'Erro grave.' : classe === 'erro' ? 'Erro.' : 'Imprecisão.';
  return `${rotulo} O melhor era ${melhor}.${depois}`;
}

const NOME_FASE: Record<keyof Fases, string> = { abertura: 'na abertura', meio: 'no meio-jogo', final: 'no final' };

function plural(n: number, um: string, varios: string): string {
  return `${n} ${n === 1 ? um : varios}`;
}

/** Resumo da partida em uma ou duas frases, com os números da análise. */
export function resumoDaPartida(
  precisao: number,
  contagem: { grave: number; erro: number; imprecisao: number },
  piorFase: keyof Fases | null,
): string {
  const partes: string[] = [];
  if (contagem.grave) partes.push(plural(contagem.grave, 'erro grave', 'erros graves'));
  if (contagem.erro) partes.push(plural(contagem.erro, 'erro', 'erros'));
  if (contagem.imprecisao) partes.push(plural(contagem.imprecisao, 'imprecisão', 'imprecisões'));
  if (!partes.length) return `Precisão de ${precisao}%, sem erros.`;
  const lista = partes.length > 1 ? `${partes.slice(0, -1).join(', ')} e ${partes[partes.length - 1]}` : partes[0];
  const fase = piorFase ? ` A maior parte dos erros foi ${NOME_FASE[piorFase]}.` : '';
  return `Precisão de ${precisao}%, com ${lista}.${fase}`;
}
