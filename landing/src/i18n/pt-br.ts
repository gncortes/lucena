import type { Dictionary } from './types';

const pt: Dictionary = {
  meta: {
    title: 'Lucena: treine finais de xadrez contra o Maia e o Stockfish',
    description:
      'Aprenda xadrez pelos finais. Treine finais de xadrez contra uma IA que joga como gente, do seu nível até o Stockfish na força máxima, com aulas interativas de dama contra torre, bispo e cavalo e muito mais.',
    ogAlt:
      'O app Lucena aberto num celular, com um final de xadrez no tabuleiro.',
  },
  nav: {
    features: 'Recursos',
    roadmap: 'Roadmap',
    support: 'Apoie',
    tester: 'Seja testador',
    skip: 'Pular para o conteúdo',
    theme: 'Alternar tema claro e escuro',
    language: 'Idioma',
    menu: 'Menu',
  },
  hero: {
    eyebrow: 'App de xadrez gratuito e de código aberto',
    title: 'Treine finais de xadrez até virar',
    titleAccent: 'técnica',
    lead: 'O Lucena coloca você para jogar finais contra uma IA que joga como gente, do seu nível até o Stockfish na força máxima.',
    cta: 'Quero ser testador',
    secondary: 'Ver como funciona',
    note: 'Android, versão de testes. Em breve no Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', 'Aulas interativas'],
  },
  stats: [
    { value: '9', label: 'níveis do Maia, de 1000 a 2600' },
    { value: '12', label: 'aulas de finais clássicos' },
    { value: '25', label: 'aulas para quem está começando' },
    { value: '55', label: 'finais para treinar quantas vezes quiser' },
  ],
  marquee: [
    'Posição de Lucena',
    'Posição de Philidor',
    'Dama contra torre',
    'Mate de bispo e cavalo',
    'Casas-chave',
    'Oposição à distância',
    'Defesa pela última fileira',
    'Defesa pelo lado curto',
  ],
  message: {
    kicker: 'Aprender xadrez pelos finais',
    title: 'Comece pelo fim do tabuleiro',
    quote:
      'Para melhorar o seu jogo, você deve estudar os finais antes de tudo.',
    quoteAuthor: 'José Raúl Capablanca, campeão mundial',
    body: [
      'Com poucas peças no tabuleiro, cada uma mostra o que sabe fazer. Fica mais fácil entender como o rei ataca, como a torre corta, como o bispo e o cavalo trabalham juntos.',
      'É aí que se aprende a jogar com precisão: cada lance conta, e você vê na hora o que funcionou. Essa clareza vale para a partida inteira.',
    ],
    boardCaption:
      'A primeira aula da escola do Viktor: só a torre no tabuleiro. Com poucas peças, cada uma mostra o que sabe fazer.',
  },
  story: {
    kicker: 'Por que o Lucena existe',
    title: 'Feito por quem ama xadrez',
    paragraphs: [
      'Sou programador e amo programar. Minha outra paixão é o xadrez. O Lucena nasceu de uma necessidade minha: os finais sempre foram o meu ponto fraco, e eu queria um jeito de treiná-los de verdade.',
      'O que funcionou foi treinar de forma progressiva: primeiro contra o Maia, uma IA que erra e acerta como gente do meu nível, depois subindo até o Stockfish. Repetir a mesma posição contra adversários cada vez mais fortes fixou as técnicas.',
      'Mas eu gosto tanto de xadrez que quis ir além: criar algo para que qualquer pessoa consiga aprender e praticar com facilidade e entrar no mundo desse jogo milenar. Quero espalhar o Lucena para que muita gente aprenda a jogar por ele e domine os finais que mais custam a entrar na cabeça.',
      'E quero mostrar como os finais são interessantes. Não é a parte do xadrez que mais aparece, mas é uma das mais bonitas. Philidor já estudava essas posições no século XVIII, e muitos, como o grande mestre Rafael Leitão, o consideram o maior gênio da história do xadrez.',
    ],
    signature: 'Gabriel, criador do Lucena',
  },
  features: {
    kicker: 'Recursos',
    title: 'Tudo para dominar os finais',
    items: {
      progression: {
        title: 'Do Maia ao Stockfish',
        body: 'Jogue contra o Maia, uma IA treinada em partidas de pessoas reais, com estilo humano no seu nível: de 1000 a 2600. Escolha o ritmo, suba degrau por degrau e, quando estiver pronto, enfrente o Stockfish na força máxima.',
        bullets: [
          'Níveis humanos de 1000 a 2600',
          'Relógio com tempo e incremento',
          'Stockfish na força máxima',
        ],
      },
      lessons: {
        title: 'Aulas que dividem o difícil em passos simples',
        body: 'Finais complexos viram etapas curtas e interativas. Você aprende cada ideia, pratica na hora e só segue quando acertar.',
        bullets: [
          'Dama contra torre',
          'Mate de bispo e cavalo',
          'Finais de torre e de peões',
        ],
      },
      levels: {
        title: 'Treino para iniciantes e intermediários',
        body: 'Quem está começando aprende as peças com aulas guiadas. Quem já joga segue a Jornada: desafios por nível de rating, com adversários que têm personalidade.',
        bullets: [
          'Aulas guiadas para quem está começando',
          'Jornada por nível de rating',
          'Estrelas e conquistas para acompanhar o progresso',
        ],
      },
      speedrun: {
        title: 'Speedrun: contra o relógio',
        body: 'Resolva uma sequência de finais o mais rápido que conseguir. Bata o seu recorde e veja a técnica ficar automática.',
        bullets: ['Parciais por etapa', 'Recorde pessoal', 'Vários ritmos'],
      },
      analysis: {
        title: 'Análise da partida',
        body: 'Depois de jogar, reveja lance a lance com a avaliação da engine e descubra onde a vitória escapou ou onde a defesa segurou.',
        bullets: [
          'Barra de avaliação',
          'Melhores lances da engine',
          'Precisão de cada jogador',
        ],
      },
      custom: {
        title: 'Do seu jeito',
        body: 'Tema claro ou escuro, cores do app, peças e tabuleiro, relógio em cima ou embaixo. O app se adapta a você.',
        bullets: [],
      },
    },
  },
  levels: {
    kicker: 'Para todos os níveis',
    title: 'Sabe pouco ou já joga bem? Tem desafio para você',
    beginner: {
      title: 'Está começando',
      body: 'Aprenda como cada peça se move e dá mate com aulas curtas, dicas na hora certa e adversários que jogam no seu ritmo.',
    },
    advanced: {
      title: 'Já joga bem',
      body: 'Converta finais teóricos contra o Maia 2600 e o Stockfish. Se você ganhar a dama contra a torre do Stockfish, a técnica é sua.',
    },
  },
  roadmap: {
    kicker: 'Roadmap',
    title: 'Para onde o Lucena vai',
    items: [
      {
        status: 'Agora',
        title: 'Versão de testes no Android',
        body: 'Quem entra no grupo de testes recebe sempre a versão mais recente.',
      },
      {
        status: 'Em preparação',
        title: 'Google Play',
        body: 'A publicação na loja já está sendo preparada.',
      },
      {
        status: 'Em seguida',
        title: 'App Store',
        body: 'Levar o Lucena ao iPhone é o próximo passo, e é aí que o seu apoio faz diferença.',
      },
    ],
  },
  support: {
    kicker: 'Apoie o projeto',
    title: 'Para onde vai o dinheiro',
    body: [
      'O Lucena é gratuito e de código aberto. Para publicar na App Store, a Apple exige o Apple Developer Program, que custa US$ 99 por ano.',
      'As doações pagam essa conta: elas levam o app ao iPhone e ajudam a validar a ideia por lá. Qualquer valor ajuda.',
    ],
    price: 'US$ 99',
    priceNote: 'por ano, para publicar na App Store',
    cta: 'Fazer uma doação',
    placeholder: 'Link de doação em breve',
  },
  tester: {
    kicker: 'Seja testador',
    title: 'Teste antes de todo mundo',
    body: 'Entre no grupo de testes e receba sempre a versão mais recente do Lucena no seu Android.',
    teachers:
      'É professor de xadrez? Passe o app para os seus alunos. Os finais são a melhor porta de entrada, e o feedback de quem ensina vale ouro.',
    cta: 'Entrar no grupo de testes',
    thanks:
      'Obrigado de verdade. Alguém dedicar tempo para testar, validar a ideia e mandar feedback é muito importante para mim. Cada mensagem ajuda a decidir o próximo passo do app.',
  },
  vision: {
    kicker: 'Visão',
    title: 'Um projeto vivo',
    body: 'O objetivo é oferecer a melhor experiência para aprender xadrez, melhorar nos finais e se desafiar neles. O Lucena vai crescer com novos recursos, guiados pelo que a comunidade pedir.',
    cta: 'Sugerir um recurso',
  },
  footer: {
    tagline: 'Treine finais de xadrez contra o Maia e o Stockfish.',
    source: 'Código no GitHub',
    license: 'Licença AGPL-3.0',
    contact: 'Contato e sugestões',
    credits:
      'Maia: CSSLab, Universidade de Toronto. Stockfish: projeto Stockfish (GPL-3.0). Peças: cburnett, de Colin M.L. Burnett.',
  },
  media: {
    hero: 'Escolha do nível do Maia e do ritmo, e a partida contra ele no Lucena',
    school: 'Primeira aula da escola do Viktor no Lucena: a torre e as estrelas',
    journey: 'A Jornada do Lucena: o adversário atual e os desafios',
    queenRook: 'Aula interativa de dama contra torre no Lucena',
    speedrun: 'Speedrun do Lucena: as etapas e a partida contra o relógio',
    theme: 'Escolha do tema escuro e da cor do app no Lucena',
    journeyChallenge: 'Desafio da Jornada no Lucena: mate de dama contra o Tito, nível 1200',
    exercise: 'Exercício de dama contra torre numa aula de finais do Lucena',
    queenRookLesson: 'Aula de finais do Lucena: dama contra torre, como chegar a Philidor',
    shortSide: 'Aula de finais do Lucena: a defesa pelo lado curto',
    stars: 'Desafio das estrelas do Lucena com a torre, no nível difícil',
    play: 'Reproduzir vídeo',
    pause: 'Pausar vídeo',
  },
};

export default pt;
