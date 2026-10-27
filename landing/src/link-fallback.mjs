const hosts = new Set(['playlucena.com', 'www.playlucena.com', 'lucena-2f4de.web.app']);

/** A visual preview only; the app validates the full position before play. */
export function boardPreview(fen, orientation = 'white') {
  const pieces = {K:'♔',Q:'♕',R:'♖',B:'♗',N:'♘',P:'♙',k:'♚',q:'♛',r:'♜',b:'♝',n:'♞',p:'♟'};
  if (typeof fen !== 'string') return null;
  const fields = fen.trim().split(/\s+/);
  if (!['w','b'].includes(fields[1])) return null;
  const ranks = fields[0].split('/');
  if (ranks.length !== 8) return null;
  const squares = [];
  for (const rank of ranks) {
    const row = [];
    for (const char of rank) {
      if (/^[1-8]$/.test(char)) row.push(...Array(Number(char)).fill(''));
      else if (Object.hasOwn(pieces,char)) row.push(pieces[char]);
      else return null;
    }
    if (row.length !== 8) return null;
    squares.push(...row);
  }
  return { squares: orientation === 'black' ? squares.reverse() : squares, turn: fields[1] === 'w' ? 'white' : 'black' };
}

/** Uses the browser URL: Astro's build-time path is / for Firebase rewrites. */
export function linkFallback(address) {
  const url = new URL(address);
  if (url.protocol !== 'https:' || !hosts.has(url.host)) return null;
  const daily = /^\/(dia|daily)\/?$/.test(url.pathname);
  if (!daily && !url.pathname.startsWith('/p/')) return null;
  const target = `${url.origin}${url.pathname}${url.search}`;
  return {
    daily,
    target,
    fen: daily ? null : url.searchParams.get('fen'),
    intent: `intent://${url.host}${url.pathname}${url.search}#Intent;scheme=https;package=com.gncortes.lucena;S.browser_fallback_url=${encodeURIComponent(target)};end`,
  };
}
