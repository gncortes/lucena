import 'package:flutter/widgets.dart';

/// Objetivo, diagnóstico, plano, Guia e torneios do Treino (T85, Treino B).
abstract final class TrainingGoalKeys {
  // Objetivo.
  static const goalScreen = Key('treinoGoal.screen');
  static const goalTournament = Key('treinoGoal.tournament');
  static const goalImprove = Key('treinoGoal.improve');
  static const goalDateRow = Key('treinoGoal.dateRow');
  static const goalDateError = Key('treinoGoal.dateError');
  static const goalTomorrowWarning = Key('treinoGoal.tomorrowWarning');
  static const goalAddToCalendar = Key('treinoGoal.addToCalendar');
  static const goalContinue = Key('treinoGoal.continue');

  static const planUntilTournament = Key('treinoGoal.planUntilTournament');

  // Diagnóstico.
  static const diagnosticScreen = Key('treinoDiag.screen');
  static const diagnosticTest = Key('treinoDiag.test');
  static const diagnosticQuestionnaire = Key('treinoDiag.questionnaire');
  static const diagnosticOffline = Key('treinoDiag.offline');

  // Teste.
  static const testScreen = Key('treinoTest.screen');
  static const testProgress = Key('treinoTest.progress');
  static const testBoard = Key('treinoTest.board');
  static const testDontKnow = Key('treinoTest.dontKnow');
  static const testResume = Key('treinoTest.resume');
  static const testResumeContinue = Key('treinoTest.resumeContinue');
  static const testRestart = Key('treinoTest.restart');
  static const testResult = Key('treinoTest.result');
  static const testSeePlan = Key('treinoTest.seePlan');

  // Questionário.
  static const questScreen = Key('treinoQuest.screen');
  static const questBuild = Key('treinoQuest.build');
  static const questResume = Key('treinoQuest.resume');
  static const questRestart = Key('treinoQuest.restart');
  static Key questLevel(String part, String level) =>
      Key('treinoQuest.$part.$level');

  // Apresentação, semana, ajuste.
  static const presentationScreen = Key('treinoPresent.screen');
  static const presentationStart = Key('treinoPresent.start');
  static const presentationAdjust = Key('treinoPresent.adjust');
  static const presentationDeferred = Key('treinoPresent.deferred');
  static Key presentationWeek(int index) => Key('treinoPresent.week.$index');
  static const weekScreen = Key('treinoWeek.screen');
  static Key weekChapter(String id) => Key('treinoWeek.chapter.$id');
  static const adjustSheet = Key('treinoAdjust.sheet');
  static const adjustConfirm = Key('treinoAdjust.confirm');
  static const adjustUndo = Key('treinoAdjust.undo');

  // Aba Guia.
  static const guideTab = Key('treinoGuide.tab');
  static const guideEmpty = Key('treinoGuide.empty');
  static const guideDefine = Key('treinoGuide.define');
  static const guideChange = Key('treinoGuide.change');
  static const guideNode = Key('treinoGuide.node');
  static Key guideWeek(int index) => Key('treinoGuide.week.$index');
  static const guideLate = Key('treinoGuide.late');
  static const guideLateReplan = Key('treinoGuide.lateReplan');
  static const guideLateDismiss = Key('treinoGuide.lateDismiss');
  static const guideTournamentDay = Key('treinoGuide.tournamentDay');
  static const guideRegister = Key('treinoGuide.register');
  static const guidePlanDone = Key('treinoGuide.planDone');
  static const guideMyTournaments = Key('treinoGuide.myTournaments');
  static const guideImprove = Key('treinoGuide.improve');
  static const guidePushDenied = Key('treinoGuide.pushDenied');
  static const guidePushEnable = Key('treinoGuide.pushEnable');

  // Metas.
  static const goalCard = Key('treinoMetas.goalCard');
  static const goalCardDefine = Key('treinoMetas.goalCardDefine');
  static const streak = Key('treinoMetas.streak');
  static const missedNotice = Key('treinoMetas.missedNotice');
  static const missedSheet = Key('treinoMetas.missedSheet');
  static const missedMore = Key('treinoMetas.missedMore');
  static const missedKeep = Key('treinoMetas.missedKeep');
  static const missedConfirm = Key('treinoMetas.missedConfirm');

  // Catálogo.
  static const catalogFilter = Key('treinoCatalog.filter');
  static const catalogFilterPlan = Key('treinoCatalog.filterPlan');
  static const catalogFilterAll = Key('treinoCatalog.filterAll');
  static const catalogChangePlan = Key('treinoCatalog.changePlan');
  static const catalogAbout = Key('treinoCatalog.about');

  // Torneios.
  static const registerScreen = Key('treinoRegister.screen');
  static const registerName = Key('treinoRegister.name');
  static const registerDate = Key('treinoRegister.date');
  static const registerPoints = Key('treinoRegister.points');
  static const registerRounds = Key('treinoRegister.rounds');
  static const registerRatingBefore = Key('treinoRegister.ratingBefore');
  static const registerRatingAfter = Key('treinoRegister.ratingAfter');
  static const registerNotes = Key('treinoRegister.notes');
  static const registerSave = Key('treinoRegister.save');
  static Key registerPace(String name) => Key('treinoRegister.pace.$name');
  static Key registerEntity(String name) => Key('treinoRegister.entity.$name');
  static Key registerFeeling(int n) => Key('treinoRegister.feeling.$n');
  static const tournamentsScreen = Key('treinoTournaments.screen');
  static const tournamentsEmpty = Key('treinoTournaments.empty');
  static const tournamentsRegister = Key('treinoTournaments.register');
  static Key tournamentRow(String id) => Key('treinoTournaments.row.$id');
  static const nextGoalScreen = Key('treinoNext.screen');
  static const nextGoalTournament = Key('treinoNext.tournament');
  static const nextGoalImprove = Key('treinoNext.improve');
}
