/// Limites do torneio como meta (contrato T85-torneio-meta §8).
const maxTournamentName = 60;
const maxTournamentNotes = 500;
const maxTournamentRounds = 30;
const maxTournaments = 100;
const maxObjectiveHistory = 20;

/// O registro aceita datas de até 2 anos atrás.
const registerWindowYears = 2;

/// Corta o texto em [max] caracteres, sem espaço nas pontas.
String clampText(String text, int max) {
  final t = text.trim();
  if (t.length <= max) return t;
  // Não corta um emoji (par substituto) ao meio.
  final last = t.codeUnitAt(max - 1);
  final end = last >= 0xD800 && last <= 0xDBFF ? max - 1 : max;
  return t.substring(0, end).trimRight();
}
