export interface LinkFallback {
  daily: boolean;
  target: string;
  fen: string | null;
  intent: string;
}

export function linkFallback(address: string): LinkFallback | null;
export function boardPreview(fen: string | null, orientation?: string): { squares: string[]; turn: 'white'|'black' } | null;
