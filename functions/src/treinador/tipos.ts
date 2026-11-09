// T87 · Tipos do contrato de dados do treinador (docs/tasks/T87-treinador.md, seção "Dados").
// O servidor é o dono destes documentos; mudança aqui vai para o contrato no mesmo commit.

export type Plataforma = 'lichess' | 'chesscom';
export type Ritmo = 'bullet' | 'blitz' | 'rapida';
export type Cor = 'brancas' | 'pretas';
export type Resultado = 'vitoria' | 'derrota' | 'empate';
export type StatusPartida = 'nova' | 'na_fila' | 'analisando' | 'pronta' | 'erro';
export type TipoExercicio = 'adversario' | 'profilaxia' | 'seu_melhor' | 'decisivo';
export type ClasseLance = 'ok' | 'imprecisao' | 'erro' | 'grave';

/** Partida como veio da plataforma, já no formato do contrato (sem análise). */
export interface PartidaBruta {
  /** `plataforma_idExterno`. */
  id: string;
  plataforma: Plataforma;
  idExterno: string;
  url: string;
  jogadaEm: Date;
  ritmo: Ritmo;
  /** "5+0". */
  cadencia: string;
  cor: Cor;
  adversario: { nome: string; rating: number | null };
  rating: number | null;
  resultado: Resultado;
  abertura: { eco: string; nome: string } | null;
  pgn: string;
}

export interface Falas {
  enunciado: string;
  acerto: string;
  erro: string;
  solucao: string;
}

export interface Exercicio {
  /** 1 a N, na ordem da partida. */
  n: number;
  tipo: TipoExercicio;
  /** Posição antes do lance a achar. */
  fen: string;
  /** Número do lance na partida ("Lance 8"). */
  lance: number;
  /** Lance certo, em UCI. */
  solucao: string;
  /** Outros lances aceitos (até 30 cp do melhor), em UCI. */
  aceitos: string[];
  /** O que foi jogado na partida, em SAN. */
  jogado: string;
  tema: string | null;
  /** 1 a 3. */
  estrelas: number;
  falas: Falas;
}

export interface LanceAnalisado {
  san: string;
  /** Posição depois do lance. */
  fen: string;
  /** Centipeões do ponto de vista das brancas (null com mate). */
  cp: number | null;
  /** Mate em N do ponto de vista das brancas (positivo: brancas dão), null sem mate. */
  mate: number | null;
  /** Melhor lance na posição anterior, em SAN. */
  melhor: string | null;
  classe: ClasseLance;
  comentario: string | null;
}

export interface CandidatoTeoria {
  san: string;
  partidas: number;
  brancas: number;
  empates: number;
  pretas: number;
  linha: string[];
}

export interface Teoria {
  /** Índice do meio-lance (0 = 1º lance das brancas) em que ele saiu da teoria. */
  lance: number;
  /** Posição antes desse meio-lance. */
  fen: string;
  candidatos: CandidatoTeoria[];
}

/** Precisão (0 a 100) do usuário em cada fase; null quando a partida não chegou à fase. */
export interface Fases {
  abertura: number | null;
  meio: number | null;
  final: number | null;
}

/** O que a análise acrescenta ao documento da partida. */
export interface ResultadoAnalise {
  resumo: string;
  precisao: number;
  exercicios: Exercicio[];
  lances: LanceAnalisado[];
  teoria: Teoria | null;
  fases: Fases;
  temas: string[];
  motor: { versao: string; nos: number };
  /** Erros do usuário (para as estatísticas): fase e tema por lance. */
  errosDoUsuario: { lance: number; indice: number; fen: string; fase: keyof Fases; tema: string | null }[];
  /** Segundos de motor gastos (custo estimado). */
  segundosMotor: number;
}
