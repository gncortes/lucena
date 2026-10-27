import 'package:flutter/widgets.dart';

abstract final class FeaturedKeys {
  // Na tela inicial.
  static const homeSection = Key('featured.home.section');
  static const homeSeeAll = Key('featured.home.seeAll');
  static const homeCard = Key('featured.home.card');

  // O cartão de um final (a chave leva o id).
  static Key card(String id) => Key('featured.card.$id');
  static const cardPlayed = Key('featured.card.played');

  // A lista.
  static const listScreen = Key('featured.list.screen');
  static const listEmpty = Key('featured.list.empty');
  static const listFilteredOut = Key('featured.list.filteredOut');
  static const clearFilters = Key('featured.list.clearFilters');
  static const countryFilter = Key('featured.list.country');
  static const ongoingTitle = Key('featured.list.ongoing');
  static Key originFilter(String code) => Key('featured.list.origin.$code');
  static const originAll = Key('featured.list.origin.all');
  static Key countryOption(String code) => Key('featured.list.country.$code');
  static const countryAll = Key('featured.list.country.all');
  static Key tournamentCard(String id) => Key('featured.tournamentCard.$id');

  // O torneio.
  static const tournamentScreen = Key('featured.tournament.screen');
  static const tournamentSummary = Key('featured.tournament.summary');
  static const tournamentName = Key('featured.tournament.name');
  static const tournamentOngoing = Key('featured.tournament.ongoing');
  static Key tournamentLink(String kind) =>
      Key('featured.tournament.link.$kind');
  static const tournamentNoFinals = Key('featured.tournament.noFinals');
  static const tournamentAlert = Key('featured.tournament.alert');
  static const tournamentMissing = Key('featured.tournament.missing');

  // O final.
  static const endgameScreen = Key('featured.endgame.screen');
  static const crowdCard = Key('featured.endgame.crowdCard');
  static const crowdFew = Key('featured.endgame.crowdFew');
  static const endgameMissing = Key('featured.endgame.missing');
  static const endgamePlayers = Key('featured.endgame.players');
  static const endgamePrompt = Key('featured.endgame.prompt');
  static const endgameBoard = Key('featured.endgame.board');
  static const opponentRow = Key('featured.endgame.opponent');
  static const clockRow = Key('featured.endgame.clock');
  static const lockedIcon = Key('featured.endgame.locked');
  static const configNote = Key('featured.endgame.note');
  static const playButton = Key('featured.endgame.play');
  static const bookButton = Key('featured.book');
  static const shareButton = Key('featured.share');

  // A folha de adversário e relógio.
  static const choiceSheet = Key('featured.choice.sheet');
  static Key choiceOpponent(String code) =>
      Key('featured.choice.opponent.$code');
  static Key choiceLevel(int level) => Key('featured.choice.level.$level');
  static Key choiceClock(String code) => Key('featured.choice.clock.$code');
  static const choiceDone = Key('featured.choice.done');

  // O livrinho ("Sobre a partida").
  static const bookSheet = Key('featured.book.sheet');
  static const bookTournament = Key('featured.book.tournament');
  static const bookWhite = Key('featured.book.white');
  static const bookBlack = Key('featured.book.black');
  static const bookHappened = Key('featured.book.happened');
  static const bookHappenedText = Key('featured.book.happenedText');
  static const bookFullGame = Key('featured.book.fullGame');

  // O fim da partida.
  static const playAgain = Key('featured.end.playAgain');
  static const continueButton = Key('featured.end.continue');
  static const nextSheet = Key('featured.next.sheet');
  static const nextLesson = Key('featured.next.lesson');
  static const nextSimilar = Key('featured.next.similar');
  static const nextMore = Key('featured.next.more');
  static const nextAgain = Key('featured.next.again');

  // Ache o lance.
  static const findScreen = Key('featured.find.screen');
  static const findBoard = Key('featured.find.board');
  static const findPrompt = Key('featured.find.prompt');
  static const findHint = Key('featured.find.hint');
  static const findHintText = Key('featured.find.hintText');
  static const findAnswer = Key('featured.find.answer');
  static const findResult = Key('featured.find.result');
  static const findRetry = Key('featured.find.retry');
  static const findContinue = Key('featured.find.continue');
}
